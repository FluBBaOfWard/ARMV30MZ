
void i_add_br8(void);
void i_add_wr16(void);
void i_add_r8b(void);
void i_add_r16w(void);
void i_add_ald8(void);
void i_add_axd16(void);
void i_push_es(void);
void i_pop_es(void);
void i_or_br8(void);
void i_or_r8b(void);
void i_or_wr16(void);
void i_or_r16w(void);
void i_or_ald8(void);
void i_or_axd16(void);
void i_push_cs(void);
void i_pop_cs(void);
void i_adc_br8(void);
void i_adc_wr16(void);
void i_adc_r8b(void);
void i_adc_r16w(void);
void i_adc_ald8(void);
void i_adc_axd16(void);
void i_push_ss(void);
void i_pop_ss(void);
void i_sbb_br8(void);
void i_sbb_wr16(void);
void i_sbb_r8b(void);
void i_sbb_r16w(void);
void i_sbb_ald8(void);
void i_sbb_axd16(void);
void i_push_ds(void);
void i_pop_ds(void);
void i_and_br8(void);
void i_and_r8b(void);
void i_and_wr16(void);
void i_and_r16w(void);
void i_and_ald8(void);
void i_and_axd16(void);
void i_es(void);
void i_daa(void);
void i_sub_br8(void);
void i_sub_wr16(void);
void i_sub_r8b(void);
void i_sub_r16w(void);
void i_sub_ald8(void);
void i_sub_axd16(void);
void i_cs(void);
void i_das(void);
void i_xor_br8(void);
void i_xor_r8b(void);
void i_xor_wr16(void);
void i_xor_r16w(void);
void i_xor_ald8(void);
void i_xor_axd16(void);
void i_ss(void);
void i_aaa(void);
void i_cmp_br8(void);
void i_cmp_wr16(void);
void i_cmp_r8b(void);
void i_cmp_r16w(void);
void i_cmp_ald8(void);
void i_cmp_axd16(void);
void i_ds(void);
void i_aas(void);
void i_inc_ax(void);
void i_inc_cx(void);
void i_inc_dx(void);
void i_inc_bx(void);
void i_inc_sp(void);
void i_inc_bp(void);
void i_inc_si(void);
void i_inc_di(void);
void i_dec_ax(void);
void i_dec_cx(void);
void i_dec_dx(void);
void i_dec_bx(void);
void i_dec_sp(void);
void i_dec_bp(void);
void i_dec_si(void);
void i_dec_di(void);
void i_push_ax(void);
void i_push_cx(void);
void i_push_dx(void);
void i_push_bx(void);
void i_push_sp(void);
void i_push_bp(void);
void i_push_si(void);
void i_push_di(void);
void i_pop_ax(void);
void i_pop_cx(void);
void i_pop_dx(void);
void i_pop_bx(void);
void i_pop_sp(void);
void i_pop_bp(void);
void i_pop_si(void);
void i_pop_di(void);
void i_pusha(void);
void i_popa(void);
void i_chkind(void);
void i_push_d16(void);
void i_imul_d16(void);
void i_push_d8(void);
void i_imul_d8(void);
void i_insb(void);
void i_insw(void);
void i_outsb(void);
void i_outsw(void);
void i_jo(void);
void i_jno(void);
void i_jc(void);
void i_jnc(void);
void i_jz(void);
void i_jnz(void);
void i_jce(void);
void i_jnce(void);
void i_js(void);
void i_jns(void);
void i_jp(void);
void i_jnp(void);
void i_jl(void);
void i_jnl(void);
void i_jle(void);
void i_jnle(void);
void i_80pre(void);
void i_82pre(void);
void i_81pre(void);
void i_83pre(void);
void i_test_br8(void);
void i_test_wr16(void);
void i_xchg_br8(void);
void i_xchg_wr16(void);
void i_mov_br8(void);
void i_mov_r8b(void);
void i_mov_wr16(void);
void i_mov_r16w(void);
void i_mov_wsreg(void);
void i_lea(void);
void i_mov_sregw(void);
void i_invalid(void);
void i_popw(void);
void i_nop(void);
void i_xchg_axcx(void);
void i_xchg_axdx(void);
void i_xchg_axbx(void);
void i_xchg_axsp(void);
void i_xchg_axbp(void);
void i_xchg_axsi(void);
void i_xchg_axdi(void);
void i_cbw(void);
void i_cwd(void);
void i_call_far(void);
void i_pushf(void);
void i_popf(void);
void i_sahf(void);
void i_lahf(void);
void i_mov_aldisp(void);
void i_mov_axdisp(void);
void i_mov_dispal(void);
void i_mov_dispax(void);
void i_movsb(void);
void i_movsw(void);
void i_cmpsb(void);
void i_cmpsw(void);
void i_test_ald8(void);
void i_test_axd16(void);
void i_stosb(void);
void i_stosw(void);
void i_lodsb(void);
void i_lodsw(void);
void i_scasb(void);
void i_scasw(void);
void i_mov_ald8(void);
void i_mov_cld8(void);
void i_mov_dld8(void);
void i_mov_bld8(void);
void i_mov_ahd8(void);
void i_mov_chd8(void);
void i_mov_dhd8(void);
void i_mov_bhd8(void);
void i_mov_axd16(void);
void i_mov_cxd16(void);
void i_mov_dxd16(void);
void i_mov_bxd16(void);
void i_mov_spd16(void);
void i_mov_bpd16(void);
void i_mov_sid16(void);
void i_mov_did16(void);
void i_rotshft_bd8(void);
void i_rotshft_wd8(void);
void i_ret_d16(void);
void i_ret(void);
void i_les_dw(void);
void i_lds_dw(void);
void i_mov_bd8(void);
void i_mov_wd16(void);
void i_enter(void);
void i_leave(void);
void i_retf_d16(void);
void i_retf(void);
void i_int3(void);
void i_int(void);
void i_into(void);
void i_iret(void);
void i_rotshft_b(void);
void i_rotshft_w(void);
void i_rotshft_bcl(void);
void i_rotshft_wcl(void);
void i_aam(void);
void i_aad(void);
void i_trans(void);
void i_loopne(void);
void i_loope(void);
void i_loop(void);
void i_jcxz(void);
void i_inal(void);
void i_inax(void);
void i_outal(void);
void i_outax(void);
void i_call_d16(void);
void i_jmp_d16(void);
void i_jmp_far(void);
void i_jmp_d8(void);
void i_inaldx(void);
void i_inaxdx(void);
void i_outdxal(void);
void i_outdxax(void);
void i_lock(void);
void i_repne(void);
void i_repe(void);
void i_hlt(void);
void i_cmc(void);
void i_f6pre(void);
void i_f7pre(void);
void i_clc(void);
void i_stc(void);
void i_di(void);
void i_ei(void);
void i_cld(void);
void i_std(void);
void i_fepre(void);
void i_ffpre(void);
void i_wait(void);

void (* __attribute__((section(".dtcm"))) nec_instru_ction[256])(void) =
{
	i_add_br8,
	i_add_wr16,
	i_add_r8b,
	i_add_r16w,
	i_add_ald8,
	i_add_axd16,
	i_push_es,
	i_pop_es,
	i_or_br8,
	i_or_wr16,
	i_or_r8b,
	i_or_r16w,
	i_or_ald8,
	i_or_axd16,
	i_push_cs,
	i_pop_cs,
	i_adc_br8,
	i_adc_wr16,
	i_adc_r8b,
	i_adc_r16w,
	i_adc_ald8,
	i_adc_axd16,
	i_push_ss,
	i_pop_ss,
	i_sbb_br8,
	i_sbb_wr16,
	i_sbb_r8b,
	i_sbb_r16w,
	i_sbb_ald8,
	i_sbb_axd16,
	i_push_ds,
	i_pop_ds,
	i_and_br8,
	i_and_wr16,
	i_and_r8b,
	i_and_r16w,
	i_and_ald8,
	i_and_axd16,
	i_es,
	i_daa,
	i_sub_br8,
	i_sub_wr16,
	i_sub_r8b,
	i_sub_r16w,
	i_sub_ald8,
	i_sub_axd16,
	i_cs,
	i_das,
	i_xor_br8,
	i_xor_wr16,
	i_xor_r8b,
	i_xor_r16w,
	i_xor_ald8,
	i_xor_axd16,
	i_ss,
	i_aaa,
	i_cmp_br8,
	i_cmp_wr16,
	i_cmp_r8b,
	i_cmp_r16w,
	i_cmp_ald8,
	i_cmp_axd16,
	i_ds,
	i_aas,
	i_inc_ax,
	i_inc_cx,
	i_inc_dx,
	i_inc_bx,
	i_inc_sp,
	i_inc_bp,
	i_inc_si,
	i_inc_di,
	i_dec_ax,
	i_dec_cx,
	i_dec_dx,
	i_dec_bx,
	i_dec_sp,
	i_dec_bp,
	i_dec_si,
	i_dec_di,
	i_push_ax,
	i_push_cx,
	i_push_dx,
	i_push_bx,
	i_push_sp,
	i_push_bp,
	i_push_si,
	i_push_di,
	i_pop_ax,
	i_pop_cx,
	i_pop_dx,
	i_pop_bx,
	i_pop_sp,
	i_pop_bp,
	i_pop_si,
	i_pop_di,
	i_pusha,
	i_popa,
	i_chkind,
	i_invalid,
	i_invalid,	// repnc
	i_invalid,	// repc
	i_invalid,	// fpo2
	i_invalid,	// fpo2
	i_push_d16,
	i_imul_d16,
	i_push_d8,
	i_imul_d8,
	i_insb,
	i_insw,
	i_outsb,
	i_outsw,
	i_jo,
	i_jno,
	i_jc,
	i_jnc,
	i_jz,
	i_jnz,
	i_jce,
	i_jnce,
	i_js,
	i_jns,
	i_jp,
	i_jnp,
	i_jl,
	i_jnl,
	i_jle,
	i_jnle,
	i_80pre,
	i_81pre,
	i_82pre,
	i_83pre,
	i_test_br8,
	i_test_wr16,
	i_xchg_br8,
	i_xchg_wr16,
	i_mov_br8,
	i_mov_wr16,
	i_mov_r8b,
	i_mov_r16w,
	i_mov_wsreg,
	i_lea,
	i_mov_sregw,
	i_popw,
	i_nop,
	i_xchg_axcx,
	i_xchg_axdx,
	i_xchg_axbx,
	i_xchg_axsp,
	i_xchg_axbp,
	i_xchg_axsi,
	i_xchg_axdi,
	i_cbw,
	i_cwd,
	i_call_far,
	i_wait,
	i_pushf,
	i_popf,
	i_sahf,
	i_lahf,
	i_mov_aldisp,
	i_mov_axdisp,
	i_mov_dispal,
	i_mov_dispax,
	i_movsb,
	i_movsw,
	i_cmpsb,
	i_cmpsw,
	i_test_ald8,
	i_test_axd16,
	i_stosb,
	i_stosw,
	i_lodsb,
	i_lodsw,
	i_scasb,
	i_scasw,
	i_mov_ald8,
	i_mov_cld8,
	i_mov_dld8,
	i_mov_bld8,
	i_mov_ahd8,
	i_mov_chd8,
	i_mov_dhd8,
	i_mov_bhd8,
	i_mov_axd16,
	i_mov_cxd16,
	i_mov_dxd16,
	i_mov_bxd16,
	i_mov_spd16,
	i_mov_bpd16,
	i_mov_sid16,
	i_mov_did16,
	i_rotshft_bd8,
	i_rotshft_wd8,
	i_ret_d16,
	i_ret,
	i_les_dw,
	i_lds_dw,
	i_mov_bd8,
	i_mov_wd16,
	i_enter,
	i_leave,
	i_retf_d16,
	i_retf,
	i_int3,
	i_int,
	i_into,
	i_iret,
	i_rotshft_b,
	i_rotshft_w,
	i_rotshft_bcl,
	i_rotshft_wcl,
	i_aam,
	i_aad,
	i_trans,  	//xlat (undocumented mirror)
	i_trans,  	//xlat
	i_invalid,	// fpo1
	i_invalid,	// fpo1
	i_invalid,	// fpo1
	i_invalid,	// fpo1
	i_invalid,	// fpo1
	i_invalid,	// fpo1
	i_invalid,	// fpo1
	i_invalid,	// fpo1
	i_loopne,
	i_loope,
	i_loop,
	i_jcxz,
	i_inal,
	i_inax,
	i_outal,
	i_outax,
	i_call_d16,
	i_jmp_d16,
	i_jmp_far,
	i_jmp_d8,
	i_inaldx,
	i_inaxdx,
	i_outdxal,
	i_outdxax,
	i_lock,
	i_invalid,
	i_repne,
	i_repe,
	i_hlt,
	i_cmc,
	i_f6pre,
	i_f7pre,
	i_clc,
	i_stc,
	i_di,
	i_ei,
	i_cld,
	i_std,
	i_fepre,
	i_ffpre,
};
