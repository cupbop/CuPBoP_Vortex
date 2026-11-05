// What runs on which schedule (experiments/p4/REPORT_KO.md, "pass 순서"): the only place this table is written down. A schedule without a row
// (0: flat) gets the pipeline of experiments/p3 alone, as CUPBOP_LIFT_OPT_P4=0 does: nothing here was measured there.
// prehext: goes in front of lo-hext (mkp3.sh ${P4_PREHEXT:-}). stage2: the function passes of mkp4.sh's second opt ($P4). env: defaults, an existing value stays.
// schedule 1: lo-mm and lo-stale stay off, the skip of lo-tree too (no counted barriers), and so do the steady-state queue parts of lo-dq.
struct LiftOptEnv { const char *name, *value; };
struct LiftOptRow { int schedule; const char *prehext, *stage2; LiftOptEnv env[4]; };
static const LiftOptRow LIFT_OPT_SCHEDULES[] = {
    {2, "function(lo-cvtphi),", "lo-mm,lo-pred,lo-stale,lo-tree", {}},
    {1, "function(lo-cvtphi),", "lo-pred,lo-tree", {{"LO_TREE_NOSKIP", "1"}, {"LO_DQ_STEADY", "0"}, {"P2C_QSSA", "0"}, {"CUPBOP_BAR_MERGE", "1"}}},
};
// the queue of experiments/p3 instead of lo-dq (library geomean 1.000 against that queue)
static const LiftOptEnv LIFT_OPT_NO_P4_ENV[] = {{"P2C_DQ_MIN", "99"}, {"P2C_QSSA", "0"}};
