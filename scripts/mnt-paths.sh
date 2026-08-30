# Source from other scripts: source "$(dirname "$0")/mnt-paths.sh"
WORKBENCH_ROOT="${WORKBENCH_ROOT:-/workspaces/silentorb-workbench}"
MNT="${MNT:-${WORKBENCH_ROOT}/.mnt}"
TOME="${TOME:-${MNT}/tome}"
MARLOTH="${MARLOTH:-${MNT}/marloth-story}"
SILENTORB="${SILENTORB:-${MNT}/silentorb-web}"
TRANSLUCENCE="${TRANSLUCENCE:-${MNT}/translucence}"
IMP_TS="${IMP_TS:-${MNT}/imp-ts}"
IMP_RUST="${IMP_RUST:-${MNT}/imp-rust}"
IMP_SPEC="${IMP_SPEC:-${MNT}/imp-spec}"

# Host-side imp-rust path for docker-outside-of-docker compose (see devcontainer remoteEnv).
resolve_imp_rust_host_repo() {
  if [[ -n "${IMP_RUST_HOST_REPO:-}" ]]; then
    printf '%s\n' "$IMP_RUST_HOST_REPO"
    return 0
  fi
  if [[ -r /proc/self/mountinfo ]]; then
    awk -v mnt="${IMP_RUST}" '$5 == mnt { print $4; exit }' /proc/self/mountinfo
  fi
}
