{ ... }:

{
  # Ported from the hand-written ~/.ssh/config. The old file had two
  # conflicting `Host haiiro.moe` blocks; only the first ever took effect, so
  # the second is split out under its own alias here.
  programs.ssh = {
    enable = true;

    # We spell out the defaults we actually want below instead of inheriting
    # Home Manager's (soon-to-be-removed) implicit ones.
    enableDefaultConfig = false;

    settings = {
      "*" = {
        SetEnv.TERM = "xterm-256color";
        HostKeyAlgorithms = "ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,ssh-rsa,ssh-ed25519";
        AddKeysToAgent = "no";
        Compression = false;
        ForwardAgent = false;
        HashKnownHosts = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
    };
  };
}
