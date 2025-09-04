// hack to silence host.bc referencing missing kernel wrapper
extern "C" {
void * _Z17BoundingBoxKerneliiPiS_PfS_S0_iS_S_PS_15float4jS_S_15float4_wrapper(void *) { return 0; }
void * _Z13ClearKernel1iiPi_wrapper(void *) { return 0; }
void * _Z18TreeBuildingKerneliiPViPK15float4PKfiPi_wrapper(void *) { return 0; }
void * _Z13ClearKernel2iiPi15float4PS1_S0__wrapper(void *) { return 0; }
void * _Z20SummarizationKerneliiPViS_PV15float4i_wrapper(void *) { return 0; }
void * _Z10SortKerneliiPiPKiPViS_PS_S__wrapper(void *) { return 0; }
void * _Z22ForceCalculationKerneliifffPKiS1_PK15float4PfS_Pf2_wrapper(void *) { return 0; }
void * _Z18IntegrationKerneliffff15float4P15float2PfS__wrapper(void *) { return 0; }
void * _Z20InitializationKernelPiPj_wrapper(void *) { return 0; }

}
