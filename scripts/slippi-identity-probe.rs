// Run only in a fresh directory under a network-denied OS sandbox.
// Uses the real pinned Rust UserManager; all account values are synthetic.
use slippi_gg_api::APIClient;
use slippi_user::UserManager;
use std::path::PathBuf;

fn identity(manager: &UserManager) -> (String, String, String) {
    manager.get(|u| (u.uid.clone(), u.play_key.clone(), u.connect_code.clone()))
}

fn main() {
    let root = PathBuf::from(std::env::args().nth(1).expect("fresh test directory"));
    assert!(!root.exists());
    std::fs::create_dir_all(&root).unwrap();
    let version = "0.0.0-meleepad-dev";
    let client = APIClient::new(version);
    let mut managers = Vec::new();
    for i in 0..1000 {
        let directory = root.join(i.to_string());
        std::fs::create_dir(&directory).unwrap();
        let manager = UserManager::new(client.clone(), directory, version.into());
        assert_eq!(identity(&manager), (String::new(), String::new(), String::new()));
        manager.set(|u| {
            u.uid = format!("offline-fixture-{i}");
            u.play_key = format!("not-a-real-credential-{i}");
            u.connect_code = format!("TEST#{i}");
        });
        managers.push(manager);
    }
    for (i, manager) in managers.iter().enumerate() {
        assert_eq!(identity(manager), (format!("offline-fixture-{i}"),
            format!("not-a-real-credential-{i}"), format!("TEST#{i}")));
    }
    // Cloning a manager intentionally shares one account. It is NOT a new user.
    let alias = managers[0].clone();
    managers[0].set(|u| u.display_name = "Changed fixture".into());
    assert_eq!(alias.get(|u| u.display_name.clone()), "Changed fixture");
    assert!(managers[1].get(|u| u.display_name.is_empty()));

    // Exercise the actual file loader under network denial. Loading a local
    // credential file can succeed even though server verification cannot.
    let fixture = r#"{"uid":"offline-file-user","playKey":"not-a-real-key","displayName":"Fixture","connectCode":"TEST#9999","latestVersion":"0.0.0"}"#;
    std::fs::write(root.join("0/user.json"), fixture).unwrap();
    std::fs::write(root.join("1/user.json"), fixture).unwrap();
    assert!(managers[0].attempt_login());
    assert!(managers[1].attempt_login());
    assert_eq!(identity(&managers[0]), identity(&managers[1]));
    // A cloned user.json duplicates account identity despite separate folders.
    // Logout deletes only that manager's file and clears its shared aliases.
    managers[0].logout();
    assert!(alias.get(|u| u.uid.is_empty() && u.play_key.is_empty()));
    assert!(!root.join("0/user.json").exists());
    assert!(root.join("1/user.json").exists());
    assert_eq!(managers[1].get(|u| u.uid.clone()), "offline-file-user");
    managers[0].set(|u| { u.uid = "replacement-fixture".into(); u.play_key = "replacement-key".into(); });
    assert_eq!(alias.get(|u| u.uid.clone()), "replacement-fixture");
    assert_eq!(managers[1].get(|u| u.uid.clone()), "offline-file-user");
    println!("{{\"pass\":true,\"independent_managers\":1000,\"anonymous_initialization\":true,\"independent_account_state\":true,\"clones_share_account\":true,\"copied_credential_file_duplicates_identity\":true,\"local_login_success_without_server_verification\":true,\"logout_file_isolation\":true,\"account_switch_isolation\":true,\"live_authentication_tested\":false,\"matchmaking_tested\":false}}");
}
