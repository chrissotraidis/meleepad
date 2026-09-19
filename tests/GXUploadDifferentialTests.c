#include "StaticRecompABI.h"
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>
static const StaticRecompModuleDesc *modules[2];
static unsigned long long rng=0x398316575abULL;
static unsigned rnd(void){rng^=rng<<13;rng^=rng>>7;rng^=rng<<17;return (unsigned)rng;}
struct Event {u32 pc,ea;u64 value;u8 size,write;CPUState state;};
static struct Event events[2][1024];static unsigned counts[2],arm;static int mutate, timing;
static void record(CPUState*c,u32 ea,u64 value,u8 size,u8 write){unsigned n=counts[arm]++;if(n>=1024)abort();events[arm][n].pc=c->pc;events[arm][n].ea=ea;events[arm][n].value=value;events[arm][n].size=size;events[arm][n].write=write;if(!timing){events[arm][n].state=*c;events[arm][n].state.ram=NULL;}if(mutate && n==0){switch(mutate%5){case 0:c->msr&=~PPC_MSR_FP;break;case 1:c->gqr[0]=0x040004;break;case 2:c->hid2=0;break;case 3:c->exception=1;break;case 4:c->gpr[4]=0x80002000;break;}}}
static u64 rd(CPUState*c,u32 ea,u8 size){u64 v=((u64)ea<<32)|(ea^0xabc78123u);record(c,ea,v,size,0);return v;}
static void wr(CPUState*c,u32 ea,u64 value,u8 size){record(c,ea,value,size,1);}
static const u32 entry[]={0x80341408,0x8034143C,0x80342204,0x80379A20,0x8037A54C};
static const char* names[]={"WriteMTXPS4x3","WriteMTXPS3x3from3x4","PSMTXConcat","HSD_MtxInverseTranspose","HSD_MtxScaledAdd"};
static void setup(CPUState*c,u8*ram,unsigned n,unsigned which){
 memset(c,0,sizeof(*c));c->ram=ram;c->ram_size=5242880;c->pc=entry[which];c->lr=0x81234000;c->msr=PPC_MSR_FP;c->hid2=PPC_HID2_LSQE;
 for(int i=0;i<32;i++){c->gpr[i]=rnd();c->fpr[i]=(int)rnd()/33554432.0;c->ps1[i]=(int)rnd()/67108864.0;}
 if(n%2)c->fpr[1]=0.5;c->gpr[1]=0x80004000;c->gpr[2]=0x80008000;c->gpr[3]=0x80002000;c->gpr[4]=0x80002800;c->gpr[5]=0x80003000;c->cr=rnd();c->xer=rnd();c->fpscr=rnd()&0x0007f8ff;c->downcount=-(n%600);
 for(int i=0;i<65536;i+=4)write_be32(ram+i,rnd());
 for(int j=0;j<3;j++)for(int i=0;i<12;i++){float f=(int)rnd()/268435456.0f;u32 bits;memcpy(&bits,&f,4);write_be32(ram+0x2000+j*0x800+i*4,bits);}
 // Constants consumed by the original inverse routine, not by the candidate generator.
 const float constants[]={1.0e-10f,1.0f,0.0f};for(int i=0;i<3;i++){u32 bits;memcpy(&bits,&constants[i],4);write_be32(ram+0x8000-5000+i*4,bits);}
 if(which<2)c->gpr[4]=0xcc008000;
 write_be32(ram+0x4D5C00,0);write_be32(ram+0x4D5C04,0x3f800000);c->external_read=rd;c->external_write=wr;
}
static double now(void){struct timespec ts;clock_gettime(CLOCK_MONOTONIC,&ts);return ts.tv_sec+ts.tv_nsec*1e-9;}
static double bench(unsigned which,unsigned variant,CPUState*c){
 unsigned runs=100000;timing=1;arm=variant;mutate=0;double start=now();
 for(unsigned i=0;i<runs;i++){c->pc=entry[which];c->lr=0x81234000;c->gpr[1]=0x80004000;c->gpr[3]=0x80002000;c->gpr[4]=which<2?0xcc008000:0x80002800;c->gpr[5]=0x80003000;c->downcount=0;if(which==4)c->fpr[1]=0.5;counts[variant]=0;modules[variant]->dispatch(c,c->pc);if(c->pc!=0x81234000 || c->exception || (which<2 && counts[variant]!=6)){printf("BAD BENCH state %s pc=%x exception=%u events=%u\n",names[which],c->pc,c->exception,counts[variant]);exit(4);}}
 return (now()-start)*1e9/runs;
}
int main(int argc,char**argv){
 if(argc!=3)return 2;
 for(int i=0;i<2;i++){void*h=dlopen(argv[i+1],RTLD_NOW|RTLD_LOCAL);if(!h){puts(dlerror());return 2;}StaticRecompGetModuleFn fn=(StaticRecompGetModuleFn)dlsym(h,STATICRECOMP_GET_MODULE_SYMBOL);if(!fn)return 2;modules[i]=fn();if(modules[i]->cpu_state_size!=sizeof(CPUState)||modules[i]->cpu_abi_version!=GXRUNTIME_CPU_ABI_VERSION)return 2;}
 const StaticRecompModuleDesc*a=modules[0],*b=modules[1];
 if(a->abi_version!=b->abi_version||a->num_code_ranges!=b->num_code_ranges||a->num_chunk_ranges!=b->num_chunk_ranges||a->num_smc_ranges!=b->num_smc_ranges||memcmp(a->code_ranges,b->code_ranges,a->num_code_ranges*sizeof(*a->code_ranges))||memcmp(a->chunk_ranges,b->chunk_ranges,a->num_chunk_ranges*sizeof(*a->chunk_ranges))||memcmp(a->chunk_hashes,b->chunk_hashes,a->num_chunk_ranges*sizeof(*a->chunk_hashes))||memcmp(a->smc_ranges,b->smc_ranges,a->num_smc_ranges*sizeof(*a->smc_ranges)))return 3;
 u8 *ra=calloc(5242880,1),*rb=calloc(5242880,1);CPUState x,y;
 const u32 edges[]={0,0x80000000,0x7f800000,0xff800000,0x7fc12345,0x7f812345,1,0x007fffff,0x00800000,0x7f7fffff};
 for(unsigned which=0;which<2;which++){timing=0;
  for(unsigned n=0;n<3000;n++){
   setup(&x,ra,n,which);
   if(n%4==0)for(int i=0;i<12;i++)write_be32(ra+0x2000+i*4,edges[(n/4+i)%10]);
   if(n%4==1)for(int i=0;i<12;i++)write_be32(ra+0x2000+i*4,rnd());
   if(n%11==0)x.msr=0;
   if(n%13==0)x.hid2=0;
   if(n%17==0)x.gqr[0]=rnd();
   if(n%19==0)x.gpr[5]=x.gpr[3]+4;
   if(n%23==0)x.gpr[4]=x.gpr[3];
   if(n%29==0)x.gpr[3]=0x8000fff0;
   if(n%31==0)x.gpr[1]=0x80000020;
   if(n%37==0){x.reserve_valid=1;x.reserve_addr=x.gpr[5];}
   if(n%41==0)x.exception=1;
   if(n%47==0)x.gpr[3]=0x804ffff0;
   if(n%53==0)x.gpr[3]=0xcc008000;
   if(n%59==0)x.gpr[3]=0x2000;
   if(n%61==0)x.gpr[3]=0x80002001;

   mutate=n%43==0 ? 1+n%5 : 0;
   y=x;memcpy(rb,ra,5242880);y.ram=rb;memset(events,0,sizeof(events));counts[0]=counts[1]=0;
   arm=0;if(modules[0]->on_state_loaded)modules[0]->on_state_loaded(&x);int ca=modules[0]->dispatch(&x,x.pc);
   arm=1;if(modules[1]->on_state_loaded)modules[1]->on_state_loaded(&y);int cb=modules[1]->dispatch(&y,y.pc);y.ram=ra;
   if(ca!=cb||memcmp(&x,&y,sizeof(x))||memcmp(ra,rb,5242880)||counts[0]!=counts[1]||memcmp(events[0],events[1],counts[0]*sizeof(events[0][0]))){printf("FAIL %s case %u pc=%x/%x events=%u/%u\n",names[which],n,x.pc,y.pc,counts[0],counts[1]);for(unsigned i=0;i<sizeof(x);i++)if(((u8*)&x)[i]!=((u8*)&y)[i]){printf("first CPU offset=%u\n",i);for(unsigned r=0;r<32;r++){unsigned long long fa,fb;memcpy(&fa,&x.fpr[r],8);memcpy(&fb,&y.fpr[r],8);if(fa!=fb)printf("f%u %016llx/%016llx\n",r,fa,fb);}break;}return 1;}
  }
  printf("PASS 3000 differential cases %s\n",names[which]);fflush(stdout);
  mutate=0;setup(&x,ra,1,which);x.fpscr=0;x.msr=PPC_MSR_FP;x.hid2=PPC_HID2_LSQE;if(modules[0]->on_state_loaded)modules[0]->on_state_loaded(&x);
  for(int round=0;round<5;round++){double ca,cb;if(round%2){cb=bench(which,1,&x);ca=bench(which,0,&x);}else{ca=bench(which,0,&x);cb=bench(which,1,&x);}printf("BENCH %s control_ns=%.1f candidate_ns=%.1f saving=%.2f%%\n",names[which],ca,cb,100*(1-cb/ca));fflush(stdout);}
 }
 puts("PASS module ABI, code ranges, SMC ranges and original chunk hashes unchanged");return 0;
}
