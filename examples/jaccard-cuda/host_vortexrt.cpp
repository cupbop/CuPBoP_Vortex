// hack to silence host.bc referencing missing kernel wrapper
extern "C" {
void * fillILb1EfEviPT0_S0__wrapper(void *) { return 0; }
void * fillILb0EfEviPT0_S0__wrapper(void *) { return 0; }
void * jaccard_row_sumILb1EfEviPKiS1_PKT0_PS2__wrapper(void *) { return 0; }
void * jaccard_is_optILb1EfEviiPKiS1_PKT0_S4_PS2_S5__wrapper(void *) { return 0; }
void * jaccard_jwILb1EfEviPKT0_S0_S2_S2_PS0__wrapper(void *) { return 0; }
void * jaccard_row_sumILb0EfEviPKiS1_PKT0_PS2__wrapper(void *) { return 0; }
void * jaccard_is_optILb0EfEviiPKiS1_PKT0_S4_PS2_S5__wrapper(void *) { return 0; }
void * jaccard_jwILb0EfEviPKT0_S0_S2_S2_PS0__wrapper(void *) { return 0; }
}
