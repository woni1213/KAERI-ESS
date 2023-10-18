# ESS
 Emittance Scanner System

0. Address Map
ADC A :     0x4000_0000
ADC B :     0x4000_1000
DAC   :     0x4000_2000
Motor A :   0x4000_3000
Motor B :   0x4000_4000
Limit :     0x4000_5000  

1. System
 a. 개요
    - 2개의 채널을 가짐
    - 각 채널은 ADC, DAC, Motor, Limit로 구성
    - System Clock 5ns
    - count 1 = 5ns


 b. 구성
    Zynq -  ADC A
            ADC B
            DAC (2채널 동시 제어)
            Motor A
            Motor B
            Limit

2. ADC
 a. 개요
    - AD7903 (Differntial Endded ADC), +-10V
    - 1개의 칩에 Isolation이 되어있는 2개의 ADC로 구성
    - 각 채널 별 SPI 통신
    - 최대 1.2us Sampling
    - 16 Bit
    - RAM Size 최대 10000 (수정 가능)

 b. 구성
    Top_ADC.v - adc_AD7903.v (AD7903 Control)
                adc_s00_AXI.v (AXI)
                adc_spi.v (SPI)
                DPBRAM.v (DPRAM)

 c. 동작
    - 전원이 켜지는 순간 설정된 Samping 시간으로 ADC 동작. ADC Off 시 Sampling Time을 0으로 설정.
    - Sampling Time 240 이상 설정해야함. 0일 경우 동작 안함.
    - Conversion Time : 650ns 고정 (Busy 신호가 없음)
    - SPI 20MHz, CPOL : 0, CPHA : 0

 d. AXI
    [READ Only]
    slv_reg 0 [15:0]    : 현재 ADC 값
    slv_reg 1 [2:0]  +4 : SPI Status (Used Debug)
    slv_reg 2 [15:0] +8 : DPBRAM Data

    [Write]
    slv_reg 3 [9:0]  +C     : ADC Sampling Time (240 이상) 최소 sampling 시간. * 5ns
    slv_reg 4 [13:0] +10    : RAM Save Size : (Capture time = Size * Sampling Time)
    slv_reg 5 [15:0] +14    : RAM Address

 e. 변환식
    (ADC data * 0.0003814) - 0.000732 = ADC Voltage

 f. 주의 사항
    - Samping Time 240 이상

3. DAC
 a. 개요
    - DAC8563, +-10V
    - 1개의 SPI로 2개의 DAC 제어
    - Initialize 필요
    - PS에서 명령하는 데이터 포맷을 그대로 DAC에 SPI로 보내주는 방식. 따라서 PL에서 별도의 연산을 하지 않음.
    - 16 Bit (SPI 24 Bit)
    - 2의 보수

 b. 구성
    Top_DAC.v - dac_DAC8563.v
                dac_S00_AXI.v
                dac_spi.v

 c. Initialize
    Reset           : 0010 1000 0000 0000 0000 0001 : 2621441  : 0x28 0001
    Power up        : 0010 0000 0000 0000 0000 0011 : 2097155  : 0x20 0003
    Internal ref en : 0011 1000 0000 0000 0000 0001 : 3670017  : 0x38 0001
    Gain Setup      : 0010 0000 0000 0000 0000 0000 : 131072   : 0x20 0000
    LDAC Pin dis    : 0011 0000 0000 0000 0000 0011 : 3145731  : 0x30 0003

 d. 동작
    DAC Out Set A : 0001 1000 0000 0000 0000 0000 (1572864) + DAC Data (16 Bit) : 0x18 xxxx
    DAC Out Set B : 0001 1001 0000 0000 0000 0000 (1572864) + DAC Data (16 Bit) : 0x19 xxxx

 e. AXI
    [Write]
    slv_reg 0 [23:0]    : DAC Data Write

 f. 변환식
    (DAC data * 0.000304932) - 9.99414796 = DAC Voltage

 g. 주의사항
    - DAC Data는 2의 보수임
    - Interlock 발생 시 0으로 설정 (1572864), slv_reg 1 [0] 1로 써줌 (LED 용)

4. Motor
 a. 개요
    - 5상 스테핑모터
    - MD5-HF14
    - 1 Pulse Type
    - CW : Pulse, CCW : Direction, Hold off

 b. 구성
    Top_Motor.v - Motor.v
                  Motor_S00_AXI.v
    
 c. 동작
    - Step수 만큼 회전
    - Dir에 따라서 방향 결정
    - Motor Speed 최소 10us 이상임 (2000 * 5ns). 실제 테스트 시 10us로도 안돌아가긴함. 5ms(1000000) 정도 줘야 잘 돌아감.

 d. AXI
    [Read Only]
    slv_reg 0 [31:0] +0    : 현재 남아있는 Motor Step (모터 동작 중 사용. 0인 경우 Stop 상태. 설정값에서 0으로 내려감)
    slv_reg 1 [0]    +4       : Motor Status (0 : Stop / 1 : Run)

    [Write]
    slv_reg 2 [31:0] +8    : Motor Step Setup
    slv_reg 3 [31:0] +C    : Motor Speed Setup : 1 -> 5ns
    slv_reg 4 [0]    +10       : Motor Run (0 : Stop / 1 : Run, 1 하고 난 뒤 0으로 Clear 후 다시 1로 해야 동작함)
    slv_reg 5 [0]    +14       : Motor Dir (0 : CCW, 1 : CW)
    slv_reg 6 [0]    +18       : Motor Hold Off (0 : Hold On / 1 : Hold Off)
    slv_reg 7 [0]    +1C       : Motor Enable (0 : Diable / 1 : Enable)

 e. 주의사항
    - 모터 속도가 빠르면 안돌아감
    - Interlock 발생 시 Motor Enable 신호 0으로 바꿔줌. 그러면 모터 바로 정지함

5. Limit
 a. 개요
    - 후면 Limit 및 Interlock 관련

 b. 구성
    Top_Limit.v - limit_S00_AXI.v

 c. 동작
    - 각 채널 별 Limit 발생 시 AXI와 PS에 바로 Interlock 발생함

 d. AXI
    [Read Only]
    slv_reg 0 [0]       : Interlock A Ch
    slv_reg 0 [1]       : - Limit A Ch
    slv_reg 0 [2]       : 0 Limit A Ch
    slv_reg 0 [3]       : + Limit A Ch

    slv_reg 1 [0]       : Interlock B Ch
    slv_reg 1 [1]       : - Limit B Ch
    slv_reg 1 [2]       : 0 Limit B Ch
    slv_reg 1 [3]       : + Limit B Ch

e. 주의사항
    - PS로 Interlock 신호 발생 시 해당 reg를 읽어서 원인 파악

6. Sequence
 a. 전체 동작
    - 모터 동작 -> DAC -> ADC -> DAC -> ADC -> .... -> 모터 동작 이후 반복
    - DAC는 -10V에서 사용자가 설정한 Step 전압만큼 점진적 증가 후 +10V가 되었을 시 다시 모터 동작

 b. 설정
    - 동작 Cycle 횟수 (전체 동작 횟수)
    - 모터 Step (이동 거리)
    - 모터 Speed
    - DAC Step 전압
    - ADC 측정 시간 (RAM Size, Sampling Time)

 c. Interlock
    - 후면 Interlock, Limit 및 사용자가 설정한 조건 시 발생
    - DAC 0V
    - Motor Stop, Hold Off
    - 기타 사용자가 설정한 기능들 추가