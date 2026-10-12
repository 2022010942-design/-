* Encoding: UTF-8.
* ======================================================================.
* 의사소통 건강문해력 - 통증 개념 지식 - 신체활동 자기조절 재분석 (2026-10).
* X = 의사소통 건강문해력(HLS19-COM-P-Q6, 0-100점).
* M = 통증 개념 지식(COPI-Adult, 0-52점).
* Y = 신체활동 자기조절(ISR 신체활동판, 9-54점).
* 실행 순서: STEP 0부터 하나씩 실행하고, STEP 2까지 결과를 먼저 공유해 주세요.
* ======================================================================.

* ----------------------------------------------------------------------.
* [수정 구간 A] 문항 변수명: 오른쪽 목록을 실제 변수명으로 바꾸세요(공백으로 구분).
* ----------------------------------------------------------------------.
DEFINE !comp () comp1 comp2 comp3 comp4 comp5 comp6 !ENDDEFINE.
DEFINE !copi () copi1 copi2 copi3 copi4 copi5 copi6 copi7 copi8 copi9 copi10 copi11 copi12 copi13 !ENDDEFINE.
DEFINE !isr () isr1 isr2 isr3 isr4 isr5 isr6 isr7 isr8 isr9 !ENDDEFINE.

* ----------------------------------------------------------------------.
* [수정 구간 B] 특성 변수: 등호 오른쪽을 실제 변수명으로 바꾸세요.
* ----------------------------------------------------------------------.
COMPUTE id = 연구번호.
COMPUTE age = 나이.
COMPUTE sex = 성별.
COMPUTE edu = 최종학력.
COMPUTE job = 취업상태.
COMPUTE dur = 통증지속기간.
COMPUTE freq = 통증빈도6개월.
COMPUTE painavg = 지난1주평균통증.
EXECUTE.

* ======================================================================.
* STEP 0. 자료 확인: 문항 응답 범위와 특성 변수 코드 확인.
* 확인할 것: COM-P 1-4, COPI 0-4(1-5로 입력되어 있는지), ISR 1-6, 99 같은 결측 코드.
* ======================================================================.
FREQUENCIES VARIABLES=!comp !copi !isr
  /FORMAT=NOTABLE
  /STATISTICS=MINIMUM MAXIMUM.
FREQUENCIES VARIABLES=sex edu job dur freq painavg.
DESCRIPTIVES VARIABLES=age painavg
  /STATISTICS=MEAN STDDEV MIN MAX.

* (선택) COPI가 1-5로 입력되어 있으면 아래 4줄의 맨 앞 별표를 지우고 실행.
* DO REPEAT x = !copi.
* COMPUTE x = x - 1.
* END REPEAT.
* EXECUTE.

* ======================================================================.
* STEP 1. 점수 산출(새 이름으로 만들어 기존 총점과 섞이지 않게 함).
* PROCESS는 변수명 8자 이하만 받으므로 이름을 짧게 둠.
* ======================================================================.

* COM-P: 유효 응답(1-4) 중 쉬움(3)·매우 쉬움(4) 비율 x 100, 유효 응답 5개 미만이면 결측.
COUNT comp_val = !comp (1 THRU 4).
COUNT comp_easy = !comp (3 4).
COMPUTE COMP_r = $SYSMIS.
IF (comp_val >= 5) COMP_r = comp_easy / comp_val * 100.

* COPI: 13문항 합(0-52), 한 문항이라도 결측이면 결측.
COMPUTE COPI_r = 0.
DO REPEAT x = !copi.
COMPUTE COPI_r = COPI_r + x.
END REPEAT.

* ISR: 9문항 합(9-54), 한 문항이라도 결측이면 결측.
COMPUTE ISR_r = 0.
DO REPEAT x = !isr.
COMPUTE ISR_r = ISR_r + x.
END REPEAT.

COUNT copi_n = !copi (0 THRU 4).
COUNT isr_n = !isr (1 THRU 6).
EXECUTE.

* (선택) 기존 총점과 비교: 별표를 지우고 기존 총점 변수명으로 바꿔 실행. 차이가 0이 아닌 사례가 있으면 공유.
* COMPUTE d_copi = COPI_r - 기존COPI총점.
* COMPUTE d_isr = ISR_r - 기존ISR총점.
* COMPUTE d_comp = COMP_r - 기존COMP점수.
* FREQUENCIES VARIABLES=d_copi d_isr d_comp.

* ======================================================================.
* STEP 2. 분석 대상 확정: 제외 후보를 목록으로 확인(자동으로 제외하지 않음).
* ======================================================================.
COMPUTE f_miss = (NMISS(COMP_r, COPI_r, ISR_r) > 0).
COMPUTE f_copi0 = (COPI_r = 0).
COMPUTE f_pain0 = (painavg = 0).
EXECUTE.
FREQUENCIES VARIABLES=f_miss f_copi0 f_pain0 comp_val copi_n isr_n.

* 제외 후보 사례 목록(결측, COPI 0점, 지난 1주 평균 통증 0점).
TEMPORARY.
SELECT IF (f_miss = 1 OR f_copi0 = 1 OR f_pain0 = 1).
LIST VARIABLES=id COMP_r COPI_r ISR_r painavg comp_val copi_n isr_n.

* COPI 0점 응답자의 문항 응답 확인(모든 문항을 0으로 찍었는지).
TEMPORARY.
SELECT IF (f_copi0 = 1).
LIST VARIABLES=id !copi.

* 분석 포함 여부: 기본은 세 점수가 모두 있는 사례.
COMPUTE inc = (f_miss = 0).
* 제외하기로 정한 사례가 있으면 아래 줄의 별표를 지우고 연구번호를 넣으세요.
* IF (ANY(id, 101, 102)) inc = 0.
EXECUTE.
FREQUENCIES VARIABLES=inc.

* ======================================================================.
* 여기까지 결과를 먼저 공유해 주세요(STEP 0-2). 이후 STEP 3부터 실행.
* ======================================================================.

* ----------------------------------------------------------------------.
* 분석용 데이터셋 만들기(PROCESS가 FILTER를 무시할 수 있어 사례를 실제로 선택함).
* ----------------------------------------------------------------------.
DATASET NAME raw WINDOW=FRONT.
DATASET COPY ana.
DATASET ACTIVATE ana.
SELECT IF (inc = 1).
EXECUTE.

* ======================================================================.
* STEP 3. 범주 만들기와 더미변수.
* [수정 구간 C] 아래 RECODE의 원래 코드는 추정값입니다. STEP 0의 빈도표를 보고 맞추세요.
* ======================================================================.

* 연령: 29세 이하 / 30대 / 40대 / 50세 이상.
RECODE age (LOWEST THRU 29=1) (30 THRU 39=2) (40 THRU 49=3) (50 THRU HIGHEST=4) INTO age_g.
VALUE LABELS age_g 1 '29세 이하' 2 '30-39세' 3 '40-49세' 4 '50세 이상'.

* 성별: 1 남, 2 여로 가정.
VALUE LABELS sex 1 '남성' 2 '여성'.

* 학력: 1 고졸 이하, 2 전문대졸, 3 학사, 4 석사 이상으로 가정(4범주 유지).
RECODE edu (1=1) (2=2) (3=3) (4=4) INTO edu_g.
VALUE LABELS edu_g 1 '고졸 이하' 2 '전문대졸' 3 '학사' 4 '석사 이상'.

* 취업상태: 1 취업, 2 미취업/구직, 3 학생, 4 주부, 5 기타로 가정하고 3범주로 합침.
RECODE job (1=1) (3=2) (2,4,5=3) INTO job_g.
VALUE LABELS job_g 1 '취업' 2 '학생' 3 '비취업(미취업·주부·기타)'.

* 통증 지속기간: 1 3개월-1년 미만, 2 1-3년 미만, 3 3-5년 미만, 4 5년 이상으로 가정.
RECODE dur (1=1) (2=2) (3=3) (4=4) INTO dur_g.
VALUE LABELS dur_g 1 '3개월-1년 미만' 2 '1-3년 미만' 3 '3-5년 미만' 4 '5년 이상'.

* 지난 6개월 통증 빈도: 1 매일 또는 거의 매일, 2 3개월 이상, 3 3개월 미만으로 가정.
RECODE freq (1=1) (2=2) (3=3) INTO freq_g.
VALUE LABELS freq_g 1 '매일 또는 거의 매일' 2 '3개월 이상' 3 '3개월 미만'.

* 지난 1주 평균 통증 강도: 0 / 1-3 / 4-6 / 7-10.
RECODE painavg (0=1) (1 THRU 3=2) (4 THRU 6=3) (7 THRU 10=4) INTO pain_g.
VALUE LABELS pain_g 1 '없음(0)' 2 '경도(1-3)' 3 '중등도(4-6)' 4 '중증(7-10)'.

* 공변량 후보 더미(기준: 남성, 29세 이하, 고졸 이하, 취업, 3개월 미만).
COMPUTE gender_f = (sex = 2).
COMPUTE age_30 = (age_g = 2).
COMPUTE age_40 = (age_g = 3).
COMPUTE age_50p = (age_g = 4).
COMPUTE edu_2 = (edu_g = 2).
COMPUTE edu_3 = (edu_g = 3).
COMPUTE edu_4 = (edu_g = 4).
COMPUTE job_st = (job_g = 2).
COMPUTE job_no = (job_g = 3).
COMPUTE pain_d = (freq_g = 1).
COMPUTE pain_m = (freq_g = 2).
EXECUTE.

VARIABLE LEVEL age_g sex edu_g job_g dur_g freq_g pain_g (NOMINAL).
VARIABLE LEVEL COMP_r COPI_r ISR_r age painavg (SCALE).

* ======================================================================.
* STEP 4. 신뢰도(Cronbach's alpha): 문항-총점 상관이 음수인 문항이 있으면 역문항 여부 확인.
* ======================================================================.
RELIABILITY /VARIABLES=!comp /SCALE('COM-P') ALL /MODEL=ALPHA /SUMMARY=TOTAL.
RELIABILITY /VARIABLES=!copi /SCALE('COPI') ALL /MODEL=ALPHA /SUMMARY=TOTAL.
RELIABILITY /VARIABLES=!isr /SCALE('ISR') ALL /MODEL=ALPHA /SUMMARY=TOTAL.

* ======================================================================.
* STEP 5. Table 1: 대상자 특성.
* ======================================================================.
FREQUENCIES VARIABLES=sex age_g edu_g job_g dur_g freq_g pain_g.
DESCRIPTIVES VARIABLES=age painavg
  /STATISTICS=MEAN STDDEV MIN MAX.

* 특성에 따른 신체활동 자기조절(Y) 차이: t-test, ANOVA(등분산 위배 시 Welch와 Games-Howell).
T-TEST GROUPS=sex(1 2)
  /VARIABLES=ISR_r.
ONEWAY ISR_r BY age_g
  /STATISTICS DESCRIPTIVES HOMOGENEITY WELCH
  /POSTHOC=BONFERRONI GH ALPHA(0.05).
ONEWAY ISR_r BY edu_g
  /STATISTICS DESCRIPTIVES HOMOGENEITY WELCH
  /POSTHOC=BONFERRONI GH ALPHA(0.05).
ONEWAY ISR_r BY job_g
  /STATISTICS DESCRIPTIVES HOMOGENEITY WELCH
  /POSTHOC=BONFERRONI GH ALPHA(0.05).
ONEWAY ISR_r BY dur_g
  /STATISTICS DESCRIPTIVES HOMOGENEITY WELCH
  /POSTHOC=BONFERRONI GH ALPHA(0.05).
ONEWAY ISR_r BY freq_g
  /STATISTICS DESCRIPTIVES HOMOGENEITY WELCH
  /POSTHOC=BONFERRONI GH ALPHA(0.05).
ONEWAY ISR_r BY pain_g
  /STATISTICS DESCRIPTIVES HOMOGENEITY WELCH
  /POSTHOC=BONFERRONI GH ALPHA(0.05).

* 특성에 따른 통증 개념 지식(M)·의사소통 건강문해력(X) 차이: Mann-Whitney, Kruskal-Wallis.
NPAR TESTS /M-W=COPI_r COMP_r BY sex(1 2).
NPAR TESTS /K-W=COPI_r COMP_r BY age_g(1 4).
NPAR TESTS /K-W=COPI_r COMP_r BY edu_g(1 4).
NPAR TESTS /K-W=COPI_r COMP_r BY job_g(1 3).
NPAR TESTS /K-W=COPI_r COMP_r BY dur_g(1 4).
NPAR TESTS /K-W=COPI_r COMP_r BY freq_g(1 3).
NPAR TESTS /K-W=COPI_r COMP_r BY pain_g(1 4).

* 집단별 중앙값(사분위수) 확인용.
MEANS TABLES=COPI_r COMP_r BY sex age_g edu_g job_g dur_g freq_g pain_g
  /CELLS=COUNT MEDIAN MEAN STDDEV.

* Kruskal-Wallis가 유의한 변수만 사후검정(Dunn, Bonferroni 보정): GROUP 안의 변수명만 바꿔 실행.
NPTESTS
  /INDEPENDENT TEST (COPI_r COMP_r) GROUP (age_g) KRUSKAL_WALLIS(COMPARE=PAIRWISE)
  /MISSING SCOPE=ANALYSIS USERMISSING=EXCLUDE
  /CRITERIA ALPHA=0.05 CILEVEL=95.

* ======================================================================.
* STEP 6. Table 2: 기술통계, 정규성(왜도·첨도), 최고점 비율, 상관.
* ======================================================================.
DESCRIPTIVES VARIABLES=COMP_r COPI_r ISR_r
  /STATISTICS=MEAN STDDEV MIN MAX SKEWNESS KURTOSIS.
EXAMINE VARIABLES=COMP_r COPI_r ISR_r
  /PLOT HISTOGRAM NPPLOT
  /STATISTICS DESCRIPTIVES
  /MISSING LISTWISE.

COMPUTE comp_100 = (COMP_r = 100).
EXECUTE.
FREQUENCIES VARIABLES=comp_100.

* 주요 변수 간 Spearman 상관(연속형 연령·통증 강도 포함: 공변량 결정 참고용).
NONPAR CORR
  /VARIABLES=COMP_r COPI_r ISR_r age painavg
  /PRINT=SPEARMAN TWOTAIL NOSIG
  /MISSING=PAIRWISE.

* ======================================================================.
* STEP 7. 회귀 가정 확인(선형성, 잔차 정규성·등분산성, 영향점, 다중공선성).
* ======================================================================.
REGRESSION
  /STATISTICS COEFF R ANOVA COLLIN TOL
  /DEPENDENT COPI_r
  /METHOD=ENTER COMP_r
  /SCATTERPLOT=(*ZRESID, *ZPRED)
  /RESIDUALS HISTOGRAM(ZRESID) NORMPROB(ZRESID)
  /SAVE COOK(cook_m).
REGRESSION
  /STATISTICS COEFF R ANOVA COLLIN TOL
  /DEPENDENT ISR_r
  /METHOD=ENTER COMP_r COPI_r
  /SCATTERPLOT=(*ZRESID, *ZPRED)
  /RESIDUALS HISTOGRAM(ZRESID) NORMPROB(ZRESID)
  /SAVE COOK(cook_y).
DESCRIPTIVES VARIABLES=cook_m cook_y
  /STATISTICS=MEAN MAX.

* ======================================================================.
* STEP 8. 매개분석(PROCESS Model 4): process.sps를 먼저 한 번 실행해 두어야 함.
* X는 연속형으로 넣음(/mcx 옵션 쓰지 않음).
* ======================================================================.

* Model 1: 공변량 없음.
process y=ISR_r/x=COMP_r/m=COPI_r/model=4/total=1/boot=5000/seed=1234.

* Model 2: 공변량 투입(현재 Method 기준: 성별, 연령, 지난 6개월 통증 빈도).
* STEP 5-6 결과를 보고 공변량을 바꾸면 /cov= 뒤의 더미만 바꾸면 됨.
process y=ISR_r/x=COMP_r/m=COPI_r/cov=gender_f age_30 age_40 age_50p pain_d pain_m/model=4/total=1/boot=5000/seed=1234.

* (대안 예시) von Wagner 개인 요인(연령, 학력) + 통증 빈도.
* process y=ISR_r/x=COMP_r/m=COPI_r/cov=age_30 age_40 age_50p edu_2 edu_3 edu_4 pain_d pain_m/model=4/total=1/boot=5000/seed=1234.
