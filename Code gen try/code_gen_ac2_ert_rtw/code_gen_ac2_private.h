/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: code_gen_ac2_private.h
 *
 * Code generated for Simulink model 'code_gen_ac2'.
 *
 * Model version                  : 1.9
 * Simulink Coder version         : 25.2 (R2025b) 28-Jul-2025
 * C/C++ source code generated on : Sat Jul 11 16:12:43 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: ARM Compatible->ARM Cortex
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#ifndef code_gen_ac2_private_h_
#define code_gen_ac2_private_h_
#include "rtwtypes.h"
#include "multiword_types.h"
#include "code_gen_ac2_types.h"

/* Private macros used by the generated code to access rtModel */
#ifndef rtmSetTFinal
#define rtmSetTFinal(rtm, val)         ((rtm)->Timing.tFinal = (val))
#endif

extern real_T rt_roundd_snf(real_T u);

#endif                                 /* code_gen_ac2_private_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
