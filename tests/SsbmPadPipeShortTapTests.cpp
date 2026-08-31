#include <cassert>
#include <iostream>

#include "InputCommon/ControllerInterface/ControllerInterface.h"

#define private public
#include "InputCommon/ControllerInterface/Pipes/Pipes.h"
#undef private

bool ciface::Core::Device::Control::IsMatchingName(std::string_view name) const
{
  return GetName() == name;
}

bool ciface::Core::Device::Control::IsHidden() const
{
  return false;
}

int main()
{
  using PipeInput = ciface::Pipes::PipeDevice::PipeInput;

  PipeInput short_tap("Button A", true);
  short_tap.SetState(1.0);
  short_tap.SetState(0.0);
  assert(short_tap.GetState() == 1.0);
  assert(short_tap.GetState() == 0.0);

  PipeInput observed_hold("Button B", true);
  observed_hold.SetState(1.0);
  assert(observed_hold.GetState() == 1.0);
  observed_hold.SetState(1.0);
  observed_hold.SetState(0.0);
  assert(observed_hold.GetState() == 0.0);

  PipeInput ordinary_axis("Axis MAIN X +");
  ordinary_axis.SetState(1.0);
  ordinary_axis.SetState(0.0);
  assert(ordinary_axis.GetState() == 0.0);

  std::cout << "SsbmPad pipe short-tap tests passed\n";
  return 0;
}
