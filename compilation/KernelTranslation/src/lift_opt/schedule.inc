// What runs on which schedule (experiments/p4/REPORT_KO.md, "pass 순서"): the only place this table is written down. A schedule without a row
// (0: flat) gets the pipeline of experiments/p3 alone, as CUPBOP_LIFT_OPT_P4=0 does: nothing here was measured there.
// prehext: goes in front of lo-hext (mkp3.sh ${P4_PREHEXT:-}). stage2: the function passes of mkp4.sh's second opt ($P4). env: defaults, an existing value stays.
// schedule 1: lo-mm and lo-stale stay off, the skip of lo-tree too (no counted barriers), and so do the steady-state queue parts of lo-dq.
struct LiftOptEnv { const char *name, *value; };
struct LiftOptRow { int schedule; const char *prehext, *stage2; LiftOptEnv env[5]; };
static const LiftOptRow LIFT_OPT_SCHEDULES[] = {
    {2, "function(lo-cvtphi),", "lo-mm,lo-pred,lo-stale,lo-tree", {{"CUPBOP_PARAM_FORWARD", "all"}}},   // schedule 1 forwards without it
    {1, "function(lo-cvtphi),", "lo-pred,lo-tree", {{"LO_TREE_NOSKIP", "1"}, {"LO_DQ_STEADY", "0"}, {"P2C_QSSA", "0"}, {"CUPBOP_BAR_MERGE", "1"}}},
};
// the queue of experiments/p3 instead of lo-dq (library geomean 1.000 against that queue)
static const LiftOptEnv LIFT_OPT_NO_P4_ENV[] = {{"P2C_DQ_MIN", "99"}, {"P2C_QSSA", "0"}};
// What a lifted module gets with an empty environment (user decisions of 2026-11-04 and 11-05, 2026-11-04_CUPBOP_INTEGRATION_PLAN_KO.md): every switch is read by the translator alone.
// An existing value stays, so VAR=0 turns one off; CUPBOP_LIFT_OPT=0 turns all of this off with the pipeline. Not here on purpose: CUPBOP_MUFU, CUPBOP_TMA_DXA (they need the hardware).
static const LiftOptEnv LIFT_OPT_DEFAULTS[] = {
    {"CUPBOP_DXA_CLOBBER", "1"},  {"CUPBOP_SMEM_SHRINK", "1"}, {"CUPBOP_SMEM_RESERVE_DROP", "1"}, {"CUPBOP_DIV_RESTORE", "1"}, {"CUPBOP_SQRT_RESTORE", "1"},
    {"CUPBOP_ADDR_CARRY", "1"},   {"CUPBOP_PARAM_SPAN", "1"},  {"CUPBOP_TRIP_HOIST", "1"},        {"CUPBOP_TRIP_VERSION", "1"}, {"CUPBOP_BAR_INLINE", "1"},
    {"CUPBOP_UNIFORM_BR", "1"},   {"CUPBOP_PARAM_DYN", "2"},   {"LO_HEXT", "2"},
};
