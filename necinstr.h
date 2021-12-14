
static void i_add_br8(void);
static void i_add_wr16(void);
static void i_add_r8b(void);
static void i_add_r16w(void);
static void i_add_ald8(void);
static void i_add_axd16(void);
static void i_push_es(void);
static void i_pop_es(void);
static void i_or_br8(void);
static void i_or_r8b(void);
static void i_or_wr16(void);
static void i_or_r16w(void);
static void i_or_ald8(void);
static void i_or_axd16(void);
static void i_push_cs(void);
static void i_pop_cs(void);
static void i_adc_br8(void);
static void i_adc_wr16(void);
static void i_adc_r8b(void);
static void i_adc_r16w(void);
static void i_adc_ald8(void);
static void i_adc_axd16(void);
static void i_push_ss(void);
static void i_pop_ss(void);
static void i_sbb_br8(void);
static void i_sbb_wr16(void);
static void i_sbb_r8b(void);
static void i_sbb_r16w(void);
static void i_sbb_ald8(void);
static void i_sbb_axd16(void);
static void i_push_ds(void);
static void i_pop_ds(void);
static void i_and_br8(void);
static void i_and_r8b(void);
static void i_and_wr16(void);
static void i_and_r16w(void);
static void i_and_ald8(void);
static void i_and_axd16(void);
static void i_es(void);
static void i_daa(void);
static void i_sub_br8(void);
static void i_sub_wr16(void);
static void i_sub_r8b(void);
static void i_sub_r16w(void);
static void i_sub_ald8(void);
static void i_sub_axd16(void);
static void i_cs(void);
static void i_das(void);
static void i_xor_br8(void);
static void i_xor_r8b(void);
static void i_xor_wr16(void);
static void i_xor_r16w(void);
static void i_xor_ald8(void);
static void i_xor_axd16(void);
static void i_ss(void);
static void i_aaa(void);
static void i_cmp_br8(void);
static void i_cmp_wr16(void);
static void i_cmp_r8b(void);
static void i_cmp_r16w(void);
static void i_cmp_ald8(void);
static void i_cmp_axd16(void);
static void i_ds(void);
static void i_aas(void);
static void i_inc_ax(void);
static void i_inc_cx(void);
static void i_inc_dx(void);
static void i_inc_bx(void);
static void i_inc_sp(void);
static void i_inc_bp(void);
static void i_inc_si(void);
static void i_inc_di(void);
static void i_dec_ax(void);
static void i_dec_cx(void);
static void i_dec_dx(void);
static void i_dec_bx(void);
static void i_dec_sp(void);
static void i_dec_bp(void);
static void i_dec_si(void);
static void i_dec_di(void);
static void i_push_ax(void);
static void i_push_cx(void);
static void i_push_dx(void);
static void i_push_bx(void);
static void i_push_sp(void);
static void i_push_bp(void);
static void i_push_si(void);
static void i_push_di(void);
static void i_pop_ax(void);
static void i_pop_cx(void);
static void i_pop_dx(void);
static void i_pop_bx(void);
static void i_pop_sp(void);
static void i_pop_bp(void);
static void i_pop_si(void);
static void i_pop_di(void);
static void i_pusha(void);
static void i_popa(void);
static void i_chkind(void);
static void i_push_d16(void);
static void i_imul_d16(void);
static void i_push_d8(void);
static void i_imul_d8(void);
static void i_insb(void);
static void i_insw(void);
static void i_outsb(void);
static void i_outsw(void);
static void i_jo(void);
static void i_jno(void);
static void i_jc(void);
static void i_jnc(void);
static void i_jz(void);
static void i_jnz(void);
static void i_jce(void);
static void i_jnce(void);
static void i_js(void);
static void i_jns(void);
static void i_jp(void);
static void i_jnp(void);
static void i_jl(void);
static void i_jnl(void);
static void i_jle(void);
static void i_jnle(void);
static void i_80pre(void);
static void i_82pre(void);
static void i_81pre(void);
static void i_83pre(void);
static void i_test_br8(void);
static void i_test_wr16(void);
static void i_xchg_br8(void);
static void i_xchg_wr16(void);
static void i_mov_br8(void);
static void i_mov_r8b(void);
static void i_mov_wr16(void);
static void i_mov_r16w(void);
static void i_mov_wsreg(void);
static void i_lea(void);
static void i_mov_sregw(void);
static void i_invalid(void);
static void i_popw(void);
static void i_nop(void);
static void i_xchg_axcx(void);
static void i_xchg_axdx(void);
static void i_xchg_axbx(void);
static void i_xchg_axsp(void);
static void i_xchg_axbp(void);
static void i_xchg_axsi(void);
static void i_xchg_axdi(void);
static void i_cbw(void);
static void i_cwd(void);
static void i_call_far(void);
static void i_pushf(void);
static void i_popf(void);
static void i_sahf(void);
static void i_lahf(void);
static void i_mov_aldisp(void);
static void i_mov_axdisp(void);
static void i_mov_dispal(void);
static void i_mov_dispax(void);
static void i_movsb(void);
static void i_movsw(void);
static void i_cmpsb(void);
static void i_cmpsw(void);
static void i_test_ald8(void);
static void i_test_axd16(void);
static void i_stosb(void);
static void i_stosw(void);
static void i_lodsb(void);
static void i_lodsw(void);
static void i_scasb(void);
static void i_scasw(void);
static void i_mov_ald8(void);
static void i_mov_cld8(void);
static void i_mov_dld8(void);
static void i_mov_bld8(void);
static void i_mov_ahd8(void);
static void i_mov_chd8(void);
static void i_mov_dhd8(void);
static void i_mov_bhd8(void);
static void i_mov_axd16(void);
static void i_mov_cxd16(void);
static void i_mov_dxd16(void);
static void i_mov_bxd16(void);
static void i_mov_spd16(void);
static void i_mov_bpd16(void);
static void i_mov_sid16(void);
static void i_mov_did16(void);
static void i_rotshft_bd8(void);
static void i_rotshft_wd8(void);
static void i_ret_d16(void);
static void i_ret(void);
static void i_les_dw(void);
static void i_lds_dw(void);
static void i_mov_bd8(void);
static void i_mov_wd16(void);
static void i_enter(void);
static void i_leave(void);
static void i_retf_d16(void);
static void i_retf(void);
static void i_int3(void);
static void i_int(void);
static void i_into(void);
static void i_iret(void);
static void i_rotshft_b(void);
static void i_rotshft_w(void);
static void i_rotshft_bcl(void);
static void i_rotshft_wcl(void);
static void i_aam(void);
static void i_aad(void);
static void i_trans(void);
static void i_loopne(void);
static void i_loope(void);
static void i_loop(void);
static void i_jcxz(void);
static void i_inal(void);
static void i_inax(void);
static void i_outal(void);
static void i_outax(void);
static void i_call_d16(void);
static void i_jmp_d16(void);
static void i_jmp_far(void);
static void i_jmp_d8(void);
static void i_inaldx(void);
static void i_inaxdx(void);
static void i_outdxal(void);
static void i_outdxax(void);
static void i_lock(void);
static void i_repne(void);
static void i_repe(void);
static void i_hlt(void);
static void i_cmc(void);
static void i_f6pre(void);
static void i_f7pre(void);
static void i_clc(void);
static void i_stc(void);
static void i_di(void);
static void i_ei(void);
static void i_cld(void);
static void i_std(void);
static void i_fepre(void);
static void i_ffpre(void);
static void i_wait(void);

void (* __attribute__((section(".dtcm"))) nec_instruction[256])(void) =
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
