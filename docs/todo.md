Unrelated failures: Pre-existing issues with snapshot helper, doctor scripts, and VS Code integration


⚠️ Some pre-existing test failures identified (unrelated to global Justfile changes):
Doctor script issues (missing check_optional function)
VS Code integration test failures
Snapshot helper permissions (fixed by making test/helpers/state_snapshot.sh executable)

Warning: scripts/load_env.sh is deprecated. Please use lib/env-loader.sh instead.
This compatibility bridge will be removed in a future version.
Warning: load_env_file() is deprecated. Use the new lib/env-loader.sh system.
Platform: wsl

Some tests failed: test-doctor-flags.sh test-doctor.sh
