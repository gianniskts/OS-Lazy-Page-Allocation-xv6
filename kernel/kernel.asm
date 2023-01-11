
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8a013103          	ld	sp,-1888(sp) # 800088a0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8b070713          	addi	a4,a4,-1872 # 80008900 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	b6e78793          	addi	a5,a5,-1170 # 80005bd0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca8f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	3aa080e7          	jalr	938(ra) # 800024d4 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8b650513          	addi	a0,a0,-1866 # 80010a40 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8a648493          	addi	s1,s1,-1882 # 80010a40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	93690913          	addi	s2,s2,-1738 # 80010ad8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	80e080e7          	jalr	-2034(ra) # 800019ce <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	156080e7          	jalr	342(ra) # 8000231e <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	ea0080e7          	jalr	-352(ra) # 80002076 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	26c080e7          	jalr	620(ra) # 8000247e <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	81a50513          	addi	a0,a0,-2022 # 80010a40 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	80450513          	addi	a0,a0,-2044 # 80010a40 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	86f72323          	sw	a5,-1946(a4) # 80010ad8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	77450513          	addi	a0,a0,1908 # 80010a40 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	238080e7          	jalr	568(ra) # 8000252a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	74650513          	addi	a0,a0,1862 # 80010a40 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	72270713          	addi	a4,a4,1826 # 80010a40 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	6f878793          	addi	a5,a5,1784 # 80010a40 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7627a783          	lw	a5,1890(a5) # 80010ad8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6b670713          	addi	a4,a4,1718 # 80010a40 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6a648493          	addi	s1,s1,1702 # 80010a40 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	66a70713          	addi	a4,a4,1642 # 80010a40 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	6ef72a23          	sw	a5,1780(a4) # 80010ae0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	62e78793          	addi	a5,a5,1582 # 80010a40 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ac7a323          	sw	a2,1702(a5) # 80010adc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	69a50513          	addi	a0,a0,1690 # 80010ad8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c94080e7          	jalr	-876(ra) # 800020da <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5e050513          	addi	a0,a0,1504 # 80010a40 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00020797          	auipc	a5,0x20
    8000047c:	76078793          	addi	a5,a5,1888 # 80020bd8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5a07aa23          	sw	zero,1460(a5) # 80010b00 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	34f72023          	sw	a5,832(a4) # 800088c0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	544dad83          	lw	s11,1348(s11) # 80010b00 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	4ee50513          	addi	a0,a0,1262 # 80010ae8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	39050513          	addi	a0,a0,912 # 80010ae8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	37448493          	addi	s1,s1,884 # 80010ae8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	33450513          	addi	a0,a0,820 # 80010b08 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0c07a783          	lw	a5,192(a5) # 800088c0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0907b783          	ld	a5,144(a5) # 800088c8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	09073703          	ld	a4,144(a4) # 800088d0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2a6a0a13          	addi	s4,s4,678 # 80010b08 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	05e48493          	addi	s1,s1,94 # 800088c8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	05e98993          	addi	s3,s3,94 # 800088d0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	846080e7          	jalr	-1978(ra) # 800020da <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	23850513          	addi	a0,a0,568 # 80010b08 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	fe07a783          	lw	a5,-32(a5) # 800088c0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	fe673703          	ld	a4,-26(a4) # 800088d0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fd67b783          	ld	a5,-42(a5) # 800088c8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	20a98993          	addi	s3,s3,522 # 80010b08 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fc248493          	addi	s1,s1,-62 # 800088c8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fc290913          	addi	s2,s2,-62 # 800088d0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	758080e7          	jalr	1880(ra) # 80002076 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1d448493          	addi	s1,s1,468 # 80010b08 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	f8e7b423          	sd	a4,-120(a5) # 800088d0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	14e48493          	addi	s1,s1,334 # 80010b08 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00021797          	auipc	a5,0x21
    80000a00:	37478793          	addi	a5,a5,884 # 80021d70 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	12490913          	addi	s2,s2,292 # 80010b40 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	08650513          	addi	a0,a0,134 # 80010b40 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	2a250513          	addi	a0,a0,674 # 80021d70 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	05048493          	addi	s1,s1,80 # 80010b40 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	03850513          	addi	a0,a0,56 # 80010b40 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	00c50513          	addi	a0,a0,12 # 80010b40 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e42080e7          	jalr	-446(ra) # 800019b2 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	e10080e7          	jalr	-496(ra) # 800019b2 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	e04080e7          	jalr	-508(ra) # 800019b2 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dec080e7          	jalr	-532(ra) # 800019b2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	dac080e7          	jalr	-596(ra) # 800019b2 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d80080e7          	jalr	-640(ra) # 800019b2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd291>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b22080e7          	jalr	-1246(ra) # 800019a2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a5070713          	addi	a4,a4,-1456 # 800088d8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	b06080e7          	jalr	-1274(ra) # 800019a2 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0fa080e7          	jalr	250(ra) # 80000fb0 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00001097          	auipc	ra,0x1
    80000ec2:	7ae080e7          	jalr	1966(ra) # 8000266c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	d4a080e7          	jalr	-694(ra) # 80005c10 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	ff6080e7          	jalr	-10(ra) # 80001ec4 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	348080e7          	jalr	840(ra) # 80001266 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	08a080e7          	jalr	138(ra) # 80000fb0 <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	9c0080e7          	jalr	-1600(ra) # 800018ee <procinit>
    trapinit();      // trap vectors
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	70e080e7          	jalr	1806(ra) # 80002644 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	72e080e7          	jalr	1838(ra) # 8000266c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	cb4080e7          	jalr	-844(ra) # 80005bfa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	cc2080e7          	jalr	-830(ra) # 80005c10 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	e52080e7          	jalr	-430(ra) # 80002da8 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	4f2080e7          	jalr	1266(ra) # 80003450 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	498080e7          	jalr	1176(ra) # 800043fe <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	daa080e7          	jalr	-598(ra) # 80005d18 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d30080e7          	jalr	-720(ra) # 80001ca6 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	94f72a23          	sw	a5,-1708(a4) # 800088d8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <vmprint>:

extern char trampoline[]; // trampoline.S

void
vmprint(pagetable_t pagetable)
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e406                	sd	ra,8(sp)
    80000f92:	e022                	sd	s0,0(sp)
    80000f94:	0800                	addi	s0,sp,16
    80000f96:	85aa                	mv	a1,a0
  printf("page table %p\n", pagetable);
    80000f98:	00007517          	auipc	a0,0x7
    80000f9c:	13850513          	addi	a0,a0,312 # 800080d0 <digits+0x90>
    80000fa0:	fffff097          	auipc	ra,0xfffff
    80000fa4:	5ea080e7          	jalr	1514(ra) # 8000058a <printf>

  // for (int i=0; i<512; i++) {
  //   pte_t pte = pagetable[i];
    
  // }
}
    80000fa8:	60a2                	ld	ra,8(sp)
    80000faa:	6402                	ld	s0,0(sp)
    80000fac:	0141                	addi	sp,sp,16
    80000fae:	8082                	ret

0000000080000fb0 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fb0:	1141                	addi	sp,sp,-16
    80000fb2:	e422                	sd	s0,8(sp)
    80000fb4:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb6:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fba:	00008797          	auipc	a5,0x8
    80000fbe:	9267b783          	ld	a5,-1754(a5) # 800088e0 <kernel_pagetable>
    80000fc2:	83b1                	srli	a5,a5,0xc
    80000fc4:	577d                	li	a4,-1
    80000fc6:	177e                	slli	a4,a4,0x3f
    80000fc8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fca:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fce:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fd2:	6422                	ld	s0,8(sp)
    80000fd4:	0141                	addi	sp,sp,16
    80000fd6:	8082                	ret

0000000080000fd8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd8:	7139                	addi	sp,sp,-64
    80000fda:	fc06                	sd	ra,56(sp)
    80000fdc:	f822                	sd	s0,48(sp)
    80000fde:	f426                	sd	s1,40(sp)
    80000fe0:	f04a                	sd	s2,32(sp)
    80000fe2:	ec4e                	sd	s3,24(sp)
    80000fe4:	e852                	sd	s4,16(sp)
    80000fe6:	e456                	sd	s5,8(sp)
    80000fe8:	e05a                	sd	s6,0(sp)
    80000fea:	0080                	addi	s0,sp,64
    80000fec:	84aa                	mv	s1,a0
    80000fee:	89ae                	mv	s3,a1
    80000ff0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000ff2:	57fd                	li	a5,-1
    80000ff4:	83e9                	srli	a5,a5,0x1a
    80000ff6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ffa:	04b7f263          	bgeu	a5,a1,8000103e <walk+0x66>
    panic("walk");
    80000ffe:	00007517          	auipc	a0,0x7
    80001002:	0e250513          	addi	a0,a0,226 # 800080e0 <digits+0xa0>
    80001006:	fffff097          	auipc	ra,0xfffff
    8000100a:	53a080e7          	jalr	1338(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000100e:	060a8663          	beqz	s5,8000107a <walk+0xa2>
    80001012:	00000097          	auipc	ra,0x0
    80001016:	ad4080e7          	jalr	-1324(ra) # 80000ae6 <kalloc>
    8000101a:	84aa                	mv	s1,a0
    8000101c:	c529                	beqz	a0,80001066 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000101e:	6605                	lui	a2,0x1
    80001020:	4581                	li	a1,0
    80001022:	00000097          	auipc	ra,0x0
    80001026:	cb0080e7          	jalr	-848(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000102a:	00c4d793          	srli	a5,s1,0xc
    8000102e:	07aa                	slli	a5,a5,0xa
    80001030:	0017e793          	ori	a5,a5,1
    80001034:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001038:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd287>
    8000103a:	036a0063          	beq	s4,s6,8000105a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000103e:	0149d933          	srl	s2,s3,s4
    80001042:	1ff97913          	andi	s2,s2,511
    80001046:	090e                	slli	s2,s2,0x3
    80001048:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000104a:	00093483          	ld	s1,0(s2)
    8000104e:	0014f793          	andi	a5,s1,1
    80001052:	dfd5                	beqz	a5,8000100e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001054:	80a9                	srli	s1,s1,0xa
    80001056:	04b2                	slli	s1,s1,0xc
    80001058:	b7c5                	j	80001038 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000105a:	00c9d513          	srli	a0,s3,0xc
    8000105e:	1ff57513          	andi	a0,a0,511
    80001062:	050e                	slli	a0,a0,0x3
    80001064:	9526                	add	a0,a0,s1
}
    80001066:	70e2                	ld	ra,56(sp)
    80001068:	7442                	ld	s0,48(sp)
    8000106a:	74a2                	ld	s1,40(sp)
    8000106c:	7902                	ld	s2,32(sp)
    8000106e:	69e2                	ld	s3,24(sp)
    80001070:	6a42                	ld	s4,16(sp)
    80001072:	6aa2                	ld	s5,8(sp)
    80001074:	6b02                	ld	s6,0(sp)
    80001076:	6121                	addi	sp,sp,64
    80001078:	8082                	ret
        return 0;
    8000107a:	4501                	li	a0,0
    8000107c:	b7ed                	j	80001066 <walk+0x8e>

000000008000107e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000107e:	57fd                	li	a5,-1
    80001080:	83e9                	srli	a5,a5,0x1a
    80001082:	00b7f463          	bgeu	a5,a1,8000108a <walkaddr+0xc>
    return 0;
    80001086:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001088:	8082                	ret
{
    8000108a:	1141                	addi	sp,sp,-16
    8000108c:	e406                	sd	ra,8(sp)
    8000108e:	e022                	sd	s0,0(sp)
    80001090:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001092:	4601                	li	a2,0
    80001094:	00000097          	auipc	ra,0x0
    80001098:	f44080e7          	jalr	-188(ra) # 80000fd8 <walk>
  if(pte == 0)
    8000109c:	c105                	beqz	a0,800010bc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000109e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010a0:	0117f693          	andi	a3,a5,17
    800010a4:	4745                	li	a4,17
    return 0;
    800010a6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a8:	00e68663          	beq	a3,a4,800010b4 <walkaddr+0x36>
}
    800010ac:	60a2                	ld	ra,8(sp)
    800010ae:	6402                	ld	s0,0(sp)
    800010b0:	0141                	addi	sp,sp,16
    800010b2:	8082                	ret
  pa = PTE2PA(*pte);
    800010b4:	83a9                	srli	a5,a5,0xa
    800010b6:	00c79513          	slli	a0,a5,0xc
  return pa;
    800010ba:	bfcd                	j	800010ac <walkaddr+0x2e>
    return 0;
    800010bc:	4501                	li	a0,0
    800010be:	b7fd                	j	800010ac <walkaddr+0x2e>

00000000800010c0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010c0:	715d                	addi	sp,sp,-80
    800010c2:	e486                	sd	ra,72(sp)
    800010c4:	e0a2                	sd	s0,64(sp)
    800010c6:	fc26                	sd	s1,56(sp)
    800010c8:	f84a                	sd	s2,48(sp)
    800010ca:	f44e                	sd	s3,40(sp)
    800010cc:	f052                	sd	s4,32(sp)
    800010ce:	ec56                	sd	s5,24(sp)
    800010d0:	e85a                	sd	s6,16(sp)
    800010d2:	e45e                	sd	s7,8(sp)
    800010d4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d6:	c639                	beqz	a2,80001124 <mappages+0x64>
    800010d8:	8aaa                	mv	s5,a0
    800010da:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010dc:	777d                	lui	a4,0xfffff
    800010de:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010e2:	fff58993          	addi	s3,a1,-1
    800010e6:	99b2                	add	s3,s3,a2
    800010e8:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ec:	893e                	mv	s2,a5
    800010ee:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010f2:	6b85                	lui	s7,0x1
    800010f4:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f8:	4605                	li	a2,1
    800010fa:	85ca                	mv	a1,s2
    800010fc:	8556                	mv	a0,s5
    800010fe:	00000097          	auipc	ra,0x0
    80001102:	eda080e7          	jalr	-294(ra) # 80000fd8 <walk>
    80001106:	cd1d                	beqz	a0,80001144 <mappages+0x84>
    if(*pte & PTE_V)
    80001108:	611c                	ld	a5,0(a0)
    8000110a:	8b85                	andi	a5,a5,1
    8000110c:	e785                	bnez	a5,80001134 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000110e:	80b1                	srli	s1,s1,0xc
    80001110:	04aa                	slli	s1,s1,0xa
    80001112:	0164e4b3          	or	s1,s1,s6
    80001116:	0014e493          	ori	s1,s1,1
    8000111a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000111c:	05390063          	beq	s2,s3,8000115c <mappages+0x9c>
    a += PGSIZE;
    80001120:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001122:	bfc9                	j	800010f4 <mappages+0x34>
    panic("mappages: size");
    80001124:	00007517          	auipc	a0,0x7
    80001128:	fc450513          	addi	a0,a0,-60 # 800080e8 <digits+0xa8>
    8000112c:	fffff097          	auipc	ra,0xfffff
    80001130:	414080e7          	jalr	1044(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001134:	00007517          	auipc	a0,0x7
    80001138:	fc450513          	addi	a0,a0,-60 # 800080f8 <digits+0xb8>
    8000113c:	fffff097          	auipc	ra,0xfffff
    80001140:	404080e7          	jalr	1028(ra) # 80000540 <panic>
      return -1;
    80001144:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001146:	60a6                	ld	ra,72(sp)
    80001148:	6406                	ld	s0,64(sp)
    8000114a:	74e2                	ld	s1,56(sp)
    8000114c:	7942                	ld	s2,48(sp)
    8000114e:	79a2                	ld	s3,40(sp)
    80001150:	7a02                	ld	s4,32(sp)
    80001152:	6ae2                	ld	s5,24(sp)
    80001154:	6b42                	ld	s6,16(sp)
    80001156:	6ba2                	ld	s7,8(sp)
    80001158:	6161                	addi	sp,sp,80
    8000115a:	8082                	ret
  return 0;
    8000115c:	4501                	li	a0,0
    8000115e:	b7e5                	j	80001146 <mappages+0x86>

0000000080001160 <kvmmap>:
{
    80001160:	1141                	addi	sp,sp,-16
    80001162:	e406                	sd	ra,8(sp)
    80001164:	e022                	sd	s0,0(sp)
    80001166:	0800                	addi	s0,sp,16
    80001168:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000116a:	86b2                	mv	a3,a2
    8000116c:	863e                	mv	a2,a5
    8000116e:	00000097          	auipc	ra,0x0
    80001172:	f52080e7          	jalr	-174(ra) # 800010c0 <mappages>
    80001176:	e509                	bnez	a0,80001180 <kvmmap+0x20>
}
    80001178:	60a2                	ld	ra,8(sp)
    8000117a:	6402                	ld	s0,0(sp)
    8000117c:	0141                	addi	sp,sp,16
    8000117e:	8082                	ret
    panic("kvmmap");
    80001180:	00007517          	auipc	a0,0x7
    80001184:	f8850513          	addi	a0,a0,-120 # 80008108 <digits+0xc8>
    80001188:	fffff097          	auipc	ra,0xfffff
    8000118c:	3b8080e7          	jalr	952(ra) # 80000540 <panic>

0000000080001190 <kvmmake>:
{
    80001190:	1101                	addi	sp,sp,-32
    80001192:	ec06                	sd	ra,24(sp)
    80001194:	e822                	sd	s0,16(sp)
    80001196:	e426                	sd	s1,8(sp)
    80001198:	e04a                	sd	s2,0(sp)
    8000119a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000119c:	00000097          	auipc	ra,0x0
    800011a0:	94a080e7          	jalr	-1718(ra) # 80000ae6 <kalloc>
    800011a4:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a6:	6605                	lui	a2,0x1
    800011a8:	4581                	li	a1,0
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	b28080e7          	jalr	-1240(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	6685                	lui	a3,0x1
    800011b6:	10000637          	lui	a2,0x10000
    800011ba:	100005b7          	lui	a1,0x10000
    800011be:	8526                	mv	a0,s1
    800011c0:	00000097          	auipc	ra,0x0
    800011c4:	fa0080e7          	jalr	-96(ra) # 80001160 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c8:	4719                	li	a4,6
    800011ca:	6685                	lui	a3,0x1
    800011cc:	10001637          	lui	a2,0x10001
    800011d0:	100015b7          	lui	a1,0x10001
    800011d4:	8526                	mv	a0,s1
    800011d6:	00000097          	auipc	ra,0x0
    800011da:	f8a080e7          	jalr	-118(ra) # 80001160 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011de:	4719                	li	a4,6
    800011e0:	004006b7          	lui	a3,0x400
    800011e4:	0c000637          	lui	a2,0xc000
    800011e8:	0c0005b7          	lui	a1,0xc000
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f72080e7          	jalr	-142(ra) # 80001160 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f6:	00007917          	auipc	s2,0x7
    800011fa:	e0a90913          	addi	s2,s2,-502 # 80008000 <etext>
    800011fe:	4729                	li	a4,10
    80001200:	80007697          	auipc	a3,0x80007
    80001204:	e0068693          	addi	a3,a3,-512 # 8000 <_entry-0x7fff8000>
    80001208:	4605                	li	a2,1
    8000120a:	067e                	slli	a2,a2,0x1f
    8000120c:	85b2                	mv	a1,a2
    8000120e:	8526                	mv	a0,s1
    80001210:	00000097          	auipc	ra,0x0
    80001214:	f50080e7          	jalr	-176(ra) # 80001160 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001218:	4719                	li	a4,6
    8000121a:	46c5                	li	a3,17
    8000121c:	06ee                	slli	a3,a3,0x1b
    8000121e:	412686b3          	sub	a3,a3,s2
    80001222:	864a                	mv	a2,s2
    80001224:	85ca                	mv	a1,s2
    80001226:	8526                	mv	a0,s1
    80001228:	00000097          	auipc	ra,0x0
    8000122c:	f38080e7          	jalr	-200(ra) # 80001160 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001230:	4729                	li	a4,10
    80001232:	6685                	lui	a3,0x1
    80001234:	00006617          	auipc	a2,0x6
    80001238:	dcc60613          	addi	a2,a2,-564 # 80007000 <_trampoline>
    8000123c:	040005b7          	lui	a1,0x4000
    80001240:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001242:	05b2                	slli	a1,a1,0xc
    80001244:	8526                	mv	a0,s1
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	f1a080e7          	jalr	-230(ra) # 80001160 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000124e:	8526                	mv	a0,s1
    80001250:	00000097          	auipc	ra,0x0
    80001254:	608080e7          	jalr	1544(ra) # 80001858 <proc_mapstacks>
}
    80001258:	8526                	mv	a0,s1
    8000125a:	60e2                	ld	ra,24(sp)
    8000125c:	6442                	ld	s0,16(sp)
    8000125e:	64a2                	ld	s1,8(sp)
    80001260:	6902                	ld	s2,0(sp)
    80001262:	6105                	addi	sp,sp,32
    80001264:	8082                	ret

0000000080001266 <kvminit>:
{
    80001266:	1141                	addi	sp,sp,-16
    80001268:	e406                	sd	ra,8(sp)
    8000126a:	e022                	sd	s0,0(sp)
    8000126c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000126e:	00000097          	auipc	ra,0x0
    80001272:	f22080e7          	jalr	-222(ra) # 80001190 <kvmmake>
    80001276:	00007797          	auipc	a5,0x7
    8000127a:	66a7b523          	sd	a0,1642(a5) # 800088e0 <kernel_pagetable>
}
    8000127e:	60a2                	ld	ra,8(sp)
    80001280:	6402                	ld	s0,0(sp)
    80001282:	0141                	addi	sp,sp,16
    80001284:	8082                	ret

0000000080001286 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001286:	715d                	addi	sp,sp,-80
    80001288:	e486                	sd	ra,72(sp)
    8000128a:	e0a2                	sd	s0,64(sp)
    8000128c:	fc26                	sd	s1,56(sp)
    8000128e:	f84a                	sd	s2,48(sp)
    80001290:	f44e                	sd	s3,40(sp)
    80001292:	f052                	sd	s4,32(sp)
    80001294:	ec56                	sd	s5,24(sp)
    80001296:	e85a                	sd	s6,16(sp)
    80001298:	e45e                	sd	s7,8(sp)
    8000129a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000129c:	03459793          	slli	a5,a1,0x34
    800012a0:	e795                	bnez	a5,800012cc <uvmunmap+0x46>
    800012a2:	8a2a                	mv	s4,a0
    800012a4:	892e                	mv	s2,a1
    800012a6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a8:	0632                	slli	a2,a2,0xc
    800012aa:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ae:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012b0:	6b05                	lui	s6,0x1
    800012b2:	0735e263          	bltu	a1,s3,80001316 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b6:	60a6                	ld	ra,72(sp)
    800012b8:	6406                	ld	s0,64(sp)
    800012ba:	74e2                	ld	s1,56(sp)
    800012bc:	7942                	ld	s2,48(sp)
    800012be:	79a2                	ld	s3,40(sp)
    800012c0:	7a02                	ld	s4,32(sp)
    800012c2:	6ae2                	ld	s5,24(sp)
    800012c4:	6b42                	ld	s6,16(sp)
    800012c6:	6ba2                	ld	s7,8(sp)
    800012c8:	6161                	addi	sp,sp,80
    800012ca:	8082                	ret
    panic("uvmunmap: not aligned");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4450513          	addi	a0,a0,-444 # 80008110 <digits+0xd0>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26c080e7          	jalr	620(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25c080e7          	jalr	604(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e4c50513          	addi	a0,a0,-436 # 80008138 <digits+0xf8>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24c080e7          	jalr	588(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012fc:	00007517          	auipc	a0,0x7
    80001300:	e5450513          	addi	a0,a0,-428 # 80008150 <digits+0x110>
    80001304:	fffff097          	auipc	ra,0xfffff
    80001308:	23c080e7          	jalr	572(ra) # 80000540 <panic>
    *pte = 0;
    8000130c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001310:	995a                	add	s2,s2,s6
    80001312:	fb3972e3          	bgeu	s2,s3,800012b6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001316:	4601                	li	a2,0
    80001318:	85ca                	mv	a1,s2
    8000131a:	8552                	mv	a0,s4
    8000131c:	00000097          	auipc	ra,0x0
    80001320:	cbc080e7          	jalr	-836(ra) # 80000fd8 <walk>
    80001324:	84aa                	mv	s1,a0
    80001326:	d95d                	beqz	a0,800012dc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001328:	6108                	ld	a0,0(a0)
    8000132a:	00157793          	andi	a5,a0,1
    8000132e:	dfdd                	beqz	a5,800012ec <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001330:	3ff57793          	andi	a5,a0,1023
    80001334:	fd7784e3          	beq	a5,s7,800012fc <uvmunmap+0x76>
    if(do_free){
    80001338:	fc0a8ae3          	beqz	s5,8000130c <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000133c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000133e:	0532                	slli	a0,a0,0xc
    80001340:	fffff097          	auipc	ra,0xfffff
    80001344:	6a8080e7          	jalr	1704(ra) # 800009e8 <kfree>
    80001348:	b7d1                	j	8000130c <uvmunmap+0x86>

000000008000134a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000134a:	1101                	addi	sp,sp,-32
    8000134c:	ec06                	sd	ra,24(sp)
    8000134e:	e822                	sd	s0,16(sp)
    80001350:	e426                	sd	s1,8(sp)
    80001352:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001354:	fffff097          	auipc	ra,0xfffff
    80001358:	792080e7          	jalr	1938(ra) # 80000ae6 <kalloc>
    8000135c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000135e:	c519                	beqz	a0,8000136c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001360:	6605                	lui	a2,0x1
    80001362:	4581                	li	a1,0
    80001364:	00000097          	auipc	ra,0x0
    80001368:	96e080e7          	jalr	-1682(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000136c:	8526                	mv	a0,s1
    8000136e:	60e2                	ld	ra,24(sp)
    80001370:	6442                	ld	s0,16(sp)
    80001372:	64a2                	ld	s1,8(sp)
    80001374:	6105                	addi	sp,sp,32
    80001376:	8082                	ret

0000000080001378 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001378:	7179                	addi	sp,sp,-48
    8000137a:	f406                	sd	ra,40(sp)
    8000137c:	f022                	sd	s0,32(sp)
    8000137e:	ec26                	sd	s1,24(sp)
    80001380:	e84a                	sd	s2,16(sp)
    80001382:	e44e                	sd	s3,8(sp)
    80001384:	e052                	sd	s4,0(sp)
    80001386:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001388:	6785                	lui	a5,0x1
    8000138a:	04f67863          	bgeu	a2,a5,800013da <uvmfirst+0x62>
    8000138e:	8a2a                	mv	s4,a0
    80001390:	89ae                	mv	s3,a1
    80001392:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001394:	fffff097          	auipc	ra,0xfffff
    80001398:	752080e7          	jalr	1874(ra) # 80000ae6 <kalloc>
    8000139c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	00000097          	auipc	ra,0x0
    800013a6:	930080e7          	jalr	-1744(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013aa:	4779                	li	a4,30
    800013ac:	86ca                	mv	a3,s2
    800013ae:	6605                	lui	a2,0x1
    800013b0:	4581                	li	a1,0
    800013b2:	8552                	mv	a0,s4
    800013b4:	00000097          	auipc	ra,0x0
    800013b8:	d0c080e7          	jalr	-756(ra) # 800010c0 <mappages>
  memmove(mem, src, sz);
    800013bc:	8626                	mv	a2,s1
    800013be:	85ce                	mv	a1,s3
    800013c0:	854a                	mv	a0,s2
    800013c2:	00000097          	auipc	ra,0x0
    800013c6:	96c080e7          	jalr	-1684(ra) # 80000d2e <memmove>
}
    800013ca:	70a2                	ld	ra,40(sp)
    800013cc:	7402                	ld	s0,32(sp)
    800013ce:	64e2                	ld	s1,24(sp)
    800013d0:	6942                	ld	s2,16(sp)
    800013d2:	69a2                	ld	s3,8(sp)
    800013d4:	6a02                	ld	s4,0(sp)
    800013d6:	6145                	addi	sp,sp,48
    800013d8:	8082                	ret
    panic("uvmfirst: more than a page");
    800013da:	00007517          	auipc	a0,0x7
    800013de:	d8e50513          	addi	a0,a0,-626 # 80008168 <digits+0x128>
    800013e2:	fffff097          	auipc	ra,0xfffff
    800013e6:	15e080e7          	jalr	350(ra) # 80000540 <panic>

00000000800013ea <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013ea:	1101                	addi	sp,sp,-32
    800013ec:	ec06                	sd	ra,24(sp)
    800013ee:	e822                	sd	s0,16(sp)
    800013f0:	e426                	sd	s1,8(sp)
    800013f2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013f4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f6:	00b67d63          	bgeu	a2,a1,80001410 <uvmdealloc+0x26>
    800013fa:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013fc:	6785                	lui	a5,0x1
    800013fe:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001400:	00f60733          	add	a4,a2,a5
    80001404:	76fd                	lui	a3,0xfffff
    80001406:	8f75                	and	a4,a4,a3
    80001408:	97ae                	add	a5,a5,a1
    8000140a:	8ff5                	and	a5,a5,a3
    8000140c:	00f76863          	bltu	a4,a5,8000141c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001410:	8526                	mv	a0,s1
    80001412:	60e2                	ld	ra,24(sp)
    80001414:	6442                	ld	s0,16(sp)
    80001416:	64a2                	ld	s1,8(sp)
    80001418:	6105                	addi	sp,sp,32
    8000141a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000141c:	8f99                	sub	a5,a5,a4
    8000141e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001420:	4685                	li	a3,1
    80001422:	0007861b          	sext.w	a2,a5
    80001426:	85ba                	mv	a1,a4
    80001428:	00000097          	auipc	ra,0x0
    8000142c:	e5e080e7          	jalr	-418(ra) # 80001286 <uvmunmap>
    80001430:	b7c5                	j	80001410 <uvmdealloc+0x26>

0000000080001432 <uvmalloc>:
  if(newsz < oldsz)
    80001432:	0ab66563          	bltu	a2,a1,800014dc <uvmalloc+0xaa>
{
    80001436:	7139                	addi	sp,sp,-64
    80001438:	fc06                	sd	ra,56(sp)
    8000143a:	f822                	sd	s0,48(sp)
    8000143c:	f426                	sd	s1,40(sp)
    8000143e:	f04a                	sd	s2,32(sp)
    80001440:	ec4e                	sd	s3,24(sp)
    80001442:	e852                	sd	s4,16(sp)
    80001444:	e456                	sd	s5,8(sp)
    80001446:	e05a                	sd	s6,0(sp)
    80001448:	0080                	addi	s0,sp,64
    8000144a:	8aaa                	mv	s5,a0
    8000144c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000144e:	6785                	lui	a5,0x1
    80001450:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001452:	95be                	add	a1,a1,a5
    80001454:	77fd                	lui	a5,0xfffff
    80001456:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145a:	08c9f363          	bgeu	s3,a2,800014e0 <uvmalloc+0xae>
    8000145e:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001460:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001464:	fffff097          	auipc	ra,0xfffff
    80001468:	682080e7          	jalr	1666(ra) # 80000ae6 <kalloc>
    8000146c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000146e:	c51d                	beqz	a0,8000149c <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001470:	6605                	lui	a2,0x1
    80001472:	4581                	li	a1,0
    80001474:	00000097          	auipc	ra,0x0
    80001478:	85e080e7          	jalr	-1954(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000147c:	875a                	mv	a4,s6
    8000147e:	86a6                	mv	a3,s1
    80001480:	6605                	lui	a2,0x1
    80001482:	85ca                	mv	a1,s2
    80001484:	8556                	mv	a0,s5
    80001486:	00000097          	auipc	ra,0x0
    8000148a:	c3a080e7          	jalr	-966(ra) # 800010c0 <mappages>
    8000148e:	e90d                	bnez	a0,800014c0 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001490:	6785                	lui	a5,0x1
    80001492:	993e                	add	s2,s2,a5
    80001494:	fd4968e3          	bltu	s2,s4,80001464 <uvmalloc+0x32>
  return newsz;
    80001498:	8552                	mv	a0,s4
    8000149a:	a809                	j	800014ac <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000149c:	864e                	mv	a2,s3
    8000149e:	85ca                	mv	a1,s2
    800014a0:	8556                	mv	a0,s5
    800014a2:	00000097          	auipc	ra,0x0
    800014a6:	f48080e7          	jalr	-184(ra) # 800013ea <uvmdealloc>
      return 0;
    800014aa:	4501                	li	a0,0
}
    800014ac:	70e2                	ld	ra,56(sp)
    800014ae:	7442                	ld	s0,48(sp)
    800014b0:	74a2                	ld	s1,40(sp)
    800014b2:	7902                	ld	s2,32(sp)
    800014b4:	69e2                	ld	s3,24(sp)
    800014b6:	6a42                	ld	s4,16(sp)
    800014b8:	6aa2                	ld	s5,8(sp)
    800014ba:	6b02                	ld	s6,0(sp)
    800014bc:	6121                	addi	sp,sp,64
    800014be:	8082                	ret
      kfree(mem);
    800014c0:	8526                	mv	a0,s1
    800014c2:	fffff097          	auipc	ra,0xfffff
    800014c6:	526080e7          	jalr	1318(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ca:	864e                	mv	a2,s3
    800014cc:	85ca                	mv	a1,s2
    800014ce:	8556                	mv	a0,s5
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	f1a080e7          	jalr	-230(ra) # 800013ea <uvmdealloc>
      return 0;
    800014d8:	4501                	li	a0,0
    800014da:	bfc9                	j	800014ac <uvmalloc+0x7a>
    return oldsz;
    800014dc:	852e                	mv	a0,a1
}
    800014de:	8082                	ret
  return newsz;
    800014e0:	8532                	mv	a0,a2
    800014e2:	b7e9                	j	800014ac <uvmalloc+0x7a>

00000000800014e4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014e4:	7179                	addi	sp,sp,-48
    800014e6:	f406                	sd	ra,40(sp)
    800014e8:	f022                	sd	s0,32(sp)
    800014ea:	ec26                	sd	s1,24(sp)
    800014ec:	e84a                	sd	s2,16(sp)
    800014ee:	e44e                	sd	s3,8(sp)
    800014f0:	e052                	sd	s4,0(sp)
    800014f2:	1800                	addi	s0,sp,48
    800014f4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f6:	84aa                	mv	s1,a0
    800014f8:	6905                	lui	s2,0x1
    800014fa:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014fc:	4985                	li	s3,1
    800014fe:	a829                	j	80001518 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001500:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001502:	00c79513          	slli	a0,a5,0xc
    80001506:	00000097          	auipc	ra,0x0
    8000150a:	fde080e7          	jalr	-34(ra) # 800014e4 <freewalk>
      pagetable[i] = 0;
    8000150e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001512:	04a1                	addi	s1,s1,8
    80001514:	03248163          	beq	s1,s2,80001536 <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001518:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000151a:	00f7f713          	andi	a4,a5,15
    8000151e:	ff3701e3          	beq	a4,s3,80001500 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001522:	8b85                	andi	a5,a5,1
    80001524:	d7fd                	beqz	a5,80001512 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001526:	00007517          	auipc	a0,0x7
    8000152a:	c6250513          	addi	a0,a0,-926 # 80008188 <digits+0x148>
    8000152e:	fffff097          	auipc	ra,0xfffff
    80001532:	012080e7          	jalr	18(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001536:	8552                	mv	a0,s4
    80001538:	fffff097          	auipc	ra,0xfffff
    8000153c:	4b0080e7          	jalr	1200(ra) # 800009e8 <kfree>
}
    80001540:	70a2                	ld	ra,40(sp)
    80001542:	7402                	ld	s0,32(sp)
    80001544:	64e2                	ld	s1,24(sp)
    80001546:	6942                	ld	s2,16(sp)
    80001548:	69a2                	ld	s3,8(sp)
    8000154a:	6a02                	ld	s4,0(sp)
    8000154c:	6145                	addi	sp,sp,48
    8000154e:	8082                	ret

0000000080001550 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001550:	1101                	addi	sp,sp,-32
    80001552:	ec06                	sd	ra,24(sp)
    80001554:	e822                	sd	s0,16(sp)
    80001556:	e426                	sd	s1,8(sp)
    80001558:	1000                	addi	s0,sp,32
    8000155a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000155c:	e999                	bnez	a1,80001572 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000155e:	8526                	mv	a0,s1
    80001560:	00000097          	auipc	ra,0x0
    80001564:	f84080e7          	jalr	-124(ra) # 800014e4 <freewalk>
}
    80001568:	60e2                	ld	ra,24(sp)
    8000156a:	6442                	ld	s0,16(sp)
    8000156c:	64a2                	ld	s1,8(sp)
    8000156e:	6105                	addi	sp,sp,32
    80001570:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001572:	6785                	lui	a5,0x1
    80001574:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001576:	95be                	add	a1,a1,a5
    80001578:	4685                	li	a3,1
    8000157a:	00c5d613          	srli	a2,a1,0xc
    8000157e:	4581                	li	a1,0
    80001580:	00000097          	auipc	ra,0x0
    80001584:	d06080e7          	jalr	-762(ra) # 80001286 <uvmunmap>
    80001588:	bfd9                	j	8000155e <uvmfree+0xe>

000000008000158a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000158a:	c679                	beqz	a2,80001658 <uvmcopy+0xce>
{
    8000158c:	715d                	addi	sp,sp,-80
    8000158e:	e486                	sd	ra,72(sp)
    80001590:	e0a2                	sd	s0,64(sp)
    80001592:	fc26                	sd	s1,56(sp)
    80001594:	f84a                	sd	s2,48(sp)
    80001596:	f44e                	sd	s3,40(sp)
    80001598:	f052                	sd	s4,32(sp)
    8000159a:	ec56                	sd	s5,24(sp)
    8000159c:	e85a                	sd	s6,16(sp)
    8000159e:	e45e                	sd	s7,8(sp)
    800015a0:	0880                	addi	s0,sp,80
    800015a2:	8b2a                	mv	s6,a0
    800015a4:	8aae                	mv	s5,a1
    800015a6:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015a8:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015aa:	4601                	li	a2,0
    800015ac:	85ce                	mv	a1,s3
    800015ae:	855a                	mv	a0,s6
    800015b0:	00000097          	auipc	ra,0x0
    800015b4:	a28080e7          	jalr	-1496(ra) # 80000fd8 <walk>
    800015b8:	c531                	beqz	a0,80001604 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015ba:	6118                	ld	a4,0(a0)
    800015bc:	00177793          	andi	a5,a4,1
    800015c0:	cbb1                	beqz	a5,80001614 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015c2:	00a75593          	srli	a1,a4,0xa
    800015c6:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ca:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ce:	fffff097          	auipc	ra,0xfffff
    800015d2:	518080e7          	jalr	1304(ra) # 80000ae6 <kalloc>
    800015d6:	892a                	mv	s2,a0
    800015d8:	c939                	beqz	a0,8000162e <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015da:	6605                	lui	a2,0x1
    800015dc:	85de                	mv	a1,s7
    800015de:	fffff097          	auipc	ra,0xfffff
    800015e2:	750080e7          	jalr	1872(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015e6:	8726                	mv	a4,s1
    800015e8:	86ca                	mv	a3,s2
    800015ea:	6605                	lui	a2,0x1
    800015ec:	85ce                	mv	a1,s3
    800015ee:	8556                	mv	a0,s5
    800015f0:	00000097          	auipc	ra,0x0
    800015f4:	ad0080e7          	jalr	-1328(ra) # 800010c0 <mappages>
    800015f8:	e515                	bnez	a0,80001624 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015fa:	6785                	lui	a5,0x1
    800015fc:	99be                	add	s3,s3,a5
    800015fe:	fb49e6e3          	bltu	s3,s4,800015aa <uvmcopy+0x20>
    80001602:	a081                	j	80001642 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001604:	00007517          	auipc	a0,0x7
    80001608:	b9450513          	addi	a0,a0,-1132 # 80008198 <digits+0x158>
    8000160c:	fffff097          	auipc	ra,0xfffff
    80001610:	f34080e7          	jalr	-204(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    80001614:	00007517          	auipc	a0,0x7
    80001618:	ba450513          	addi	a0,a0,-1116 # 800081b8 <digits+0x178>
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	f24080e7          	jalr	-220(ra) # 80000540 <panic>
      kfree(mem);
    80001624:	854a                	mv	a0,s2
    80001626:	fffff097          	auipc	ra,0xfffff
    8000162a:	3c2080e7          	jalr	962(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000162e:	4685                	li	a3,1
    80001630:	00c9d613          	srli	a2,s3,0xc
    80001634:	4581                	li	a1,0
    80001636:	8556                	mv	a0,s5
    80001638:	00000097          	auipc	ra,0x0
    8000163c:	c4e080e7          	jalr	-946(ra) # 80001286 <uvmunmap>
  return -1;
    80001640:	557d                	li	a0,-1
}
    80001642:	60a6                	ld	ra,72(sp)
    80001644:	6406                	ld	s0,64(sp)
    80001646:	74e2                	ld	s1,56(sp)
    80001648:	7942                	ld	s2,48(sp)
    8000164a:	79a2                	ld	s3,40(sp)
    8000164c:	7a02                	ld	s4,32(sp)
    8000164e:	6ae2                	ld	s5,24(sp)
    80001650:	6b42                	ld	s6,16(sp)
    80001652:	6ba2                	ld	s7,8(sp)
    80001654:	6161                	addi	sp,sp,80
    80001656:	8082                	ret
  return 0;
    80001658:	4501                	li	a0,0
}
    8000165a:	8082                	ret

000000008000165c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000165c:	1141                	addi	sp,sp,-16
    8000165e:	e406                	sd	ra,8(sp)
    80001660:	e022                	sd	s0,0(sp)
    80001662:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001664:	4601                	li	a2,0
    80001666:	00000097          	auipc	ra,0x0
    8000166a:	972080e7          	jalr	-1678(ra) # 80000fd8 <walk>
  if(pte == 0)
    8000166e:	c901                	beqz	a0,8000167e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001670:	611c                	ld	a5,0(a0)
    80001672:	9bbd                	andi	a5,a5,-17
    80001674:	e11c                	sd	a5,0(a0)
}
    80001676:	60a2                	ld	ra,8(sp)
    80001678:	6402                	ld	s0,0(sp)
    8000167a:	0141                	addi	sp,sp,16
    8000167c:	8082                	ret
    panic("uvmclear");
    8000167e:	00007517          	auipc	a0,0x7
    80001682:	b5a50513          	addi	a0,a0,-1190 # 800081d8 <digits+0x198>
    80001686:	fffff097          	auipc	ra,0xfffff
    8000168a:	eba080e7          	jalr	-326(ra) # 80000540 <panic>

000000008000168e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000168e:	c6bd                	beqz	a3,800016fc <copyout+0x6e>
{
    80001690:	715d                	addi	sp,sp,-80
    80001692:	e486                	sd	ra,72(sp)
    80001694:	e0a2                	sd	s0,64(sp)
    80001696:	fc26                	sd	s1,56(sp)
    80001698:	f84a                	sd	s2,48(sp)
    8000169a:	f44e                	sd	s3,40(sp)
    8000169c:	f052                	sd	s4,32(sp)
    8000169e:	ec56                	sd	s5,24(sp)
    800016a0:	e85a                	sd	s6,16(sp)
    800016a2:	e45e                	sd	s7,8(sp)
    800016a4:	e062                	sd	s8,0(sp)
    800016a6:	0880                	addi	s0,sp,80
    800016a8:	8b2a                	mv	s6,a0
    800016aa:	8c2e                	mv	s8,a1
    800016ac:	8a32                	mv	s4,a2
    800016ae:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016b0:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016b2:	6a85                	lui	s5,0x1
    800016b4:	a015                	j	800016d8 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016b6:	9562                	add	a0,a0,s8
    800016b8:	0004861b          	sext.w	a2,s1
    800016bc:	85d2                	mv	a1,s4
    800016be:	41250533          	sub	a0,a0,s2
    800016c2:	fffff097          	auipc	ra,0xfffff
    800016c6:	66c080e7          	jalr	1644(ra) # 80000d2e <memmove>

    len -= n;
    800016ca:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ce:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016d0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016d4:	02098263          	beqz	s3,800016f8 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016d8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016dc:	85ca                	mv	a1,s2
    800016de:	855a                	mv	a0,s6
    800016e0:	00000097          	auipc	ra,0x0
    800016e4:	99e080e7          	jalr	-1634(ra) # 8000107e <walkaddr>
    if(pa0 == 0)
    800016e8:	cd01                	beqz	a0,80001700 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ea:	418904b3          	sub	s1,s2,s8
    800016ee:	94d6                	add	s1,s1,s5
    800016f0:	fc99f3e3          	bgeu	s3,s1,800016b6 <copyout+0x28>
    800016f4:	84ce                	mv	s1,s3
    800016f6:	b7c1                	j	800016b6 <copyout+0x28>
  }
  return 0;
    800016f8:	4501                	li	a0,0
    800016fa:	a021                	j	80001702 <copyout+0x74>
    800016fc:	4501                	li	a0,0
}
    800016fe:	8082                	ret
      return -1;
    80001700:	557d                	li	a0,-1
}
    80001702:	60a6                	ld	ra,72(sp)
    80001704:	6406                	ld	s0,64(sp)
    80001706:	74e2                	ld	s1,56(sp)
    80001708:	7942                	ld	s2,48(sp)
    8000170a:	79a2                	ld	s3,40(sp)
    8000170c:	7a02                	ld	s4,32(sp)
    8000170e:	6ae2                	ld	s5,24(sp)
    80001710:	6b42                	ld	s6,16(sp)
    80001712:	6ba2                	ld	s7,8(sp)
    80001714:	6c02                	ld	s8,0(sp)
    80001716:	6161                	addi	sp,sp,80
    80001718:	8082                	ret

000000008000171a <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000171a:	caa5                	beqz	a3,8000178a <copyin+0x70>
{
    8000171c:	715d                	addi	sp,sp,-80
    8000171e:	e486                	sd	ra,72(sp)
    80001720:	e0a2                	sd	s0,64(sp)
    80001722:	fc26                	sd	s1,56(sp)
    80001724:	f84a                	sd	s2,48(sp)
    80001726:	f44e                	sd	s3,40(sp)
    80001728:	f052                	sd	s4,32(sp)
    8000172a:	ec56                	sd	s5,24(sp)
    8000172c:	e85a                	sd	s6,16(sp)
    8000172e:	e45e                	sd	s7,8(sp)
    80001730:	e062                	sd	s8,0(sp)
    80001732:	0880                	addi	s0,sp,80
    80001734:	8b2a                	mv	s6,a0
    80001736:	8a2e                	mv	s4,a1
    80001738:	8c32                	mv	s8,a2
    8000173a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000173c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000173e:	6a85                	lui	s5,0x1
    80001740:	a01d                	j	80001766 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001742:	018505b3          	add	a1,a0,s8
    80001746:	0004861b          	sext.w	a2,s1
    8000174a:	412585b3          	sub	a1,a1,s2
    8000174e:	8552                	mv	a0,s4
    80001750:	fffff097          	auipc	ra,0xfffff
    80001754:	5de080e7          	jalr	1502(ra) # 80000d2e <memmove>

    len -= n;
    80001758:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000175c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000175e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001762:	02098263          	beqz	s3,80001786 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001766:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000176a:	85ca                	mv	a1,s2
    8000176c:	855a                	mv	a0,s6
    8000176e:	00000097          	auipc	ra,0x0
    80001772:	910080e7          	jalr	-1776(ra) # 8000107e <walkaddr>
    if(pa0 == 0)
    80001776:	cd01                	beqz	a0,8000178e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001778:	418904b3          	sub	s1,s2,s8
    8000177c:	94d6                	add	s1,s1,s5
    8000177e:	fc99f2e3          	bgeu	s3,s1,80001742 <copyin+0x28>
    80001782:	84ce                	mv	s1,s3
    80001784:	bf7d                	j	80001742 <copyin+0x28>
  }
  return 0;
    80001786:	4501                	li	a0,0
    80001788:	a021                	j	80001790 <copyin+0x76>
    8000178a:	4501                	li	a0,0
}
    8000178c:	8082                	ret
      return -1;
    8000178e:	557d                	li	a0,-1
}
    80001790:	60a6                	ld	ra,72(sp)
    80001792:	6406                	ld	s0,64(sp)
    80001794:	74e2                	ld	s1,56(sp)
    80001796:	7942                	ld	s2,48(sp)
    80001798:	79a2                	ld	s3,40(sp)
    8000179a:	7a02                	ld	s4,32(sp)
    8000179c:	6ae2                	ld	s5,24(sp)
    8000179e:	6b42                	ld	s6,16(sp)
    800017a0:	6ba2                	ld	s7,8(sp)
    800017a2:	6c02                	ld	s8,0(sp)
    800017a4:	6161                	addi	sp,sp,80
    800017a6:	8082                	ret

00000000800017a8 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017a8:	c2dd                	beqz	a3,8000184e <copyinstr+0xa6>
{
    800017aa:	715d                	addi	sp,sp,-80
    800017ac:	e486                	sd	ra,72(sp)
    800017ae:	e0a2                	sd	s0,64(sp)
    800017b0:	fc26                	sd	s1,56(sp)
    800017b2:	f84a                	sd	s2,48(sp)
    800017b4:	f44e                	sd	s3,40(sp)
    800017b6:	f052                	sd	s4,32(sp)
    800017b8:	ec56                	sd	s5,24(sp)
    800017ba:	e85a                	sd	s6,16(sp)
    800017bc:	e45e                	sd	s7,8(sp)
    800017be:	0880                	addi	s0,sp,80
    800017c0:	8a2a                	mv	s4,a0
    800017c2:	8b2e                	mv	s6,a1
    800017c4:	8bb2                	mv	s7,a2
    800017c6:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017c8:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ca:	6985                	lui	s3,0x1
    800017cc:	a02d                	j	800017f6 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ce:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017d2:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017d4:	37fd                	addiw	a5,a5,-1
    800017d6:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017da:	60a6                	ld	ra,72(sp)
    800017dc:	6406                	ld	s0,64(sp)
    800017de:	74e2                	ld	s1,56(sp)
    800017e0:	7942                	ld	s2,48(sp)
    800017e2:	79a2                	ld	s3,40(sp)
    800017e4:	7a02                	ld	s4,32(sp)
    800017e6:	6ae2                	ld	s5,24(sp)
    800017e8:	6b42                	ld	s6,16(sp)
    800017ea:	6ba2                	ld	s7,8(sp)
    800017ec:	6161                	addi	sp,sp,80
    800017ee:	8082                	ret
    srcva = va0 + PGSIZE;
    800017f0:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017f4:	c8a9                	beqz	s1,80001846 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017f6:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017fa:	85ca                	mv	a1,s2
    800017fc:	8552                	mv	a0,s4
    800017fe:	00000097          	auipc	ra,0x0
    80001802:	880080e7          	jalr	-1920(ra) # 8000107e <walkaddr>
    if(pa0 == 0)
    80001806:	c131                	beqz	a0,8000184a <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001808:	417906b3          	sub	a3,s2,s7
    8000180c:	96ce                	add	a3,a3,s3
    8000180e:	00d4f363          	bgeu	s1,a3,80001814 <copyinstr+0x6c>
    80001812:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001814:	955e                	add	a0,a0,s7
    80001816:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000181a:	daf9                	beqz	a3,800017f0 <copyinstr+0x48>
    8000181c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000181e:	41650633          	sub	a2,a0,s6
    80001822:	fff48593          	addi	a1,s1,-1
    80001826:	95da                	add	a1,a1,s6
    while(n > 0){
    80001828:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    8000182a:	00f60733          	add	a4,a2,a5
    8000182e:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd290>
    80001832:	df51                	beqz	a4,800017ce <copyinstr+0x26>
        *dst = *p;
    80001834:	00e78023          	sb	a4,0(a5)
      --max;
    80001838:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000183c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000183e:	fed796e3          	bne	a5,a3,8000182a <copyinstr+0x82>
      dst++;
    80001842:	8b3e                	mv	s6,a5
    80001844:	b775                	j	800017f0 <copyinstr+0x48>
    80001846:	4781                	li	a5,0
    80001848:	b771                	j	800017d4 <copyinstr+0x2c>
      return -1;
    8000184a:	557d                	li	a0,-1
    8000184c:	b779                	j	800017da <copyinstr+0x32>
  int got_null = 0;
    8000184e:	4781                	li	a5,0
  if(got_null){
    80001850:	37fd                	addiw	a5,a5,-1
    80001852:	0007851b          	sext.w	a0,a5
}
    80001856:	8082                	ret

0000000080001858 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001858:	7139                	addi	sp,sp,-64
    8000185a:	fc06                	sd	ra,56(sp)
    8000185c:	f822                	sd	s0,48(sp)
    8000185e:	f426                	sd	s1,40(sp)
    80001860:	f04a                	sd	s2,32(sp)
    80001862:	ec4e                	sd	s3,24(sp)
    80001864:	e852                	sd	s4,16(sp)
    80001866:	e456                	sd	s5,8(sp)
    80001868:	e05a                	sd	s6,0(sp)
    8000186a:	0080                	addi	s0,sp,64
    8000186c:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	0000f497          	auipc	s1,0xf
    80001872:	72248493          	addi	s1,s1,1826 # 80010f90 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001876:	8b26                	mv	s6,s1
    80001878:	00006a97          	auipc	s5,0x6
    8000187c:	788a8a93          	addi	s5,s5,1928 # 80008000 <etext>
    80001880:	04000937          	lui	s2,0x4000
    80001884:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001886:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001888:	00015a17          	auipc	s4,0x15
    8000188c:	108a0a13          	addi	s4,s4,264 # 80016990 <tickslock>
    char *pa = kalloc();
    80001890:	fffff097          	auipc	ra,0xfffff
    80001894:	256080e7          	jalr	598(ra) # 80000ae6 <kalloc>
    80001898:	862a                	mv	a2,a0
    if(pa == 0)
    8000189a:	c131                	beqz	a0,800018de <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000189c:	416485b3          	sub	a1,s1,s6
    800018a0:	858d                	srai	a1,a1,0x3
    800018a2:	000ab783          	ld	a5,0(s5)
    800018a6:	02f585b3          	mul	a1,a1,a5
    800018aa:	2585                	addiw	a1,a1,1
    800018ac:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018b0:	4719                	li	a4,6
    800018b2:	6685                	lui	a3,0x1
    800018b4:	40b905b3          	sub	a1,s2,a1
    800018b8:	854e                	mv	a0,s3
    800018ba:	00000097          	auipc	ra,0x0
    800018be:	8a6080e7          	jalr	-1882(ra) # 80001160 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c2:	16848493          	addi	s1,s1,360
    800018c6:	fd4495e3          	bne	s1,s4,80001890 <proc_mapstacks+0x38>
  }
}
    800018ca:	70e2                	ld	ra,56(sp)
    800018cc:	7442                	ld	s0,48(sp)
    800018ce:	74a2                	ld	s1,40(sp)
    800018d0:	7902                	ld	s2,32(sp)
    800018d2:	69e2                	ld	s3,24(sp)
    800018d4:	6a42                	ld	s4,16(sp)
    800018d6:	6aa2                	ld	s5,8(sp)
    800018d8:	6b02                	ld	s6,0(sp)
    800018da:	6121                	addi	sp,sp,64
    800018dc:	8082                	ret
      panic("kalloc");
    800018de:	00007517          	auipc	a0,0x7
    800018e2:	90a50513          	addi	a0,a0,-1782 # 800081e8 <digits+0x1a8>
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	c5a080e7          	jalr	-934(ra) # 80000540 <panic>

00000000800018ee <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018ee:	7139                	addi	sp,sp,-64
    800018f0:	fc06                	sd	ra,56(sp)
    800018f2:	f822                	sd	s0,48(sp)
    800018f4:	f426                	sd	s1,40(sp)
    800018f6:	f04a                	sd	s2,32(sp)
    800018f8:	ec4e                	sd	s3,24(sp)
    800018fa:	e852                	sd	s4,16(sp)
    800018fc:	e456                	sd	s5,8(sp)
    800018fe:	e05a                	sd	s6,0(sp)
    80001900:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001902:	00007597          	auipc	a1,0x7
    80001906:	8ee58593          	addi	a1,a1,-1810 # 800081f0 <digits+0x1b0>
    8000190a:	0000f517          	auipc	a0,0xf
    8000190e:	25650513          	addi	a0,a0,598 # 80010b60 <pid_lock>
    80001912:	fffff097          	auipc	ra,0xfffff
    80001916:	234080e7          	jalr	564(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000191a:	00007597          	auipc	a1,0x7
    8000191e:	8de58593          	addi	a1,a1,-1826 # 800081f8 <digits+0x1b8>
    80001922:	0000f517          	auipc	a0,0xf
    80001926:	25650513          	addi	a0,a0,598 # 80010b78 <wait_lock>
    8000192a:	fffff097          	auipc	ra,0xfffff
    8000192e:	21c080e7          	jalr	540(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	0000f497          	auipc	s1,0xf
    80001936:	65e48493          	addi	s1,s1,1630 # 80010f90 <proc>
      initlock(&p->lock, "proc");
    8000193a:	00007b17          	auipc	s6,0x7
    8000193e:	8ceb0b13          	addi	s6,s6,-1842 # 80008208 <digits+0x1c8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001942:	8aa6                	mv	s5,s1
    80001944:	00006a17          	auipc	s4,0x6
    80001948:	6bca0a13          	addi	s4,s4,1724 # 80008000 <etext>
    8000194c:	04000937          	lui	s2,0x4000
    80001950:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001952:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001954:	00015997          	auipc	s3,0x15
    80001958:	03c98993          	addi	s3,s3,60 # 80016990 <tickslock>
      initlock(&p->lock, "proc");
    8000195c:	85da                	mv	a1,s6
    8000195e:	8526                	mv	a0,s1
    80001960:	fffff097          	auipc	ra,0xfffff
    80001964:	1e6080e7          	jalr	486(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001968:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000196c:	415487b3          	sub	a5,s1,s5
    80001970:	878d                	srai	a5,a5,0x3
    80001972:	000a3703          	ld	a4,0(s4)
    80001976:	02e787b3          	mul	a5,a5,a4
    8000197a:	2785                	addiw	a5,a5,1
    8000197c:	00d7979b          	slliw	a5,a5,0xd
    80001980:	40f907b3          	sub	a5,s2,a5
    80001984:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001986:	16848493          	addi	s1,s1,360
    8000198a:	fd3499e3          	bne	s1,s3,8000195c <procinit+0x6e>
  }
}
    8000198e:	70e2                	ld	ra,56(sp)
    80001990:	7442                	ld	s0,48(sp)
    80001992:	74a2                	ld	s1,40(sp)
    80001994:	7902                	ld	s2,32(sp)
    80001996:	69e2                	ld	s3,24(sp)
    80001998:	6a42                	ld	s4,16(sp)
    8000199a:	6aa2                	ld	s5,8(sp)
    8000199c:	6b02                	ld	s6,0(sp)
    8000199e:	6121                	addi	sp,sp,64
    800019a0:	8082                	ret

00000000800019a2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019a2:	1141                	addi	sp,sp,-16
    800019a4:	e422                	sd	s0,8(sp)
    800019a6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019aa:	2501                	sext.w	a0,a0
    800019ac:	6422                	ld	s0,8(sp)
    800019ae:	0141                	addi	sp,sp,16
    800019b0:	8082                	ret

00000000800019b2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019b2:	1141                	addi	sp,sp,-16
    800019b4:	e422                	sd	s0,8(sp)
    800019b6:	0800                	addi	s0,sp,16
    800019b8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019ba:	2781                	sext.w	a5,a5
    800019bc:	079e                	slli	a5,a5,0x7
  return c;
}
    800019be:	0000f517          	auipc	a0,0xf
    800019c2:	1d250513          	addi	a0,a0,466 # 80010b90 <cpus>
    800019c6:	953e                	add	a0,a0,a5
    800019c8:	6422                	ld	s0,8(sp)
    800019ca:	0141                	addi	sp,sp,16
    800019cc:	8082                	ret

00000000800019ce <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ce:	1101                	addi	sp,sp,-32
    800019d0:	ec06                	sd	ra,24(sp)
    800019d2:	e822                	sd	s0,16(sp)
    800019d4:	e426                	sd	s1,8(sp)
    800019d6:	1000                	addi	s0,sp,32
  push_off();
    800019d8:	fffff097          	auipc	ra,0xfffff
    800019dc:	1b2080e7          	jalr	434(ra) # 80000b8a <push_off>
    800019e0:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019e2:	2781                	sext.w	a5,a5
    800019e4:	079e                	slli	a5,a5,0x7
    800019e6:	0000f717          	auipc	a4,0xf
    800019ea:	17a70713          	addi	a4,a4,378 # 80010b60 <pid_lock>
    800019ee:	97ba                	add	a5,a5,a4
    800019f0:	7b84                	ld	s1,48(a5)
  pop_off();
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	238080e7          	jalr	568(ra) # 80000c2a <pop_off>
  return p;
}
    800019fa:	8526                	mv	a0,s1
    800019fc:	60e2                	ld	ra,24(sp)
    800019fe:	6442                	ld	s0,16(sp)
    80001a00:	64a2                	ld	s1,8(sp)
    80001a02:	6105                	addi	sp,sp,32
    80001a04:	8082                	ret

0000000080001a06 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a06:	1141                	addi	sp,sp,-16
    80001a08:	e406                	sd	ra,8(sp)
    80001a0a:	e022                	sd	s0,0(sp)
    80001a0c:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a0e:	00000097          	auipc	ra,0x0
    80001a12:	fc0080e7          	jalr	-64(ra) # 800019ce <myproc>
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	274080e7          	jalr	628(ra) # 80000c8a <release>

  if (first) {
    80001a1e:	00007797          	auipc	a5,0x7
    80001a22:	e327a783          	lw	a5,-462(a5) # 80008850 <first.1>
    80001a26:	eb89                	bnez	a5,80001a38 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a28:	00001097          	auipc	ra,0x1
    80001a2c:	c5c080e7          	jalr	-932(ra) # 80002684 <usertrapret>
}
    80001a30:	60a2                	ld	ra,8(sp)
    80001a32:	6402                	ld	s0,0(sp)
    80001a34:	0141                	addi	sp,sp,16
    80001a36:	8082                	ret
    first = 0;
    80001a38:	00007797          	auipc	a5,0x7
    80001a3c:	e007ac23          	sw	zero,-488(a5) # 80008850 <first.1>
    fsinit(ROOTDEV);
    80001a40:	4505                	li	a0,1
    80001a42:	00002097          	auipc	ra,0x2
    80001a46:	98e080e7          	jalr	-1650(ra) # 800033d0 <fsinit>
    80001a4a:	bff9                	j	80001a28 <forkret+0x22>

0000000080001a4c <allocpid>:
{
    80001a4c:	1101                	addi	sp,sp,-32
    80001a4e:	ec06                	sd	ra,24(sp)
    80001a50:	e822                	sd	s0,16(sp)
    80001a52:	e426                	sd	s1,8(sp)
    80001a54:	e04a                	sd	s2,0(sp)
    80001a56:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a58:	0000f917          	auipc	s2,0xf
    80001a5c:	10890913          	addi	s2,s2,264 # 80010b60 <pid_lock>
    80001a60:	854a                	mv	a0,s2
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	174080e7          	jalr	372(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a6a:	00007797          	auipc	a5,0x7
    80001a6e:	dea78793          	addi	a5,a5,-534 # 80008854 <nextpid>
    80001a72:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a74:	0014871b          	addiw	a4,s1,1
    80001a78:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a7a:	854a                	mv	a0,s2
    80001a7c:	fffff097          	auipc	ra,0xfffff
    80001a80:	20e080e7          	jalr	526(ra) # 80000c8a <release>
}
    80001a84:	8526                	mv	a0,s1
    80001a86:	60e2                	ld	ra,24(sp)
    80001a88:	6442                	ld	s0,16(sp)
    80001a8a:	64a2                	ld	s1,8(sp)
    80001a8c:	6902                	ld	s2,0(sp)
    80001a8e:	6105                	addi	sp,sp,32
    80001a90:	8082                	ret

0000000080001a92 <proc_pagetable>:
{
    80001a92:	1101                	addi	sp,sp,-32
    80001a94:	ec06                	sd	ra,24(sp)
    80001a96:	e822                	sd	s0,16(sp)
    80001a98:	e426                	sd	s1,8(sp)
    80001a9a:	e04a                	sd	s2,0(sp)
    80001a9c:	1000                	addi	s0,sp,32
    80001a9e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aa0:	00000097          	auipc	ra,0x0
    80001aa4:	8aa080e7          	jalr	-1878(ra) # 8000134a <uvmcreate>
    80001aa8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aaa:	c121                	beqz	a0,80001aea <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aac:	4729                	li	a4,10
    80001aae:	00005697          	auipc	a3,0x5
    80001ab2:	55268693          	addi	a3,a3,1362 # 80007000 <_trampoline>
    80001ab6:	6605                	lui	a2,0x1
    80001ab8:	040005b7          	lui	a1,0x4000
    80001abc:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001abe:	05b2                	slli	a1,a1,0xc
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	600080e7          	jalr	1536(ra) # 800010c0 <mappages>
    80001ac8:	02054863          	bltz	a0,80001af8 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001acc:	4719                	li	a4,6
    80001ace:	05893683          	ld	a3,88(s2)
    80001ad2:	6605                	lui	a2,0x1
    80001ad4:	020005b7          	lui	a1,0x2000
    80001ad8:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ada:	05b6                	slli	a1,a1,0xd
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	5e2080e7          	jalr	1506(ra) # 800010c0 <mappages>
    80001ae6:	02054163          	bltz	a0,80001b08 <proc_pagetable+0x76>
}
    80001aea:	8526                	mv	a0,s1
    80001aec:	60e2                	ld	ra,24(sp)
    80001aee:	6442                	ld	s0,16(sp)
    80001af0:	64a2                	ld	s1,8(sp)
    80001af2:	6902                	ld	s2,0(sp)
    80001af4:	6105                	addi	sp,sp,32
    80001af6:	8082                	ret
    uvmfree(pagetable, 0);
    80001af8:	4581                	li	a1,0
    80001afa:	8526                	mv	a0,s1
    80001afc:	00000097          	auipc	ra,0x0
    80001b00:	a54080e7          	jalr	-1452(ra) # 80001550 <uvmfree>
    return 0;
    80001b04:	4481                	li	s1,0
    80001b06:	b7d5                	j	80001aea <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b08:	4681                	li	a3,0
    80001b0a:	4605                	li	a2,1
    80001b0c:	040005b7          	lui	a1,0x4000
    80001b10:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b12:	05b2                	slli	a1,a1,0xc
    80001b14:	8526                	mv	a0,s1
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	770080e7          	jalr	1904(ra) # 80001286 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b1e:	4581                	li	a1,0
    80001b20:	8526                	mv	a0,s1
    80001b22:	00000097          	auipc	ra,0x0
    80001b26:	a2e080e7          	jalr	-1490(ra) # 80001550 <uvmfree>
    return 0;
    80001b2a:	4481                	li	s1,0
    80001b2c:	bf7d                	j	80001aea <proc_pagetable+0x58>

0000000080001b2e <proc_freepagetable>:
{
    80001b2e:	1101                	addi	sp,sp,-32
    80001b30:	ec06                	sd	ra,24(sp)
    80001b32:	e822                	sd	s0,16(sp)
    80001b34:	e426                	sd	s1,8(sp)
    80001b36:	e04a                	sd	s2,0(sp)
    80001b38:	1000                	addi	s0,sp,32
    80001b3a:	84aa                	mv	s1,a0
    80001b3c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b3e:	4681                	li	a3,0
    80001b40:	4605                	li	a2,1
    80001b42:	040005b7          	lui	a1,0x4000
    80001b46:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b48:	05b2                	slli	a1,a1,0xc
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	73c080e7          	jalr	1852(ra) # 80001286 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b52:	4681                	li	a3,0
    80001b54:	4605                	li	a2,1
    80001b56:	020005b7          	lui	a1,0x2000
    80001b5a:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b5c:	05b6                	slli	a1,a1,0xd
    80001b5e:	8526                	mv	a0,s1
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	726080e7          	jalr	1830(ra) # 80001286 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b68:	85ca                	mv	a1,s2
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	00000097          	auipc	ra,0x0
    80001b70:	9e4080e7          	jalr	-1564(ra) # 80001550 <uvmfree>
}
    80001b74:	60e2                	ld	ra,24(sp)
    80001b76:	6442                	ld	s0,16(sp)
    80001b78:	64a2                	ld	s1,8(sp)
    80001b7a:	6902                	ld	s2,0(sp)
    80001b7c:	6105                	addi	sp,sp,32
    80001b7e:	8082                	ret

0000000080001b80 <freeproc>:
{
    80001b80:	1101                	addi	sp,sp,-32
    80001b82:	ec06                	sd	ra,24(sp)
    80001b84:	e822                	sd	s0,16(sp)
    80001b86:	e426                	sd	s1,8(sp)
    80001b88:	1000                	addi	s0,sp,32
    80001b8a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b8c:	6d28                	ld	a0,88(a0)
    80001b8e:	c509                	beqz	a0,80001b98 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	e58080e7          	jalr	-424(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b98:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b9c:	68a8                	ld	a0,80(s1)
    80001b9e:	c511                	beqz	a0,80001baa <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ba0:	64ac                	ld	a1,72(s1)
    80001ba2:	00000097          	auipc	ra,0x0
    80001ba6:	f8c080e7          	jalr	-116(ra) # 80001b2e <proc_freepagetable>
  p->pagetable = 0;
    80001baa:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bae:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bb2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bb6:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bba:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bbe:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bc2:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bc6:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bca:	0004ac23          	sw	zero,24(s1)
}
    80001bce:	60e2                	ld	ra,24(sp)
    80001bd0:	6442                	ld	s0,16(sp)
    80001bd2:	64a2                	ld	s1,8(sp)
    80001bd4:	6105                	addi	sp,sp,32
    80001bd6:	8082                	ret

0000000080001bd8 <allocproc>:
{
    80001bd8:	1101                	addi	sp,sp,-32
    80001bda:	ec06                	sd	ra,24(sp)
    80001bdc:	e822                	sd	s0,16(sp)
    80001bde:	e426                	sd	s1,8(sp)
    80001be0:	e04a                	sd	s2,0(sp)
    80001be2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be4:	0000f497          	auipc	s1,0xf
    80001be8:	3ac48493          	addi	s1,s1,940 # 80010f90 <proc>
    80001bec:	00015917          	auipc	s2,0x15
    80001bf0:	da490913          	addi	s2,s2,-604 # 80016990 <tickslock>
    acquire(&p->lock);
    80001bf4:	8526                	mv	a0,s1
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	fe0080e7          	jalr	-32(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bfe:	4c9c                	lw	a5,24(s1)
    80001c00:	cf81                	beqz	a5,80001c18 <allocproc+0x40>
      release(&p->lock);
    80001c02:	8526                	mv	a0,s1
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	086080e7          	jalr	134(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0c:	16848493          	addi	s1,s1,360
    80001c10:	ff2492e3          	bne	s1,s2,80001bf4 <allocproc+0x1c>
  return 0;
    80001c14:	4481                	li	s1,0
    80001c16:	a889                	j	80001c68 <allocproc+0x90>
  p->pid = allocpid();
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e34080e7          	jalr	-460(ra) # 80001a4c <allocpid>
    80001c20:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c22:	4785                	li	a5,1
    80001c24:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	ec0080e7          	jalr	-320(ra) # 80000ae6 <kalloc>
    80001c2e:	892a                	mv	s2,a0
    80001c30:	eca8                	sd	a0,88(s1)
    80001c32:	c131                	beqz	a0,80001c76 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c34:	8526                	mv	a0,s1
    80001c36:	00000097          	auipc	ra,0x0
    80001c3a:	e5c080e7          	jalr	-420(ra) # 80001a92 <proc_pagetable>
    80001c3e:	892a                	mv	s2,a0
    80001c40:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c42:	c531                	beqz	a0,80001c8e <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c44:	07000613          	li	a2,112
    80001c48:	4581                	li	a1,0
    80001c4a:	06048513          	addi	a0,s1,96
    80001c4e:	fffff097          	auipc	ra,0xfffff
    80001c52:	084080e7          	jalr	132(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c56:	00000797          	auipc	a5,0x0
    80001c5a:	db078793          	addi	a5,a5,-592 # 80001a06 <forkret>
    80001c5e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c60:	60bc                	ld	a5,64(s1)
    80001c62:	6705                	lui	a4,0x1
    80001c64:	97ba                	add	a5,a5,a4
    80001c66:	f4bc                	sd	a5,104(s1)
}
    80001c68:	8526                	mv	a0,s1
    80001c6a:	60e2                	ld	ra,24(sp)
    80001c6c:	6442                	ld	s0,16(sp)
    80001c6e:	64a2                	ld	s1,8(sp)
    80001c70:	6902                	ld	s2,0(sp)
    80001c72:	6105                	addi	sp,sp,32
    80001c74:	8082                	ret
    freeproc(p);
    80001c76:	8526                	mv	a0,s1
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	f08080e7          	jalr	-248(ra) # 80001b80 <freeproc>
    release(&p->lock);
    80001c80:	8526                	mv	a0,s1
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	008080e7          	jalr	8(ra) # 80000c8a <release>
    return 0;
    80001c8a:	84ca                	mv	s1,s2
    80001c8c:	bff1                	j	80001c68 <allocproc+0x90>
    freeproc(p);
    80001c8e:	8526                	mv	a0,s1
    80001c90:	00000097          	auipc	ra,0x0
    80001c94:	ef0080e7          	jalr	-272(ra) # 80001b80 <freeproc>
    release(&p->lock);
    80001c98:	8526                	mv	a0,s1
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	ff0080e7          	jalr	-16(ra) # 80000c8a <release>
    return 0;
    80001ca2:	84ca                	mv	s1,s2
    80001ca4:	b7d1                	j	80001c68 <allocproc+0x90>

0000000080001ca6 <userinit>:
{
    80001ca6:	1101                	addi	sp,sp,-32
    80001ca8:	ec06                	sd	ra,24(sp)
    80001caa:	e822                	sd	s0,16(sp)
    80001cac:	e426                	sd	s1,8(sp)
    80001cae:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb0:	00000097          	auipc	ra,0x0
    80001cb4:	f28080e7          	jalr	-216(ra) # 80001bd8 <allocproc>
    80001cb8:	84aa                	mv	s1,a0
  initproc = p;
    80001cba:	00007797          	auipc	a5,0x7
    80001cbe:	c2a7b723          	sd	a0,-978(a5) # 800088e8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cc2:	03400613          	li	a2,52
    80001cc6:	00007597          	auipc	a1,0x7
    80001cca:	b9a58593          	addi	a1,a1,-1126 # 80008860 <initcode>
    80001cce:	6928                	ld	a0,80(a0)
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	6a8080e7          	jalr	1704(ra) # 80001378 <uvmfirst>
  p->sz = PGSIZE;
    80001cd8:	6785                	lui	a5,0x1
    80001cda:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cdc:	6cb8                	ld	a4,88(s1)
    80001cde:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ce2:	6cb8                	ld	a4,88(s1)
    80001ce4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ce6:	4641                	li	a2,16
    80001ce8:	00006597          	auipc	a1,0x6
    80001cec:	52858593          	addi	a1,a1,1320 # 80008210 <digits+0x1d0>
    80001cf0:	15848513          	addi	a0,s1,344
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	128080e7          	jalr	296(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cfc:	00006517          	auipc	a0,0x6
    80001d00:	52450513          	addi	a0,a0,1316 # 80008220 <digits+0x1e0>
    80001d04:	00002097          	auipc	ra,0x2
    80001d08:	0f6080e7          	jalr	246(ra) # 80003dfa <namei>
    80001d0c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d10:	478d                	li	a5,3
    80001d12:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d14:	8526                	mv	a0,s1
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	f74080e7          	jalr	-140(ra) # 80000c8a <release>
}
    80001d1e:	60e2                	ld	ra,24(sp)
    80001d20:	6442                	ld	s0,16(sp)
    80001d22:	64a2                	ld	s1,8(sp)
    80001d24:	6105                	addi	sp,sp,32
    80001d26:	8082                	ret

0000000080001d28 <growproc>:
{
    80001d28:	1101                	addi	sp,sp,-32
    80001d2a:	ec06                	sd	ra,24(sp)
    80001d2c:	e822                	sd	s0,16(sp)
    80001d2e:	e426                	sd	s1,8(sp)
    80001d30:	e04a                	sd	s2,0(sp)
    80001d32:	1000                	addi	s0,sp,32
    80001d34:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d36:	00000097          	auipc	ra,0x0
    80001d3a:	c98080e7          	jalr	-872(ra) # 800019ce <myproc>
    80001d3e:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d40:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d42:	01204c63          	bgtz	s2,80001d5a <growproc+0x32>
  } else if(n < 0){
    80001d46:	02094663          	bltz	s2,80001d72 <growproc+0x4a>
  p->sz = sz;
    80001d4a:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d4c:	4501                	li	a0,0
}
    80001d4e:	60e2                	ld	ra,24(sp)
    80001d50:	6442                	ld	s0,16(sp)
    80001d52:	64a2                	ld	s1,8(sp)
    80001d54:	6902                	ld	s2,0(sp)
    80001d56:	6105                	addi	sp,sp,32
    80001d58:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d5a:	4691                	li	a3,4
    80001d5c:	00b90633          	add	a2,s2,a1
    80001d60:	6928                	ld	a0,80(a0)
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	6d0080e7          	jalr	1744(ra) # 80001432 <uvmalloc>
    80001d6a:	85aa                	mv	a1,a0
    80001d6c:	fd79                	bnez	a0,80001d4a <growproc+0x22>
      return -1;
    80001d6e:	557d                	li	a0,-1
    80001d70:	bff9                	j	80001d4e <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d72:	00b90633          	add	a2,s2,a1
    80001d76:	6928                	ld	a0,80(a0)
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	672080e7          	jalr	1650(ra) # 800013ea <uvmdealloc>
    80001d80:	85aa                	mv	a1,a0
    80001d82:	b7e1                	j	80001d4a <growproc+0x22>

0000000080001d84 <fork>:
{
    80001d84:	7139                	addi	sp,sp,-64
    80001d86:	fc06                	sd	ra,56(sp)
    80001d88:	f822                	sd	s0,48(sp)
    80001d8a:	f426                	sd	s1,40(sp)
    80001d8c:	f04a                	sd	s2,32(sp)
    80001d8e:	ec4e                	sd	s3,24(sp)
    80001d90:	e852                	sd	s4,16(sp)
    80001d92:	e456                	sd	s5,8(sp)
    80001d94:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	c38080e7          	jalr	-968(ra) # 800019ce <myproc>
    80001d9e:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001da0:	00000097          	auipc	ra,0x0
    80001da4:	e38080e7          	jalr	-456(ra) # 80001bd8 <allocproc>
    80001da8:	10050c63          	beqz	a0,80001ec0 <fork+0x13c>
    80001dac:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dae:	048ab603          	ld	a2,72(s5)
    80001db2:	692c                	ld	a1,80(a0)
    80001db4:	050ab503          	ld	a0,80(s5)
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	7d2080e7          	jalr	2002(ra) # 8000158a <uvmcopy>
    80001dc0:	04054863          	bltz	a0,80001e10 <fork+0x8c>
  np->sz = p->sz;
    80001dc4:	048ab783          	ld	a5,72(s5)
    80001dc8:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dcc:	058ab683          	ld	a3,88(s5)
    80001dd0:	87b6                	mv	a5,a3
    80001dd2:	058a3703          	ld	a4,88(s4)
    80001dd6:	12068693          	addi	a3,a3,288
    80001dda:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dde:	6788                	ld	a0,8(a5)
    80001de0:	6b8c                	ld	a1,16(a5)
    80001de2:	6f90                	ld	a2,24(a5)
    80001de4:	01073023          	sd	a6,0(a4)
    80001de8:	e708                	sd	a0,8(a4)
    80001dea:	eb0c                	sd	a1,16(a4)
    80001dec:	ef10                	sd	a2,24(a4)
    80001dee:	02078793          	addi	a5,a5,32
    80001df2:	02070713          	addi	a4,a4,32
    80001df6:	fed792e3          	bne	a5,a3,80001dda <fork+0x56>
  np->trapframe->a0 = 0;
    80001dfa:	058a3783          	ld	a5,88(s4)
    80001dfe:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e02:	0d0a8493          	addi	s1,s5,208
    80001e06:	0d0a0913          	addi	s2,s4,208
    80001e0a:	150a8993          	addi	s3,s5,336
    80001e0e:	a00d                	j	80001e30 <fork+0xac>
    freeproc(np);
    80001e10:	8552                	mv	a0,s4
    80001e12:	00000097          	auipc	ra,0x0
    80001e16:	d6e080e7          	jalr	-658(ra) # 80001b80 <freeproc>
    release(&np->lock);
    80001e1a:	8552                	mv	a0,s4
    80001e1c:	fffff097          	auipc	ra,0xfffff
    80001e20:	e6e080e7          	jalr	-402(ra) # 80000c8a <release>
    return -1;
    80001e24:	597d                	li	s2,-1
    80001e26:	a059                	j	80001eac <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e28:	04a1                	addi	s1,s1,8
    80001e2a:	0921                	addi	s2,s2,8
    80001e2c:	01348b63          	beq	s1,s3,80001e42 <fork+0xbe>
    if(p->ofile[i])
    80001e30:	6088                	ld	a0,0(s1)
    80001e32:	d97d                	beqz	a0,80001e28 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e34:	00002097          	auipc	ra,0x2
    80001e38:	65c080e7          	jalr	1628(ra) # 80004490 <filedup>
    80001e3c:	00a93023          	sd	a0,0(s2)
    80001e40:	b7e5                	j	80001e28 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e42:	150ab503          	ld	a0,336(s5)
    80001e46:	00001097          	auipc	ra,0x1
    80001e4a:	7ca080e7          	jalr	1994(ra) # 80003610 <idup>
    80001e4e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e52:	4641                	li	a2,16
    80001e54:	158a8593          	addi	a1,s5,344
    80001e58:	158a0513          	addi	a0,s4,344
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	fc0080e7          	jalr	-64(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e64:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e68:	8552                	mv	a0,s4
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	e20080e7          	jalr	-480(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e72:	0000f497          	auipc	s1,0xf
    80001e76:	d0648493          	addi	s1,s1,-762 # 80010b78 <wait_lock>
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	d5a080e7          	jalr	-678(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e84:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e88:	8526                	mv	a0,s1
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	e00080e7          	jalr	-512(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e92:	8552                	mv	a0,s4
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	d42080e7          	jalr	-702(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e9c:	478d                	li	a5,3
    80001e9e:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ea2:	8552                	mv	a0,s4
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	de6080e7          	jalr	-538(ra) # 80000c8a <release>
}
    80001eac:	854a                	mv	a0,s2
    80001eae:	70e2                	ld	ra,56(sp)
    80001eb0:	7442                	ld	s0,48(sp)
    80001eb2:	74a2                	ld	s1,40(sp)
    80001eb4:	7902                	ld	s2,32(sp)
    80001eb6:	69e2                	ld	s3,24(sp)
    80001eb8:	6a42                	ld	s4,16(sp)
    80001eba:	6aa2                	ld	s5,8(sp)
    80001ebc:	6121                	addi	sp,sp,64
    80001ebe:	8082                	ret
    return -1;
    80001ec0:	597d                	li	s2,-1
    80001ec2:	b7ed                	j	80001eac <fork+0x128>

0000000080001ec4 <scheduler>:
{
    80001ec4:	7139                	addi	sp,sp,-64
    80001ec6:	fc06                	sd	ra,56(sp)
    80001ec8:	f822                	sd	s0,48(sp)
    80001eca:	f426                	sd	s1,40(sp)
    80001ecc:	f04a                	sd	s2,32(sp)
    80001ece:	ec4e                	sd	s3,24(sp)
    80001ed0:	e852                	sd	s4,16(sp)
    80001ed2:	e456                	sd	s5,8(sp)
    80001ed4:	e05a                	sd	s6,0(sp)
    80001ed6:	0080                	addi	s0,sp,64
    80001ed8:	8792                	mv	a5,tp
  int id = r_tp();
    80001eda:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001edc:	00779a93          	slli	s5,a5,0x7
    80001ee0:	0000f717          	auipc	a4,0xf
    80001ee4:	c8070713          	addi	a4,a4,-896 # 80010b60 <pid_lock>
    80001ee8:	9756                	add	a4,a4,s5
    80001eea:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001eee:	0000f717          	auipc	a4,0xf
    80001ef2:	caa70713          	addi	a4,a4,-854 # 80010b98 <cpus+0x8>
    80001ef6:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ef8:	498d                	li	s3,3
        p->state = RUNNING;
    80001efa:	4b11                	li	s6,4
        c->proc = p;
    80001efc:	079e                	slli	a5,a5,0x7
    80001efe:	0000fa17          	auipc	s4,0xf
    80001f02:	c62a0a13          	addi	s4,s4,-926 # 80010b60 <pid_lock>
    80001f06:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f08:	00015917          	auipc	s2,0x15
    80001f0c:	a8890913          	addi	s2,s2,-1400 # 80016990 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f10:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f14:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f18:	10079073          	csrw	sstatus,a5
    80001f1c:	0000f497          	auipc	s1,0xf
    80001f20:	07448493          	addi	s1,s1,116 # 80010f90 <proc>
    80001f24:	a811                	j	80001f38 <scheduler+0x74>
      release(&p->lock);
    80001f26:	8526                	mv	a0,s1
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	d62080e7          	jalr	-670(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f30:	16848493          	addi	s1,s1,360
    80001f34:	fd248ee3          	beq	s1,s2,80001f10 <scheduler+0x4c>
      acquire(&p->lock);
    80001f38:	8526                	mv	a0,s1
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	c9c080e7          	jalr	-868(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f42:	4c9c                	lw	a5,24(s1)
    80001f44:	ff3791e3          	bne	a5,s3,80001f26 <scheduler+0x62>
        p->state = RUNNING;
    80001f48:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f4c:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f50:	06048593          	addi	a1,s1,96
    80001f54:	8556                	mv	a0,s5
    80001f56:	00000097          	auipc	ra,0x0
    80001f5a:	684080e7          	jalr	1668(ra) # 800025da <swtch>
        c->proc = 0;
    80001f5e:	020a3823          	sd	zero,48(s4)
    80001f62:	b7d1                	j	80001f26 <scheduler+0x62>

0000000080001f64 <sched>:
{
    80001f64:	7179                	addi	sp,sp,-48
    80001f66:	f406                	sd	ra,40(sp)
    80001f68:	f022                	sd	s0,32(sp)
    80001f6a:	ec26                	sd	s1,24(sp)
    80001f6c:	e84a                	sd	s2,16(sp)
    80001f6e:	e44e                	sd	s3,8(sp)
    80001f70:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f72:	00000097          	auipc	ra,0x0
    80001f76:	a5c080e7          	jalr	-1444(ra) # 800019ce <myproc>
    80001f7a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	be0080e7          	jalr	-1056(ra) # 80000b5c <holding>
    80001f84:	c93d                	beqz	a0,80001ffa <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f86:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f88:	2781                	sext.w	a5,a5
    80001f8a:	079e                	slli	a5,a5,0x7
    80001f8c:	0000f717          	auipc	a4,0xf
    80001f90:	bd470713          	addi	a4,a4,-1068 # 80010b60 <pid_lock>
    80001f94:	97ba                	add	a5,a5,a4
    80001f96:	0a87a703          	lw	a4,168(a5)
    80001f9a:	4785                	li	a5,1
    80001f9c:	06f71763          	bne	a4,a5,8000200a <sched+0xa6>
  if(p->state == RUNNING)
    80001fa0:	4c98                	lw	a4,24(s1)
    80001fa2:	4791                	li	a5,4
    80001fa4:	06f70b63          	beq	a4,a5,8000201a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fa8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fac:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fae:	efb5                	bnez	a5,8000202a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fb0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fb2:	0000f917          	auipc	s2,0xf
    80001fb6:	bae90913          	addi	s2,s2,-1106 # 80010b60 <pid_lock>
    80001fba:	2781                	sext.w	a5,a5
    80001fbc:	079e                	slli	a5,a5,0x7
    80001fbe:	97ca                	add	a5,a5,s2
    80001fc0:	0ac7a983          	lw	s3,172(a5)
    80001fc4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fc6:	2781                	sext.w	a5,a5
    80001fc8:	079e                	slli	a5,a5,0x7
    80001fca:	0000f597          	auipc	a1,0xf
    80001fce:	bce58593          	addi	a1,a1,-1074 # 80010b98 <cpus+0x8>
    80001fd2:	95be                	add	a1,a1,a5
    80001fd4:	06048513          	addi	a0,s1,96
    80001fd8:	00000097          	auipc	ra,0x0
    80001fdc:	602080e7          	jalr	1538(ra) # 800025da <swtch>
    80001fe0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fe2:	2781                	sext.w	a5,a5
    80001fe4:	079e                	slli	a5,a5,0x7
    80001fe6:	993e                	add	s2,s2,a5
    80001fe8:	0b392623          	sw	s3,172(s2)
}
    80001fec:	70a2                	ld	ra,40(sp)
    80001fee:	7402                	ld	s0,32(sp)
    80001ff0:	64e2                	ld	s1,24(sp)
    80001ff2:	6942                	ld	s2,16(sp)
    80001ff4:	69a2                	ld	s3,8(sp)
    80001ff6:	6145                	addi	sp,sp,48
    80001ff8:	8082                	ret
    panic("sched p->lock");
    80001ffa:	00006517          	auipc	a0,0x6
    80001ffe:	22e50513          	addi	a0,a0,558 # 80008228 <digits+0x1e8>
    80002002:	ffffe097          	auipc	ra,0xffffe
    80002006:	53e080e7          	jalr	1342(ra) # 80000540 <panic>
    panic("sched locks");
    8000200a:	00006517          	auipc	a0,0x6
    8000200e:	22e50513          	addi	a0,a0,558 # 80008238 <digits+0x1f8>
    80002012:	ffffe097          	auipc	ra,0xffffe
    80002016:	52e080e7          	jalr	1326(ra) # 80000540 <panic>
    panic("sched running");
    8000201a:	00006517          	auipc	a0,0x6
    8000201e:	22e50513          	addi	a0,a0,558 # 80008248 <digits+0x208>
    80002022:	ffffe097          	auipc	ra,0xffffe
    80002026:	51e080e7          	jalr	1310(ra) # 80000540 <panic>
    panic("sched interruptible");
    8000202a:	00006517          	auipc	a0,0x6
    8000202e:	22e50513          	addi	a0,a0,558 # 80008258 <digits+0x218>
    80002032:	ffffe097          	auipc	ra,0xffffe
    80002036:	50e080e7          	jalr	1294(ra) # 80000540 <panic>

000000008000203a <yield>:
{
    8000203a:	1101                	addi	sp,sp,-32
    8000203c:	ec06                	sd	ra,24(sp)
    8000203e:	e822                	sd	s0,16(sp)
    80002040:	e426                	sd	s1,8(sp)
    80002042:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002044:	00000097          	auipc	ra,0x0
    80002048:	98a080e7          	jalr	-1654(ra) # 800019ce <myproc>
    8000204c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	b88080e7          	jalr	-1144(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002056:	478d                	li	a5,3
    80002058:	cc9c                	sw	a5,24(s1)
  sched();
    8000205a:	00000097          	auipc	ra,0x0
    8000205e:	f0a080e7          	jalr	-246(ra) # 80001f64 <sched>
  release(&p->lock);
    80002062:	8526                	mv	a0,s1
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	c26080e7          	jalr	-986(ra) # 80000c8a <release>
}
    8000206c:	60e2                	ld	ra,24(sp)
    8000206e:	6442                	ld	s0,16(sp)
    80002070:	64a2                	ld	s1,8(sp)
    80002072:	6105                	addi	sp,sp,32
    80002074:	8082                	ret

0000000080002076 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002076:	7179                	addi	sp,sp,-48
    80002078:	f406                	sd	ra,40(sp)
    8000207a:	f022                	sd	s0,32(sp)
    8000207c:	ec26                	sd	s1,24(sp)
    8000207e:	e84a                	sd	s2,16(sp)
    80002080:	e44e                	sd	s3,8(sp)
    80002082:	1800                	addi	s0,sp,48
    80002084:	89aa                	mv	s3,a0
    80002086:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002088:	00000097          	auipc	ra,0x0
    8000208c:	946080e7          	jalr	-1722(ra) # 800019ce <myproc>
    80002090:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	b44080e7          	jalr	-1212(ra) # 80000bd6 <acquire>
  release(lk);
    8000209a:	854a                	mv	a0,s2
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	bee080e7          	jalr	-1042(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800020a4:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020a8:	4789                	li	a5,2
    800020aa:	cc9c                	sw	a5,24(s1)

  sched();
    800020ac:	00000097          	auipc	ra,0x0
    800020b0:	eb8080e7          	jalr	-328(ra) # 80001f64 <sched>

  // Tidy up.
  p->chan = 0;
    800020b4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020b8:	8526                	mv	a0,s1
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	bd0080e7          	jalr	-1072(ra) # 80000c8a <release>
  acquire(lk);
    800020c2:	854a                	mv	a0,s2
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	b12080e7          	jalr	-1262(ra) # 80000bd6 <acquire>
}
    800020cc:	70a2                	ld	ra,40(sp)
    800020ce:	7402                	ld	s0,32(sp)
    800020d0:	64e2                	ld	s1,24(sp)
    800020d2:	6942                	ld	s2,16(sp)
    800020d4:	69a2                	ld	s3,8(sp)
    800020d6:	6145                	addi	sp,sp,48
    800020d8:	8082                	ret

00000000800020da <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020da:	7139                	addi	sp,sp,-64
    800020dc:	fc06                	sd	ra,56(sp)
    800020de:	f822                	sd	s0,48(sp)
    800020e0:	f426                	sd	s1,40(sp)
    800020e2:	f04a                	sd	s2,32(sp)
    800020e4:	ec4e                	sd	s3,24(sp)
    800020e6:	e852                	sd	s4,16(sp)
    800020e8:	e456                	sd	s5,8(sp)
    800020ea:	0080                	addi	s0,sp,64
    800020ec:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020ee:	0000f497          	auipc	s1,0xf
    800020f2:	ea248493          	addi	s1,s1,-350 # 80010f90 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020f6:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020f8:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020fa:	00015917          	auipc	s2,0x15
    800020fe:	89690913          	addi	s2,s2,-1898 # 80016990 <tickslock>
    80002102:	a811                	j	80002116 <wakeup+0x3c>
      }
      release(&p->lock);
    80002104:	8526                	mv	a0,s1
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	b84080e7          	jalr	-1148(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000210e:	16848493          	addi	s1,s1,360
    80002112:	03248663          	beq	s1,s2,8000213e <wakeup+0x64>
    if(p != myproc()){
    80002116:	00000097          	auipc	ra,0x0
    8000211a:	8b8080e7          	jalr	-1864(ra) # 800019ce <myproc>
    8000211e:	fea488e3          	beq	s1,a0,8000210e <wakeup+0x34>
      acquire(&p->lock);
    80002122:	8526                	mv	a0,s1
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	ab2080e7          	jalr	-1358(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000212c:	4c9c                	lw	a5,24(s1)
    8000212e:	fd379be3          	bne	a5,s3,80002104 <wakeup+0x2a>
    80002132:	709c                	ld	a5,32(s1)
    80002134:	fd4798e3          	bne	a5,s4,80002104 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002138:	0154ac23          	sw	s5,24(s1)
    8000213c:	b7e1                	j	80002104 <wakeup+0x2a>
    }
  }
}
    8000213e:	70e2                	ld	ra,56(sp)
    80002140:	7442                	ld	s0,48(sp)
    80002142:	74a2                	ld	s1,40(sp)
    80002144:	7902                	ld	s2,32(sp)
    80002146:	69e2                	ld	s3,24(sp)
    80002148:	6a42                	ld	s4,16(sp)
    8000214a:	6aa2                	ld	s5,8(sp)
    8000214c:	6121                	addi	sp,sp,64
    8000214e:	8082                	ret

0000000080002150 <reparent>:
{
    80002150:	7179                	addi	sp,sp,-48
    80002152:	f406                	sd	ra,40(sp)
    80002154:	f022                	sd	s0,32(sp)
    80002156:	ec26                	sd	s1,24(sp)
    80002158:	e84a                	sd	s2,16(sp)
    8000215a:	e44e                	sd	s3,8(sp)
    8000215c:	e052                	sd	s4,0(sp)
    8000215e:	1800                	addi	s0,sp,48
    80002160:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002162:	0000f497          	auipc	s1,0xf
    80002166:	e2e48493          	addi	s1,s1,-466 # 80010f90 <proc>
      pp->parent = initproc;
    8000216a:	00006a17          	auipc	s4,0x6
    8000216e:	77ea0a13          	addi	s4,s4,1918 # 800088e8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002172:	00015997          	auipc	s3,0x15
    80002176:	81e98993          	addi	s3,s3,-2018 # 80016990 <tickslock>
    8000217a:	a029                	j	80002184 <reparent+0x34>
    8000217c:	16848493          	addi	s1,s1,360
    80002180:	01348d63          	beq	s1,s3,8000219a <reparent+0x4a>
    if(pp->parent == p){
    80002184:	7c9c                	ld	a5,56(s1)
    80002186:	ff279be3          	bne	a5,s2,8000217c <reparent+0x2c>
      pp->parent = initproc;
    8000218a:	000a3503          	ld	a0,0(s4)
    8000218e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002190:	00000097          	auipc	ra,0x0
    80002194:	f4a080e7          	jalr	-182(ra) # 800020da <wakeup>
    80002198:	b7d5                	j	8000217c <reparent+0x2c>
}
    8000219a:	70a2                	ld	ra,40(sp)
    8000219c:	7402                	ld	s0,32(sp)
    8000219e:	64e2                	ld	s1,24(sp)
    800021a0:	6942                	ld	s2,16(sp)
    800021a2:	69a2                	ld	s3,8(sp)
    800021a4:	6a02                	ld	s4,0(sp)
    800021a6:	6145                	addi	sp,sp,48
    800021a8:	8082                	ret

00000000800021aa <exit>:
{
    800021aa:	7179                	addi	sp,sp,-48
    800021ac:	f406                	sd	ra,40(sp)
    800021ae:	f022                	sd	s0,32(sp)
    800021b0:	ec26                	sd	s1,24(sp)
    800021b2:	e84a                	sd	s2,16(sp)
    800021b4:	e44e                	sd	s3,8(sp)
    800021b6:	e052                	sd	s4,0(sp)
    800021b8:	1800                	addi	s0,sp,48
    800021ba:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021bc:	00000097          	auipc	ra,0x0
    800021c0:	812080e7          	jalr	-2030(ra) # 800019ce <myproc>
    800021c4:	89aa                	mv	s3,a0
  if(p == initproc)
    800021c6:	00006797          	auipc	a5,0x6
    800021ca:	7227b783          	ld	a5,1826(a5) # 800088e8 <initproc>
    800021ce:	0d050493          	addi	s1,a0,208
    800021d2:	15050913          	addi	s2,a0,336
    800021d6:	02a79363          	bne	a5,a0,800021fc <exit+0x52>
    panic("init exiting");
    800021da:	00006517          	auipc	a0,0x6
    800021de:	09650513          	addi	a0,a0,150 # 80008270 <digits+0x230>
    800021e2:	ffffe097          	auipc	ra,0xffffe
    800021e6:	35e080e7          	jalr	862(ra) # 80000540 <panic>
      fileclose(f);
    800021ea:	00002097          	auipc	ra,0x2
    800021ee:	2f8080e7          	jalr	760(ra) # 800044e2 <fileclose>
      p->ofile[fd] = 0;
    800021f2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021f6:	04a1                	addi	s1,s1,8
    800021f8:	01248563          	beq	s1,s2,80002202 <exit+0x58>
    if(p->ofile[fd]){
    800021fc:	6088                	ld	a0,0(s1)
    800021fe:	f575                	bnez	a0,800021ea <exit+0x40>
    80002200:	bfdd                	j	800021f6 <exit+0x4c>
  begin_op();
    80002202:	00002097          	auipc	ra,0x2
    80002206:	e18080e7          	jalr	-488(ra) # 8000401a <begin_op>
  iput(p->cwd);
    8000220a:	1509b503          	ld	a0,336(s3)
    8000220e:	00001097          	auipc	ra,0x1
    80002212:	5fa080e7          	jalr	1530(ra) # 80003808 <iput>
  end_op();
    80002216:	00002097          	auipc	ra,0x2
    8000221a:	e82080e7          	jalr	-382(ra) # 80004098 <end_op>
  p->cwd = 0;
    8000221e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002222:	0000f497          	auipc	s1,0xf
    80002226:	95648493          	addi	s1,s1,-1706 # 80010b78 <wait_lock>
    8000222a:	8526                	mv	a0,s1
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	9aa080e7          	jalr	-1622(ra) # 80000bd6 <acquire>
  reparent(p);
    80002234:	854e                	mv	a0,s3
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	f1a080e7          	jalr	-230(ra) # 80002150 <reparent>
  wakeup(p->parent);
    8000223e:	0389b503          	ld	a0,56(s3)
    80002242:	00000097          	auipc	ra,0x0
    80002246:	e98080e7          	jalr	-360(ra) # 800020da <wakeup>
  acquire(&p->lock);
    8000224a:	854e                	mv	a0,s3
    8000224c:	fffff097          	auipc	ra,0xfffff
    80002250:	98a080e7          	jalr	-1654(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002254:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002258:	4795                	li	a5,5
    8000225a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000225e:	8526                	mv	a0,s1
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	a2a080e7          	jalr	-1494(ra) # 80000c8a <release>
  sched();
    80002268:	00000097          	auipc	ra,0x0
    8000226c:	cfc080e7          	jalr	-772(ra) # 80001f64 <sched>
  panic("zombie exit");
    80002270:	00006517          	auipc	a0,0x6
    80002274:	01050513          	addi	a0,a0,16 # 80008280 <digits+0x240>
    80002278:	ffffe097          	auipc	ra,0xffffe
    8000227c:	2c8080e7          	jalr	712(ra) # 80000540 <panic>

0000000080002280 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002280:	7179                	addi	sp,sp,-48
    80002282:	f406                	sd	ra,40(sp)
    80002284:	f022                	sd	s0,32(sp)
    80002286:	ec26                	sd	s1,24(sp)
    80002288:	e84a                	sd	s2,16(sp)
    8000228a:	e44e                	sd	s3,8(sp)
    8000228c:	1800                	addi	s0,sp,48
    8000228e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002290:	0000f497          	auipc	s1,0xf
    80002294:	d0048493          	addi	s1,s1,-768 # 80010f90 <proc>
    80002298:	00014997          	auipc	s3,0x14
    8000229c:	6f898993          	addi	s3,s3,1784 # 80016990 <tickslock>
    acquire(&p->lock);
    800022a0:	8526                	mv	a0,s1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	934080e7          	jalr	-1740(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    800022aa:	589c                	lw	a5,48(s1)
    800022ac:	01278d63          	beq	a5,s2,800022c6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9d8080e7          	jalr	-1576(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022ba:	16848493          	addi	s1,s1,360
    800022be:	ff3491e3          	bne	s1,s3,800022a0 <kill+0x20>
  }
  return -1;
    800022c2:	557d                	li	a0,-1
    800022c4:	a829                	j	800022de <kill+0x5e>
      p->killed = 1;
    800022c6:	4785                	li	a5,1
    800022c8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022ca:	4c98                	lw	a4,24(s1)
    800022cc:	4789                	li	a5,2
    800022ce:	00f70f63          	beq	a4,a5,800022ec <kill+0x6c>
      release(&p->lock);
    800022d2:	8526                	mv	a0,s1
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	9b6080e7          	jalr	-1610(ra) # 80000c8a <release>
      return 0;
    800022dc:	4501                	li	a0,0
}
    800022de:	70a2                	ld	ra,40(sp)
    800022e0:	7402                	ld	s0,32(sp)
    800022e2:	64e2                	ld	s1,24(sp)
    800022e4:	6942                	ld	s2,16(sp)
    800022e6:	69a2                	ld	s3,8(sp)
    800022e8:	6145                	addi	sp,sp,48
    800022ea:	8082                	ret
        p->state = RUNNABLE;
    800022ec:	478d                	li	a5,3
    800022ee:	cc9c                	sw	a5,24(s1)
    800022f0:	b7cd                	j	800022d2 <kill+0x52>

00000000800022f2 <setkilled>:

void
setkilled(struct proc *p)
{
    800022f2:	1101                	addi	sp,sp,-32
    800022f4:	ec06                	sd	ra,24(sp)
    800022f6:	e822                	sd	s0,16(sp)
    800022f8:	e426                	sd	s1,8(sp)
    800022fa:	1000                	addi	s0,sp,32
    800022fc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	8d8080e7          	jalr	-1832(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002306:	4785                	li	a5,1
    80002308:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000230a:	8526                	mv	a0,s1
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	97e080e7          	jalr	-1666(ra) # 80000c8a <release>
}
    80002314:	60e2                	ld	ra,24(sp)
    80002316:	6442                	ld	s0,16(sp)
    80002318:	64a2                	ld	s1,8(sp)
    8000231a:	6105                	addi	sp,sp,32
    8000231c:	8082                	ret

000000008000231e <killed>:

int
killed(struct proc *p)
{
    8000231e:	1101                	addi	sp,sp,-32
    80002320:	ec06                	sd	ra,24(sp)
    80002322:	e822                	sd	s0,16(sp)
    80002324:	e426                	sd	s1,8(sp)
    80002326:	e04a                	sd	s2,0(sp)
    80002328:	1000                	addi	s0,sp,32
    8000232a:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	8aa080e7          	jalr	-1878(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002334:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002338:	8526                	mv	a0,s1
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	950080e7          	jalr	-1712(ra) # 80000c8a <release>
  return k;
}
    80002342:	854a                	mv	a0,s2
    80002344:	60e2                	ld	ra,24(sp)
    80002346:	6442                	ld	s0,16(sp)
    80002348:	64a2                	ld	s1,8(sp)
    8000234a:	6902                	ld	s2,0(sp)
    8000234c:	6105                	addi	sp,sp,32
    8000234e:	8082                	ret

0000000080002350 <wait>:
{
    80002350:	715d                	addi	sp,sp,-80
    80002352:	e486                	sd	ra,72(sp)
    80002354:	e0a2                	sd	s0,64(sp)
    80002356:	fc26                	sd	s1,56(sp)
    80002358:	f84a                	sd	s2,48(sp)
    8000235a:	f44e                	sd	s3,40(sp)
    8000235c:	f052                	sd	s4,32(sp)
    8000235e:	ec56                	sd	s5,24(sp)
    80002360:	e85a                	sd	s6,16(sp)
    80002362:	e45e                	sd	s7,8(sp)
    80002364:	e062                	sd	s8,0(sp)
    80002366:	0880                	addi	s0,sp,80
    80002368:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	664080e7          	jalr	1636(ra) # 800019ce <myproc>
    80002372:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002374:	0000f517          	auipc	a0,0xf
    80002378:	80450513          	addi	a0,a0,-2044 # 80010b78 <wait_lock>
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	85a080e7          	jalr	-1958(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002384:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002386:	4a15                	li	s4,5
        havekids = 1;
    80002388:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000238a:	00014997          	auipc	s3,0x14
    8000238e:	60698993          	addi	s3,s3,1542 # 80016990 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002392:	0000ec17          	auipc	s8,0xe
    80002396:	7e6c0c13          	addi	s8,s8,2022 # 80010b78 <wait_lock>
    havekids = 0;
    8000239a:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000239c:	0000f497          	auipc	s1,0xf
    800023a0:	bf448493          	addi	s1,s1,-1036 # 80010f90 <proc>
    800023a4:	a0bd                	j	80002412 <wait+0xc2>
          pid = pp->pid;
    800023a6:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023aa:	000b0e63          	beqz	s6,800023c6 <wait+0x76>
    800023ae:	4691                	li	a3,4
    800023b0:	02c48613          	addi	a2,s1,44
    800023b4:	85da                	mv	a1,s6
    800023b6:	05093503          	ld	a0,80(s2)
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	2d4080e7          	jalr	724(ra) # 8000168e <copyout>
    800023c2:	02054563          	bltz	a0,800023ec <wait+0x9c>
          freeproc(pp);
    800023c6:	8526                	mv	a0,s1
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	7b8080e7          	jalr	1976(ra) # 80001b80 <freeproc>
          release(&pp->lock);
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	8b8080e7          	jalr	-1864(ra) # 80000c8a <release>
          release(&wait_lock);
    800023da:	0000e517          	auipc	a0,0xe
    800023de:	79e50513          	addi	a0,a0,1950 # 80010b78 <wait_lock>
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	8a8080e7          	jalr	-1880(ra) # 80000c8a <release>
          return pid;
    800023ea:	a0b5                	j	80002456 <wait+0x106>
            release(&pp->lock);
    800023ec:	8526                	mv	a0,s1
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	89c080e7          	jalr	-1892(ra) # 80000c8a <release>
            release(&wait_lock);
    800023f6:	0000e517          	auipc	a0,0xe
    800023fa:	78250513          	addi	a0,a0,1922 # 80010b78 <wait_lock>
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	88c080e7          	jalr	-1908(ra) # 80000c8a <release>
            return -1;
    80002406:	59fd                	li	s3,-1
    80002408:	a0b9                	j	80002456 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000240a:	16848493          	addi	s1,s1,360
    8000240e:	03348463          	beq	s1,s3,80002436 <wait+0xe6>
      if(pp->parent == p){
    80002412:	7c9c                	ld	a5,56(s1)
    80002414:	ff279be3          	bne	a5,s2,8000240a <wait+0xba>
        acquire(&pp->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	ffffe097          	auipc	ra,0xffffe
    8000241e:	7bc080e7          	jalr	1980(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    80002422:	4c9c                	lw	a5,24(s1)
    80002424:	f94781e3          	beq	a5,s4,800023a6 <wait+0x56>
        release(&pp->lock);
    80002428:	8526                	mv	a0,s1
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	860080e7          	jalr	-1952(ra) # 80000c8a <release>
        havekids = 1;
    80002432:	8756                	mv	a4,s5
    80002434:	bfd9                	j	8000240a <wait+0xba>
    if(!havekids || killed(p)){
    80002436:	c719                	beqz	a4,80002444 <wait+0xf4>
    80002438:	854a                	mv	a0,s2
    8000243a:	00000097          	auipc	ra,0x0
    8000243e:	ee4080e7          	jalr	-284(ra) # 8000231e <killed>
    80002442:	c51d                	beqz	a0,80002470 <wait+0x120>
      release(&wait_lock);
    80002444:	0000e517          	auipc	a0,0xe
    80002448:	73450513          	addi	a0,a0,1844 # 80010b78 <wait_lock>
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	83e080e7          	jalr	-1986(ra) # 80000c8a <release>
      return -1;
    80002454:	59fd                	li	s3,-1
}
    80002456:	854e                	mv	a0,s3
    80002458:	60a6                	ld	ra,72(sp)
    8000245a:	6406                	ld	s0,64(sp)
    8000245c:	74e2                	ld	s1,56(sp)
    8000245e:	7942                	ld	s2,48(sp)
    80002460:	79a2                	ld	s3,40(sp)
    80002462:	7a02                	ld	s4,32(sp)
    80002464:	6ae2                	ld	s5,24(sp)
    80002466:	6b42                	ld	s6,16(sp)
    80002468:	6ba2                	ld	s7,8(sp)
    8000246a:	6c02                	ld	s8,0(sp)
    8000246c:	6161                	addi	sp,sp,80
    8000246e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002470:	85e2                	mv	a1,s8
    80002472:	854a                	mv	a0,s2
    80002474:	00000097          	auipc	ra,0x0
    80002478:	c02080e7          	jalr	-1022(ra) # 80002076 <sleep>
    havekids = 0;
    8000247c:	bf39                	j	8000239a <wait+0x4a>

000000008000247e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000247e:	7179                	addi	sp,sp,-48
    80002480:	f406                	sd	ra,40(sp)
    80002482:	f022                	sd	s0,32(sp)
    80002484:	ec26                	sd	s1,24(sp)
    80002486:	e84a                	sd	s2,16(sp)
    80002488:	e44e                	sd	s3,8(sp)
    8000248a:	e052                	sd	s4,0(sp)
    8000248c:	1800                	addi	s0,sp,48
    8000248e:	84aa                	mv	s1,a0
    80002490:	892e                	mv	s2,a1
    80002492:	89b2                	mv	s3,a2
    80002494:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	538080e7          	jalr	1336(ra) # 800019ce <myproc>
  if(user_dst){
    8000249e:	c08d                	beqz	s1,800024c0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024a0:	86d2                	mv	a3,s4
    800024a2:	864e                	mv	a2,s3
    800024a4:	85ca                	mv	a1,s2
    800024a6:	6928                	ld	a0,80(a0)
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	1e6080e7          	jalr	486(ra) # 8000168e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024b0:	70a2                	ld	ra,40(sp)
    800024b2:	7402                	ld	s0,32(sp)
    800024b4:	64e2                	ld	s1,24(sp)
    800024b6:	6942                	ld	s2,16(sp)
    800024b8:	69a2                	ld	s3,8(sp)
    800024ba:	6a02                	ld	s4,0(sp)
    800024bc:	6145                	addi	sp,sp,48
    800024be:	8082                	ret
    memmove((char *)dst, src, len);
    800024c0:	000a061b          	sext.w	a2,s4
    800024c4:	85ce                	mv	a1,s3
    800024c6:	854a                	mv	a0,s2
    800024c8:	fffff097          	auipc	ra,0xfffff
    800024cc:	866080e7          	jalr	-1946(ra) # 80000d2e <memmove>
    return 0;
    800024d0:	8526                	mv	a0,s1
    800024d2:	bff9                	j	800024b0 <either_copyout+0x32>

00000000800024d4 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024d4:	7179                	addi	sp,sp,-48
    800024d6:	f406                	sd	ra,40(sp)
    800024d8:	f022                	sd	s0,32(sp)
    800024da:	ec26                	sd	s1,24(sp)
    800024dc:	e84a                	sd	s2,16(sp)
    800024de:	e44e                	sd	s3,8(sp)
    800024e0:	e052                	sd	s4,0(sp)
    800024e2:	1800                	addi	s0,sp,48
    800024e4:	892a                	mv	s2,a0
    800024e6:	84ae                	mv	s1,a1
    800024e8:	89b2                	mv	s3,a2
    800024ea:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	4e2080e7          	jalr	1250(ra) # 800019ce <myproc>
  if(user_src){
    800024f4:	c08d                	beqz	s1,80002516 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024f6:	86d2                	mv	a3,s4
    800024f8:	864e                	mv	a2,s3
    800024fa:	85ca                	mv	a1,s2
    800024fc:	6928                	ld	a0,80(a0)
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	21c080e7          	jalr	540(ra) # 8000171a <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002506:	70a2                	ld	ra,40(sp)
    80002508:	7402                	ld	s0,32(sp)
    8000250a:	64e2                	ld	s1,24(sp)
    8000250c:	6942                	ld	s2,16(sp)
    8000250e:	69a2                	ld	s3,8(sp)
    80002510:	6a02                	ld	s4,0(sp)
    80002512:	6145                	addi	sp,sp,48
    80002514:	8082                	ret
    memmove(dst, (char*)src, len);
    80002516:	000a061b          	sext.w	a2,s4
    8000251a:	85ce                	mv	a1,s3
    8000251c:	854a                	mv	a0,s2
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	810080e7          	jalr	-2032(ra) # 80000d2e <memmove>
    return 0;
    80002526:	8526                	mv	a0,s1
    80002528:	bff9                	j	80002506 <either_copyin+0x32>

000000008000252a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000252a:	715d                	addi	sp,sp,-80
    8000252c:	e486                	sd	ra,72(sp)
    8000252e:	e0a2                	sd	s0,64(sp)
    80002530:	fc26                	sd	s1,56(sp)
    80002532:	f84a                	sd	s2,48(sp)
    80002534:	f44e                	sd	s3,40(sp)
    80002536:	f052                	sd	s4,32(sp)
    80002538:	ec56                	sd	s5,24(sp)
    8000253a:	e85a                	sd	s6,16(sp)
    8000253c:	e45e                	sd	s7,8(sp)
    8000253e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002540:	00006517          	auipc	a0,0x6
    80002544:	b8850513          	addi	a0,a0,-1144 # 800080c8 <digits+0x88>
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	042080e7          	jalr	66(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002550:	0000f497          	auipc	s1,0xf
    80002554:	b9848493          	addi	s1,s1,-1128 # 800110e8 <proc+0x158>
    80002558:	00014917          	auipc	s2,0x14
    8000255c:	59090913          	addi	s2,s2,1424 # 80016ae8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002560:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002562:	00006997          	auipc	s3,0x6
    80002566:	d2e98993          	addi	s3,s3,-722 # 80008290 <digits+0x250>
    printf("%d %s %s", p->pid, state, p->name);
    8000256a:	00006a97          	auipc	s5,0x6
    8000256e:	d2ea8a93          	addi	s5,s5,-722 # 80008298 <digits+0x258>
    printf("\n");
    80002572:	00006a17          	auipc	s4,0x6
    80002576:	b56a0a13          	addi	s4,s4,-1194 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000257a:	00006b97          	auipc	s7,0x6
    8000257e:	d5eb8b93          	addi	s7,s7,-674 # 800082d8 <states.0>
    80002582:	a00d                	j	800025a4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002584:	ed86a583          	lw	a1,-296(a3)
    80002588:	8556                	mv	a0,s5
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	000080e7          	jalr	ra # 8000058a <printf>
    printf("\n");
    80002592:	8552                	mv	a0,s4
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	ff6080e7          	jalr	-10(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000259c:	16848493          	addi	s1,s1,360
    800025a0:	03248263          	beq	s1,s2,800025c4 <procdump+0x9a>
    if(p->state == UNUSED)
    800025a4:	86a6                	mv	a3,s1
    800025a6:	ec04a783          	lw	a5,-320(s1)
    800025aa:	dbed                	beqz	a5,8000259c <procdump+0x72>
      state = "???";
    800025ac:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ae:	fcfb6be3          	bltu	s6,a5,80002584 <procdump+0x5a>
    800025b2:	02079713          	slli	a4,a5,0x20
    800025b6:	01d75793          	srli	a5,a4,0x1d
    800025ba:	97de                	add	a5,a5,s7
    800025bc:	6390                	ld	a2,0(a5)
    800025be:	f279                	bnez	a2,80002584 <procdump+0x5a>
      state = "???";
    800025c0:	864e                	mv	a2,s3
    800025c2:	b7c9                	j	80002584 <procdump+0x5a>
  }
}
    800025c4:	60a6                	ld	ra,72(sp)
    800025c6:	6406                	ld	s0,64(sp)
    800025c8:	74e2                	ld	s1,56(sp)
    800025ca:	7942                	ld	s2,48(sp)
    800025cc:	79a2                	ld	s3,40(sp)
    800025ce:	7a02                	ld	s4,32(sp)
    800025d0:	6ae2                	ld	s5,24(sp)
    800025d2:	6b42                	ld	s6,16(sp)
    800025d4:	6ba2                	ld	s7,8(sp)
    800025d6:	6161                	addi	sp,sp,80
    800025d8:	8082                	ret

00000000800025da <swtch>:
    800025da:	00153023          	sd	ra,0(a0)
    800025de:	00253423          	sd	sp,8(a0)
    800025e2:	e900                	sd	s0,16(a0)
    800025e4:	ed04                	sd	s1,24(a0)
    800025e6:	03253023          	sd	s2,32(a0)
    800025ea:	03353423          	sd	s3,40(a0)
    800025ee:	03453823          	sd	s4,48(a0)
    800025f2:	03553c23          	sd	s5,56(a0)
    800025f6:	05653023          	sd	s6,64(a0)
    800025fa:	05753423          	sd	s7,72(a0)
    800025fe:	05853823          	sd	s8,80(a0)
    80002602:	05953c23          	sd	s9,88(a0)
    80002606:	07a53023          	sd	s10,96(a0)
    8000260a:	07b53423          	sd	s11,104(a0)
    8000260e:	0005b083          	ld	ra,0(a1)
    80002612:	0085b103          	ld	sp,8(a1)
    80002616:	6980                	ld	s0,16(a1)
    80002618:	6d84                	ld	s1,24(a1)
    8000261a:	0205b903          	ld	s2,32(a1)
    8000261e:	0285b983          	ld	s3,40(a1)
    80002622:	0305ba03          	ld	s4,48(a1)
    80002626:	0385ba83          	ld	s5,56(a1)
    8000262a:	0405bb03          	ld	s6,64(a1)
    8000262e:	0485bb83          	ld	s7,72(a1)
    80002632:	0505bc03          	ld	s8,80(a1)
    80002636:	0585bc83          	ld	s9,88(a1)
    8000263a:	0605bd03          	ld	s10,96(a1)
    8000263e:	0685bd83          	ld	s11,104(a1)
    80002642:	8082                	ret

0000000080002644 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002644:	1141                	addi	sp,sp,-16
    80002646:	e406                	sd	ra,8(sp)
    80002648:	e022                	sd	s0,0(sp)
    8000264a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000264c:	00006597          	auipc	a1,0x6
    80002650:	cbc58593          	addi	a1,a1,-836 # 80008308 <states.0+0x30>
    80002654:	00014517          	auipc	a0,0x14
    80002658:	33c50513          	addi	a0,a0,828 # 80016990 <tickslock>
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	4ea080e7          	jalr	1258(ra) # 80000b46 <initlock>
}
    80002664:	60a2                	ld	ra,8(sp)
    80002666:	6402                	ld	s0,0(sp)
    80002668:	0141                	addi	sp,sp,16
    8000266a:	8082                	ret

000000008000266c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000266c:	1141                	addi	sp,sp,-16
    8000266e:	e422                	sd	s0,8(sp)
    80002670:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002672:	00003797          	auipc	a5,0x3
    80002676:	4ce78793          	addi	a5,a5,1230 # 80005b40 <kernelvec>
    8000267a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000267e:	6422                	ld	s0,8(sp)
    80002680:	0141                	addi	sp,sp,16
    80002682:	8082                	ret

0000000080002684 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002684:	1141                	addi	sp,sp,-16
    80002686:	e406                	sd	ra,8(sp)
    80002688:	e022                	sd	s0,0(sp)
    8000268a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000268c:	fffff097          	auipc	ra,0xfffff
    80002690:	342080e7          	jalr	834(ra) # 800019ce <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002694:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002698:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000269a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000269e:	00005697          	auipc	a3,0x5
    800026a2:	96268693          	addi	a3,a3,-1694 # 80007000 <_trampoline>
    800026a6:	00005717          	auipc	a4,0x5
    800026aa:	95a70713          	addi	a4,a4,-1702 # 80007000 <_trampoline>
    800026ae:	8f15                	sub	a4,a4,a3
    800026b0:	040007b7          	lui	a5,0x4000
    800026b4:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800026b6:	07b2                	slli	a5,a5,0xc
    800026b8:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026ba:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026be:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026c0:	18002673          	csrr	a2,satp
    800026c4:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026c6:	6d30                	ld	a2,88(a0)
    800026c8:	6138                	ld	a4,64(a0)
    800026ca:	6585                	lui	a1,0x1
    800026cc:	972e                	add	a4,a4,a1
    800026ce:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026d0:	6d38                	ld	a4,88(a0)
    800026d2:	00000617          	auipc	a2,0x0
    800026d6:	13060613          	addi	a2,a2,304 # 80002802 <usertrap>
    800026da:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026dc:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026de:	8612                	mv	a2,tp
    800026e0:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026e2:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026e6:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026ea:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026ee:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026f2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026f4:	6f18                	ld	a4,24(a4)
    800026f6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026fa:	6928                	ld	a0,80(a0)
    800026fc:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800026fe:	00005717          	auipc	a4,0x5
    80002702:	99e70713          	addi	a4,a4,-1634 # 8000709c <userret>
    80002706:	8f15                	sub	a4,a4,a3
    80002708:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000270a:	577d                	li	a4,-1
    8000270c:	177e                	slli	a4,a4,0x3f
    8000270e:	8d59                	or	a0,a0,a4
    80002710:	9782                	jalr	a5
}
    80002712:	60a2                	ld	ra,8(sp)
    80002714:	6402                	ld	s0,0(sp)
    80002716:	0141                	addi	sp,sp,16
    80002718:	8082                	ret

000000008000271a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000271a:	1101                	addi	sp,sp,-32
    8000271c:	ec06                	sd	ra,24(sp)
    8000271e:	e822                	sd	s0,16(sp)
    80002720:	e426                	sd	s1,8(sp)
    80002722:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002724:	00014497          	auipc	s1,0x14
    80002728:	26c48493          	addi	s1,s1,620 # 80016990 <tickslock>
    8000272c:	8526                	mv	a0,s1
    8000272e:	ffffe097          	auipc	ra,0xffffe
    80002732:	4a8080e7          	jalr	1192(ra) # 80000bd6 <acquire>
  ticks++;
    80002736:	00006517          	auipc	a0,0x6
    8000273a:	1ba50513          	addi	a0,a0,442 # 800088f0 <ticks>
    8000273e:	411c                	lw	a5,0(a0)
    80002740:	2785                	addiw	a5,a5,1
    80002742:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002744:	00000097          	auipc	ra,0x0
    80002748:	996080e7          	jalr	-1642(ra) # 800020da <wakeup>
  release(&tickslock);
    8000274c:	8526                	mv	a0,s1
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	53c080e7          	jalr	1340(ra) # 80000c8a <release>
}
    80002756:	60e2                	ld	ra,24(sp)
    80002758:	6442                	ld	s0,16(sp)
    8000275a:	64a2                	ld	s1,8(sp)
    8000275c:	6105                	addi	sp,sp,32
    8000275e:	8082                	ret

0000000080002760 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002760:	1101                	addi	sp,sp,-32
    80002762:	ec06                	sd	ra,24(sp)
    80002764:	e822                	sd	s0,16(sp)
    80002766:	e426                	sd	s1,8(sp)
    80002768:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000276a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000276e:	00074d63          	bltz	a4,80002788 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002772:	57fd                	li	a5,-1
    80002774:	17fe                	slli	a5,a5,0x3f
    80002776:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002778:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000277a:	06f70363          	beq	a4,a5,800027e0 <devintr+0x80>
  }
}
    8000277e:	60e2                	ld	ra,24(sp)
    80002780:	6442                	ld	s0,16(sp)
    80002782:	64a2                	ld	s1,8(sp)
    80002784:	6105                	addi	sp,sp,32
    80002786:	8082                	ret
     (scause & 0xff) == 9){
    80002788:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    8000278c:	46a5                	li	a3,9
    8000278e:	fed792e3          	bne	a5,a3,80002772 <devintr+0x12>
    int irq = plic_claim();
    80002792:	00003097          	auipc	ra,0x3
    80002796:	4b6080e7          	jalr	1206(ra) # 80005c48 <plic_claim>
    8000279a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000279c:	47a9                	li	a5,10
    8000279e:	02f50763          	beq	a0,a5,800027cc <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027a2:	4785                	li	a5,1
    800027a4:	02f50963          	beq	a0,a5,800027d6 <devintr+0x76>
    return 1;
    800027a8:	4505                	li	a0,1
    } else if(irq){
    800027aa:	d8f1                	beqz	s1,8000277e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027ac:	85a6                	mv	a1,s1
    800027ae:	00006517          	auipc	a0,0x6
    800027b2:	b6250513          	addi	a0,a0,-1182 # 80008310 <states.0+0x38>
    800027b6:	ffffe097          	auipc	ra,0xffffe
    800027ba:	dd4080e7          	jalr	-556(ra) # 8000058a <printf>
      plic_complete(irq);
    800027be:	8526                	mv	a0,s1
    800027c0:	00003097          	auipc	ra,0x3
    800027c4:	4ac080e7          	jalr	1196(ra) # 80005c6c <plic_complete>
    return 1;
    800027c8:	4505                	li	a0,1
    800027ca:	bf55                	j	8000277e <devintr+0x1e>
      uartintr();
    800027cc:	ffffe097          	auipc	ra,0xffffe
    800027d0:	1cc080e7          	jalr	460(ra) # 80000998 <uartintr>
    800027d4:	b7ed                	j	800027be <devintr+0x5e>
      virtio_disk_intr();
    800027d6:	00004097          	auipc	ra,0x4
    800027da:	95e080e7          	jalr	-1698(ra) # 80006134 <virtio_disk_intr>
    800027de:	b7c5                	j	800027be <devintr+0x5e>
    if(cpuid() == 0){
    800027e0:	fffff097          	auipc	ra,0xfffff
    800027e4:	1c2080e7          	jalr	450(ra) # 800019a2 <cpuid>
    800027e8:	c901                	beqz	a0,800027f8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027ea:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027ee:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027f0:	14479073          	csrw	sip,a5
    return 2;
    800027f4:	4509                	li	a0,2
    800027f6:	b761                	j	8000277e <devintr+0x1e>
      clockintr();
    800027f8:	00000097          	auipc	ra,0x0
    800027fc:	f22080e7          	jalr	-222(ra) # 8000271a <clockintr>
    80002800:	b7ed                	j	800027ea <devintr+0x8a>

0000000080002802 <usertrap>:
{
    80002802:	1101                	addi	sp,sp,-32
    80002804:	ec06                	sd	ra,24(sp)
    80002806:	e822                	sd	s0,16(sp)
    80002808:	e426                	sd	s1,8(sp)
    8000280a:	e04a                	sd	s2,0(sp)
    8000280c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000280e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002812:	1007f793          	andi	a5,a5,256
    80002816:	e3b1                	bnez	a5,8000285a <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002818:	00003797          	auipc	a5,0x3
    8000281c:	32878793          	addi	a5,a5,808 # 80005b40 <kernelvec>
    80002820:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002824:	fffff097          	auipc	ra,0xfffff
    80002828:	1aa080e7          	jalr	426(ra) # 800019ce <myproc>
    8000282c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000282e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002830:	14102773          	csrr	a4,sepc
    80002834:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002836:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000283a:	47a1                	li	a5,8
    8000283c:	02f70763          	beq	a4,a5,8000286a <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002840:	00000097          	auipc	ra,0x0
    80002844:	f20080e7          	jalr	-224(ra) # 80002760 <devintr>
    80002848:	892a                	mv	s2,a0
    8000284a:	c151                	beqz	a0,800028ce <usertrap+0xcc>
  if(killed(p))
    8000284c:	8526                	mv	a0,s1
    8000284e:	00000097          	auipc	ra,0x0
    80002852:	ad0080e7          	jalr	-1328(ra) # 8000231e <killed>
    80002856:	c929                	beqz	a0,800028a8 <usertrap+0xa6>
    80002858:	a099                	j	8000289e <usertrap+0x9c>
    panic("usertrap: not from user mode");
    8000285a:	00006517          	auipc	a0,0x6
    8000285e:	ad650513          	addi	a0,a0,-1322 # 80008330 <states.0+0x58>
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	cde080e7          	jalr	-802(ra) # 80000540 <panic>
    if(killed(p))
    8000286a:	00000097          	auipc	ra,0x0
    8000286e:	ab4080e7          	jalr	-1356(ra) # 8000231e <killed>
    80002872:	e921                	bnez	a0,800028c2 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002874:	6cb8                	ld	a4,88(s1)
    80002876:	6f1c                	ld	a5,24(a4)
    80002878:	0791                	addi	a5,a5,4
    8000287a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000287c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002880:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002884:	10079073          	csrw	sstatus,a5
    syscall();
    80002888:	00000097          	auipc	ra,0x0
    8000288c:	2d4080e7          	jalr	724(ra) # 80002b5c <syscall>
  if(killed(p))
    80002890:	8526                	mv	a0,s1
    80002892:	00000097          	auipc	ra,0x0
    80002896:	a8c080e7          	jalr	-1396(ra) # 8000231e <killed>
    8000289a:	c911                	beqz	a0,800028ae <usertrap+0xac>
    8000289c:	4901                	li	s2,0
    exit(-1);
    8000289e:	557d                	li	a0,-1
    800028a0:	00000097          	auipc	ra,0x0
    800028a4:	90a080e7          	jalr	-1782(ra) # 800021aa <exit>
  if(which_dev == 2)
    800028a8:	4789                	li	a5,2
    800028aa:	04f90f63          	beq	s2,a5,80002908 <usertrap+0x106>
  usertrapret();
    800028ae:	00000097          	auipc	ra,0x0
    800028b2:	dd6080e7          	jalr	-554(ra) # 80002684 <usertrapret>
}
    800028b6:	60e2                	ld	ra,24(sp)
    800028b8:	6442                	ld	s0,16(sp)
    800028ba:	64a2                	ld	s1,8(sp)
    800028bc:	6902                	ld	s2,0(sp)
    800028be:	6105                	addi	sp,sp,32
    800028c0:	8082                	ret
      exit(-1);
    800028c2:	557d                	li	a0,-1
    800028c4:	00000097          	auipc	ra,0x0
    800028c8:	8e6080e7          	jalr	-1818(ra) # 800021aa <exit>
    800028cc:	b765                	j	80002874 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ce:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028d2:	5890                	lw	a2,48(s1)
    800028d4:	00006517          	auipc	a0,0x6
    800028d8:	a7c50513          	addi	a0,a0,-1412 # 80008350 <states.0+0x78>
    800028dc:	ffffe097          	auipc	ra,0xffffe
    800028e0:	cae080e7          	jalr	-850(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028e4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028e8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028ec:	00006517          	auipc	a0,0x6
    800028f0:	a9450513          	addi	a0,a0,-1388 # 80008380 <states.0+0xa8>
    800028f4:	ffffe097          	auipc	ra,0xffffe
    800028f8:	c96080e7          	jalr	-874(ra) # 8000058a <printf>
    setkilled(p);
    800028fc:	8526                	mv	a0,s1
    800028fe:	00000097          	auipc	ra,0x0
    80002902:	9f4080e7          	jalr	-1548(ra) # 800022f2 <setkilled>
    80002906:	b769                	j	80002890 <usertrap+0x8e>
    yield();
    80002908:	fffff097          	auipc	ra,0xfffff
    8000290c:	732080e7          	jalr	1842(ra) # 8000203a <yield>
    80002910:	bf79                	j	800028ae <usertrap+0xac>

0000000080002912 <kerneltrap>:
{
    80002912:	7179                	addi	sp,sp,-48
    80002914:	f406                	sd	ra,40(sp)
    80002916:	f022                	sd	s0,32(sp)
    80002918:	ec26                	sd	s1,24(sp)
    8000291a:	e84a                	sd	s2,16(sp)
    8000291c:	e44e                	sd	s3,8(sp)
    8000291e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002920:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002924:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002928:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000292c:	1004f793          	andi	a5,s1,256
    80002930:	cb85                	beqz	a5,80002960 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002932:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002936:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002938:	ef85                	bnez	a5,80002970 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000293a:	00000097          	auipc	ra,0x0
    8000293e:	e26080e7          	jalr	-474(ra) # 80002760 <devintr>
    80002942:	cd1d                	beqz	a0,80002980 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002944:	4789                	li	a5,2
    80002946:	06f50a63          	beq	a0,a5,800029ba <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000294a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000294e:	10049073          	csrw	sstatus,s1
}
    80002952:	70a2                	ld	ra,40(sp)
    80002954:	7402                	ld	s0,32(sp)
    80002956:	64e2                	ld	s1,24(sp)
    80002958:	6942                	ld	s2,16(sp)
    8000295a:	69a2                	ld	s3,8(sp)
    8000295c:	6145                	addi	sp,sp,48
    8000295e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002960:	00006517          	auipc	a0,0x6
    80002964:	a4050513          	addi	a0,a0,-1472 # 800083a0 <states.0+0xc8>
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	bd8080e7          	jalr	-1064(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002970:	00006517          	auipc	a0,0x6
    80002974:	a5850513          	addi	a0,a0,-1448 # 800083c8 <states.0+0xf0>
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	bc8080e7          	jalr	-1080(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002980:	85ce                	mv	a1,s3
    80002982:	00006517          	auipc	a0,0x6
    80002986:	a6650513          	addi	a0,a0,-1434 # 800083e8 <states.0+0x110>
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	c00080e7          	jalr	-1024(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002992:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002996:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000299a:	00006517          	auipc	a0,0x6
    8000299e:	a5e50513          	addi	a0,a0,-1442 # 800083f8 <states.0+0x120>
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	be8080e7          	jalr	-1048(ra) # 8000058a <printf>
    panic("kerneltrap");
    800029aa:	00006517          	auipc	a0,0x6
    800029ae:	a6650513          	addi	a0,a0,-1434 # 80008410 <states.0+0x138>
    800029b2:	ffffe097          	auipc	ra,0xffffe
    800029b6:	b8e080e7          	jalr	-1138(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029ba:	fffff097          	auipc	ra,0xfffff
    800029be:	014080e7          	jalr	20(ra) # 800019ce <myproc>
    800029c2:	d541                	beqz	a0,8000294a <kerneltrap+0x38>
    800029c4:	fffff097          	auipc	ra,0xfffff
    800029c8:	00a080e7          	jalr	10(ra) # 800019ce <myproc>
    800029cc:	4d18                	lw	a4,24(a0)
    800029ce:	4791                	li	a5,4
    800029d0:	f6f71de3          	bne	a4,a5,8000294a <kerneltrap+0x38>
    yield();
    800029d4:	fffff097          	auipc	ra,0xfffff
    800029d8:	666080e7          	jalr	1638(ra) # 8000203a <yield>
    800029dc:	b7bd                	j	8000294a <kerneltrap+0x38>

00000000800029de <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029de:	1101                	addi	sp,sp,-32
    800029e0:	ec06                	sd	ra,24(sp)
    800029e2:	e822                	sd	s0,16(sp)
    800029e4:	e426                	sd	s1,8(sp)
    800029e6:	1000                	addi	s0,sp,32
    800029e8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029ea:	fffff097          	auipc	ra,0xfffff
    800029ee:	fe4080e7          	jalr	-28(ra) # 800019ce <myproc>
  switch (n) {
    800029f2:	4795                	li	a5,5
    800029f4:	0497e163          	bltu	a5,s1,80002a36 <argraw+0x58>
    800029f8:	048a                	slli	s1,s1,0x2
    800029fa:	00006717          	auipc	a4,0x6
    800029fe:	a4e70713          	addi	a4,a4,-1458 # 80008448 <states.0+0x170>
    80002a02:	94ba                	add	s1,s1,a4
    80002a04:	409c                	lw	a5,0(s1)
    80002a06:	97ba                	add	a5,a5,a4
    80002a08:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a0a:	6d3c                	ld	a5,88(a0)
    80002a0c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a0e:	60e2                	ld	ra,24(sp)
    80002a10:	6442                	ld	s0,16(sp)
    80002a12:	64a2                	ld	s1,8(sp)
    80002a14:	6105                	addi	sp,sp,32
    80002a16:	8082                	ret
    return p->trapframe->a1;
    80002a18:	6d3c                	ld	a5,88(a0)
    80002a1a:	7fa8                	ld	a0,120(a5)
    80002a1c:	bfcd                	j	80002a0e <argraw+0x30>
    return p->trapframe->a2;
    80002a1e:	6d3c                	ld	a5,88(a0)
    80002a20:	63c8                	ld	a0,128(a5)
    80002a22:	b7f5                	j	80002a0e <argraw+0x30>
    return p->trapframe->a3;
    80002a24:	6d3c                	ld	a5,88(a0)
    80002a26:	67c8                	ld	a0,136(a5)
    80002a28:	b7dd                	j	80002a0e <argraw+0x30>
    return p->trapframe->a4;
    80002a2a:	6d3c                	ld	a5,88(a0)
    80002a2c:	6bc8                	ld	a0,144(a5)
    80002a2e:	b7c5                	j	80002a0e <argraw+0x30>
    return p->trapframe->a5;
    80002a30:	6d3c                	ld	a5,88(a0)
    80002a32:	6fc8                	ld	a0,152(a5)
    80002a34:	bfe9                	j	80002a0e <argraw+0x30>
  panic("argraw");
    80002a36:	00006517          	auipc	a0,0x6
    80002a3a:	9ea50513          	addi	a0,a0,-1558 # 80008420 <states.0+0x148>
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	b02080e7          	jalr	-1278(ra) # 80000540 <panic>

0000000080002a46 <fetchaddr>:
{
    80002a46:	1101                	addi	sp,sp,-32
    80002a48:	ec06                	sd	ra,24(sp)
    80002a4a:	e822                	sd	s0,16(sp)
    80002a4c:	e426                	sd	s1,8(sp)
    80002a4e:	e04a                	sd	s2,0(sp)
    80002a50:	1000                	addi	s0,sp,32
    80002a52:	84aa                	mv	s1,a0
    80002a54:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a56:	fffff097          	auipc	ra,0xfffff
    80002a5a:	f78080e7          	jalr	-136(ra) # 800019ce <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a5e:	653c                	ld	a5,72(a0)
    80002a60:	02f4f863          	bgeu	s1,a5,80002a90 <fetchaddr+0x4a>
    80002a64:	00848713          	addi	a4,s1,8
    80002a68:	02e7e663          	bltu	a5,a4,80002a94 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a6c:	46a1                	li	a3,8
    80002a6e:	8626                	mv	a2,s1
    80002a70:	85ca                	mv	a1,s2
    80002a72:	6928                	ld	a0,80(a0)
    80002a74:	fffff097          	auipc	ra,0xfffff
    80002a78:	ca6080e7          	jalr	-858(ra) # 8000171a <copyin>
    80002a7c:	00a03533          	snez	a0,a0
    80002a80:	40a00533          	neg	a0,a0
}
    80002a84:	60e2                	ld	ra,24(sp)
    80002a86:	6442                	ld	s0,16(sp)
    80002a88:	64a2                	ld	s1,8(sp)
    80002a8a:	6902                	ld	s2,0(sp)
    80002a8c:	6105                	addi	sp,sp,32
    80002a8e:	8082                	ret
    return -1;
    80002a90:	557d                	li	a0,-1
    80002a92:	bfcd                	j	80002a84 <fetchaddr+0x3e>
    80002a94:	557d                	li	a0,-1
    80002a96:	b7fd                	j	80002a84 <fetchaddr+0x3e>

0000000080002a98 <fetchstr>:
{
    80002a98:	7179                	addi	sp,sp,-48
    80002a9a:	f406                	sd	ra,40(sp)
    80002a9c:	f022                	sd	s0,32(sp)
    80002a9e:	ec26                	sd	s1,24(sp)
    80002aa0:	e84a                	sd	s2,16(sp)
    80002aa2:	e44e                	sd	s3,8(sp)
    80002aa4:	1800                	addi	s0,sp,48
    80002aa6:	892a                	mv	s2,a0
    80002aa8:	84ae                	mv	s1,a1
    80002aaa:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002aac:	fffff097          	auipc	ra,0xfffff
    80002ab0:	f22080e7          	jalr	-222(ra) # 800019ce <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ab4:	86ce                	mv	a3,s3
    80002ab6:	864a                	mv	a2,s2
    80002ab8:	85a6                	mv	a1,s1
    80002aba:	6928                	ld	a0,80(a0)
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	cec080e7          	jalr	-788(ra) # 800017a8 <copyinstr>
    80002ac4:	00054e63          	bltz	a0,80002ae0 <fetchstr+0x48>
  return strlen(buf);
    80002ac8:	8526                	mv	a0,s1
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	384080e7          	jalr	900(ra) # 80000e4e <strlen>
}
    80002ad2:	70a2                	ld	ra,40(sp)
    80002ad4:	7402                	ld	s0,32(sp)
    80002ad6:	64e2                	ld	s1,24(sp)
    80002ad8:	6942                	ld	s2,16(sp)
    80002ada:	69a2                	ld	s3,8(sp)
    80002adc:	6145                	addi	sp,sp,48
    80002ade:	8082                	ret
    return -1;
    80002ae0:	557d                	li	a0,-1
    80002ae2:	bfc5                	j	80002ad2 <fetchstr+0x3a>

0000000080002ae4 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002ae4:	1101                	addi	sp,sp,-32
    80002ae6:	ec06                	sd	ra,24(sp)
    80002ae8:	e822                	sd	s0,16(sp)
    80002aea:	e426                	sd	s1,8(sp)
    80002aec:	1000                	addi	s0,sp,32
    80002aee:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002af0:	00000097          	auipc	ra,0x0
    80002af4:	eee080e7          	jalr	-274(ra) # 800029de <argraw>
    80002af8:	c088                	sw	a0,0(s1)
}
    80002afa:	60e2                	ld	ra,24(sp)
    80002afc:	6442                	ld	s0,16(sp)
    80002afe:	64a2                	ld	s1,8(sp)
    80002b00:	6105                	addi	sp,sp,32
    80002b02:	8082                	ret

0000000080002b04 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b04:	1101                	addi	sp,sp,-32
    80002b06:	ec06                	sd	ra,24(sp)
    80002b08:	e822                	sd	s0,16(sp)
    80002b0a:	e426                	sd	s1,8(sp)
    80002b0c:	1000                	addi	s0,sp,32
    80002b0e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b10:	00000097          	auipc	ra,0x0
    80002b14:	ece080e7          	jalr	-306(ra) # 800029de <argraw>
    80002b18:	e088                	sd	a0,0(s1)
}
    80002b1a:	60e2                	ld	ra,24(sp)
    80002b1c:	6442                	ld	s0,16(sp)
    80002b1e:	64a2                	ld	s1,8(sp)
    80002b20:	6105                	addi	sp,sp,32
    80002b22:	8082                	ret

0000000080002b24 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b24:	7179                	addi	sp,sp,-48
    80002b26:	f406                	sd	ra,40(sp)
    80002b28:	f022                	sd	s0,32(sp)
    80002b2a:	ec26                	sd	s1,24(sp)
    80002b2c:	e84a                	sd	s2,16(sp)
    80002b2e:	1800                	addi	s0,sp,48
    80002b30:	84ae                	mv	s1,a1
    80002b32:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b34:	fd840593          	addi	a1,s0,-40
    80002b38:	00000097          	auipc	ra,0x0
    80002b3c:	fcc080e7          	jalr	-52(ra) # 80002b04 <argaddr>
  return fetchstr(addr, buf, max);
    80002b40:	864a                	mv	a2,s2
    80002b42:	85a6                	mv	a1,s1
    80002b44:	fd843503          	ld	a0,-40(s0)
    80002b48:	00000097          	auipc	ra,0x0
    80002b4c:	f50080e7          	jalr	-176(ra) # 80002a98 <fetchstr>
}
    80002b50:	70a2                	ld	ra,40(sp)
    80002b52:	7402                	ld	s0,32(sp)
    80002b54:	64e2                	ld	s1,24(sp)
    80002b56:	6942                	ld	s2,16(sp)
    80002b58:	6145                	addi	sp,sp,48
    80002b5a:	8082                	ret

0000000080002b5c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002b5c:	1101                	addi	sp,sp,-32
    80002b5e:	ec06                	sd	ra,24(sp)
    80002b60:	e822                	sd	s0,16(sp)
    80002b62:	e426                	sd	s1,8(sp)
    80002b64:	e04a                	sd	s2,0(sp)
    80002b66:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b68:	fffff097          	auipc	ra,0xfffff
    80002b6c:	e66080e7          	jalr	-410(ra) # 800019ce <myproc>
    80002b70:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b72:	05853903          	ld	s2,88(a0)
    80002b76:	0a893783          	ld	a5,168(s2)
    80002b7a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b7e:	37fd                	addiw	a5,a5,-1
    80002b80:	4751                	li	a4,20
    80002b82:	00f76f63          	bltu	a4,a5,80002ba0 <syscall+0x44>
    80002b86:	00369713          	slli	a4,a3,0x3
    80002b8a:	00006797          	auipc	a5,0x6
    80002b8e:	8d678793          	addi	a5,a5,-1834 # 80008460 <syscalls>
    80002b92:	97ba                	add	a5,a5,a4
    80002b94:	639c                	ld	a5,0(a5)
    80002b96:	c789                	beqz	a5,80002ba0 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002b98:	9782                	jalr	a5
    80002b9a:	06a93823          	sd	a0,112(s2)
    80002b9e:	a839                	j	80002bbc <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ba0:	15848613          	addi	a2,s1,344
    80002ba4:	588c                	lw	a1,48(s1)
    80002ba6:	00006517          	auipc	a0,0x6
    80002baa:	88250513          	addi	a0,a0,-1918 # 80008428 <states.0+0x150>
    80002bae:	ffffe097          	auipc	ra,0xffffe
    80002bb2:	9dc080e7          	jalr	-1572(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bb6:	6cbc                	ld	a5,88(s1)
    80002bb8:	577d                	li	a4,-1
    80002bba:	fbb8                	sd	a4,112(a5)
  }
}
    80002bbc:	60e2                	ld	ra,24(sp)
    80002bbe:	6442                	ld	s0,16(sp)
    80002bc0:	64a2                	ld	s1,8(sp)
    80002bc2:	6902                	ld	s2,0(sp)
    80002bc4:	6105                	addi	sp,sp,32
    80002bc6:	8082                	ret

0000000080002bc8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002bc8:	1101                	addi	sp,sp,-32
    80002bca:	ec06                	sd	ra,24(sp)
    80002bcc:	e822                	sd	s0,16(sp)
    80002bce:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002bd0:	fec40593          	addi	a1,s0,-20
    80002bd4:	4501                	li	a0,0
    80002bd6:	00000097          	auipc	ra,0x0
    80002bda:	f0e080e7          	jalr	-242(ra) # 80002ae4 <argint>
  exit(n);
    80002bde:	fec42503          	lw	a0,-20(s0)
    80002be2:	fffff097          	auipc	ra,0xfffff
    80002be6:	5c8080e7          	jalr	1480(ra) # 800021aa <exit>
  return 0;  // not reached
}
    80002bea:	4501                	li	a0,0
    80002bec:	60e2                	ld	ra,24(sp)
    80002bee:	6442                	ld	s0,16(sp)
    80002bf0:	6105                	addi	sp,sp,32
    80002bf2:	8082                	ret

0000000080002bf4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bf4:	1141                	addi	sp,sp,-16
    80002bf6:	e406                	sd	ra,8(sp)
    80002bf8:	e022                	sd	s0,0(sp)
    80002bfa:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bfc:	fffff097          	auipc	ra,0xfffff
    80002c00:	dd2080e7          	jalr	-558(ra) # 800019ce <myproc>
}
    80002c04:	5908                	lw	a0,48(a0)
    80002c06:	60a2                	ld	ra,8(sp)
    80002c08:	6402                	ld	s0,0(sp)
    80002c0a:	0141                	addi	sp,sp,16
    80002c0c:	8082                	ret

0000000080002c0e <sys_fork>:

uint64
sys_fork(void)
{
    80002c0e:	1141                	addi	sp,sp,-16
    80002c10:	e406                	sd	ra,8(sp)
    80002c12:	e022                	sd	s0,0(sp)
    80002c14:	0800                	addi	s0,sp,16
  return fork();
    80002c16:	fffff097          	auipc	ra,0xfffff
    80002c1a:	16e080e7          	jalr	366(ra) # 80001d84 <fork>
}
    80002c1e:	60a2                	ld	ra,8(sp)
    80002c20:	6402                	ld	s0,0(sp)
    80002c22:	0141                	addi	sp,sp,16
    80002c24:	8082                	ret

0000000080002c26 <sys_wait>:

uint64
sys_wait(void)
{
    80002c26:	1101                	addi	sp,sp,-32
    80002c28:	ec06                	sd	ra,24(sp)
    80002c2a:	e822                	sd	s0,16(sp)
    80002c2c:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002c2e:	fe840593          	addi	a1,s0,-24
    80002c32:	4501                	li	a0,0
    80002c34:	00000097          	auipc	ra,0x0
    80002c38:	ed0080e7          	jalr	-304(ra) # 80002b04 <argaddr>
  return wait(p);
    80002c3c:	fe843503          	ld	a0,-24(s0)
    80002c40:	fffff097          	auipc	ra,0xfffff
    80002c44:	710080e7          	jalr	1808(ra) # 80002350 <wait>
}
    80002c48:	60e2                	ld	ra,24(sp)
    80002c4a:	6442                	ld	s0,16(sp)
    80002c4c:	6105                	addi	sp,sp,32
    80002c4e:	8082                	ret

0000000080002c50 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c50:	7179                	addi	sp,sp,-48
    80002c52:	f406                	sd	ra,40(sp)
    80002c54:	f022                	sd	s0,32(sp)
    80002c56:	ec26                	sd	s1,24(sp)
    80002c58:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002c5a:	fdc40593          	addi	a1,s0,-36
    80002c5e:	4501                	li	a0,0
    80002c60:	00000097          	auipc	ra,0x0
    80002c64:	e84080e7          	jalr	-380(ra) # 80002ae4 <argint>
  addr = myproc()->sz;
    80002c68:	fffff097          	auipc	ra,0xfffff
    80002c6c:	d66080e7          	jalr	-666(ra) # 800019ce <myproc>
    80002c70:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002c72:	fdc42503          	lw	a0,-36(s0)
    80002c76:	fffff097          	auipc	ra,0xfffff
    80002c7a:	0b2080e7          	jalr	178(ra) # 80001d28 <growproc>
    80002c7e:	00054863          	bltz	a0,80002c8e <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002c82:	8526                	mv	a0,s1
    80002c84:	70a2                	ld	ra,40(sp)
    80002c86:	7402                	ld	s0,32(sp)
    80002c88:	64e2                	ld	s1,24(sp)
    80002c8a:	6145                	addi	sp,sp,48
    80002c8c:	8082                	ret
    return -1;
    80002c8e:	54fd                	li	s1,-1
    80002c90:	bfcd                	j	80002c82 <sys_sbrk+0x32>

0000000080002c92 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c92:	7139                	addi	sp,sp,-64
    80002c94:	fc06                	sd	ra,56(sp)
    80002c96:	f822                	sd	s0,48(sp)
    80002c98:	f426                	sd	s1,40(sp)
    80002c9a:	f04a                	sd	s2,32(sp)
    80002c9c:	ec4e                	sd	s3,24(sp)
    80002c9e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002ca0:	fcc40593          	addi	a1,s0,-52
    80002ca4:	4501                	li	a0,0
    80002ca6:	00000097          	auipc	ra,0x0
    80002caa:	e3e080e7          	jalr	-450(ra) # 80002ae4 <argint>
  acquire(&tickslock);
    80002cae:	00014517          	auipc	a0,0x14
    80002cb2:	ce250513          	addi	a0,a0,-798 # 80016990 <tickslock>
    80002cb6:	ffffe097          	auipc	ra,0xffffe
    80002cba:	f20080e7          	jalr	-224(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002cbe:	00006917          	auipc	s2,0x6
    80002cc2:	c3292903          	lw	s2,-974(s2) # 800088f0 <ticks>
  while(ticks - ticks0 < n){
    80002cc6:	fcc42783          	lw	a5,-52(s0)
    80002cca:	cf9d                	beqz	a5,80002d08 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ccc:	00014997          	auipc	s3,0x14
    80002cd0:	cc498993          	addi	s3,s3,-828 # 80016990 <tickslock>
    80002cd4:	00006497          	auipc	s1,0x6
    80002cd8:	c1c48493          	addi	s1,s1,-996 # 800088f0 <ticks>
    if(killed(myproc())){
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	cf2080e7          	jalr	-782(ra) # 800019ce <myproc>
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	63a080e7          	jalr	1594(ra) # 8000231e <killed>
    80002cec:	ed15                	bnez	a0,80002d28 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002cee:	85ce                	mv	a1,s3
    80002cf0:	8526                	mv	a0,s1
    80002cf2:	fffff097          	auipc	ra,0xfffff
    80002cf6:	384080e7          	jalr	900(ra) # 80002076 <sleep>
  while(ticks - ticks0 < n){
    80002cfa:	409c                	lw	a5,0(s1)
    80002cfc:	412787bb          	subw	a5,a5,s2
    80002d00:	fcc42703          	lw	a4,-52(s0)
    80002d04:	fce7ece3          	bltu	a5,a4,80002cdc <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d08:	00014517          	auipc	a0,0x14
    80002d0c:	c8850513          	addi	a0,a0,-888 # 80016990 <tickslock>
    80002d10:	ffffe097          	auipc	ra,0xffffe
    80002d14:	f7a080e7          	jalr	-134(ra) # 80000c8a <release>
  return 0;
    80002d18:	4501                	li	a0,0
}
    80002d1a:	70e2                	ld	ra,56(sp)
    80002d1c:	7442                	ld	s0,48(sp)
    80002d1e:	74a2                	ld	s1,40(sp)
    80002d20:	7902                	ld	s2,32(sp)
    80002d22:	69e2                	ld	s3,24(sp)
    80002d24:	6121                	addi	sp,sp,64
    80002d26:	8082                	ret
      release(&tickslock);
    80002d28:	00014517          	auipc	a0,0x14
    80002d2c:	c6850513          	addi	a0,a0,-920 # 80016990 <tickslock>
    80002d30:	ffffe097          	auipc	ra,0xffffe
    80002d34:	f5a080e7          	jalr	-166(ra) # 80000c8a <release>
      return -1;
    80002d38:	557d                	li	a0,-1
    80002d3a:	b7c5                	j	80002d1a <sys_sleep+0x88>

0000000080002d3c <sys_kill>:

uint64
sys_kill(void)
{
    80002d3c:	1101                	addi	sp,sp,-32
    80002d3e:	ec06                	sd	ra,24(sp)
    80002d40:	e822                	sd	s0,16(sp)
    80002d42:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002d44:	fec40593          	addi	a1,s0,-20
    80002d48:	4501                	li	a0,0
    80002d4a:	00000097          	auipc	ra,0x0
    80002d4e:	d9a080e7          	jalr	-614(ra) # 80002ae4 <argint>
  return kill(pid);
    80002d52:	fec42503          	lw	a0,-20(s0)
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	52a080e7          	jalr	1322(ra) # 80002280 <kill>
}
    80002d5e:	60e2                	ld	ra,24(sp)
    80002d60:	6442                	ld	s0,16(sp)
    80002d62:	6105                	addi	sp,sp,32
    80002d64:	8082                	ret

0000000080002d66 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d66:	1101                	addi	sp,sp,-32
    80002d68:	ec06                	sd	ra,24(sp)
    80002d6a:	e822                	sd	s0,16(sp)
    80002d6c:	e426                	sd	s1,8(sp)
    80002d6e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d70:	00014517          	auipc	a0,0x14
    80002d74:	c2050513          	addi	a0,a0,-992 # 80016990 <tickslock>
    80002d78:	ffffe097          	auipc	ra,0xffffe
    80002d7c:	e5e080e7          	jalr	-418(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002d80:	00006497          	auipc	s1,0x6
    80002d84:	b704a483          	lw	s1,-1168(s1) # 800088f0 <ticks>
  release(&tickslock);
    80002d88:	00014517          	auipc	a0,0x14
    80002d8c:	c0850513          	addi	a0,a0,-1016 # 80016990 <tickslock>
    80002d90:	ffffe097          	auipc	ra,0xffffe
    80002d94:	efa080e7          	jalr	-262(ra) # 80000c8a <release>
  return xticks;
}
    80002d98:	02049513          	slli	a0,s1,0x20
    80002d9c:	9101                	srli	a0,a0,0x20
    80002d9e:	60e2                	ld	ra,24(sp)
    80002da0:	6442                	ld	s0,16(sp)
    80002da2:	64a2                	ld	s1,8(sp)
    80002da4:	6105                	addi	sp,sp,32
    80002da6:	8082                	ret

0000000080002da8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002da8:	7179                	addi	sp,sp,-48
    80002daa:	f406                	sd	ra,40(sp)
    80002dac:	f022                	sd	s0,32(sp)
    80002dae:	ec26                	sd	s1,24(sp)
    80002db0:	e84a                	sd	s2,16(sp)
    80002db2:	e44e                	sd	s3,8(sp)
    80002db4:	e052                	sd	s4,0(sp)
    80002db6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002db8:	00005597          	auipc	a1,0x5
    80002dbc:	75858593          	addi	a1,a1,1880 # 80008510 <syscalls+0xb0>
    80002dc0:	00014517          	auipc	a0,0x14
    80002dc4:	be850513          	addi	a0,a0,-1048 # 800169a8 <bcache>
    80002dc8:	ffffe097          	auipc	ra,0xffffe
    80002dcc:	d7e080e7          	jalr	-642(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002dd0:	0001c797          	auipc	a5,0x1c
    80002dd4:	bd878793          	addi	a5,a5,-1064 # 8001e9a8 <bcache+0x8000>
    80002dd8:	0001c717          	auipc	a4,0x1c
    80002ddc:	e3870713          	addi	a4,a4,-456 # 8001ec10 <bcache+0x8268>
    80002de0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002de4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002de8:	00014497          	auipc	s1,0x14
    80002dec:	bd848493          	addi	s1,s1,-1064 # 800169c0 <bcache+0x18>
    b->next = bcache.head.next;
    80002df0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002df2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002df4:	00005a17          	auipc	s4,0x5
    80002df8:	724a0a13          	addi	s4,s4,1828 # 80008518 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002dfc:	2b893783          	ld	a5,696(s2)
    80002e00:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e02:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e06:	85d2                	mv	a1,s4
    80002e08:	01048513          	addi	a0,s1,16
    80002e0c:	00001097          	auipc	ra,0x1
    80002e10:	4c8080e7          	jalr	1224(ra) # 800042d4 <initsleeplock>
    bcache.head.next->prev = b;
    80002e14:	2b893783          	ld	a5,696(s2)
    80002e18:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e1a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e1e:	45848493          	addi	s1,s1,1112
    80002e22:	fd349de3          	bne	s1,s3,80002dfc <binit+0x54>
  }
}
    80002e26:	70a2                	ld	ra,40(sp)
    80002e28:	7402                	ld	s0,32(sp)
    80002e2a:	64e2                	ld	s1,24(sp)
    80002e2c:	6942                	ld	s2,16(sp)
    80002e2e:	69a2                	ld	s3,8(sp)
    80002e30:	6a02                	ld	s4,0(sp)
    80002e32:	6145                	addi	sp,sp,48
    80002e34:	8082                	ret

0000000080002e36 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e36:	7179                	addi	sp,sp,-48
    80002e38:	f406                	sd	ra,40(sp)
    80002e3a:	f022                	sd	s0,32(sp)
    80002e3c:	ec26                	sd	s1,24(sp)
    80002e3e:	e84a                	sd	s2,16(sp)
    80002e40:	e44e                	sd	s3,8(sp)
    80002e42:	1800                	addi	s0,sp,48
    80002e44:	892a                	mv	s2,a0
    80002e46:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002e48:	00014517          	auipc	a0,0x14
    80002e4c:	b6050513          	addi	a0,a0,-1184 # 800169a8 <bcache>
    80002e50:	ffffe097          	auipc	ra,0xffffe
    80002e54:	d86080e7          	jalr	-634(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e58:	0001c497          	auipc	s1,0x1c
    80002e5c:	e084b483          	ld	s1,-504(s1) # 8001ec60 <bcache+0x82b8>
    80002e60:	0001c797          	auipc	a5,0x1c
    80002e64:	db078793          	addi	a5,a5,-592 # 8001ec10 <bcache+0x8268>
    80002e68:	02f48f63          	beq	s1,a5,80002ea6 <bread+0x70>
    80002e6c:	873e                	mv	a4,a5
    80002e6e:	a021                	j	80002e76 <bread+0x40>
    80002e70:	68a4                	ld	s1,80(s1)
    80002e72:	02e48a63          	beq	s1,a4,80002ea6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e76:	449c                	lw	a5,8(s1)
    80002e78:	ff279ce3          	bne	a5,s2,80002e70 <bread+0x3a>
    80002e7c:	44dc                	lw	a5,12(s1)
    80002e7e:	ff3799e3          	bne	a5,s3,80002e70 <bread+0x3a>
      b->refcnt++;
    80002e82:	40bc                	lw	a5,64(s1)
    80002e84:	2785                	addiw	a5,a5,1
    80002e86:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e88:	00014517          	auipc	a0,0x14
    80002e8c:	b2050513          	addi	a0,a0,-1248 # 800169a8 <bcache>
    80002e90:	ffffe097          	auipc	ra,0xffffe
    80002e94:	dfa080e7          	jalr	-518(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002e98:	01048513          	addi	a0,s1,16
    80002e9c:	00001097          	auipc	ra,0x1
    80002ea0:	472080e7          	jalr	1138(ra) # 8000430e <acquiresleep>
      return b;
    80002ea4:	a8b9                	j	80002f02 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ea6:	0001c497          	auipc	s1,0x1c
    80002eaa:	db24b483          	ld	s1,-590(s1) # 8001ec58 <bcache+0x82b0>
    80002eae:	0001c797          	auipc	a5,0x1c
    80002eb2:	d6278793          	addi	a5,a5,-670 # 8001ec10 <bcache+0x8268>
    80002eb6:	00f48863          	beq	s1,a5,80002ec6 <bread+0x90>
    80002eba:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ebc:	40bc                	lw	a5,64(s1)
    80002ebe:	cf81                	beqz	a5,80002ed6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ec0:	64a4                	ld	s1,72(s1)
    80002ec2:	fee49de3          	bne	s1,a4,80002ebc <bread+0x86>
  panic("bget: no buffers");
    80002ec6:	00005517          	auipc	a0,0x5
    80002eca:	65a50513          	addi	a0,a0,1626 # 80008520 <syscalls+0xc0>
    80002ece:	ffffd097          	auipc	ra,0xffffd
    80002ed2:	672080e7          	jalr	1650(ra) # 80000540 <panic>
      b->dev = dev;
    80002ed6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002eda:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002ede:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ee2:	4785                	li	a5,1
    80002ee4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ee6:	00014517          	auipc	a0,0x14
    80002eea:	ac250513          	addi	a0,a0,-1342 # 800169a8 <bcache>
    80002eee:	ffffe097          	auipc	ra,0xffffe
    80002ef2:	d9c080e7          	jalr	-612(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002ef6:	01048513          	addi	a0,s1,16
    80002efa:	00001097          	auipc	ra,0x1
    80002efe:	414080e7          	jalr	1044(ra) # 8000430e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f02:	409c                	lw	a5,0(s1)
    80002f04:	cb89                	beqz	a5,80002f16 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f06:	8526                	mv	a0,s1
    80002f08:	70a2                	ld	ra,40(sp)
    80002f0a:	7402                	ld	s0,32(sp)
    80002f0c:	64e2                	ld	s1,24(sp)
    80002f0e:	6942                	ld	s2,16(sp)
    80002f10:	69a2                	ld	s3,8(sp)
    80002f12:	6145                	addi	sp,sp,48
    80002f14:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f16:	4581                	li	a1,0
    80002f18:	8526                	mv	a0,s1
    80002f1a:	00003097          	auipc	ra,0x3
    80002f1e:	fe8080e7          	jalr	-24(ra) # 80005f02 <virtio_disk_rw>
    b->valid = 1;
    80002f22:	4785                	li	a5,1
    80002f24:	c09c                	sw	a5,0(s1)
  return b;
    80002f26:	b7c5                	j	80002f06 <bread+0xd0>

0000000080002f28 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f28:	1101                	addi	sp,sp,-32
    80002f2a:	ec06                	sd	ra,24(sp)
    80002f2c:	e822                	sd	s0,16(sp)
    80002f2e:	e426                	sd	s1,8(sp)
    80002f30:	1000                	addi	s0,sp,32
    80002f32:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f34:	0541                	addi	a0,a0,16
    80002f36:	00001097          	auipc	ra,0x1
    80002f3a:	472080e7          	jalr	1138(ra) # 800043a8 <holdingsleep>
    80002f3e:	cd01                	beqz	a0,80002f56 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f40:	4585                	li	a1,1
    80002f42:	8526                	mv	a0,s1
    80002f44:	00003097          	auipc	ra,0x3
    80002f48:	fbe080e7          	jalr	-66(ra) # 80005f02 <virtio_disk_rw>
}
    80002f4c:	60e2                	ld	ra,24(sp)
    80002f4e:	6442                	ld	s0,16(sp)
    80002f50:	64a2                	ld	s1,8(sp)
    80002f52:	6105                	addi	sp,sp,32
    80002f54:	8082                	ret
    panic("bwrite");
    80002f56:	00005517          	auipc	a0,0x5
    80002f5a:	5e250513          	addi	a0,a0,1506 # 80008538 <syscalls+0xd8>
    80002f5e:	ffffd097          	auipc	ra,0xffffd
    80002f62:	5e2080e7          	jalr	1506(ra) # 80000540 <panic>

0000000080002f66 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f66:	1101                	addi	sp,sp,-32
    80002f68:	ec06                	sd	ra,24(sp)
    80002f6a:	e822                	sd	s0,16(sp)
    80002f6c:	e426                	sd	s1,8(sp)
    80002f6e:	e04a                	sd	s2,0(sp)
    80002f70:	1000                	addi	s0,sp,32
    80002f72:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f74:	01050913          	addi	s2,a0,16
    80002f78:	854a                	mv	a0,s2
    80002f7a:	00001097          	auipc	ra,0x1
    80002f7e:	42e080e7          	jalr	1070(ra) # 800043a8 <holdingsleep>
    80002f82:	c92d                	beqz	a0,80002ff4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f84:	854a                	mv	a0,s2
    80002f86:	00001097          	auipc	ra,0x1
    80002f8a:	3de080e7          	jalr	990(ra) # 80004364 <releasesleep>

  acquire(&bcache.lock);
    80002f8e:	00014517          	auipc	a0,0x14
    80002f92:	a1a50513          	addi	a0,a0,-1510 # 800169a8 <bcache>
    80002f96:	ffffe097          	auipc	ra,0xffffe
    80002f9a:	c40080e7          	jalr	-960(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80002f9e:	40bc                	lw	a5,64(s1)
    80002fa0:	37fd                	addiw	a5,a5,-1
    80002fa2:	0007871b          	sext.w	a4,a5
    80002fa6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002fa8:	eb05                	bnez	a4,80002fd8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002faa:	68bc                	ld	a5,80(s1)
    80002fac:	64b8                	ld	a4,72(s1)
    80002fae:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002fb0:	64bc                	ld	a5,72(s1)
    80002fb2:	68b8                	ld	a4,80(s1)
    80002fb4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002fb6:	0001c797          	auipc	a5,0x1c
    80002fba:	9f278793          	addi	a5,a5,-1550 # 8001e9a8 <bcache+0x8000>
    80002fbe:	2b87b703          	ld	a4,696(a5)
    80002fc2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002fc4:	0001c717          	auipc	a4,0x1c
    80002fc8:	c4c70713          	addi	a4,a4,-948 # 8001ec10 <bcache+0x8268>
    80002fcc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002fce:	2b87b703          	ld	a4,696(a5)
    80002fd2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002fd4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002fd8:	00014517          	auipc	a0,0x14
    80002fdc:	9d050513          	addi	a0,a0,-1584 # 800169a8 <bcache>
    80002fe0:	ffffe097          	auipc	ra,0xffffe
    80002fe4:	caa080e7          	jalr	-854(ra) # 80000c8a <release>
}
    80002fe8:	60e2                	ld	ra,24(sp)
    80002fea:	6442                	ld	s0,16(sp)
    80002fec:	64a2                	ld	s1,8(sp)
    80002fee:	6902                	ld	s2,0(sp)
    80002ff0:	6105                	addi	sp,sp,32
    80002ff2:	8082                	ret
    panic("brelse");
    80002ff4:	00005517          	auipc	a0,0x5
    80002ff8:	54c50513          	addi	a0,a0,1356 # 80008540 <syscalls+0xe0>
    80002ffc:	ffffd097          	auipc	ra,0xffffd
    80003000:	544080e7          	jalr	1348(ra) # 80000540 <panic>

0000000080003004 <bpin>:

void
bpin(struct buf *b) {
    80003004:	1101                	addi	sp,sp,-32
    80003006:	ec06                	sd	ra,24(sp)
    80003008:	e822                	sd	s0,16(sp)
    8000300a:	e426                	sd	s1,8(sp)
    8000300c:	1000                	addi	s0,sp,32
    8000300e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003010:	00014517          	auipc	a0,0x14
    80003014:	99850513          	addi	a0,a0,-1640 # 800169a8 <bcache>
    80003018:	ffffe097          	auipc	ra,0xffffe
    8000301c:	bbe080e7          	jalr	-1090(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003020:	40bc                	lw	a5,64(s1)
    80003022:	2785                	addiw	a5,a5,1
    80003024:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003026:	00014517          	auipc	a0,0x14
    8000302a:	98250513          	addi	a0,a0,-1662 # 800169a8 <bcache>
    8000302e:	ffffe097          	auipc	ra,0xffffe
    80003032:	c5c080e7          	jalr	-932(ra) # 80000c8a <release>
}
    80003036:	60e2                	ld	ra,24(sp)
    80003038:	6442                	ld	s0,16(sp)
    8000303a:	64a2                	ld	s1,8(sp)
    8000303c:	6105                	addi	sp,sp,32
    8000303e:	8082                	ret

0000000080003040 <bunpin>:

void
bunpin(struct buf *b) {
    80003040:	1101                	addi	sp,sp,-32
    80003042:	ec06                	sd	ra,24(sp)
    80003044:	e822                	sd	s0,16(sp)
    80003046:	e426                	sd	s1,8(sp)
    80003048:	1000                	addi	s0,sp,32
    8000304a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000304c:	00014517          	auipc	a0,0x14
    80003050:	95c50513          	addi	a0,a0,-1700 # 800169a8 <bcache>
    80003054:	ffffe097          	auipc	ra,0xffffe
    80003058:	b82080e7          	jalr	-1150(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000305c:	40bc                	lw	a5,64(s1)
    8000305e:	37fd                	addiw	a5,a5,-1
    80003060:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003062:	00014517          	auipc	a0,0x14
    80003066:	94650513          	addi	a0,a0,-1722 # 800169a8 <bcache>
    8000306a:	ffffe097          	auipc	ra,0xffffe
    8000306e:	c20080e7          	jalr	-992(ra) # 80000c8a <release>
}
    80003072:	60e2                	ld	ra,24(sp)
    80003074:	6442                	ld	s0,16(sp)
    80003076:	64a2                	ld	s1,8(sp)
    80003078:	6105                	addi	sp,sp,32
    8000307a:	8082                	ret

000000008000307c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000307c:	1101                	addi	sp,sp,-32
    8000307e:	ec06                	sd	ra,24(sp)
    80003080:	e822                	sd	s0,16(sp)
    80003082:	e426                	sd	s1,8(sp)
    80003084:	e04a                	sd	s2,0(sp)
    80003086:	1000                	addi	s0,sp,32
    80003088:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000308a:	00d5d59b          	srliw	a1,a1,0xd
    8000308e:	0001c797          	auipc	a5,0x1c
    80003092:	ff67a783          	lw	a5,-10(a5) # 8001f084 <sb+0x1c>
    80003096:	9dbd                	addw	a1,a1,a5
    80003098:	00000097          	auipc	ra,0x0
    8000309c:	d9e080e7          	jalr	-610(ra) # 80002e36 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030a0:	0074f713          	andi	a4,s1,7
    800030a4:	4785                	li	a5,1
    800030a6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030aa:	14ce                	slli	s1,s1,0x33
    800030ac:	90d9                	srli	s1,s1,0x36
    800030ae:	00950733          	add	a4,a0,s1
    800030b2:	05874703          	lbu	a4,88(a4)
    800030b6:	00e7f6b3          	and	a3,a5,a4
    800030ba:	c69d                	beqz	a3,800030e8 <bfree+0x6c>
    800030bc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030be:	94aa                	add	s1,s1,a0
    800030c0:	fff7c793          	not	a5,a5
    800030c4:	8f7d                	and	a4,a4,a5
    800030c6:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800030ca:	00001097          	auipc	ra,0x1
    800030ce:	126080e7          	jalr	294(ra) # 800041f0 <log_write>
  brelse(bp);
    800030d2:	854a                	mv	a0,s2
    800030d4:	00000097          	auipc	ra,0x0
    800030d8:	e92080e7          	jalr	-366(ra) # 80002f66 <brelse>
}
    800030dc:	60e2                	ld	ra,24(sp)
    800030de:	6442                	ld	s0,16(sp)
    800030e0:	64a2                	ld	s1,8(sp)
    800030e2:	6902                	ld	s2,0(sp)
    800030e4:	6105                	addi	sp,sp,32
    800030e6:	8082                	ret
    panic("freeing free block");
    800030e8:	00005517          	auipc	a0,0x5
    800030ec:	46050513          	addi	a0,a0,1120 # 80008548 <syscalls+0xe8>
    800030f0:	ffffd097          	auipc	ra,0xffffd
    800030f4:	450080e7          	jalr	1104(ra) # 80000540 <panic>

00000000800030f8 <balloc>:
{
    800030f8:	711d                	addi	sp,sp,-96
    800030fa:	ec86                	sd	ra,88(sp)
    800030fc:	e8a2                	sd	s0,80(sp)
    800030fe:	e4a6                	sd	s1,72(sp)
    80003100:	e0ca                	sd	s2,64(sp)
    80003102:	fc4e                	sd	s3,56(sp)
    80003104:	f852                	sd	s4,48(sp)
    80003106:	f456                	sd	s5,40(sp)
    80003108:	f05a                	sd	s6,32(sp)
    8000310a:	ec5e                	sd	s7,24(sp)
    8000310c:	e862                	sd	s8,16(sp)
    8000310e:	e466                	sd	s9,8(sp)
    80003110:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003112:	0001c797          	auipc	a5,0x1c
    80003116:	f5a7a783          	lw	a5,-166(a5) # 8001f06c <sb+0x4>
    8000311a:	cff5                	beqz	a5,80003216 <balloc+0x11e>
    8000311c:	8baa                	mv	s7,a0
    8000311e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003120:	0001cb17          	auipc	s6,0x1c
    80003124:	f48b0b13          	addi	s6,s6,-184 # 8001f068 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003128:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000312a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000312c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000312e:	6c89                	lui	s9,0x2
    80003130:	a061                	j	800031b8 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003132:	97ca                	add	a5,a5,s2
    80003134:	8e55                	or	a2,a2,a3
    80003136:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000313a:	854a                	mv	a0,s2
    8000313c:	00001097          	auipc	ra,0x1
    80003140:	0b4080e7          	jalr	180(ra) # 800041f0 <log_write>
        brelse(bp);
    80003144:	854a                	mv	a0,s2
    80003146:	00000097          	auipc	ra,0x0
    8000314a:	e20080e7          	jalr	-480(ra) # 80002f66 <brelse>
  bp = bread(dev, bno);
    8000314e:	85a6                	mv	a1,s1
    80003150:	855e                	mv	a0,s7
    80003152:	00000097          	auipc	ra,0x0
    80003156:	ce4080e7          	jalr	-796(ra) # 80002e36 <bread>
    8000315a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000315c:	40000613          	li	a2,1024
    80003160:	4581                	li	a1,0
    80003162:	05850513          	addi	a0,a0,88
    80003166:	ffffe097          	auipc	ra,0xffffe
    8000316a:	b6c080e7          	jalr	-1172(ra) # 80000cd2 <memset>
  log_write(bp);
    8000316e:	854a                	mv	a0,s2
    80003170:	00001097          	auipc	ra,0x1
    80003174:	080080e7          	jalr	128(ra) # 800041f0 <log_write>
  brelse(bp);
    80003178:	854a                	mv	a0,s2
    8000317a:	00000097          	auipc	ra,0x0
    8000317e:	dec080e7          	jalr	-532(ra) # 80002f66 <brelse>
}
    80003182:	8526                	mv	a0,s1
    80003184:	60e6                	ld	ra,88(sp)
    80003186:	6446                	ld	s0,80(sp)
    80003188:	64a6                	ld	s1,72(sp)
    8000318a:	6906                	ld	s2,64(sp)
    8000318c:	79e2                	ld	s3,56(sp)
    8000318e:	7a42                	ld	s4,48(sp)
    80003190:	7aa2                	ld	s5,40(sp)
    80003192:	7b02                	ld	s6,32(sp)
    80003194:	6be2                	ld	s7,24(sp)
    80003196:	6c42                	ld	s8,16(sp)
    80003198:	6ca2                	ld	s9,8(sp)
    8000319a:	6125                	addi	sp,sp,96
    8000319c:	8082                	ret
    brelse(bp);
    8000319e:	854a                	mv	a0,s2
    800031a0:	00000097          	auipc	ra,0x0
    800031a4:	dc6080e7          	jalr	-570(ra) # 80002f66 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031a8:	015c87bb          	addw	a5,s9,s5
    800031ac:	00078a9b          	sext.w	s5,a5
    800031b0:	004b2703          	lw	a4,4(s6)
    800031b4:	06eaf163          	bgeu	s5,a4,80003216 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800031b8:	41fad79b          	sraiw	a5,s5,0x1f
    800031bc:	0137d79b          	srliw	a5,a5,0x13
    800031c0:	015787bb          	addw	a5,a5,s5
    800031c4:	40d7d79b          	sraiw	a5,a5,0xd
    800031c8:	01cb2583          	lw	a1,28(s6)
    800031cc:	9dbd                	addw	a1,a1,a5
    800031ce:	855e                	mv	a0,s7
    800031d0:	00000097          	auipc	ra,0x0
    800031d4:	c66080e7          	jalr	-922(ra) # 80002e36 <bread>
    800031d8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031da:	004b2503          	lw	a0,4(s6)
    800031de:	000a849b          	sext.w	s1,s5
    800031e2:	8762                	mv	a4,s8
    800031e4:	faa4fde3          	bgeu	s1,a0,8000319e <balloc+0xa6>
      m = 1 << (bi % 8);
    800031e8:	00777693          	andi	a3,a4,7
    800031ec:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031f0:	41f7579b          	sraiw	a5,a4,0x1f
    800031f4:	01d7d79b          	srliw	a5,a5,0x1d
    800031f8:	9fb9                	addw	a5,a5,a4
    800031fa:	4037d79b          	sraiw	a5,a5,0x3
    800031fe:	00f90633          	add	a2,s2,a5
    80003202:	05864603          	lbu	a2,88(a2)
    80003206:	00c6f5b3          	and	a1,a3,a2
    8000320a:	d585                	beqz	a1,80003132 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000320c:	2705                	addiw	a4,a4,1
    8000320e:	2485                	addiw	s1,s1,1
    80003210:	fd471ae3          	bne	a4,s4,800031e4 <balloc+0xec>
    80003214:	b769                	j	8000319e <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003216:	00005517          	auipc	a0,0x5
    8000321a:	34a50513          	addi	a0,a0,842 # 80008560 <syscalls+0x100>
    8000321e:	ffffd097          	auipc	ra,0xffffd
    80003222:	36c080e7          	jalr	876(ra) # 8000058a <printf>
  return 0;
    80003226:	4481                	li	s1,0
    80003228:	bfa9                	j	80003182 <balloc+0x8a>

000000008000322a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000322a:	7179                	addi	sp,sp,-48
    8000322c:	f406                	sd	ra,40(sp)
    8000322e:	f022                	sd	s0,32(sp)
    80003230:	ec26                	sd	s1,24(sp)
    80003232:	e84a                	sd	s2,16(sp)
    80003234:	e44e                	sd	s3,8(sp)
    80003236:	e052                	sd	s4,0(sp)
    80003238:	1800                	addi	s0,sp,48
    8000323a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000323c:	47ad                	li	a5,11
    8000323e:	02b7e863          	bltu	a5,a1,8000326e <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003242:	02059793          	slli	a5,a1,0x20
    80003246:	01e7d593          	srli	a1,a5,0x1e
    8000324a:	00b504b3          	add	s1,a0,a1
    8000324e:	0504a903          	lw	s2,80(s1)
    80003252:	06091e63          	bnez	s2,800032ce <bmap+0xa4>
      addr = balloc(ip->dev);
    80003256:	4108                	lw	a0,0(a0)
    80003258:	00000097          	auipc	ra,0x0
    8000325c:	ea0080e7          	jalr	-352(ra) # 800030f8 <balloc>
    80003260:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003264:	06090563          	beqz	s2,800032ce <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003268:	0524a823          	sw	s2,80(s1)
    8000326c:	a08d                	j	800032ce <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000326e:	ff45849b          	addiw	s1,a1,-12
    80003272:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003276:	0ff00793          	li	a5,255
    8000327a:	08e7e563          	bltu	a5,a4,80003304 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000327e:	08052903          	lw	s2,128(a0)
    80003282:	00091d63          	bnez	s2,8000329c <bmap+0x72>
      addr = balloc(ip->dev);
    80003286:	4108                	lw	a0,0(a0)
    80003288:	00000097          	auipc	ra,0x0
    8000328c:	e70080e7          	jalr	-400(ra) # 800030f8 <balloc>
    80003290:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003294:	02090d63          	beqz	s2,800032ce <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003298:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000329c:	85ca                	mv	a1,s2
    8000329e:	0009a503          	lw	a0,0(s3)
    800032a2:	00000097          	auipc	ra,0x0
    800032a6:	b94080e7          	jalr	-1132(ra) # 80002e36 <bread>
    800032aa:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032ac:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032b0:	02049713          	slli	a4,s1,0x20
    800032b4:	01e75593          	srli	a1,a4,0x1e
    800032b8:	00b784b3          	add	s1,a5,a1
    800032bc:	0004a903          	lw	s2,0(s1)
    800032c0:	02090063          	beqz	s2,800032e0 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800032c4:	8552                	mv	a0,s4
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	ca0080e7          	jalr	-864(ra) # 80002f66 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032ce:	854a                	mv	a0,s2
    800032d0:	70a2                	ld	ra,40(sp)
    800032d2:	7402                	ld	s0,32(sp)
    800032d4:	64e2                	ld	s1,24(sp)
    800032d6:	6942                	ld	s2,16(sp)
    800032d8:	69a2                	ld	s3,8(sp)
    800032da:	6a02                	ld	s4,0(sp)
    800032dc:	6145                	addi	sp,sp,48
    800032de:	8082                	ret
      addr = balloc(ip->dev);
    800032e0:	0009a503          	lw	a0,0(s3)
    800032e4:	00000097          	auipc	ra,0x0
    800032e8:	e14080e7          	jalr	-492(ra) # 800030f8 <balloc>
    800032ec:	0005091b          	sext.w	s2,a0
      if(addr){
    800032f0:	fc090ae3          	beqz	s2,800032c4 <bmap+0x9a>
        a[bn] = addr;
    800032f4:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800032f8:	8552                	mv	a0,s4
    800032fa:	00001097          	auipc	ra,0x1
    800032fe:	ef6080e7          	jalr	-266(ra) # 800041f0 <log_write>
    80003302:	b7c9                	j	800032c4 <bmap+0x9a>
  panic("bmap: out of range");
    80003304:	00005517          	auipc	a0,0x5
    80003308:	27450513          	addi	a0,a0,628 # 80008578 <syscalls+0x118>
    8000330c:	ffffd097          	auipc	ra,0xffffd
    80003310:	234080e7          	jalr	564(ra) # 80000540 <panic>

0000000080003314 <iget>:
{
    80003314:	7179                	addi	sp,sp,-48
    80003316:	f406                	sd	ra,40(sp)
    80003318:	f022                	sd	s0,32(sp)
    8000331a:	ec26                	sd	s1,24(sp)
    8000331c:	e84a                	sd	s2,16(sp)
    8000331e:	e44e                	sd	s3,8(sp)
    80003320:	e052                	sd	s4,0(sp)
    80003322:	1800                	addi	s0,sp,48
    80003324:	89aa                	mv	s3,a0
    80003326:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003328:	0001c517          	auipc	a0,0x1c
    8000332c:	d6050513          	addi	a0,a0,-672 # 8001f088 <itable>
    80003330:	ffffe097          	auipc	ra,0xffffe
    80003334:	8a6080e7          	jalr	-1882(ra) # 80000bd6 <acquire>
  empty = 0;
    80003338:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000333a:	0001c497          	auipc	s1,0x1c
    8000333e:	d6648493          	addi	s1,s1,-666 # 8001f0a0 <itable+0x18>
    80003342:	0001d697          	auipc	a3,0x1d
    80003346:	7ee68693          	addi	a3,a3,2030 # 80020b30 <log>
    8000334a:	a039                	j	80003358 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000334c:	02090b63          	beqz	s2,80003382 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003350:	08848493          	addi	s1,s1,136
    80003354:	02d48a63          	beq	s1,a3,80003388 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003358:	449c                	lw	a5,8(s1)
    8000335a:	fef059e3          	blez	a5,8000334c <iget+0x38>
    8000335e:	4098                	lw	a4,0(s1)
    80003360:	ff3716e3          	bne	a4,s3,8000334c <iget+0x38>
    80003364:	40d8                	lw	a4,4(s1)
    80003366:	ff4713e3          	bne	a4,s4,8000334c <iget+0x38>
      ip->ref++;
    8000336a:	2785                	addiw	a5,a5,1
    8000336c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000336e:	0001c517          	auipc	a0,0x1c
    80003372:	d1a50513          	addi	a0,a0,-742 # 8001f088 <itable>
    80003376:	ffffe097          	auipc	ra,0xffffe
    8000337a:	914080e7          	jalr	-1772(ra) # 80000c8a <release>
      return ip;
    8000337e:	8926                	mv	s2,s1
    80003380:	a03d                	j	800033ae <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003382:	f7f9                	bnez	a5,80003350 <iget+0x3c>
    80003384:	8926                	mv	s2,s1
    80003386:	b7e9                	j	80003350 <iget+0x3c>
  if(empty == 0)
    80003388:	02090c63          	beqz	s2,800033c0 <iget+0xac>
  ip->dev = dev;
    8000338c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003390:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003394:	4785                	li	a5,1
    80003396:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000339a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000339e:	0001c517          	auipc	a0,0x1c
    800033a2:	cea50513          	addi	a0,a0,-790 # 8001f088 <itable>
    800033a6:	ffffe097          	auipc	ra,0xffffe
    800033aa:	8e4080e7          	jalr	-1820(ra) # 80000c8a <release>
}
    800033ae:	854a                	mv	a0,s2
    800033b0:	70a2                	ld	ra,40(sp)
    800033b2:	7402                	ld	s0,32(sp)
    800033b4:	64e2                	ld	s1,24(sp)
    800033b6:	6942                	ld	s2,16(sp)
    800033b8:	69a2                	ld	s3,8(sp)
    800033ba:	6a02                	ld	s4,0(sp)
    800033bc:	6145                	addi	sp,sp,48
    800033be:	8082                	ret
    panic("iget: no inodes");
    800033c0:	00005517          	auipc	a0,0x5
    800033c4:	1d050513          	addi	a0,a0,464 # 80008590 <syscalls+0x130>
    800033c8:	ffffd097          	auipc	ra,0xffffd
    800033cc:	178080e7          	jalr	376(ra) # 80000540 <panic>

00000000800033d0 <fsinit>:
fsinit(int dev) {
    800033d0:	7179                	addi	sp,sp,-48
    800033d2:	f406                	sd	ra,40(sp)
    800033d4:	f022                	sd	s0,32(sp)
    800033d6:	ec26                	sd	s1,24(sp)
    800033d8:	e84a                	sd	s2,16(sp)
    800033da:	e44e                	sd	s3,8(sp)
    800033dc:	1800                	addi	s0,sp,48
    800033de:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033e0:	4585                	li	a1,1
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	a54080e7          	jalr	-1452(ra) # 80002e36 <bread>
    800033ea:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033ec:	0001c997          	auipc	s3,0x1c
    800033f0:	c7c98993          	addi	s3,s3,-900 # 8001f068 <sb>
    800033f4:	02000613          	li	a2,32
    800033f8:	05850593          	addi	a1,a0,88
    800033fc:	854e                	mv	a0,s3
    800033fe:	ffffe097          	auipc	ra,0xffffe
    80003402:	930080e7          	jalr	-1744(ra) # 80000d2e <memmove>
  brelse(bp);
    80003406:	8526                	mv	a0,s1
    80003408:	00000097          	auipc	ra,0x0
    8000340c:	b5e080e7          	jalr	-1186(ra) # 80002f66 <brelse>
  if(sb.magic != FSMAGIC)
    80003410:	0009a703          	lw	a4,0(s3)
    80003414:	102037b7          	lui	a5,0x10203
    80003418:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000341c:	02f71263          	bne	a4,a5,80003440 <fsinit+0x70>
  initlog(dev, &sb);
    80003420:	0001c597          	auipc	a1,0x1c
    80003424:	c4858593          	addi	a1,a1,-952 # 8001f068 <sb>
    80003428:	854a                	mv	a0,s2
    8000342a:	00001097          	auipc	ra,0x1
    8000342e:	b4a080e7          	jalr	-1206(ra) # 80003f74 <initlog>
}
    80003432:	70a2                	ld	ra,40(sp)
    80003434:	7402                	ld	s0,32(sp)
    80003436:	64e2                	ld	s1,24(sp)
    80003438:	6942                	ld	s2,16(sp)
    8000343a:	69a2                	ld	s3,8(sp)
    8000343c:	6145                	addi	sp,sp,48
    8000343e:	8082                	ret
    panic("invalid file system");
    80003440:	00005517          	auipc	a0,0x5
    80003444:	16050513          	addi	a0,a0,352 # 800085a0 <syscalls+0x140>
    80003448:	ffffd097          	auipc	ra,0xffffd
    8000344c:	0f8080e7          	jalr	248(ra) # 80000540 <panic>

0000000080003450 <iinit>:
{
    80003450:	7179                	addi	sp,sp,-48
    80003452:	f406                	sd	ra,40(sp)
    80003454:	f022                	sd	s0,32(sp)
    80003456:	ec26                	sd	s1,24(sp)
    80003458:	e84a                	sd	s2,16(sp)
    8000345a:	e44e                	sd	s3,8(sp)
    8000345c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000345e:	00005597          	auipc	a1,0x5
    80003462:	15a58593          	addi	a1,a1,346 # 800085b8 <syscalls+0x158>
    80003466:	0001c517          	auipc	a0,0x1c
    8000346a:	c2250513          	addi	a0,a0,-990 # 8001f088 <itable>
    8000346e:	ffffd097          	auipc	ra,0xffffd
    80003472:	6d8080e7          	jalr	1752(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003476:	0001c497          	auipc	s1,0x1c
    8000347a:	c3a48493          	addi	s1,s1,-966 # 8001f0b0 <itable+0x28>
    8000347e:	0001d997          	auipc	s3,0x1d
    80003482:	6c298993          	addi	s3,s3,1730 # 80020b40 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003486:	00005917          	auipc	s2,0x5
    8000348a:	13a90913          	addi	s2,s2,314 # 800085c0 <syscalls+0x160>
    8000348e:	85ca                	mv	a1,s2
    80003490:	8526                	mv	a0,s1
    80003492:	00001097          	auipc	ra,0x1
    80003496:	e42080e7          	jalr	-446(ra) # 800042d4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000349a:	08848493          	addi	s1,s1,136
    8000349e:	ff3498e3          	bne	s1,s3,8000348e <iinit+0x3e>
}
    800034a2:	70a2                	ld	ra,40(sp)
    800034a4:	7402                	ld	s0,32(sp)
    800034a6:	64e2                	ld	s1,24(sp)
    800034a8:	6942                	ld	s2,16(sp)
    800034aa:	69a2                	ld	s3,8(sp)
    800034ac:	6145                	addi	sp,sp,48
    800034ae:	8082                	ret

00000000800034b0 <ialloc>:
{
    800034b0:	715d                	addi	sp,sp,-80
    800034b2:	e486                	sd	ra,72(sp)
    800034b4:	e0a2                	sd	s0,64(sp)
    800034b6:	fc26                	sd	s1,56(sp)
    800034b8:	f84a                	sd	s2,48(sp)
    800034ba:	f44e                	sd	s3,40(sp)
    800034bc:	f052                	sd	s4,32(sp)
    800034be:	ec56                	sd	s5,24(sp)
    800034c0:	e85a                	sd	s6,16(sp)
    800034c2:	e45e                	sd	s7,8(sp)
    800034c4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800034c6:	0001c717          	auipc	a4,0x1c
    800034ca:	bae72703          	lw	a4,-1106(a4) # 8001f074 <sb+0xc>
    800034ce:	4785                	li	a5,1
    800034d0:	04e7fa63          	bgeu	a5,a4,80003524 <ialloc+0x74>
    800034d4:	8aaa                	mv	s5,a0
    800034d6:	8bae                	mv	s7,a1
    800034d8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034da:	0001ca17          	auipc	s4,0x1c
    800034de:	b8ea0a13          	addi	s4,s4,-1138 # 8001f068 <sb>
    800034e2:	00048b1b          	sext.w	s6,s1
    800034e6:	0044d593          	srli	a1,s1,0x4
    800034ea:	018a2783          	lw	a5,24(s4)
    800034ee:	9dbd                	addw	a1,a1,a5
    800034f0:	8556                	mv	a0,s5
    800034f2:	00000097          	auipc	ra,0x0
    800034f6:	944080e7          	jalr	-1724(ra) # 80002e36 <bread>
    800034fa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034fc:	05850993          	addi	s3,a0,88
    80003500:	00f4f793          	andi	a5,s1,15
    80003504:	079a                	slli	a5,a5,0x6
    80003506:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003508:	00099783          	lh	a5,0(s3)
    8000350c:	c3a1                	beqz	a5,8000354c <ialloc+0x9c>
    brelse(bp);
    8000350e:	00000097          	auipc	ra,0x0
    80003512:	a58080e7          	jalr	-1448(ra) # 80002f66 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003516:	0485                	addi	s1,s1,1
    80003518:	00ca2703          	lw	a4,12(s4)
    8000351c:	0004879b          	sext.w	a5,s1
    80003520:	fce7e1e3          	bltu	a5,a4,800034e2 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003524:	00005517          	auipc	a0,0x5
    80003528:	0a450513          	addi	a0,a0,164 # 800085c8 <syscalls+0x168>
    8000352c:	ffffd097          	auipc	ra,0xffffd
    80003530:	05e080e7          	jalr	94(ra) # 8000058a <printf>
  return 0;
    80003534:	4501                	li	a0,0
}
    80003536:	60a6                	ld	ra,72(sp)
    80003538:	6406                	ld	s0,64(sp)
    8000353a:	74e2                	ld	s1,56(sp)
    8000353c:	7942                	ld	s2,48(sp)
    8000353e:	79a2                	ld	s3,40(sp)
    80003540:	7a02                	ld	s4,32(sp)
    80003542:	6ae2                	ld	s5,24(sp)
    80003544:	6b42                	ld	s6,16(sp)
    80003546:	6ba2                	ld	s7,8(sp)
    80003548:	6161                	addi	sp,sp,80
    8000354a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000354c:	04000613          	li	a2,64
    80003550:	4581                	li	a1,0
    80003552:	854e                	mv	a0,s3
    80003554:	ffffd097          	auipc	ra,0xffffd
    80003558:	77e080e7          	jalr	1918(ra) # 80000cd2 <memset>
      dip->type = type;
    8000355c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003560:	854a                	mv	a0,s2
    80003562:	00001097          	auipc	ra,0x1
    80003566:	c8e080e7          	jalr	-882(ra) # 800041f0 <log_write>
      brelse(bp);
    8000356a:	854a                	mv	a0,s2
    8000356c:	00000097          	auipc	ra,0x0
    80003570:	9fa080e7          	jalr	-1542(ra) # 80002f66 <brelse>
      return iget(dev, inum);
    80003574:	85da                	mv	a1,s6
    80003576:	8556                	mv	a0,s5
    80003578:	00000097          	auipc	ra,0x0
    8000357c:	d9c080e7          	jalr	-612(ra) # 80003314 <iget>
    80003580:	bf5d                	j	80003536 <ialloc+0x86>

0000000080003582 <iupdate>:
{
    80003582:	1101                	addi	sp,sp,-32
    80003584:	ec06                	sd	ra,24(sp)
    80003586:	e822                	sd	s0,16(sp)
    80003588:	e426                	sd	s1,8(sp)
    8000358a:	e04a                	sd	s2,0(sp)
    8000358c:	1000                	addi	s0,sp,32
    8000358e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003590:	415c                	lw	a5,4(a0)
    80003592:	0047d79b          	srliw	a5,a5,0x4
    80003596:	0001c597          	auipc	a1,0x1c
    8000359a:	aea5a583          	lw	a1,-1302(a1) # 8001f080 <sb+0x18>
    8000359e:	9dbd                	addw	a1,a1,a5
    800035a0:	4108                	lw	a0,0(a0)
    800035a2:	00000097          	auipc	ra,0x0
    800035a6:	894080e7          	jalr	-1900(ra) # 80002e36 <bread>
    800035aa:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035ac:	05850793          	addi	a5,a0,88
    800035b0:	40d8                	lw	a4,4(s1)
    800035b2:	8b3d                	andi	a4,a4,15
    800035b4:	071a                	slli	a4,a4,0x6
    800035b6:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800035b8:	04449703          	lh	a4,68(s1)
    800035bc:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800035c0:	04649703          	lh	a4,70(s1)
    800035c4:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800035c8:	04849703          	lh	a4,72(s1)
    800035cc:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800035d0:	04a49703          	lh	a4,74(s1)
    800035d4:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800035d8:	44f8                	lw	a4,76(s1)
    800035da:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035dc:	03400613          	li	a2,52
    800035e0:	05048593          	addi	a1,s1,80
    800035e4:	00c78513          	addi	a0,a5,12
    800035e8:	ffffd097          	auipc	ra,0xffffd
    800035ec:	746080e7          	jalr	1862(ra) # 80000d2e <memmove>
  log_write(bp);
    800035f0:	854a                	mv	a0,s2
    800035f2:	00001097          	auipc	ra,0x1
    800035f6:	bfe080e7          	jalr	-1026(ra) # 800041f0 <log_write>
  brelse(bp);
    800035fa:	854a                	mv	a0,s2
    800035fc:	00000097          	auipc	ra,0x0
    80003600:	96a080e7          	jalr	-1686(ra) # 80002f66 <brelse>
}
    80003604:	60e2                	ld	ra,24(sp)
    80003606:	6442                	ld	s0,16(sp)
    80003608:	64a2                	ld	s1,8(sp)
    8000360a:	6902                	ld	s2,0(sp)
    8000360c:	6105                	addi	sp,sp,32
    8000360e:	8082                	ret

0000000080003610 <idup>:
{
    80003610:	1101                	addi	sp,sp,-32
    80003612:	ec06                	sd	ra,24(sp)
    80003614:	e822                	sd	s0,16(sp)
    80003616:	e426                	sd	s1,8(sp)
    80003618:	1000                	addi	s0,sp,32
    8000361a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000361c:	0001c517          	auipc	a0,0x1c
    80003620:	a6c50513          	addi	a0,a0,-1428 # 8001f088 <itable>
    80003624:	ffffd097          	auipc	ra,0xffffd
    80003628:	5b2080e7          	jalr	1458(ra) # 80000bd6 <acquire>
  ip->ref++;
    8000362c:	449c                	lw	a5,8(s1)
    8000362e:	2785                	addiw	a5,a5,1
    80003630:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003632:	0001c517          	auipc	a0,0x1c
    80003636:	a5650513          	addi	a0,a0,-1450 # 8001f088 <itable>
    8000363a:	ffffd097          	auipc	ra,0xffffd
    8000363e:	650080e7          	jalr	1616(ra) # 80000c8a <release>
}
    80003642:	8526                	mv	a0,s1
    80003644:	60e2                	ld	ra,24(sp)
    80003646:	6442                	ld	s0,16(sp)
    80003648:	64a2                	ld	s1,8(sp)
    8000364a:	6105                	addi	sp,sp,32
    8000364c:	8082                	ret

000000008000364e <ilock>:
{
    8000364e:	1101                	addi	sp,sp,-32
    80003650:	ec06                	sd	ra,24(sp)
    80003652:	e822                	sd	s0,16(sp)
    80003654:	e426                	sd	s1,8(sp)
    80003656:	e04a                	sd	s2,0(sp)
    80003658:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000365a:	c115                	beqz	a0,8000367e <ilock+0x30>
    8000365c:	84aa                	mv	s1,a0
    8000365e:	451c                	lw	a5,8(a0)
    80003660:	00f05f63          	blez	a5,8000367e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003664:	0541                	addi	a0,a0,16
    80003666:	00001097          	auipc	ra,0x1
    8000366a:	ca8080e7          	jalr	-856(ra) # 8000430e <acquiresleep>
  if(ip->valid == 0){
    8000366e:	40bc                	lw	a5,64(s1)
    80003670:	cf99                	beqz	a5,8000368e <ilock+0x40>
}
    80003672:	60e2                	ld	ra,24(sp)
    80003674:	6442                	ld	s0,16(sp)
    80003676:	64a2                	ld	s1,8(sp)
    80003678:	6902                	ld	s2,0(sp)
    8000367a:	6105                	addi	sp,sp,32
    8000367c:	8082                	ret
    panic("ilock");
    8000367e:	00005517          	auipc	a0,0x5
    80003682:	f6250513          	addi	a0,a0,-158 # 800085e0 <syscalls+0x180>
    80003686:	ffffd097          	auipc	ra,0xffffd
    8000368a:	eba080e7          	jalr	-326(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000368e:	40dc                	lw	a5,4(s1)
    80003690:	0047d79b          	srliw	a5,a5,0x4
    80003694:	0001c597          	auipc	a1,0x1c
    80003698:	9ec5a583          	lw	a1,-1556(a1) # 8001f080 <sb+0x18>
    8000369c:	9dbd                	addw	a1,a1,a5
    8000369e:	4088                	lw	a0,0(s1)
    800036a0:	fffff097          	auipc	ra,0xfffff
    800036a4:	796080e7          	jalr	1942(ra) # 80002e36 <bread>
    800036a8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036aa:	05850593          	addi	a1,a0,88
    800036ae:	40dc                	lw	a5,4(s1)
    800036b0:	8bbd                	andi	a5,a5,15
    800036b2:	079a                	slli	a5,a5,0x6
    800036b4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036b6:	00059783          	lh	a5,0(a1)
    800036ba:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800036be:	00259783          	lh	a5,2(a1)
    800036c2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800036c6:	00459783          	lh	a5,4(a1)
    800036ca:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036ce:	00659783          	lh	a5,6(a1)
    800036d2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036d6:	459c                	lw	a5,8(a1)
    800036d8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036da:	03400613          	li	a2,52
    800036de:	05b1                	addi	a1,a1,12
    800036e0:	05048513          	addi	a0,s1,80
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	64a080e7          	jalr	1610(ra) # 80000d2e <memmove>
    brelse(bp);
    800036ec:	854a                	mv	a0,s2
    800036ee:	00000097          	auipc	ra,0x0
    800036f2:	878080e7          	jalr	-1928(ra) # 80002f66 <brelse>
    ip->valid = 1;
    800036f6:	4785                	li	a5,1
    800036f8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036fa:	04449783          	lh	a5,68(s1)
    800036fe:	fbb5                	bnez	a5,80003672 <ilock+0x24>
      panic("ilock: no type");
    80003700:	00005517          	auipc	a0,0x5
    80003704:	ee850513          	addi	a0,a0,-280 # 800085e8 <syscalls+0x188>
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	e38080e7          	jalr	-456(ra) # 80000540 <panic>

0000000080003710 <iunlock>:
{
    80003710:	1101                	addi	sp,sp,-32
    80003712:	ec06                	sd	ra,24(sp)
    80003714:	e822                	sd	s0,16(sp)
    80003716:	e426                	sd	s1,8(sp)
    80003718:	e04a                	sd	s2,0(sp)
    8000371a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000371c:	c905                	beqz	a0,8000374c <iunlock+0x3c>
    8000371e:	84aa                	mv	s1,a0
    80003720:	01050913          	addi	s2,a0,16
    80003724:	854a                	mv	a0,s2
    80003726:	00001097          	auipc	ra,0x1
    8000372a:	c82080e7          	jalr	-894(ra) # 800043a8 <holdingsleep>
    8000372e:	cd19                	beqz	a0,8000374c <iunlock+0x3c>
    80003730:	449c                	lw	a5,8(s1)
    80003732:	00f05d63          	blez	a5,8000374c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003736:	854a                	mv	a0,s2
    80003738:	00001097          	auipc	ra,0x1
    8000373c:	c2c080e7          	jalr	-980(ra) # 80004364 <releasesleep>
}
    80003740:	60e2                	ld	ra,24(sp)
    80003742:	6442                	ld	s0,16(sp)
    80003744:	64a2                	ld	s1,8(sp)
    80003746:	6902                	ld	s2,0(sp)
    80003748:	6105                	addi	sp,sp,32
    8000374a:	8082                	ret
    panic("iunlock");
    8000374c:	00005517          	auipc	a0,0x5
    80003750:	eac50513          	addi	a0,a0,-340 # 800085f8 <syscalls+0x198>
    80003754:	ffffd097          	auipc	ra,0xffffd
    80003758:	dec080e7          	jalr	-532(ra) # 80000540 <panic>

000000008000375c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000375c:	7179                	addi	sp,sp,-48
    8000375e:	f406                	sd	ra,40(sp)
    80003760:	f022                	sd	s0,32(sp)
    80003762:	ec26                	sd	s1,24(sp)
    80003764:	e84a                	sd	s2,16(sp)
    80003766:	e44e                	sd	s3,8(sp)
    80003768:	e052                	sd	s4,0(sp)
    8000376a:	1800                	addi	s0,sp,48
    8000376c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000376e:	05050493          	addi	s1,a0,80
    80003772:	08050913          	addi	s2,a0,128
    80003776:	a021                	j	8000377e <itrunc+0x22>
    80003778:	0491                	addi	s1,s1,4
    8000377a:	01248d63          	beq	s1,s2,80003794 <itrunc+0x38>
    if(ip->addrs[i]){
    8000377e:	408c                	lw	a1,0(s1)
    80003780:	dde5                	beqz	a1,80003778 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003782:	0009a503          	lw	a0,0(s3)
    80003786:	00000097          	auipc	ra,0x0
    8000378a:	8f6080e7          	jalr	-1802(ra) # 8000307c <bfree>
      ip->addrs[i] = 0;
    8000378e:	0004a023          	sw	zero,0(s1)
    80003792:	b7dd                	j	80003778 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003794:	0809a583          	lw	a1,128(s3)
    80003798:	e185                	bnez	a1,800037b8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000379a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000379e:	854e                	mv	a0,s3
    800037a0:	00000097          	auipc	ra,0x0
    800037a4:	de2080e7          	jalr	-542(ra) # 80003582 <iupdate>
}
    800037a8:	70a2                	ld	ra,40(sp)
    800037aa:	7402                	ld	s0,32(sp)
    800037ac:	64e2                	ld	s1,24(sp)
    800037ae:	6942                	ld	s2,16(sp)
    800037b0:	69a2                	ld	s3,8(sp)
    800037b2:	6a02                	ld	s4,0(sp)
    800037b4:	6145                	addi	sp,sp,48
    800037b6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037b8:	0009a503          	lw	a0,0(s3)
    800037bc:	fffff097          	auipc	ra,0xfffff
    800037c0:	67a080e7          	jalr	1658(ra) # 80002e36 <bread>
    800037c4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800037c6:	05850493          	addi	s1,a0,88
    800037ca:	45850913          	addi	s2,a0,1112
    800037ce:	a021                	j	800037d6 <itrunc+0x7a>
    800037d0:	0491                	addi	s1,s1,4
    800037d2:	01248b63          	beq	s1,s2,800037e8 <itrunc+0x8c>
      if(a[j])
    800037d6:	408c                	lw	a1,0(s1)
    800037d8:	dde5                	beqz	a1,800037d0 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800037da:	0009a503          	lw	a0,0(s3)
    800037de:	00000097          	auipc	ra,0x0
    800037e2:	89e080e7          	jalr	-1890(ra) # 8000307c <bfree>
    800037e6:	b7ed                	j	800037d0 <itrunc+0x74>
    brelse(bp);
    800037e8:	8552                	mv	a0,s4
    800037ea:	fffff097          	auipc	ra,0xfffff
    800037ee:	77c080e7          	jalr	1916(ra) # 80002f66 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037f2:	0809a583          	lw	a1,128(s3)
    800037f6:	0009a503          	lw	a0,0(s3)
    800037fa:	00000097          	auipc	ra,0x0
    800037fe:	882080e7          	jalr	-1918(ra) # 8000307c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003802:	0809a023          	sw	zero,128(s3)
    80003806:	bf51                	j	8000379a <itrunc+0x3e>

0000000080003808 <iput>:
{
    80003808:	1101                	addi	sp,sp,-32
    8000380a:	ec06                	sd	ra,24(sp)
    8000380c:	e822                	sd	s0,16(sp)
    8000380e:	e426                	sd	s1,8(sp)
    80003810:	e04a                	sd	s2,0(sp)
    80003812:	1000                	addi	s0,sp,32
    80003814:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003816:	0001c517          	auipc	a0,0x1c
    8000381a:	87250513          	addi	a0,a0,-1934 # 8001f088 <itable>
    8000381e:	ffffd097          	auipc	ra,0xffffd
    80003822:	3b8080e7          	jalr	952(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003826:	4498                	lw	a4,8(s1)
    80003828:	4785                	li	a5,1
    8000382a:	02f70363          	beq	a4,a5,80003850 <iput+0x48>
  ip->ref--;
    8000382e:	449c                	lw	a5,8(s1)
    80003830:	37fd                	addiw	a5,a5,-1
    80003832:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003834:	0001c517          	auipc	a0,0x1c
    80003838:	85450513          	addi	a0,a0,-1964 # 8001f088 <itable>
    8000383c:	ffffd097          	auipc	ra,0xffffd
    80003840:	44e080e7          	jalr	1102(ra) # 80000c8a <release>
}
    80003844:	60e2                	ld	ra,24(sp)
    80003846:	6442                	ld	s0,16(sp)
    80003848:	64a2                	ld	s1,8(sp)
    8000384a:	6902                	ld	s2,0(sp)
    8000384c:	6105                	addi	sp,sp,32
    8000384e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003850:	40bc                	lw	a5,64(s1)
    80003852:	dff1                	beqz	a5,8000382e <iput+0x26>
    80003854:	04a49783          	lh	a5,74(s1)
    80003858:	fbf9                	bnez	a5,8000382e <iput+0x26>
    acquiresleep(&ip->lock);
    8000385a:	01048913          	addi	s2,s1,16
    8000385e:	854a                	mv	a0,s2
    80003860:	00001097          	auipc	ra,0x1
    80003864:	aae080e7          	jalr	-1362(ra) # 8000430e <acquiresleep>
    release(&itable.lock);
    80003868:	0001c517          	auipc	a0,0x1c
    8000386c:	82050513          	addi	a0,a0,-2016 # 8001f088 <itable>
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	41a080e7          	jalr	1050(ra) # 80000c8a <release>
    itrunc(ip);
    80003878:	8526                	mv	a0,s1
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	ee2080e7          	jalr	-286(ra) # 8000375c <itrunc>
    ip->type = 0;
    80003882:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003886:	8526                	mv	a0,s1
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	cfa080e7          	jalr	-774(ra) # 80003582 <iupdate>
    ip->valid = 0;
    80003890:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003894:	854a                	mv	a0,s2
    80003896:	00001097          	auipc	ra,0x1
    8000389a:	ace080e7          	jalr	-1330(ra) # 80004364 <releasesleep>
    acquire(&itable.lock);
    8000389e:	0001b517          	auipc	a0,0x1b
    800038a2:	7ea50513          	addi	a0,a0,2026 # 8001f088 <itable>
    800038a6:	ffffd097          	auipc	ra,0xffffd
    800038aa:	330080e7          	jalr	816(ra) # 80000bd6 <acquire>
    800038ae:	b741                	j	8000382e <iput+0x26>

00000000800038b0 <iunlockput>:
{
    800038b0:	1101                	addi	sp,sp,-32
    800038b2:	ec06                	sd	ra,24(sp)
    800038b4:	e822                	sd	s0,16(sp)
    800038b6:	e426                	sd	s1,8(sp)
    800038b8:	1000                	addi	s0,sp,32
    800038ba:	84aa                	mv	s1,a0
  iunlock(ip);
    800038bc:	00000097          	auipc	ra,0x0
    800038c0:	e54080e7          	jalr	-428(ra) # 80003710 <iunlock>
  iput(ip);
    800038c4:	8526                	mv	a0,s1
    800038c6:	00000097          	auipc	ra,0x0
    800038ca:	f42080e7          	jalr	-190(ra) # 80003808 <iput>
}
    800038ce:	60e2                	ld	ra,24(sp)
    800038d0:	6442                	ld	s0,16(sp)
    800038d2:	64a2                	ld	s1,8(sp)
    800038d4:	6105                	addi	sp,sp,32
    800038d6:	8082                	ret

00000000800038d8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038d8:	1141                	addi	sp,sp,-16
    800038da:	e422                	sd	s0,8(sp)
    800038dc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800038de:	411c                	lw	a5,0(a0)
    800038e0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038e2:	415c                	lw	a5,4(a0)
    800038e4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038e6:	04451783          	lh	a5,68(a0)
    800038ea:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038ee:	04a51783          	lh	a5,74(a0)
    800038f2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038f6:	04c56783          	lwu	a5,76(a0)
    800038fa:	e99c                	sd	a5,16(a1)
}
    800038fc:	6422                	ld	s0,8(sp)
    800038fe:	0141                	addi	sp,sp,16
    80003900:	8082                	ret

0000000080003902 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003902:	457c                	lw	a5,76(a0)
    80003904:	0ed7e963          	bltu	a5,a3,800039f6 <readi+0xf4>
{
    80003908:	7159                	addi	sp,sp,-112
    8000390a:	f486                	sd	ra,104(sp)
    8000390c:	f0a2                	sd	s0,96(sp)
    8000390e:	eca6                	sd	s1,88(sp)
    80003910:	e8ca                	sd	s2,80(sp)
    80003912:	e4ce                	sd	s3,72(sp)
    80003914:	e0d2                	sd	s4,64(sp)
    80003916:	fc56                	sd	s5,56(sp)
    80003918:	f85a                	sd	s6,48(sp)
    8000391a:	f45e                	sd	s7,40(sp)
    8000391c:	f062                	sd	s8,32(sp)
    8000391e:	ec66                	sd	s9,24(sp)
    80003920:	e86a                	sd	s10,16(sp)
    80003922:	e46e                	sd	s11,8(sp)
    80003924:	1880                	addi	s0,sp,112
    80003926:	8b2a                	mv	s6,a0
    80003928:	8bae                	mv	s7,a1
    8000392a:	8a32                	mv	s4,a2
    8000392c:	84b6                	mv	s1,a3
    8000392e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003930:	9f35                	addw	a4,a4,a3
    return 0;
    80003932:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003934:	0ad76063          	bltu	a4,a3,800039d4 <readi+0xd2>
  if(off + n > ip->size)
    80003938:	00e7f463          	bgeu	a5,a4,80003940 <readi+0x3e>
    n = ip->size - off;
    8000393c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003940:	0a0a8963          	beqz	s5,800039f2 <readi+0xf0>
    80003944:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003946:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000394a:	5c7d                	li	s8,-1
    8000394c:	a82d                	j	80003986 <readi+0x84>
    8000394e:	020d1d93          	slli	s11,s10,0x20
    80003952:	020ddd93          	srli	s11,s11,0x20
    80003956:	05890613          	addi	a2,s2,88
    8000395a:	86ee                	mv	a3,s11
    8000395c:	963a                	add	a2,a2,a4
    8000395e:	85d2                	mv	a1,s4
    80003960:	855e                	mv	a0,s7
    80003962:	fffff097          	auipc	ra,0xfffff
    80003966:	b1c080e7          	jalr	-1252(ra) # 8000247e <either_copyout>
    8000396a:	05850d63          	beq	a0,s8,800039c4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000396e:	854a                	mv	a0,s2
    80003970:	fffff097          	auipc	ra,0xfffff
    80003974:	5f6080e7          	jalr	1526(ra) # 80002f66 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003978:	013d09bb          	addw	s3,s10,s3
    8000397c:	009d04bb          	addw	s1,s10,s1
    80003980:	9a6e                	add	s4,s4,s11
    80003982:	0559f763          	bgeu	s3,s5,800039d0 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003986:	00a4d59b          	srliw	a1,s1,0xa
    8000398a:	855a                	mv	a0,s6
    8000398c:	00000097          	auipc	ra,0x0
    80003990:	89e080e7          	jalr	-1890(ra) # 8000322a <bmap>
    80003994:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003998:	cd85                	beqz	a1,800039d0 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000399a:	000b2503          	lw	a0,0(s6)
    8000399e:	fffff097          	auipc	ra,0xfffff
    800039a2:	498080e7          	jalr	1176(ra) # 80002e36 <bread>
    800039a6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039a8:	3ff4f713          	andi	a4,s1,1023
    800039ac:	40ec87bb          	subw	a5,s9,a4
    800039b0:	413a86bb          	subw	a3,s5,s3
    800039b4:	8d3e                	mv	s10,a5
    800039b6:	2781                	sext.w	a5,a5
    800039b8:	0006861b          	sext.w	a2,a3
    800039bc:	f8f679e3          	bgeu	a2,a5,8000394e <readi+0x4c>
    800039c0:	8d36                	mv	s10,a3
    800039c2:	b771                	j	8000394e <readi+0x4c>
      brelse(bp);
    800039c4:	854a                	mv	a0,s2
    800039c6:	fffff097          	auipc	ra,0xfffff
    800039ca:	5a0080e7          	jalr	1440(ra) # 80002f66 <brelse>
      tot = -1;
    800039ce:	59fd                	li	s3,-1
  }
  return tot;
    800039d0:	0009851b          	sext.w	a0,s3
}
    800039d4:	70a6                	ld	ra,104(sp)
    800039d6:	7406                	ld	s0,96(sp)
    800039d8:	64e6                	ld	s1,88(sp)
    800039da:	6946                	ld	s2,80(sp)
    800039dc:	69a6                	ld	s3,72(sp)
    800039de:	6a06                	ld	s4,64(sp)
    800039e0:	7ae2                	ld	s5,56(sp)
    800039e2:	7b42                	ld	s6,48(sp)
    800039e4:	7ba2                	ld	s7,40(sp)
    800039e6:	7c02                	ld	s8,32(sp)
    800039e8:	6ce2                	ld	s9,24(sp)
    800039ea:	6d42                	ld	s10,16(sp)
    800039ec:	6da2                	ld	s11,8(sp)
    800039ee:	6165                	addi	sp,sp,112
    800039f0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039f2:	89d6                	mv	s3,s5
    800039f4:	bff1                	j	800039d0 <readi+0xce>
    return 0;
    800039f6:	4501                	li	a0,0
}
    800039f8:	8082                	ret

00000000800039fa <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039fa:	457c                	lw	a5,76(a0)
    800039fc:	10d7e863          	bltu	a5,a3,80003b0c <writei+0x112>
{
    80003a00:	7159                	addi	sp,sp,-112
    80003a02:	f486                	sd	ra,104(sp)
    80003a04:	f0a2                	sd	s0,96(sp)
    80003a06:	eca6                	sd	s1,88(sp)
    80003a08:	e8ca                	sd	s2,80(sp)
    80003a0a:	e4ce                	sd	s3,72(sp)
    80003a0c:	e0d2                	sd	s4,64(sp)
    80003a0e:	fc56                	sd	s5,56(sp)
    80003a10:	f85a                	sd	s6,48(sp)
    80003a12:	f45e                	sd	s7,40(sp)
    80003a14:	f062                	sd	s8,32(sp)
    80003a16:	ec66                	sd	s9,24(sp)
    80003a18:	e86a                	sd	s10,16(sp)
    80003a1a:	e46e                	sd	s11,8(sp)
    80003a1c:	1880                	addi	s0,sp,112
    80003a1e:	8aaa                	mv	s5,a0
    80003a20:	8bae                	mv	s7,a1
    80003a22:	8a32                	mv	s4,a2
    80003a24:	8936                	mv	s2,a3
    80003a26:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a28:	00e687bb          	addw	a5,a3,a4
    80003a2c:	0ed7e263          	bltu	a5,a3,80003b10 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a30:	00043737          	lui	a4,0x43
    80003a34:	0ef76063          	bltu	a4,a5,80003b14 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a38:	0c0b0863          	beqz	s6,80003b08 <writei+0x10e>
    80003a3c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a3e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a42:	5c7d                	li	s8,-1
    80003a44:	a091                	j	80003a88 <writei+0x8e>
    80003a46:	020d1d93          	slli	s11,s10,0x20
    80003a4a:	020ddd93          	srli	s11,s11,0x20
    80003a4e:	05848513          	addi	a0,s1,88
    80003a52:	86ee                	mv	a3,s11
    80003a54:	8652                	mv	a2,s4
    80003a56:	85de                	mv	a1,s7
    80003a58:	953a                	add	a0,a0,a4
    80003a5a:	fffff097          	auipc	ra,0xfffff
    80003a5e:	a7a080e7          	jalr	-1414(ra) # 800024d4 <either_copyin>
    80003a62:	07850263          	beq	a0,s8,80003ac6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a66:	8526                	mv	a0,s1
    80003a68:	00000097          	auipc	ra,0x0
    80003a6c:	788080e7          	jalr	1928(ra) # 800041f0 <log_write>
    brelse(bp);
    80003a70:	8526                	mv	a0,s1
    80003a72:	fffff097          	auipc	ra,0xfffff
    80003a76:	4f4080e7          	jalr	1268(ra) # 80002f66 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a7a:	013d09bb          	addw	s3,s10,s3
    80003a7e:	012d093b          	addw	s2,s10,s2
    80003a82:	9a6e                	add	s4,s4,s11
    80003a84:	0569f663          	bgeu	s3,s6,80003ad0 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003a88:	00a9559b          	srliw	a1,s2,0xa
    80003a8c:	8556                	mv	a0,s5
    80003a8e:	fffff097          	auipc	ra,0xfffff
    80003a92:	79c080e7          	jalr	1948(ra) # 8000322a <bmap>
    80003a96:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a9a:	c99d                	beqz	a1,80003ad0 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003a9c:	000aa503          	lw	a0,0(s5)
    80003aa0:	fffff097          	auipc	ra,0xfffff
    80003aa4:	396080e7          	jalr	918(ra) # 80002e36 <bread>
    80003aa8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aaa:	3ff97713          	andi	a4,s2,1023
    80003aae:	40ec87bb          	subw	a5,s9,a4
    80003ab2:	413b06bb          	subw	a3,s6,s3
    80003ab6:	8d3e                	mv	s10,a5
    80003ab8:	2781                	sext.w	a5,a5
    80003aba:	0006861b          	sext.w	a2,a3
    80003abe:	f8f674e3          	bgeu	a2,a5,80003a46 <writei+0x4c>
    80003ac2:	8d36                	mv	s10,a3
    80003ac4:	b749                	j	80003a46 <writei+0x4c>
      brelse(bp);
    80003ac6:	8526                	mv	a0,s1
    80003ac8:	fffff097          	auipc	ra,0xfffff
    80003acc:	49e080e7          	jalr	1182(ra) # 80002f66 <brelse>
  }

  if(off > ip->size)
    80003ad0:	04caa783          	lw	a5,76(s5)
    80003ad4:	0127f463          	bgeu	a5,s2,80003adc <writei+0xe2>
    ip->size = off;
    80003ad8:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003adc:	8556                	mv	a0,s5
    80003ade:	00000097          	auipc	ra,0x0
    80003ae2:	aa4080e7          	jalr	-1372(ra) # 80003582 <iupdate>

  return tot;
    80003ae6:	0009851b          	sext.w	a0,s3
}
    80003aea:	70a6                	ld	ra,104(sp)
    80003aec:	7406                	ld	s0,96(sp)
    80003aee:	64e6                	ld	s1,88(sp)
    80003af0:	6946                	ld	s2,80(sp)
    80003af2:	69a6                	ld	s3,72(sp)
    80003af4:	6a06                	ld	s4,64(sp)
    80003af6:	7ae2                	ld	s5,56(sp)
    80003af8:	7b42                	ld	s6,48(sp)
    80003afa:	7ba2                	ld	s7,40(sp)
    80003afc:	7c02                	ld	s8,32(sp)
    80003afe:	6ce2                	ld	s9,24(sp)
    80003b00:	6d42                	ld	s10,16(sp)
    80003b02:	6da2                	ld	s11,8(sp)
    80003b04:	6165                	addi	sp,sp,112
    80003b06:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b08:	89da                	mv	s3,s6
    80003b0a:	bfc9                	j	80003adc <writei+0xe2>
    return -1;
    80003b0c:	557d                	li	a0,-1
}
    80003b0e:	8082                	ret
    return -1;
    80003b10:	557d                	li	a0,-1
    80003b12:	bfe1                	j	80003aea <writei+0xf0>
    return -1;
    80003b14:	557d                	li	a0,-1
    80003b16:	bfd1                	j	80003aea <writei+0xf0>

0000000080003b18 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b18:	1141                	addi	sp,sp,-16
    80003b1a:	e406                	sd	ra,8(sp)
    80003b1c:	e022                	sd	s0,0(sp)
    80003b1e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b20:	4639                	li	a2,14
    80003b22:	ffffd097          	auipc	ra,0xffffd
    80003b26:	280080e7          	jalr	640(ra) # 80000da2 <strncmp>
}
    80003b2a:	60a2                	ld	ra,8(sp)
    80003b2c:	6402                	ld	s0,0(sp)
    80003b2e:	0141                	addi	sp,sp,16
    80003b30:	8082                	ret

0000000080003b32 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b32:	7139                	addi	sp,sp,-64
    80003b34:	fc06                	sd	ra,56(sp)
    80003b36:	f822                	sd	s0,48(sp)
    80003b38:	f426                	sd	s1,40(sp)
    80003b3a:	f04a                	sd	s2,32(sp)
    80003b3c:	ec4e                	sd	s3,24(sp)
    80003b3e:	e852                	sd	s4,16(sp)
    80003b40:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b42:	04451703          	lh	a4,68(a0)
    80003b46:	4785                	li	a5,1
    80003b48:	00f71a63          	bne	a4,a5,80003b5c <dirlookup+0x2a>
    80003b4c:	892a                	mv	s2,a0
    80003b4e:	89ae                	mv	s3,a1
    80003b50:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b52:	457c                	lw	a5,76(a0)
    80003b54:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b56:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b58:	e79d                	bnez	a5,80003b86 <dirlookup+0x54>
    80003b5a:	a8a5                	j	80003bd2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b5c:	00005517          	auipc	a0,0x5
    80003b60:	aa450513          	addi	a0,a0,-1372 # 80008600 <syscalls+0x1a0>
    80003b64:	ffffd097          	auipc	ra,0xffffd
    80003b68:	9dc080e7          	jalr	-1572(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003b6c:	00005517          	auipc	a0,0x5
    80003b70:	aac50513          	addi	a0,a0,-1364 # 80008618 <syscalls+0x1b8>
    80003b74:	ffffd097          	auipc	ra,0xffffd
    80003b78:	9cc080e7          	jalr	-1588(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b7c:	24c1                	addiw	s1,s1,16
    80003b7e:	04c92783          	lw	a5,76(s2)
    80003b82:	04f4f763          	bgeu	s1,a5,80003bd0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b86:	4741                	li	a4,16
    80003b88:	86a6                	mv	a3,s1
    80003b8a:	fc040613          	addi	a2,s0,-64
    80003b8e:	4581                	li	a1,0
    80003b90:	854a                	mv	a0,s2
    80003b92:	00000097          	auipc	ra,0x0
    80003b96:	d70080e7          	jalr	-656(ra) # 80003902 <readi>
    80003b9a:	47c1                	li	a5,16
    80003b9c:	fcf518e3          	bne	a0,a5,80003b6c <dirlookup+0x3a>
    if(de.inum == 0)
    80003ba0:	fc045783          	lhu	a5,-64(s0)
    80003ba4:	dfe1                	beqz	a5,80003b7c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ba6:	fc240593          	addi	a1,s0,-62
    80003baa:	854e                	mv	a0,s3
    80003bac:	00000097          	auipc	ra,0x0
    80003bb0:	f6c080e7          	jalr	-148(ra) # 80003b18 <namecmp>
    80003bb4:	f561                	bnez	a0,80003b7c <dirlookup+0x4a>
      if(poff)
    80003bb6:	000a0463          	beqz	s4,80003bbe <dirlookup+0x8c>
        *poff = off;
    80003bba:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003bbe:	fc045583          	lhu	a1,-64(s0)
    80003bc2:	00092503          	lw	a0,0(s2)
    80003bc6:	fffff097          	auipc	ra,0xfffff
    80003bca:	74e080e7          	jalr	1870(ra) # 80003314 <iget>
    80003bce:	a011                	j	80003bd2 <dirlookup+0xa0>
  return 0;
    80003bd0:	4501                	li	a0,0
}
    80003bd2:	70e2                	ld	ra,56(sp)
    80003bd4:	7442                	ld	s0,48(sp)
    80003bd6:	74a2                	ld	s1,40(sp)
    80003bd8:	7902                	ld	s2,32(sp)
    80003bda:	69e2                	ld	s3,24(sp)
    80003bdc:	6a42                	ld	s4,16(sp)
    80003bde:	6121                	addi	sp,sp,64
    80003be0:	8082                	ret

0000000080003be2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003be2:	711d                	addi	sp,sp,-96
    80003be4:	ec86                	sd	ra,88(sp)
    80003be6:	e8a2                	sd	s0,80(sp)
    80003be8:	e4a6                	sd	s1,72(sp)
    80003bea:	e0ca                	sd	s2,64(sp)
    80003bec:	fc4e                	sd	s3,56(sp)
    80003bee:	f852                	sd	s4,48(sp)
    80003bf0:	f456                	sd	s5,40(sp)
    80003bf2:	f05a                	sd	s6,32(sp)
    80003bf4:	ec5e                	sd	s7,24(sp)
    80003bf6:	e862                	sd	s8,16(sp)
    80003bf8:	e466                	sd	s9,8(sp)
    80003bfa:	e06a                	sd	s10,0(sp)
    80003bfc:	1080                	addi	s0,sp,96
    80003bfe:	84aa                	mv	s1,a0
    80003c00:	8b2e                	mv	s6,a1
    80003c02:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c04:	00054703          	lbu	a4,0(a0)
    80003c08:	02f00793          	li	a5,47
    80003c0c:	02f70363          	beq	a4,a5,80003c32 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c10:	ffffe097          	auipc	ra,0xffffe
    80003c14:	dbe080e7          	jalr	-578(ra) # 800019ce <myproc>
    80003c18:	15053503          	ld	a0,336(a0)
    80003c1c:	00000097          	auipc	ra,0x0
    80003c20:	9f4080e7          	jalr	-1548(ra) # 80003610 <idup>
    80003c24:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003c26:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003c2a:	4cb5                	li	s9,13
  len = path - s;
    80003c2c:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c2e:	4c05                	li	s8,1
    80003c30:	a87d                	j	80003cee <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003c32:	4585                	li	a1,1
    80003c34:	4505                	li	a0,1
    80003c36:	fffff097          	auipc	ra,0xfffff
    80003c3a:	6de080e7          	jalr	1758(ra) # 80003314 <iget>
    80003c3e:	8a2a                	mv	s4,a0
    80003c40:	b7dd                	j	80003c26 <namex+0x44>
      iunlockput(ip);
    80003c42:	8552                	mv	a0,s4
    80003c44:	00000097          	auipc	ra,0x0
    80003c48:	c6c080e7          	jalr	-916(ra) # 800038b0 <iunlockput>
      return 0;
    80003c4c:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c4e:	8552                	mv	a0,s4
    80003c50:	60e6                	ld	ra,88(sp)
    80003c52:	6446                	ld	s0,80(sp)
    80003c54:	64a6                	ld	s1,72(sp)
    80003c56:	6906                	ld	s2,64(sp)
    80003c58:	79e2                	ld	s3,56(sp)
    80003c5a:	7a42                	ld	s4,48(sp)
    80003c5c:	7aa2                	ld	s5,40(sp)
    80003c5e:	7b02                	ld	s6,32(sp)
    80003c60:	6be2                	ld	s7,24(sp)
    80003c62:	6c42                	ld	s8,16(sp)
    80003c64:	6ca2                	ld	s9,8(sp)
    80003c66:	6d02                	ld	s10,0(sp)
    80003c68:	6125                	addi	sp,sp,96
    80003c6a:	8082                	ret
      iunlock(ip);
    80003c6c:	8552                	mv	a0,s4
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	aa2080e7          	jalr	-1374(ra) # 80003710 <iunlock>
      return ip;
    80003c76:	bfe1                	j	80003c4e <namex+0x6c>
      iunlockput(ip);
    80003c78:	8552                	mv	a0,s4
    80003c7a:	00000097          	auipc	ra,0x0
    80003c7e:	c36080e7          	jalr	-970(ra) # 800038b0 <iunlockput>
      return 0;
    80003c82:	8a4e                	mv	s4,s3
    80003c84:	b7e9                	j	80003c4e <namex+0x6c>
  len = path - s;
    80003c86:	40998633          	sub	a2,s3,s1
    80003c8a:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003c8e:	09acd863          	bge	s9,s10,80003d1e <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003c92:	4639                	li	a2,14
    80003c94:	85a6                	mv	a1,s1
    80003c96:	8556                	mv	a0,s5
    80003c98:	ffffd097          	auipc	ra,0xffffd
    80003c9c:	096080e7          	jalr	150(ra) # 80000d2e <memmove>
    80003ca0:	84ce                	mv	s1,s3
  while(*path == '/')
    80003ca2:	0004c783          	lbu	a5,0(s1)
    80003ca6:	01279763          	bne	a5,s2,80003cb4 <namex+0xd2>
    path++;
    80003caa:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cac:	0004c783          	lbu	a5,0(s1)
    80003cb0:	ff278de3          	beq	a5,s2,80003caa <namex+0xc8>
    ilock(ip);
    80003cb4:	8552                	mv	a0,s4
    80003cb6:	00000097          	auipc	ra,0x0
    80003cba:	998080e7          	jalr	-1640(ra) # 8000364e <ilock>
    if(ip->type != T_DIR){
    80003cbe:	044a1783          	lh	a5,68(s4)
    80003cc2:	f98790e3          	bne	a5,s8,80003c42 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003cc6:	000b0563          	beqz	s6,80003cd0 <namex+0xee>
    80003cca:	0004c783          	lbu	a5,0(s1)
    80003cce:	dfd9                	beqz	a5,80003c6c <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003cd0:	865e                	mv	a2,s7
    80003cd2:	85d6                	mv	a1,s5
    80003cd4:	8552                	mv	a0,s4
    80003cd6:	00000097          	auipc	ra,0x0
    80003cda:	e5c080e7          	jalr	-420(ra) # 80003b32 <dirlookup>
    80003cde:	89aa                	mv	s3,a0
    80003ce0:	dd41                	beqz	a0,80003c78 <namex+0x96>
    iunlockput(ip);
    80003ce2:	8552                	mv	a0,s4
    80003ce4:	00000097          	auipc	ra,0x0
    80003ce8:	bcc080e7          	jalr	-1076(ra) # 800038b0 <iunlockput>
    ip = next;
    80003cec:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003cee:	0004c783          	lbu	a5,0(s1)
    80003cf2:	01279763          	bne	a5,s2,80003d00 <namex+0x11e>
    path++;
    80003cf6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cf8:	0004c783          	lbu	a5,0(s1)
    80003cfc:	ff278de3          	beq	a5,s2,80003cf6 <namex+0x114>
  if(*path == 0)
    80003d00:	cb9d                	beqz	a5,80003d36 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003d02:	0004c783          	lbu	a5,0(s1)
    80003d06:	89a6                	mv	s3,s1
  len = path - s;
    80003d08:	8d5e                	mv	s10,s7
    80003d0a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d0c:	01278963          	beq	a5,s2,80003d1e <namex+0x13c>
    80003d10:	dbbd                	beqz	a5,80003c86 <namex+0xa4>
    path++;
    80003d12:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003d14:	0009c783          	lbu	a5,0(s3)
    80003d18:	ff279ce3          	bne	a5,s2,80003d10 <namex+0x12e>
    80003d1c:	b7ad                	j	80003c86 <namex+0xa4>
    memmove(name, s, len);
    80003d1e:	2601                	sext.w	a2,a2
    80003d20:	85a6                	mv	a1,s1
    80003d22:	8556                	mv	a0,s5
    80003d24:	ffffd097          	auipc	ra,0xffffd
    80003d28:	00a080e7          	jalr	10(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003d2c:	9d56                	add	s10,s10,s5
    80003d2e:	000d0023          	sb	zero,0(s10)
    80003d32:	84ce                	mv	s1,s3
    80003d34:	b7bd                	j	80003ca2 <namex+0xc0>
  if(nameiparent){
    80003d36:	f00b0ce3          	beqz	s6,80003c4e <namex+0x6c>
    iput(ip);
    80003d3a:	8552                	mv	a0,s4
    80003d3c:	00000097          	auipc	ra,0x0
    80003d40:	acc080e7          	jalr	-1332(ra) # 80003808 <iput>
    return 0;
    80003d44:	4a01                	li	s4,0
    80003d46:	b721                	j	80003c4e <namex+0x6c>

0000000080003d48 <dirlink>:
{
    80003d48:	7139                	addi	sp,sp,-64
    80003d4a:	fc06                	sd	ra,56(sp)
    80003d4c:	f822                	sd	s0,48(sp)
    80003d4e:	f426                	sd	s1,40(sp)
    80003d50:	f04a                	sd	s2,32(sp)
    80003d52:	ec4e                	sd	s3,24(sp)
    80003d54:	e852                	sd	s4,16(sp)
    80003d56:	0080                	addi	s0,sp,64
    80003d58:	892a                	mv	s2,a0
    80003d5a:	8a2e                	mv	s4,a1
    80003d5c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d5e:	4601                	li	a2,0
    80003d60:	00000097          	auipc	ra,0x0
    80003d64:	dd2080e7          	jalr	-558(ra) # 80003b32 <dirlookup>
    80003d68:	e93d                	bnez	a0,80003dde <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d6a:	04c92483          	lw	s1,76(s2)
    80003d6e:	c49d                	beqz	s1,80003d9c <dirlink+0x54>
    80003d70:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d72:	4741                	li	a4,16
    80003d74:	86a6                	mv	a3,s1
    80003d76:	fc040613          	addi	a2,s0,-64
    80003d7a:	4581                	li	a1,0
    80003d7c:	854a                	mv	a0,s2
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	b84080e7          	jalr	-1148(ra) # 80003902 <readi>
    80003d86:	47c1                	li	a5,16
    80003d88:	06f51163          	bne	a0,a5,80003dea <dirlink+0xa2>
    if(de.inum == 0)
    80003d8c:	fc045783          	lhu	a5,-64(s0)
    80003d90:	c791                	beqz	a5,80003d9c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d92:	24c1                	addiw	s1,s1,16
    80003d94:	04c92783          	lw	a5,76(s2)
    80003d98:	fcf4ede3          	bltu	s1,a5,80003d72 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d9c:	4639                	li	a2,14
    80003d9e:	85d2                	mv	a1,s4
    80003da0:	fc240513          	addi	a0,s0,-62
    80003da4:	ffffd097          	auipc	ra,0xffffd
    80003da8:	03a080e7          	jalr	58(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003dac:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003db0:	4741                	li	a4,16
    80003db2:	86a6                	mv	a3,s1
    80003db4:	fc040613          	addi	a2,s0,-64
    80003db8:	4581                	li	a1,0
    80003dba:	854a                	mv	a0,s2
    80003dbc:	00000097          	auipc	ra,0x0
    80003dc0:	c3e080e7          	jalr	-962(ra) # 800039fa <writei>
    80003dc4:	1541                	addi	a0,a0,-16
    80003dc6:	00a03533          	snez	a0,a0
    80003dca:	40a00533          	neg	a0,a0
}
    80003dce:	70e2                	ld	ra,56(sp)
    80003dd0:	7442                	ld	s0,48(sp)
    80003dd2:	74a2                	ld	s1,40(sp)
    80003dd4:	7902                	ld	s2,32(sp)
    80003dd6:	69e2                	ld	s3,24(sp)
    80003dd8:	6a42                	ld	s4,16(sp)
    80003dda:	6121                	addi	sp,sp,64
    80003ddc:	8082                	ret
    iput(ip);
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	a2a080e7          	jalr	-1494(ra) # 80003808 <iput>
    return -1;
    80003de6:	557d                	li	a0,-1
    80003de8:	b7dd                	j	80003dce <dirlink+0x86>
      panic("dirlink read");
    80003dea:	00005517          	auipc	a0,0x5
    80003dee:	83e50513          	addi	a0,a0,-1986 # 80008628 <syscalls+0x1c8>
    80003df2:	ffffc097          	auipc	ra,0xffffc
    80003df6:	74e080e7          	jalr	1870(ra) # 80000540 <panic>

0000000080003dfa <namei>:

struct inode*
namei(char *path)
{
    80003dfa:	1101                	addi	sp,sp,-32
    80003dfc:	ec06                	sd	ra,24(sp)
    80003dfe:	e822                	sd	s0,16(sp)
    80003e00:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e02:	fe040613          	addi	a2,s0,-32
    80003e06:	4581                	li	a1,0
    80003e08:	00000097          	auipc	ra,0x0
    80003e0c:	dda080e7          	jalr	-550(ra) # 80003be2 <namex>
}
    80003e10:	60e2                	ld	ra,24(sp)
    80003e12:	6442                	ld	s0,16(sp)
    80003e14:	6105                	addi	sp,sp,32
    80003e16:	8082                	ret

0000000080003e18 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e18:	1141                	addi	sp,sp,-16
    80003e1a:	e406                	sd	ra,8(sp)
    80003e1c:	e022                	sd	s0,0(sp)
    80003e1e:	0800                	addi	s0,sp,16
    80003e20:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e22:	4585                	li	a1,1
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	dbe080e7          	jalr	-578(ra) # 80003be2 <namex>
}
    80003e2c:	60a2                	ld	ra,8(sp)
    80003e2e:	6402                	ld	s0,0(sp)
    80003e30:	0141                	addi	sp,sp,16
    80003e32:	8082                	ret

0000000080003e34 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e34:	1101                	addi	sp,sp,-32
    80003e36:	ec06                	sd	ra,24(sp)
    80003e38:	e822                	sd	s0,16(sp)
    80003e3a:	e426                	sd	s1,8(sp)
    80003e3c:	e04a                	sd	s2,0(sp)
    80003e3e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e40:	0001d917          	auipc	s2,0x1d
    80003e44:	cf090913          	addi	s2,s2,-784 # 80020b30 <log>
    80003e48:	01892583          	lw	a1,24(s2)
    80003e4c:	02892503          	lw	a0,40(s2)
    80003e50:	fffff097          	auipc	ra,0xfffff
    80003e54:	fe6080e7          	jalr	-26(ra) # 80002e36 <bread>
    80003e58:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e5a:	02c92683          	lw	a3,44(s2)
    80003e5e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e60:	02d05863          	blez	a3,80003e90 <write_head+0x5c>
    80003e64:	0001d797          	auipc	a5,0x1d
    80003e68:	cfc78793          	addi	a5,a5,-772 # 80020b60 <log+0x30>
    80003e6c:	05c50713          	addi	a4,a0,92
    80003e70:	36fd                	addiw	a3,a3,-1
    80003e72:	02069613          	slli	a2,a3,0x20
    80003e76:	01e65693          	srli	a3,a2,0x1e
    80003e7a:	0001d617          	auipc	a2,0x1d
    80003e7e:	cea60613          	addi	a2,a2,-790 # 80020b64 <log+0x34>
    80003e82:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e84:	4390                	lw	a2,0(a5)
    80003e86:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e88:	0791                	addi	a5,a5,4
    80003e8a:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003e8c:	fed79ce3          	bne	a5,a3,80003e84 <write_head+0x50>
  }
  bwrite(buf);
    80003e90:	8526                	mv	a0,s1
    80003e92:	fffff097          	auipc	ra,0xfffff
    80003e96:	096080e7          	jalr	150(ra) # 80002f28 <bwrite>
  brelse(buf);
    80003e9a:	8526                	mv	a0,s1
    80003e9c:	fffff097          	auipc	ra,0xfffff
    80003ea0:	0ca080e7          	jalr	202(ra) # 80002f66 <brelse>
}
    80003ea4:	60e2                	ld	ra,24(sp)
    80003ea6:	6442                	ld	s0,16(sp)
    80003ea8:	64a2                	ld	s1,8(sp)
    80003eaa:	6902                	ld	s2,0(sp)
    80003eac:	6105                	addi	sp,sp,32
    80003eae:	8082                	ret

0000000080003eb0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eb0:	0001d797          	auipc	a5,0x1d
    80003eb4:	cac7a783          	lw	a5,-852(a5) # 80020b5c <log+0x2c>
    80003eb8:	0af05d63          	blez	a5,80003f72 <install_trans+0xc2>
{
    80003ebc:	7139                	addi	sp,sp,-64
    80003ebe:	fc06                	sd	ra,56(sp)
    80003ec0:	f822                	sd	s0,48(sp)
    80003ec2:	f426                	sd	s1,40(sp)
    80003ec4:	f04a                	sd	s2,32(sp)
    80003ec6:	ec4e                	sd	s3,24(sp)
    80003ec8:	e852                	sd	s4,16(sp)
    80003eca:	e456                	sd	s5,8(sp)
    80003ecc:	e05a                	sd	s6,0(sp)
    80003ece:	0080                	addi	s0,sp,64
    80003ed0:	8b2a                	mv	s6,a0
    80003ed2:	0001da97          	auipc	s5,0x1d
    80003ed6:	c8ea8a93          	addi	s5,s5,-882 # 80020b60 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eda:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003edc:	0001d997          	auipc	s3,0x1d
    80003ee0:	c5498993          	addi	s3,s3,-940 # 80020b30 <log>
    80003ee4:	a00d                	j	80003f06 <install_trans+0x56>
    brelse(lbuf);
    80003ee6:	854a                	mv	a0,s2
    80003ee8:	fffff097          	auipc	ra,0xfffff
    80003eec:	07e080e7          	jalr	126(ra) # 80002f66 <brelse>
    brelse(dbuf);
    80003ef0:	8526                	mv	a0,s1
    80003ef2:	fffff097          	auipc	ra,0xfffff
    80003ef6:	074080e7          	jalr	116(ra) # 80002f66 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003efa:	2a05                	addiw	s4,s4,1
    80003efc:	0a91                	addi	s5,s5,4
    80003efe:	02c9a783          	lw	a5,44(s3)
    80003f02:	04fa5e63          	bge	s4,a5,80003f5e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f06:	0189a583          	lw	a1,24(s3)
    80003f0a:	014585bb          	addw	a1,a1,s4
    80003f0e:	2585                	addiw	a1,a1,1
    80003f10:	0289a503          	lw	a0,40(s3)
    80003f14:	fffff097          	auipc	ra,0xfffff
    80003f18:	f22080e7          	jalr	-222(ra) # 80002e36 <bread>
    80003f1c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f1e:	000aa583          	lw	a1,0(s5)
    80003f22:	0289a503          	lw	a0,40(s3)
    80003f26:	fffff097          	auipc	ra,0xfffff
    80003f2a:	f10080e7          	jalr	-240(ra) # 80002e36 <bread>
    80003f2e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f30:	40000613          	li	a2,1024
    80003f34:	05890593          	addi	a1,s2,88
    80003f38:	05850513          	addi	a0,a0,88
    80003f3c:	ffffd097          	auipc	ra,0xffffd
    80003f40:	df2080e7          	jalr	-526(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f44:	8526                	mv	a0,s1
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	fe2080e7          	jalr	-30(ra) # 80002f28 <bwrite>
    if(recovering == 0)
    80003f4e:	f80b1ce3          	bnez	s6,80003ee6 <install_trans+0x36>
      bunpin(dbuf);
    80003f52:	8526                	mv	a0,s1
    80003f54:	fffff097          	auipc	ra,0xfffff
    80003f58:	0ec080e7          	jalr	236(ra) # 80003040 <bunpin>
    80003f5c:	b769                	j	80003ee6 <install_trans+0x36>
}
    80003f5e:	70e2                	ld	ra,56(sp)
    80003f60:	7442                	ld	s0,48(sp)
    80003f62:	74a2                	ld	s1,40(sp)
    80003f64:	7902                	ld	s2,32(sp)
    80003f66:	69e2                	ld	s3,24(sp)
    80003f68:	6a42                	ld	s4,16(sp)
    80003f6a:	6aa2                	ld	s5,8(sp)
    80003f6c:	6b02                	ld	s6,0(sp)
    80003f6e:	6121                	addi	sp,sp,64
    80003f70:	8082                	ret
    80003f72:	8082                	ret

0000000080003f74 <initlog>:
{
    80003f74:	7179                	addi	sp,sp,-48
    80003f76:	f406                	sd	ra,40(sp)
    80003f78:	f022                	sd	s0,32(sp)
    80003f7a:	ec26                	sd	s1,24(sp)
    80003f7c:	e84a                	sd	s2,16(sp)
    80003f7e:	e44e                	sd	s3,8(sp)
    80003f80:	1800                	addi	s0,sp,48
    80003f82:	892a                	mv	s2,a0
    80003f84:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f86:	0001d497          	auipc	s1,0x1d
    80003f8a:	baa48493          	addi	s1,s1,-1110 # 80020b30 <log>
    80003f8e:	00004597          	auipc	a1,0x4
    80003f92:	6aa58593          	addi	a1,a1,1706 # 80008638 <syscalls+0x1d8>
    80003f96:	8526                	mv	a0,s1
    80003f98:	ffffd097          	auipc	ra,0xffffd
    80003f9c:	bae080e7          	jalr	-1106(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80003fa0:	0149a583          	lw	a1,20(s3)
    80003fa4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003fa6:	0109a783          	lw	a5,16(s3)
    80003faa:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003fac:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003fb0:	854a                	mv	a0,s2
    80003fb2:	fffff097          	auipc	ra,0xfffff
    80003fb6:	e84080e7          	jalr	-380(ra) # 80002e36 <bread>
  log.lh.n = lh->n;
    80003fba:	4d34                	lw	a3,88(a0)
    80003fbc:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003fbe:	02d05663          	blez	a3,80003fea <initlog+0x76>
    80003fc2:	05c50793          	addi	a5,a0,92
    80003fc6:	0001d717          	auipc	a4,0x1d
    80003fca:	b9a70713          	addi	a4,a4,-1126 # 80020b60 <log+0x30>
    80003fce:	36fd                	addiw	a3,a3,-1
    80003fd0:	02069613          	slli	a2,a3,0x20
    80003fd4:	01e65693          	srli	a3,a2,0x1e
    80003fd8:	06050613          	addi	a2,a0,96
    80003fdc:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80003fde:	4390                	lw	a2,0(a5)
    80003fe0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fe2:	0791                	addi	a5,a5,4
    80003fe4:	0711                	addi	a4,a4,4
    80003fe6:	fed79ce3          	bne	a5,a3,80003fde <initlog+0x6a>
  brelse(buf);
    80003fea:	fffff097          	auipc	ra,0xfffff
    80003fee:	f7c080e7          	jalr	-132(ra) # 80002f66 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003ff2:	4505                	li	a0,1
    80003ff4:	00000097          	auipc	ra,0x0
    80003ff8:	ebc080e7          	jalr	-324(ra) # 80003eb0 <install_trans>
  log.lh.n = 0;
    80003ffc:	0001d797          	auipc	a5,0x1d
    80004000:	b607a023          	sw	zero,-1184(a5) # 80020b5c <log+0x2c>
  write_head(); // clear the log
    80004004:	00000097          	auipc	ra,0x0
    80004008:	e30080e7          	jalr	-464(ra) # 80003e34 <write_head>
}
    8000400c:	70a2                	ld	ra,40(sp)
    8000400e:	7402                	ld	s0,32(sp)
    80004010:	64e2                	ld	s1,24(sp)
    80004012:	6942                	ld	s2,16(sp)
    80004014:	69a2                	ld	s3,8(sp)
    80004016:	6145                	addi	sp,sp,48
    80004018:	8082                	ret

000000008000401a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000401a:	1101                	addi	sp,sp,-32
    8000401c:	ec06                	sd	ra,24(sp)
    8000401e:	e822                	sd	s0,16(sp)
    80004020:	e426                	sd	s1,8(sp)
    80004022:	e04a                	sd	s2,0(sp)
    80004024:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004026:	0001d517          	auipc	a0,0x1d
    8000402a:	b0a50513          	addi	a0,a0,-1270 # 80020b30 <log>
    8000402e:	ffffd097          	auipc	ra,0xffffd
    80004032:	ba8080e7          	jalr	-1112(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004036:	0001d497          	auipc	s1,0x1d
    8000403a:	afa48493          	addi	s1,s1,-1286 # 80020b30 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000403e:	4979                	li	s2,30
    80004040:	a039                	j	8000404e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004042:	85a6                	mv	a1,s1
    80004044:	8526                	mv	a0,s1
    80004046:	ffffe097          	auipc	ra,0xffffe
    8000404a:	030080e7          	jalr	48(ra) # 80002076 <sleep>
    if(log.committing){
    8000404e:	50dc                	lw	a5,36(s1)
    80004050:	fbed                	bnez	a5,80004042 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004052:	5098                	lw	a4,32(s1)
    80004054:	2705                	addiw	a4,a4,1
    80004056:	0007069b          	sext.w	a3,a4
    8000405a:	0027179b          	slliw	a5,a4,0x2
    8000405e:	9fb9                	addw	a5,a5,a4
    80004060:	0017979b          	slliw	a5,a5,0x1
    80004064:	54d8                	lw	a4,44(s1)
    80004066:	9fb9                	addw	a5,a5,a4
    80004068:	00f95963          	bge	s2,a5,8000407a <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000406c:	85a6                	mv	a1,s1
    8000406e:	8526                	mv	a0,s1
    80004070:	ffffe097          	auipc	ra,0xffffe
    80004074:	006080e7          	jalr	6(ra) # 80002076 <sleep>
    80004078:	bfd9                	j	8000404e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000407a:	0001d517          	auipc	a0,0x1d
    8000407e:	ab650513          	addi	a0,a0,-1354 # 80020b30 <log>
    80004082:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004084:	ffffd097          	auipc	ra,0xffffd
    80004088:	c06080e7          	jalr	-1018(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000408c:	60e2                	ld	ra,24(sp)
    8000408e:	6442                	ld	s0,16(sp)
    80004090:	64a2                	ld	s1,8(sp)
    80004092:	6902                	ld	s2,0(sp)
    80004094:	6105                	addi	sp,sp,32
    80004096:	8082                	ret

0000000080004098 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004098:	7139                	addi	sp,sp,-64
    8000409a:	fc06                	sd	ra,56(sp)
    8000409c:	f822                	sd	s0,48(sp)
    8000409e:	f426                	sd	s1,40(sp)
    800040a0:	f04a                	sd	s2,32(sp)
    800040a2:	ec4e                	sd	s3,24(sp)
    800040a4:	e852                	sd	s4,16(sp)
    800040a6:	e456                	sd	s5,8(sp)
    800040a8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040aa:	0001d497          	auipc	s1,0x1d
    800040ae:	a8648493          	addi	s1,s1,-1402 # 80020b30 <log>
    800040b2:	8526                	mv	a0,s1
    800040b4:	ffffd097          	auipc	ra,0xffffd
    800040b8:	b22080e7          	jalr	-1246(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800040bc:	509c                	lw	a5,32(s1)
    800040be:	37fd                	addiw	a5,a5,-1
    800040c0:	0007891b          	sext.w	s2,a5
    800040c4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800040c6:	50dc                	lw	a5,36(s1)
    800040c8:	e7b9                	bnez	a5,80004116 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800040ca:	04091e63          	bnez	s2,80004126 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800040ce:	0001d497          	auipc	s1,0x1d
    800040d2:	a6248493          	addi	s1,s1,-1438 # 80020b30 <log>
    800040d6:	4785                	li	a5,1
    800040d8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040da:	8526                	mv	a0,s1
    800040dc:	ffffd097          	auipc	ra,0xffffd
    800040e0:	bae080e7          	jalr	-1106(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040e4:	54dc                	lw	a5,44(s1)
    800040e6:	06f04763          	bgtz	a5,80004154 <end_op+0xbc>
    acquire(&log.lock);
    800040ea:	0001d497          	auipc	s1,0x1d
    800040ee:	a4648493          	addi	s1,s1,-1466 # 80020b30 <log>
    800040f2:	8526                	mv	a0,s1
    800040f4:	ffffd097          	auipc	ra,0xffffd
    800040f8:	ae2080e7          	jalr	-1310(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800040fc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004100:	8526                	mv	a0,s1
    80004102:	ffffe097          	auipc	ra,0xffffe
    80004106:	fd8080e7          	jalr	-40(ra) # 800020da <wakeup>
    release(&log.lock);
    8000410a:	8526                	mv	a0,s1
    8000410c:	ffffd097          	auipc	ra,0xffffd
    80004110:	b7e080e7          	jalr	-1154(ra) # 80000c8a <release>
}
    80004114:	a03d                	j	80004142 <end_op+0xaa>
    panic("log.committing");
    80004116:	00004517          	auipc	a0,0x4
    8000411a:	52a50513          	addi	a0,a0,1322 # 80008640 <syscalls+0x1e0>
    8000411e:	ffffc097          	auipc	ra,0xffffc
    80004122:	422080e7          	jalr	1058(ra) # 80000540 <panic>
    wakeup(&log);
    80004126:	0001d497          	auipc	s1,0x1d
    8000412a:	a0a48493          	addi	s1,s1,-1526 # 80020b30 <log>
    8000412e:	8526                	mv	a0,s1
    80004130:	ffffe097          	auipc	ra,0xffffe
    80004134:	faa080e7          	jalr	-86(ra) # 800020da <wakeup>
  release(&log.lock);
    80004138:	8526                	mv	a0,s1
    8000413a:	ffffd097          	auipc	ra,0xffffd
    8000413e:	b50080e7          	jalr	-1200(ra) # 80000c8a <release>
}
    80004142:	70e2                	ld	ra,56(sp)
    80004144:	7442                	ld	s0,48(sp)
    80004146:	74a2                	ld	s1,40(sp)
    80004148:	7902                	ld	s2,32(sp)
    8000414a:	69e2                	ld	s3,24(sp)
    8000414c:	6a42                	ld	s4,16(sp)
    8000414e:	6aa2                	ld	s5,8(sp)
    80004150:	6121                	addi	sp,sp,64
    80004152:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004154:	0001da97          	auipc	s5,0x1d
    80004158:	a0ca8a93          	addi	s5,s5,-1524 # 80020b60 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000415c:	0001da17          	auipc	s4,0x1d
    80004160:	9d4a0a13          	addi	s4,s4,-1580 # 80020b30 <log>
    80004164:	018a2583          	lw	a1,24(s4)
    80004168:	012585bb          	addw	a1,a1,s2
    8000416c:	2585                	addiw	a1,a1,1
    8000416e:	028a2503          	lw	a0,40(s4)
    80004172:	fffff097          	auipc	ra,0xfffff
    80004176:	cc4080e7          	jalr	-828(ra) # 80002e36 <bread>
    8000417a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000417c:	000aa583          	lw	a1,0(s5)
    80004180:	028a2503          	lw	a0,40(s4)
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	cb2080e7          	jalr	-846(ra) # 80002e36 <bread>
    8000418c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000418e:	40000613          	li	a2,1024
    80004192:	05850593          	addi	a1,a0,88
    80004196:	05848513          	addi	a0,s1,88
    8000419a:	ffffd097          	auipc	ra,0xffffd
    8000419e:	b94080e7          	jalr	-1132(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800041a2:	8526                	mv	a0,s1
    800041a4:	fffff097          	auipc	ra,0xfffff
    800041a8:	d84080e7          	jalr	-636(ra) # 80002f28 <bwrite>
    brelse(from);
    800041ac:	854e                	mv	a0,s3
    800041ae:	fffff097          	auipc	ra,0xfffff
    800041b2:	db8080e7          	jalr	-584(ra) # 80002f66 <brelse>
    brelse(to);
    800041b6:	8526                	mv	a0,s1
    800041b8:	fffff097          	auipc	ra,0xfffff
    800041bc:	dae080e7          	jalr	-594(ra) # 80002f66 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041c0:	2905                	addiw	s2,s2,1
    800041c2:	0a91                	addi	s5,s5,4
    800041c4:	02ca2783          	lw	a5,44(s4)
    800041c8:	f8f94ee3          	blt	s2,a5,80004164 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800041cc:	00000097          	auipc	ra,0x0
    800041d0:	c68080e7          	jalr	-920(ra) # 80003e34 <write_head>
    install_trans(0); // Now install writes to home locations
    800041d4:	4501                	li	a0,0
    800041d6:	00000097          	auipc	ra,0x0
    800041da:	cda080e7          	jalr	-806(ra) # 80003eb0 <install_trans>
    log.lh.n = 0;
    800041de:	0001d797          	auipc	a5,0x1d
    800041e2:	9607af23          	sw	zero,-1666(a5) # 80020b5c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041e6:	00000097          	auipc	ra,0x0
    800041ea:	c4e080e7          	jalr	-946(ra) # 80003e34 <write_head>
    800041ee:	bdf5                	j	800040ea <end_op+0x52>

00000000800041f0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800041f0:	1101                	addi	sp,sp,-32
    800041f2:	ec06                	sd	ra,24(sp)
    800041f4:	e822                	sd	s0,16(sp)
    800041f6:	e426                	sd	s1,8(sp)
    800041f8:	e04a                	sd	s2,0(sp)
    800041fa:	1000                	addi	s0,sp,32
    800041fc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800041fe:	0001d917          	auipc	s2,0x1d
    80004202:	93290913          	addi	s2,s2,-1742 # 80020b30 <log>
    80004206:	854a                	mv	a0,s2
    80004208:	ffffd097          	auipc	ra,0xffffd
    8000420c:	9ce080e7          	jalr	-1586(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004210:	02c92603          	lw	a2,44(s2)
    80004214:	47f5                	li	a5,29
    80004216:	06c7c563          	blt	a5,a2,80004280 <log_write+0x90>
    8000421a:	0001d797          	auipc	a5,0x1d
    8000421e:	9327a783          	lw	a5,-1742(a5) # 80020b4c <log+0x1c>
    80004222:	37fd                	addiw	a5,a5,-1
    80004224:	04f65e63          	bge	a2,a5,80004280 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004228:	0001d797          	auipc	a5,0x1d
    8000422c:	9287a783          	lw	a5,-1752(a5) # 80020b50 <log+0x20>
    80004230:	06f05063          	blez	a5,80004290 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004234:	4781                	li	a5,0
    80004236:	06c05563          	blez	a2,800042a0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000423a:	44cc                	lw	a1,12(s1)
    8000423c:	0001d717          	auipc	a4,0x1d
    80004240:	92470713          	addi	a4,a4,-1756 # 80020b60 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004244:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004246:	4314                	lw	a3,0(a4)
    80004248:	04b68c63          	beq	a3,a1,800042a0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000424c:	2785                	addiw	a5,a5,1
    8000424e:	0711                	addi	a4,a4,4
    80004250:	fef61be3          	bne	a2,a5,80004246 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004254:	0621                	addi	a2,a2,8
    80004256:	060a                	slli	a2,a2,0x2
    80004258:	0001d797          	auipc	a5,0x1d
    8000425c:	8d878793          	addi	a5,a5,-1832 # 80020b30 <log>
    80004260:	97b2                	add	a5,a5,a2
    80004262:	44d8                	lw	a4,12(s1)
    80004264:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004266:	8526                	mv	a0,s1
    80004268:	fffff097          	auipc	ra,0xfffff
    8000426c:	d9c080e7          	jalr	-612(ra) # 80003004 <bpin>
    log.lh.n++;
    80004270:	0001d717          	auipc	a4,0x1d
    80004274:	8c070713          	addi	a4,a4,-1856 # 80020b30 <log>
    80004278:	575c                	lw	a5,44(a4)
    8000427a:	2785                	addiw	a5,a5,1
    8000427c:	d75c                	sw	a5,44(a4)
    8000427e:	a82d                	j	800042b8 <log_write+0xc8>
    panic("too big a transaction");
    80004280:	00004517          	auipc	a0,0x4
    80004284:	3d050513          	addi	a0,a0,976 # 80008650 <syscalls+0x1f0>
    80004288:	ffffc097          	auipc	ra,0xffffc
    8000428c:	2b8080e7          	jalr	696(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004290:	00004517          	auipc	a0,0x4
    80004294:	3d850513          	addi	a0,a0,984 # 80008668 <syscalls+0x208>
    80004298:	ffffc097          	auipc	ra,0xffffc
    8000429c:	2a8080e7          	jalr	680(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800042a0:	00878693          	addi	a3,a5,8
    800042a4:	068a                	slli	a3,a3,0x2
    800042a6:	0001d717          	auipc	a4,0x1d
    800042aa:	88a70713          	addi	a4,a4,-1910 # 80020b30 <log>
    800042ae:	9736                	add	a4,a4,a3
    800042b0:	44d4                	lw	a3,12(s1)
    800042b2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800042b4:	faf609e3          	beq	a2,a5,80004266 <log_write+0x76>
  }
  release(&log.lock);
    800042b8:	0001d517          	auipc	a0,0x1d
    800042bc:	87850513          	addi	a0,a0,-1928 # 80020b30 <log>
    800042c0:	ffffd097          	auipc	ra,0xffffd
    800042c4:	9ca080e7          	jalr	-1590(ra) # 80000c8a <release>
}
    800042c8:	60e2                	ld	ra,24(sp)
    800042ca:	6442                	ld	s0,16(sp)
    800042cc:	64a2                	ld	s1,8(sp)
    800042ce:	6902                	ld	s2,0(sp)
    800042d0:	6105                	addi	sp,sp,32
    800042d2:	8082                	ret

00000000800042d4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800042d4:	1101                	addi	sp,sp,-32
    800042d6:	ec06                	sd	ra,24(sp)
    800042d8:	e822                	sd	s0,16(sp)
    800042da:	e426                	sd	s1,8(sp)
    800042dc:	e04a                	sd	s2,0(sp)
    800042de:	1000                	addi	s0,sp,32
    800042e0:	84aa                	mv	s1,a0
    800042e2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800042e4:	00004597          	auipc	a1,0x4
    800042e8:	3a458593          	addi	a1,a1,932 # 80008688 <syscalls+0x228>
    800042ec:	0521                	addi	a0,a0,8
    800042ee:	ffffd097          	auipc	ra,0xffffd
    800042f2:	858080e7          	jalr	-1960(ra) # 80000b46 <initlock>
  lk->name = name;
    800042f6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800042fa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800042fe:	0204a423          	sw	zero,40(s1)
}
    80004302:	60e2                	ld	ra,24(sp)
    80004304:	6442                	ld	s0,16(sp)
    80004306:	64a2                	ld	s1,8(sp)
    80004308:	6902                	ld	s2,0(sp)
    8000430a:	6105                	addi	sp,sp,32
    8000430c:	8082                	ret

000000008000430e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000430e:	1101                	addi	sp,sp,-32
    80004310:	ec06                	sd	ra,24(sp)
    80004312:	e822                	sd	s0,16(sp)
    80004314:	e426                	sd	s1,8(sp)
    80004316:	e04a                	sd	s2,0(sp)
    80004318:	1000                	addi	s0,sp,32
    8000431a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000431c:	00850913          	addi	s2,a0,8
    80004320:	854a                	mv	a0,s2
    80004322:	ffffd097          	auipc	ra,0xffffd
    80004326:	8b4080e7          	jalr	-1868(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000432a:	409c                	lw	a5,0(s1)
    8000432c:	cb89                	beqz	a5,8000433e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000432e:	85ca                	mv	a1,s2
    80004330:	8526                	mv	a0,s1
    80004332:	ffffe097          	auipc	ra,0xffffe
    80004336:	d44080e7          	jalr	-700(ra) # 80002076 <sleep>
  while (lk->locked) {
    8000433a:	409c                	lw	a5,0(s1)
    8000433c:	fbed                	bnez	a5,8000432e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000433e:	4785                	li	a5,1
    80004340:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004342:	ffffd097          	auipc	ra,0xffffd
    80004346:	68c080e7          	jalr	1676(ra) # 800019ce <myproc>
    8000434a:	591c                	lw	a5,48(a0)
    8000434c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000434e:	854a                	mv	a0,s2
    80004350:	ffffd097          	auipc	ra,0xffffd
    80004354:	93a080e7          	jalr	-1734(ra) # 80000c8a <release>
}
    80004358:	60e2                	ld	ra,24(sp)
    8000435a:	6442                	ld	s0,16(sp)
    8000435c:	64a2                	ld	s1,8(sp)
    8000435e:	6902                	ld	s2,0(sp)
    80004360:	6105                	addi	sp,sp,32
    80004362:	8082                	ret

0000000080004364 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004364:	1101                	addi	sp,sp,-32
    80004366:	ec06                	sd	ra,24(sp)
    80004368:	e822                	sd	s0,16(sp)
    8000436a:	e426                	sd	s1,8(sp)
    8000436c:	e04a                	sd	s2,0(sp)
    8000436e:	1000                	addi	s0,sp,32
    80004370:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004372:	00850913          	addi	s2,a0,8
    80004376:	854a                	mv	a0,s2
    80004378:	ffffd097          	auipc	ra,0xffffd
    8000437c:	85e080e7          	jalr	-1954(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004380:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004384:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004388:	8526                	mv	a0,s1
    8000438a:	ffffe097          	auipc	ra,0xffffe
    8000438e:	d50080e7          	jalr	-688(ra) # 800020da <wakeup>
  release(&lk->lk);
    80004392:	854a                	mv	a0,s2
    80004394:	ffffd097          	auipc	ra,0xffffd
    80004398:	8f6080e7          	jalr	-1802(ra) # 80000c8a <release>
}
    8000439c:	60e2                	ld	ra,24(sp)
    8000439e:	6442                	ld	s0,16(sp)
    800043a0:	64a2                	ld	s1,8(sp)
    800043a2:	6902                	ld	s2,0(sp)
    800043a4:	6105                	addi	sp,sp,32
    800043a6:	8082                	ret

00000000800043a8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043a8:	7179                	addi	sp,sp,-48
    800043aa:	f406                	sd	ra,40(sp)
    800043ac:	f022                	sd	s0,32(sp)
    800043ae:	ec26                	sd	s1,24(sp)
    800043b0:	e84a                	sd	s2,16(sp)
    800043b2:	e44e                	sd	s3,8(sp)
    800043b4:	1800                	addi	s0,sp,48
    800043b6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043b8:	00850913          	addi	s2,a0,8
    800043bc:	854a                	mv	a0,s2
    800043be:	ffffd097          	auipc	ra,0xffffd
    800043c2:	818080e7          	jalr	-2024(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800043c6:	409c                	lw	a5,0(s1)
    800043c8:	ef99                	bnez	a5,800043e6 <holdingsleep+0x3e>
    800043ca:	4481                	li	s1,0
  release(&lk->lk);
    800043cc:	854a                	mv	a0,s2
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	8bc080e7          	jalr	-1860(ra) # 80000c8a <release>
  return r;
}
    800043d6:	8526                	mv	a0,s1
    800043d8:	70a2                	ld	ra,40(sp)
    800043da:	7402                	ld	s0,32(sp)
    800043dc:	64e2                	ld	s1,24(sp)
    800043de:	6942                	ld	s2,16(sp)
    800043e0:	69a2                	ld	s3,8(sp)
    800043e2:	6145                	addi	sp,sp,48
    800043e4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800043e6:	0284a983          	lw	s3,40(s1)
    800043ea:	ffffd097          	auipc	ra,0xffffd
    800043ee:	5e4080e7          	jalr	1508(ra) # 800019ce <myproc>
    800043f2:	5904                	lw	s1,48(a0)
    800043f4:	413484b3          	sub	s1,s1,s3
    800043f8:	0014b493          	seqz	s1,s1
    800043fc:	bfc1                	j	800043cc <holdingsleep+0x24>

00000000800043fe <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800043fe:	1141                	addi	sp,sp,-16
    80004400:	e406                	sd	ra,8(sp)
    80004402:	e022                	sd	s0,0(sp)
    80004404:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004406:	00004597          	auipc	a1,0x4
    8000440a:	29258593          	addi	a1,a1,658 # 80008698 <syscalls+0x238>
    8000440e:	0001d517          	auipc	a0,0x1d
    80004412:	86a50513          	addi	a0,a0,-1942 # 80020c78 <ftable>
    80004416:	ffffc097          	auipc	ra,0xffffc
    8000441a:	730080e7          	jalr	1840(ra) # 80000b46 <initlock>
}
    8000441e:	60a2                	ld	ra,8(sp)
    80004420:	6402                	ld	s0,0(sp)
    80004422:	0141                	addi	sp,sp,16
    80004424:	8082                	ret

0000000080004426 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004426:	1101                	addi	sp,sp,-32
    80004428:	ec06                	sd	ra,24(sp)
    8000442a:	e822                	sd	s0,16(sp)
    8000442c:	e426                	sd	s1,8(sp)
    8000442e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004430:	0001d517          	auipc	a0,0x1d
    80004434:	84850513          	addi	a0,a0,-1976 # 80020c78 <ftable>
    80004438:	ffffc097          	auipc	ra,0xffffc
    8000443c:	79e080e7          	jalr	1950(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004440:	0001d497          	auipc	s1,0x1d
    80004444:	85048493          	addi	s1,s1,-1968 # 80020c90 <ftable+0x18>
    80004448:	0001d717          	auipc	a4,0x1d
    8000444c:	7e870713          	addi	a4,a4,2024 # 80021c30 <disk>
    if(f->ref == 0){
    80004450:	40dc                	lw	a5,4(s1)
    80004452:	cf99                	beqz	a5,80004470 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004454:	02848493          	addi	s1,s1,40
    80004458:	fee49ce3          	bne	s1,a4,80004450 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000445c:	0001d517          	auipc	a0,0x1d
    80004460:	81c50513          	addi	a0,a0,-2020 # 80020c78 <ftable>
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	826080e7          	jalr	-2010(ra) # 80000c8a <release>
  return 0;
    8000446c:	4481                	li	s1,0
    8000446e:	a819                	j	80004484 <filealloc+0x5e>
      f->ref = 1;
    80004470:	4785                	li	a5,1
    80004472:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004474:	0001d517          	auipc	a0,0x1d
    80004478:	80450513          	addi	a0,a0,-2044 # 80020c78 <ftable>
    8000447c:	ffffd097          	auipc	ra,0xffffd
    80004480:	80e080e7          	jalr	-2034(ra) # 80000c8a <release>
}
    80004484:	8526                	mv	a0,s1
    80004486:	60e2                	ld	ra,24(sp)
    80004488:	6442                	ld	s0,16(sp)
    8000448a:	64a2                	ld	s1,8(sp)
    8000448c:	6105                	addi	sp,sp,32
    8000448e:	8082                	ret

0000000080004490 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004490:	1101                	addi	sp,sp,-32
    80004492:	ec06                	sd	ra,24(sp)
    80004494:	e822                	sd	s0,16(sp)
    80004496:	e426                	sd	s1,8(sp)
    80004498:	1000                	addi	s0,sp,32
    8000449a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000449c:	0001c517          	auipc	a0,0x1c
    800044a0:	7dc50513          	addi	a0,a0,2012 # 80020c78 <ftable>
    800044a4:	ffffc097          	auipc	ra,0xffffc
    800044a8:	732080e7          	jalr	1842(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800044ac:	40dc                	lw	a5,4(s1)
    800044ae:	02f05263          	blez	a5,800044d2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800044b2:	2785                	addiw	a5,a5,1
    800044b4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800044b6:	0001c517          	auipc	a0,0x1c
    800044ba:	7c250513          	addi	a0,a0,1986 # 80020c78 <ftable>
    800044be:	ffffc097          	auipc	ra,0xffffc
    800044c2:	7cc080e7          	jalr	1996(ra) # 80000c8a <release>
  return f;
}
    800044c6:	8526                	mv	a0,s1
    800044c8:	60e2                	ld	ra,24(sp)
    800044ca:	6442                	ld	s0,16(sp)
    800044cc:	64a2                	ld	s1,8(sp)
    800044ce:	6105                	addi	sp,sp,32
    800044d0:	8082                	ret
    panic("filedup");
    800044d2:	00004517          	auipc	a0,0x4
    800044d6:	1ce50513          	addi	a0,a0,462 # 800086a0 <syscalls+0x240>
    800044da:	ffffc097          	auipc	ra,0xffffc
    800044de:	066080e7          	jalr	102(ra) # 80000540 <panic>

00000000800044e2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800044e2:	7139                	addi	sp,sp,-64
    800044e4:	fc06                	sd	ra,56(sp)
    800044e6:	f822                	sd	s0,48(sp)
    800044e8:	f426                	sd	s1,40(sp)
    800044ea:	f04a                	sd	s2,32(sp)
    800044ec:	ec4e                	sd	s3,24(sp)
    800044ee:	e852                	sd	s4,16(sp)
    800044f0:	e456                	sd	s5,8(sp)
    800044f2:	0080                	addi	s0,sp,64
    800044f4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800044f6:	0001c517          	auipc	a0,0x1c
    800044fa:	78250513          	addi	a0,a0,1922 # 80020c78 <ftable>
    800044fe:	ffffc097          	auipc	ra,0xffffc
    80004502:	6d8080e7          	jalr	1752(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004506:	40dc                	lw	a5,4(s1)
    80004508:	06f05163          	blez	a5,8000456a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000450c:	37fd                	addiw	a5,a5,-1
    8000450e:	0007871b          	sext.w	a4,a5
    80004512:	c0dc                	sw	a5,4(s1)
    80004514:	06e04363          	bgtz	a4,8000457a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004518:	0004a903          	lw	s2,0(s1)
    8000451c:	0094ca83          	lbu	s5,9(s1)
    80004520:	0104ba03          	ld	s4,16(s1)
    80004524:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004528:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000452c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004530:	0001c517          	auipc	a0,0x1c
    80004534:	74850513          	addi	a0,a0,1864 # 80020c78 <ftable>
    80004538:	ffffc097          	auipc	ra,0xffffc
    8000453c:	752080e7          	jalr	1874(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004540:	4785                	li	a5,1
    80004542:	04f90d63          	beq	s2,a5,8000459c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004546:	3979                	addiw	s2,s2,-2
    80004548:	4785                	li	a5,1
    8000454a:	0527e063          	bltu	a5,s2,8000458a <fileclose+0xa8>
    begin_op();
    8000454e:	00000097          	auipc	ra,0x0
    80004552:	acc080e7          	jalr	-1332(ra) # 8000401a <begin_op>
    iput(ff.ip);
    80004556:	854e                	mv	a0,s3
    80004558:	fffff097          	auipc	ra,0xfffff
    8000455c:	2b0080e7          	jalr	688(ra) # 80003808 <iput>
    end_op();
    80004560:	00000097          	auipc	ra,0x0
    80004564:	b38080e7          	jalr	-1224(ra) # 80004098 <end_op>
    80004568:	a00d                	j	8000458a <fileclose+0xa8>
    panic("fileclose");
    8000456a:	00004517          	auipc	a0,0x4
    8000456e:	13e50513          	addi	a0,a0,318 # 800086a8 <syscalls+0x248>
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	fce080e7          	jalr	-50(ra) # 80000540 <panic>
    release(&ftable.lock);
    8000457a:	0001c517          	auipc	a0,0x1c
    8000457e:	6fe50513          	addi	a0,a0,1790 # 80020c78 <ftable>
    80004582:	ffffc097          	auipc	ra,0xffffc
    80004586:	708080e7          	jalr	1800(ra) # 80000c8a <release>
  }
}
    8000458a:	70e2                	ld	ra,56(sp)
    8000458c:	7442                	ld	s0,48(sp)
    8000458e:	74a2                	ld	s1,40(sp)
    80004590:	7902                	ld	s2,32(sp)
    80004592:	69e2                	ld	s3,24(sp)
    80004594:	6a42                	ld	s4,16(sp)
    80004596:	6aa2                	ld	s5,8(sp)
    80004598:	6121                	addi	sp,sp,64
    8000459a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000459c:	85d6                	mv	a1,s5
    8000459e:	8552                	mv	a0,s4
    800045a0:	00000097          	auipc	ra,0x0
    800045a4:	34c080e7          	jalr	844(ra) # 800048ec <pipeclose>
    800045a8:	b7cd                	j	8000458a <fileclose+0xa8>

00000000800045aa <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045aa:	715d                	addi	sp,sp,-80
    800045ac:	e486                	sd	ra,72(sp)
    800045ae:	e0a2                	sd	s0,64(sp)
    800045b0:	fc26                	sd	s1,56(sp)
    800045b2:	f84a                	sd	s2,48(sp)
    800045b4:	f44e                	sd	s3,40(sp)
    800045b6:	0880                	addi	s0,sp,80
    800045b8:	84aa                	mv	s1,a0
    800045ba:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800045bc:	ffffd097          	auipc	ra,0xffffd
    800045c0:	412080e7          	jalr	1042(ra) # 800019ce <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800045c4:	409c                	lw	a5,0(s1)
    800045c6:	37f9                	addiw	a5,a5,-2
    800045c8:	4705                	li	a4,1
    800045ca:	04f76763          	bltu	a4,a5,80004618 <filestat+0x6e>
    800045ce:	892a                	mv	s2,a0
    ilock(f->ip);
    800045d0:	6c88                	ld	a0,24(s1)
    800045d2:	fffff097          	auipc	ra,0xfffff
    800045d6:	07c080e7          	jalr	124(ra) # 8000364e <ilock>
    stati(f->ip, &st);
    800045da:	fb840593          	addi	a1,s0,-72
    800045de:	6c88                	ld	a0,24(s1)
    800045e0:	fffff097          	auipc	ra,0xfffff
    800045e4:	2f8080e7          	jalr	760(ra) # 800038d8 <stati>
    iunlock(f->ip);
    800045e8:	6c88                	ld	a0,24(s1)
    800045ea:	fffff097          	auipc	ra,0xfffff
    800045ee:	126080e7          	jalr	294(ra) # 80003710 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800045f2:	46e1                	li	a3,24
    800045f4:	fb840613          	addi	a2,s0,-72
    800045f8:	85ce                	mv	a1,s3
    800045fa:	05093503          	ld	a0,80(s2)
    800045fe:	ffffd097          	auipc	ra,0xffffd
    80004602:	090080e7          	jalr	144(ra) # 8000168e <copyout>
    80004606:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000460a:	60a6                	ld	ra,72(sp)
    8000460c:	6406                	ld	s0,64(sp)
    8000460e:	74e2                	ld	s1,56(sp)
    80004610:	7942                	ld	s2,48(sp)
    80004612:	79a2                	ld	s3,40(sp)
    80004614:	6161                	addi	sp,sp,80
    80004616:	8082                	ret
  return -1;
    80004618:	557d                	li	a0,-1
    8000461a:	bfc5                	j	8000460a <filestat+0x60>

000000008000461c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000461c:	7179                	addi	sp,sp,-48
    8000461e:	f406                	sd	ra,40(sp)
    80004620:	f022                	sd	s0,32(sp)
    80004622:	ec26                	sd	s1,24(sp)
    80004624:	e84a                	sd	s2,16(sp)
    80004626:	e44e                	sd	s3,8(sp)
    80004628:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000462a:	00854783          	lbu	a5,8(a0)
    8000462e:	c3d5                	beqz	a5,800046d2 <fileread+0xb6>
    80004630:	84aa                	mv	s1,a0
    80004632:	89ae                	mv	s3,a1
    80004634:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004636:	411c                	lw	a5,0(a0)
    80004638:	4705                	li	a4,1
    8000463a:	04e78963          	beq	a5,a4,8000468c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000463e:	470d                	li	a4,3
    80004640:	04e78d63          	beq	a5,a4,8000469a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004644:	4709                	li	a4,2
    80004646:	06e79e63          	bne	a5,a4,800046c2 <fileread+0xa6>
    ilock(f->ip);
    8000464a:	6d08                	ld	a0,24(a0)
    8000464c:	fffff097          	auipc	ra,0xfffff
    80004650:	002080e7          	jalr	2(ra) # 8000364e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004654:	874a                	mv	a4,s2
    80004656:	5094                	lw	a3,32(s1)
    80004658:	864e                	mv	a2,s3
    8000465a:	4585                	li	a1,1
    8000465c:	6c88                	ld	a0,24(s1)
    8000465e:	fffff097          	auipc	ra,0xfffff
    80004662:	2a4080e7          	jalr	676(ra) # 80003902 <readi>
    80004666:	892a                	mv	s2,a0
    80004668:	00a05563          	blez	a0,80004672 <fileread+0x56>
      f->off += r;
    8000466c:	509c                	lw	a5,32(s1)
    8000466e:	9fa9                	addw	a5,a5,a0
    80004670:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004672:	6c88                	ld	a0,24(s1)
    80004674:	fffff097          	auipc	ra,0xfffff
    80004678:	09c080e7          	jalr	156(ra) # 80003710 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000467c:	854a                	mv	a0,s2
    8000467e:	70a2                	ld	ra,40(sp)
    80004680:	7402                	ld	s0,32(sp)
    80004682:	64e2                	ld	s1,24(sp)
    80004684:	6942                	ld	s2,16(sp)
    80004686:	69a2                	ld	s3,8(sp)
    80004688:	6145                	addi	sp,sp,48
    8000468a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000468c:	6908                	ld	a0,16(a0)
    8000468e:	00000097          	auipc	ra,0x0
    80004692:	3c6080e7          	jalr	966(ra) # 80004a54 <piperead>
    80004696:	892a                	mv	s2,a0
    80004698:	b7d5                	j	8000467c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000469a:	02451783          	lh	a5,36(a0)
    8000469e:	03079693          	slli	a3,a5,0x30
    800046a2:	92c1                	srli	a3,a3,0x30
    800046a4:	4725                	li	a4,9
    800046a6:	02d76863          	bltu	a4,a3,800046d6 <fileread+0xba>
    800046aa:	0792                	slli	a5,a5,0x4
    800046ac:	0001c717          	auipc	a4,0x1c
    800046b0:	52c70713          	addi	a4,a4,1324 # 80020bd8 <devsw>
    800046b4:	97ba                	add	a5,a5,a4
    800046b6:	639c                	ld	a5,0(a5)
    800046b8:	c38d                	beqz	a5,800046da <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046ba:	4505                	li	a0,1
    800046bc:	9782                	jalr	a5
    800046be:	892a                	mv	s2,a0
    800046c0:	bf75                	j	8000467c <fileread+0x60>
    panic("fileread");
    800046c2:	00004517          	auipc	a0,0x4
    800046c6:	ff650513          	addi	a0,a0,-10 # 800086b8 <syscalls+0x258>
    800046ca:	ffffc097          	auipc	ra,0xffffc
    800046ce:	e76080e7          	jalr	-394(ra) # 80000540 <panic>
    return -1;
    800046d2:	597d                	li	s2,-1
    800046d4:	b765                	j	8000467c <fileread+0x60>
      return -1;
    800046d6:	597d                	li	s2,-1
    800046d8:	b755                	j	8000467c <fileread+0x60>
    800046da:	597d                	li	s2,-1
    800046dc:	b745                	j	8000467c <fileread+0x60>

00000000800046de <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800046de:	715d                	addi	sp,sp,-80
    800046e0:	e486                	sd	ra,72(sp)
    800046e2:	e0a2                	sd	s0,64(sp)
    800046e4:	fc26                	sd	s1,56(sp)
    800046e6:	f84a                	sd	s2,48(sp)
    800046e8:	f44e                	sd	s3,40(sp)
    800046ea:	f052                	sd	s4,32(sp)
    800046ec:	ec56                	sd	s5,24(sp)
    800046ee:	e85a                	sd	s6,16(sp)
    800046f0:	e45e                	sd	s7,8(sp)
    800046f2:	e062                	sd	s8,0(sp)
    800046f4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800046f6:	00954783          	lbu	a5,9(a0)
    800046fa:	10078663          	beqz	a5,80004806 <filewrite+0x128>
    800046fe:	892a                	mv	s2,a0
    80004700:	8b2e                	mv	s6,a1
    80004702:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004704:	411c                	lw	a5,0(a0)
    80004706:	4705                	li	a4,1
    80004708:	02e78263          	beq	a5,a4,8000472c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000470c:	470d                	li	a4,3
    8000470e:	02e78663          	beq	a5,a4,8000473a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004712:	4709                	li	a4,2
    80004714:	0ee79163          	bne	a5,a4,800047f6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004718:	0ac05d63          	blez	a2,800047d2 <filewrite+0xf4>
    int i = 0;
    8000471c:	4981                	li	s3,0
    8000471e:	6b85                	lui	s7,0x1
    80004720:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004724:	6c05                	lui	s8,0x1
    80004726:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000472a:	a861                	j	800047c2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000472c:	6908                	ld	a0,16(a0)
    8000472e:	00000097          	auipc	ra,0x0
    80004732:	22e080e7          	jalr	558(ra) # 8000495c <pipewrite>
    80004736:	8a2a                	mv	s4,a0
    80004738:	a045                	j	800047d8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000473a:	02451783          	lh	a5,36(a0)
    8000473e:	03079693          	slli	a3,a5,0x30
    80004742:	92c1                	srli	a3,a3,0x30
    80004744:	4725                	li	a4,9
    80004746:	0cd76263          	bltu	a4,a3,8000480a <filewrite+0x12c>
    8000474a:	0792                	slli	a5,a5,0x4
    8000474c:	0001c717          	auipc	a4,0x1c
    80004750:	48c70713          	addi	a4,a4,1164 # 80020bd8 <devsw>
    80004754:	97ba                	add	a5,a5,a4
    80004756:	679c                	ld	a5,8(a5)
    80004758:	cbdd                	beqz	a5,8000480e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000475a:	4505                	li	a0,1
    8000475c:	9782                	jalr	a5
    8000475e:	8a2a                	mv	s4,a0
    80004760:	a8a5                	j	800047d8 <filewrite+0xfa>
    80004762:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004766:	00000097          	auipc	ra,0x0
    8000476a:	8b4080e7          	jalr	-1868(ra) # 8000401a <begin_op>
      ilock(f->ip);
    8000476e:	01893503          	ld	a0,24(s2)
    80004772:	fffff097          	auipc	ra,0xfffff
    80004776:	edc080e7          	jalr	-292(ra) # 8000364e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000477a:	8756                	mv	a4,s5
    8000477c:	02092683          	lw	a3,32(s2)
    80004780:	01698633          	add	a2,s3,s6
    80004784:	4585                	li	a1,1
    80004786:	01893503          	ld	a0,24(s2)
    8000478a:	fffff097          	auipc	ra,0xfffff
    8000478e:	270080e7          	jalr	624(ra) # 800039fa <writei>
    80004792:	84aa                	mv	s1,a0
    80004794:	00a05763          	blez	a0,800047a2 <filewrite+0xc4>
        f->off += r;
    80004798:	02092783          	lw	a5,32(s2)
    8000479c:	9fa9                	addw	a5,a5,a0
    8000479e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047a2:	01893503          	ld	a0,24(s2)
    800047a6:	fffff097          	auipc	ra,0xfffff
    800047aa:	f6a080e7          	jalr	-150(ra) # 80003710 <iunlock>
      end_op();
    800047ae:	00000097          	auipc	ra,0x0
    800047b2:	8ea080e7          	jalr	-1814(ra) # 80004098 <end_op>

      if(r != n1){
    800047b6:	009a9f63          	bne	s5,s1,800047d4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800047ba:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047be:	0149db63          	bge	s3,s4,800047d4 <filewrite+0xf6>
      int n1 = n - i;
    800047c2:	413a04bb          	subw	s1,s4,s3
    800047c6:	0004879b          	sext.w	a5,s1
    800047ca:	f8fbdce3          	bge	s7,a5,80004762 <filewrite+0x84>
    800047ce:	84e2                	mv	s1,s8
    800047d0:	bf49                	j	80004762 <filewrite+0x84>
    int i = 0;
    800047d2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800047d4:	013a1f63          	bne	s4,s3,800047f2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800047d8:	8552                	mv	a0,s4
    800047da:	60a6                	ld	ra,72(sp)
    800047dc:	6406                	ld	s0,64(sp)
    800047de:	74e2                	ld	s1,56(sp)
    800047e0:	7942                	ld	s2,48(sp)
    800047e2:	79a2                	ld	s3,40(sp)
    800047e4:	7a02                	ld	s4,32(sp)
    800047e6:	6ae2                	ld	s5,24(sp)
    800047e8:	6b42                	ld	s6,16(sp)
    800047ea:	6ba2                	ld	s7,8(sp)
    800047ec:	6c02                	ld	s8,0(sp)
    800047ee:	6161                	addi	sp,sp,80
    800047f0:	8082                	ret
    ret = (i == n ? n : -1);
    800047f2:	5a7d                	li	s4,-1
    800047f4:	b7d5                	j	800047d8 <filewrite+0xfa>
    panic("filewrite");
    800047f6:	00004517          	auipc	a0,0x4
    800047fa:	ed250513          	addi	a0,a0,-302 # 800086c8 <syscalls+0x268>
    800047fe:	ffffc097          	auipc	ra,0xffffc
    80004802:	d42080e7          	jalr	-702(ra) # 80000540 <panic>
    return -1;
    80004806:	5a7d                	li	s4,-1
    80004808:	bfc1                	j	800047d8 <filewrite+0xfa>
      return -1;
    8000480a:	5a7d                	li	s4,-1
    8000480c:	b7f1                	j	800047d8 <filewrite+0xfa>
    8000480e:	5a7d                	li	s4,-1
    80004810:	b7e1                	j	800047d8 <filewrite+0xfa>

0000000080004812 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004812:	7179                	addi	sp,sp,-48
    80004814:	f406                	sd	ra,40(sp)
    80004816:	f022                	sd	s0,32(sp)
    80004818:	ec26                	sd	s1,24(sp)
    8000481a:	e84a                	sd	s2,16(sp)
    8000481c:	e44e                	sd	s3,8(sp)
    8000481e:	e052                	sd	s4,0(sp)
    80004820:	1800                	addi	s0,sp,48
    80004822:	84aa                	mv	s1,a0
    80004824:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004826:	0005b023          	sd	zero,0(a1)
    8000482a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000482e:	00000097          	auipc	ra,0x0
    80004832:	bf8080e7          	jalr	-1032(ra) # 80004426 <filealloc>
    80004836:	e088                	sd	a0,0(s1)
    80004838:	c551                	beqz	a0,800048c4 <pipealloc+0xb2>
    8000483a:	00000097          	auipc	ra,0x0
    8000483e:	bec080e7          	jalr	-1044(ra) # 80004426 <filealloc>
    80004842:	00aa3023          	sd	a0,0(s4)
    80004846:	c92d                	beqz	a0,800048b8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004848:	ffffc097          	auipc	ra,0xffffc
    8000484c:	29e080e7          	jalr	670(ra) # 80000ae6 <kalloc>
    80004850:	892a                	mv	s2,a0
    80004852:	c125                	beqz	a0,800048b2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004854:	4985                	li	s3,1
    80004856:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000485a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000485e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004862:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004866:	00004597          	auipc	a1,0x4
    8000486a:	e7258593          	addi	a1,a1,-398 # 800086d8 <syscalls+0x278>
    8000486e:	ffffc097          	auipc	ra,0xffffc
    80004872:	2d8080e7          	jalr	728(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004876:	609c                	ld	a5,0(s1)
    80004878:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000487c:	609c                	ld	a5,0(s1)
    8000487e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004882:	609c                	ld	a5,0(s1)
    80004884:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004888:	609c                	ld	a5,0(s1)
    8000488a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000488e:	000a3783          	ld	a5,0(s4)
    80004892:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004896:	000a3783          	ld	a5,0(s4)
    8000489a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000489e:	000a3783          	ld	a5,0(s4)
    800048a2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800048a6:	000a3783          	ld	a5,0(s4)
    800048aa:	0127b823          	sd	s2,16(a5)
  return 0;
    800048ae:	4501                	li	a0,0
    800048b0:	a025                	j	800048d8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800048b2:	6088                	ld	a0,0(s1)
    800048b4:	e501                	bnez	a0,800048bc <pipealloc+0xaa>
    800048b6:	a039                	j	800048c4 <pipealloc+0xb2>
    800048b8:	6088                	ld	a0,0(s1)
    800048ba:	c51d                	beqz	a0,800048e8 <pipealloc+0xd6>
    fileclose(*f0);
    800048bc:	00000097          	auipc	ra,0x0
    800048c0:	c26080e7          	jalr	-986(ra) # 800044e2 <fileclose>
  if(*f1)
    800048c4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800048c8:	557d                	li	a0,-1
  if(*f1)
    800048ca:	c799                	beqz	a5,800048d8 <pipealloc+0xc6>
    fileclose(*f1);
    800048cc:	853e                	mv	a0,a5
    800048ce:	00000097          	auipc	ra,0x0
    800048d2:	c14080e7          	jalr	-1004(ra) # 800044e2 <fileclose>
  return -1;
    800048d6:	557d                	li	a0,-1
}
    800048d8:	70a2                	ld	ra,40(sp)
    800048da:	7402                	ld	s0,32(sp)
    800048dc:	64e2                	ld	s1,24(sp)
    800048de:	6942                	ld	s2,16(sp)
    800048e0:	69a2                	ld	s3,8(sp)
    800048e2:	6a02                	ld	s4,0(sp)
    800048e4:	6145                	addi	sp,sp,48
    800048e6:	8082                	ret
  return -1;
    800048e8:	557d                	li	a0,-1
    800048ea:	b7fd                	j	800048d8 <pipealloc+0xc6>

00000000800048ec <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800048ec:	1101                	addi	sp,sp,-32
    800048ee:	ec06                	sd	ra,24(sp)
    800048f0:	e822                	sd	s0,16(sp)
    800048f2:	e426                	sd	s1,8(sp)
    800048f4:	e04a                	sd	s2,0(sp)
    800048f6:	1000                	addi	s0,sp,32
    800048f8:	84aa                	mv	s1,a0
    800048fa:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800048fc:	ffffc097          	auipc	ra,0xffffc
    80004900:	2da080e7          	jalr	730(ra) # 80000bd6 <acquire>
  if(writable){
    80004904:	02090d63          	beqz	s2,8000493e <pipeclose+0x52>
    pi->writeopen = 0;
    80004908:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000490c:	21848513          	addi	a0,s1,536
    80004910:	ffffd097          	auipc	ra,0xffffd
    80004914:	7ca080e7          	jalr	1994(ra) # 800020da <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004918:	2204b783          	ld	a5,544(s1)
    8000491c:	eb95                	bnez	a5,80004950 <pipeclose+0x64>
    release(&pi->lock);
    8000491e:	8526                	mv	a0,s1
    80004920:	ffffc097          	auipc	ra,0xffffc
    80004924:	36a080e7          	jalr	874(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004928:	8526                	mv	a0,s1
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	0be080e7          	jalr	190(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004932:	60e2                	ld	ra,24(sp)
    80004934:	6442                	ld	s0,16(sp)
    80004936:	64a2                	ld	s1,8(sp)
    80004938:	6902                	ld	s2,0(sp)
    8000493a:	6105                	addi	sp,sp,32
    8000493c:	8082                	ret
    pi->readopen = 0;
    8000493e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004942:	21c48513          	addi	a0,s1,540
    80004946:	ffffd097          	auipc	ra,0xffffd
    8000494a:	794080e7          	jalr	1940(ra) # 800020da <wakeup>
    8000494e:	b7e9                	j	80004918 <pipeclose+0x2c>
    release(&pi->lock);
    80004950:	8526                	mv	a0,s1
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	338080e7          	jalr	824(ra) # 80000c8a <release>
}
    8000495a:	bfe1                	j	80004932 <pipeclose+0x46>

000000008000495c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000495c:	711d                	addi	sp,sp,-96
    8000495e:	ec86                	sd	ra,88(sp)
    80004960:	e8a2                	sd	s0,80(sp)
    80004962:	e4a6                	sd	s1,72(sp)
    80004964:	e0ca                	sd	s2,64(sp)
    80004966:	fc4e                	sd	s3,56(sp)
    80004968:	f852                	sd	s4,48(sp)
    8000496a:	f456                	sd	s5,40(sp)
    8000496c:	f05a                	sd	s6,32(sp)
    8000496e:	ec5e                	sd	s7,24(sp)
    80004970:	e862                	sd	s8,16(sp)
    80004972:	1080                	addi	s0,sp,96
    80004974:	84aa                	mv	s1,a0
    80004976:	8aae                	mv	s5,a1
    80004978:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000497a:	ffffd097          	auipc	ra,0xffffd
    8000497e:	054080e7          	jalr	84(ra) # 800019ce <myproc>
    80004982:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004984:	8526                	mv	a0,s1
    80004986:	ffffc097          	auipc	ra,0xffffc
    8000498a:	250080e7          	jalr	592(ra) # 80000bd6 <acquire>
  while(i < n){
    8000498e:	0b405663          	blez	s4,80004a3a <pipewrite+0xde>
  int i = 0;
    80004992:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004994:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004996:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000499a:	21c48b93          	addi	s7,s1,540
    8000499e:	a089                	j	800049e0 <pipewrite+0x84>
      release(&pi->lock);
    800049a0:	8526                	mv	a0,s1
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	2e8080e7          	jalr	744(ra) # 80000c8a <release>
      return -1;
    800049aa:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800049ac:	854a                	mv	a0,s2
    800049ae:	60e6                	ld	ra,88(sp)
    800049b0:	6446                	ld	s0,80(sp)
    800049b2:	64a6                	ld	s1,72(sp)
    800049b4:	6906                	ld	s2,64(sp)
    800049b6:	79e2                	ld	s3,56(sp)
    800049b8:	7a42                	ld	s4,48(sp)
    800049ba:	7aa2                	ld	s5,40(sp)
    800049bc:	7b02                	ld	s6,32(sp)
    800049be:	6be2                	ld	s7,24(sp)
    800049c0:	6c42                	ld	s8,16(sp)
    800049c2:	6125                	addi	sp,sp,96
    800049c4:	8082                	ret
      wakeup(&pi->nread);
    800049c6:	8562                	mv	a0,s8
    800049c8:	ffffd097          	auipc	ra,0xffffd
    800049cc:	712080e7          	jalr	1810(ra) # 800020da <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800049d0:	85a6                	mv	a1,s1
    800049d2:	855e                	mv	a0,s7
    800049d4:	ffffd097          	auipc	ra,0xffffd
    800049d8:	6a2080e7          	jalr	1698(ra) # 80002076 <sleep>
  while(i < n){
    800049dc:	07495063          	bge	s2,s4,80004a3c <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800049e0:	2204a783          	lw	a5,544(s1)
    800049e4:	dfd5                	beqz	a5,800049a0 <pipewrite+0x44>
    800049e6:	854e                	mv	a0,s3
    800049e8:	ffffe097          	auipc	ra,0xffffe
    800049ec:	936080e7          	jalr	-1738(ra) # 8000231e <killed>
    800049f0:	f945                	bnez	a0,800049a0 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800049f2:	2184a783          	lw	a5,536(s1)
    800049f6:	21c4a703          	lw	a4,540(s1)
    800049fa:	2007879b          	addiw	a5,a5,512
    800049fe:	fcf704e3          	beq	a4,a5,800049c6 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a02:	4685                	li	a3,1
    80004a04:	01590633          	add	a2,s2,s5
    80004a08:	faf40593          	addi	a1,s0,-81
    80004a0c:	0509b503          	ld	a0,80(s3)
    80004a10:	ffffd097          	auipc	ra,0xffffd
    80004a14:	d0a080e7          	jalr	-758(ra) # 8000171a <copyin>
    80004a18:	03650263          	beq	a0,s6,80004a3c <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a1c:	21c4a783          	lw	a5,540(s1)
    80004a20:	0017871b          	addiw	a4,a5,1
    80004a24:	20e4ae23          	sw	a4,540(s1)
    80004a28:	1ff7f793          	andi	a5,a5,511
    80004a2c:	97a6                	add	a5,a5,s1
    80004a2e:	faf44703          	lbu	a4,-81(s0)
    80004a32:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a36:	2905                	addiw	s2,s2,1
    80004a38:	b755                	j	800049dc <pipewrite+0x80>
  int i = 0;
    80004a3a:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004a3c:	21848513          	addi	a0,s1,536
    80004a40:	ffffd097          	auipc	ra,0xffffd
    80004a44:	69a080e7          	jalr	1690(ra) # 800020da <wakeup>
  release(&pi->lock);
    80004a48:	8526                	mv	a0,s1
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	240080e7          	jalr	576(ra) # 80000c8a <release>
  return i;
    80004a52:	bfa9                	j	800049ac <pipewrite+0x50>

0000000080004a54 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a54:	715d                	addi	sp,sp,-80
    80004a56:	e486                	sd	ra,72(sp)
    80004a58:	e0a2                	sd	s0,64(sp)
    80004a5a:	fc26                	sd	s1,56(sp)
    80004a5c:	f84a                	sd	s2,48(sp)
    80004a5e:	f44e                	sd	s3,40(sp)
    80004a60:	f052                	sd	s4,32(sp)
    80004a62:	ec56                	sd	s5,24(sp)
    80004a64:	e85a                	sd	s6,16(sp)
    80004a66:	0880                	addi	s0,sp,80
    80004a68:	84aa                	mv	s1,a0
    80004a6a:	892e                	mv	s2,a1
    80004a6c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a6e:	ffffd097          	auipc	ra,0xffffd
    80004a72:	f60080e7          	jalr	-160(ra) # 800019ce <myproc>
    80004a76:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a78:	8526                	mv	a0,s1
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	15c080e7          	jalr	348(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a82:	2184a703          	lw	a4,536(s1)
    80004a86:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a8a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a8e:	02f71763          	bne	a4,a5,80004abc <piperead+0x68>
    80004a92:	2244a783          	lw	a5,548(s1)
    80004a96:	c39d                	beqz	a5,80004abc <piperead+0x68>
    if(killed(pr)){
    80004a98:	8552                	mv	a0,s4
    80004a9a:	ffffe097          	auipc	ra,0xffffe
    80004a9e:	884080e7          	jalr	-1916(ra) # 8000231e <killed>
    80004aa2:	e949                	bnez	a0,80004b34 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aa4:	85a6                	mv	a1,s1
    80004aa6:	854e                	mv	a0,s3
    80004aa8:	ffffd097          	auipc	ra,0xffffd
    80004aac:	5ce080e7          	jalr	1486(ra) # 80002076 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ab0:	2184a703          	lw	a4,536(s1)
    80004ab4:	21c4a783          	lw	a5,540(s1)
    80004ab8:	fcf70de3          	beq	a4,a5,80004a92 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004abc:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004abe:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ac0:	05505463          	blez	s5,80004b08 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004ac4:	2184a783          	lw	a5,536(s1)
    80004ac8:	21c4a703          	lw	a4,540(s1)
    80004acc:	02f70e63          	beq	a4,a5,80004b08 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ad0:	0017871b          	addiw	a4,a5,1
    80004ad4:	20e4ac23          	sw	a4,536(s1)
    80004ad8:	1ff7f793          	andi	a5,a5,511
    80004adc:	97a6                	add	a5,a5,s1
    80004ade:	0187c783          	lbu	a5,24(a5)
    80004ae2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ae6:	4685                	li	a3,1
    80004ae8:	fbf40613          	addi	a2,s0,-65
    80004aec:	85ca                	mv	a1,s2
    80004aee:	050a3503          	ld	a0,80(s4)
    80004af2:	ffffd097          	auipc	ra,0xffffd
    80004af6:	b9c080e7          	jalr	-1124(ra) # 8000168e <copyout>
    80004afa:	01650763          	beq	a0,s6,80004b08 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004afe:	2985                	addiw	s3,s3,1
    80004b00:	0905                	addi	s2,s2,1
    80004b02:	fd3a91e3          	bne	s5,s3,80004ac4 <piperead+0x70>
    80004b06:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b08:	21c48513          	addi	a0,s1,540
    80004b0c:	ffffd097          	auipc	ra,0xffffd
    80004b10:	5ce080e7          	jalr	1486(ra) # 800020da <wakeup>
  release(&pi->lock);
    80004b14:	8526                	mv	a0,s1
    80004b16:	ffffc097          	auipc	ra,0xffffc
    80004b1a:	174080e7          	jalr	372(ra) # 80000c8a <release>
  return i;
}
    80004b1e:	854e                	mv	a0,s3
    80004b20:	60a6                	ld	ra,72(sp)
    80004b22:	6406                	ld	s0,64(sp)
    80004b24:	74e2                	ld	s1,56(sp)
    80004b26:	7942                	ld	s2,48(sp)
    80004b28:	79a2                	ld	s3,40(sp)
    80004b2a:	7a02                	ld	s4,32(sp)
    80004b2c:	6ae2                	ld	s5,24(sp)
    80004b2e:	6b42                	ld	s6,16(sp)
    80004b30:	6161                	addi	sp,sp,80
    80004b32:	8082                	ret
      release(&pi->lock);
    80004b34:	8526                	mv	a0,s1
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	154080e7          	jalr	340(ra) # 80000c8a <release>
      return -1;
    80004b3e:	59fd                	li	s3,-1
    80004b40:	bff9                	j	80004b1e <piperead+0xca>

0000000080004b42 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004b42:	1141                	addi	sp,sp,-16
    80004b44:	e422                	sd	s0,8(sp)
    80004b46:	0800                	addi	s0,sp,16
    80004b48:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004b4a:	8905                	andi	a0,a0,1
    80004b4c:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004b4e:	8b89                	andi	a5,a5,2
    80004b50:	c399                	beqz	a5,80004b56 <flags2perm+0x14>
      perm |= PTE_W;
    80004b52:	00456513          	ori	a0,a0,4
    return perm;
}
    80004b56:	6422                	ld	s0,8(sp)
    80004b58:	0141                	addi	sp,sp,16
    80004b5a:	8082                	ret

0000000080004b5c <exec>:

int
exec(char *path, char **argv)
{
    80004b5c:	de010113          	addi	sp,sp,-544
    80004b60:	20113c23          	sd	ra,536(sp)
    80004b64:	20813823          	sd	s0,528(sp)
    80004b68:	20913423          	sd	s1,520(sp)
    80004b6c:	21213023          	sd	s2,512(sp)
    80004b70:	ffce                	sd	s3,504(sp)
    80004b72:	fbd2                	sd	s4,496(sp)
    80004b74:	f7d6                	sd	s5,488(sp)
    80004b76:	f3da                	sd	s6,480(sp)
    80004b78:	efde                	sd	s7,472(sp)
    80004b7a:	ebe2                	sd	s8,464(sp)
    80004b7c:	e7e6                	sd	s9,456(sp)
    80004b7e:	e3ea                	sd	s10,448(sp)
    80004b80:	ff6e                	sd	s11,440(sp)
    80004b82:	1400                	addi	s0,sp,544
    80004b84:	892a                	mv	s2,a0
    80004b86:	dea43423          	sd	a0,-536(s0)
    80004b8a:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b8e:	ffffd097          	auipc	ra,0xffffd
    80004b92:	e40080e7          	jalr	-448(ra) # 800019ce <myproc>
    80004b96:	84aa                	mv	s1,a0

  begin_op();
    80004b98:	fffff097          	auipc	ra,0xfffff
    80004b9c:	482080e7          	jalr	1154(ra) # 8000401a <begin_op>

  if((ip = namei(path)) == 0){
    80004ba0:	854a                	mv	a0,s2
    80004ba2:	fffff097          	auipc	ra,0xfffff
    80004ba6:	258080e7          	jalr	600(ra) # 80003dfa <namei>
    80004baa:	c93d                	beqz	a0,80004c20 <exec+0xc4>
    80004bac:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004bae:	fffff097          	auipc	ra,0xfffff
    80004bb2:	aa0080e7          	jalr	-1376(ra) # 8000364e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004bb6:	04000713          	li	a4,64
    80004bba:	4681                	li	a3,0
    80004bbc:	e5040613          	addi	a2,s0,-432
    80004bc0:	4581                	li	a1,0
    80004bc2:	8556                	mv	a0,s5
    80004bc4:	fffff097          	auipc	ra,0xfffff
    80004bc8:	d3e080e7          	jalr	-706(ra) # 80003902 <readi>
    80004bcc:	04000793          	li	a5,64
    80004bd0:	00f51a63          	bne	a0,a5,80004be4 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004bd4:	e5042703          	lw	a4,-432(s0)
    80004bd8:	464c47b7          	lui	a5,0x464c4
    80004bdc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004be0:	04f70663          	beq	a4,a5,80004c2c <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004be4:	8556                	mv	a0,s5
    80004be6:	fffff097          	auipc	ra,0xfffff
    80004bea:	cca080e7          	jalr	-822(ra) # 800038b0 <iunlockput>
    end_op();
    80004bee:	fffff097          	auipc	ra,0xfffff
    80004bf2:	4aa080e7          	jalr	1194(ra) # 80004098 <end_op>
  }
  return -1;
    80004bf6:	557d                	li	a0,-1
}
    80004bf8:	21813083          	ld	ra,536(sp)
    80004bfc:	21013403          	ld	s0,528(sp)
    80004c00:	20813483          	ld	s1,520(sp)
    80004c04:	20013903          	ld	s2,512(sp)
    80004c08:	79fe                	ld	s3,504(sp)
    80004c0a:	7a5e                	ld	s4,496(sp)
    80004c0c:	7abe                	ld	s5,488(sp)
    80004c0e:	7b1e                	ld	s6,480(sp)
    80004c10:	6bfe                	ld	s7,472(sp)
    80004c12:	6c5e                	ld	s8,464(sp)
    80004c14:	6cbe                	ld	s9,456(sp)
    80004c16:	6d1e                	ld	s10,448(sp)
    80004c18:	7dfa                	ld	s11,440(sp)
    80004c1a:	22010113          	addi	sp,sp,544
    80004c1e:	8082                	ret
    end_op();
    80004c20:	fffff097          	auipc	ra,0xfffff
    80004c24:	478080e7          	jalr	1144(ra) # 80004098 <end_op>
    return -1;
    80004c28:	557d                	li	a0,-1
    80004c2a:	b7f9                	j	80004bf8 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c2c:	8526                	mv	a0,s1
    80004c2e:	ffffd097          	auipc	ra,0xffffd
    80004c32:	e64080e7          	jalr	-412(ra) # 80001a92 <proc_pagetable>
    80004c36:	8b2a                	mv	s6,a0
    80004c38:	d555                	beqz	a0,80004be4 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c3a:	e7042783          	lw	a5,-400(s0)
    80004c3e:	e8845703          	lhu	a4,-376(s0)
    80004c42:	c735                	beqz	a4,80004cae <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c44:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c46:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004c4a:	6a05                	lui	s4,0x1
    80004c4c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004c50:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004c54:	6d85                	lui	s11,0x1
    80004c56:	7d7d                	lui	s10,0xfffff
    80004c58:	a4a9                	j	80004ea2 <exec+0x346>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004c5a:	00004517          	auipc	a0,0x4
    80004c5e:	a8650513          	addi	a0,a0,-1402 # 800086e0 <syscalls+0x280>
    80004c62:	ffffc097          	auipc	ra,0xffffc
    80004c66:	8de080e7          	jalr	-1826(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c6a:	874a                	mv	a4,s2
    80004c6c:	009c86bb          	addw	a3,s9,s1
    80004c70:	4581                	li	a1,0
    80004c72:	8556                	mv	a0,s5
    80004c74:	fffff097          	auipc	ra,0xfffff
    80004c78:	c8e080e7          	jalr	-882(ra) # 80003902 <readi>
    80004c7c:	2501                	sext.w	a0,a0
    80004c7e:	1aa91f63          	bne	s2,a0,80004e3c <exec+0x2e0>
  for(i = 0; i < sz; i += PGSIZE){
    80004c82:	009d84bb          	addw	s1,s11,s1
    80004c86:	013d09bb          	addw	s3,s10,s3
    80004c8a:	1f74fc63          	bgeu	s1,s7,80004e82 <exec+0x326>
    pa = walkaddr(pagetable, va + i);
    80004c8e:	02049593          	slli	a1,s1,0x20
    80004c92:	9181                	srli	a1,a1,0x20
    80004c94:	95e2                	add	a1,a1,s8
    80004c96:	855a                	mv	a0,s6
    80004c98:	ffffc097          	auipc	ra,0xffffc
    80004c9c:	3e6080e7          	jalr	998(ra) # 8000107e <walkaddr>
    80004ca0:	862a                	mv	a2,a0
    if(pa == 0)
    80004ca2:	dd45                	beqz	a0,80004c5a <exec+0xfe>
      n = PGSIZE;
    80004ca4:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004ca6:	fd49f2e3          	bgeu	s3,s4,80004c6a <exec+0x10e>
      n = sz - i;
    80004caa:	894e                	mv	s2,s3
    80004cac:	bf7d                	j	80004c6a <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cae:	4901                	li	s2,0
  iunlockput(ip);
    80004cb0:	8556                	mv	a0,s5
    80004cb2:	fffff097          	auipc	ra,0xfffff
    80004cb6:	bfe080e7          	jalr	-1026(ra) # 800038b0 <iunlockput>
  end_op();
    80004cba:	fffff097          	auipc	ra,0xfffff
    80004cbe:	3de080e7          	jalr	990(ra) # 80004098 <end_op>
  p = myproc();
    80004cc2:	ffffd097          	auipc	ra,0xffffd
    80004cc6:	d0c080e7          	jalr	-756(ra) # 800019ce <myproc>
    80004cca:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004ccc:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004cd0:	6785                	lui	a5,0x1
    80004cd2:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004cd4:	97ca                	add	a5,a5,s2
    80004cd6:	777d                	lui	a4,0xfffff
    80004cd8:	8ff9                	and	a5,a5,a4
    80004cda:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004cde:	4691                	li	a3,4
    80004ce0:	6609                	lui	a2,0x2
    80004ce2:	963e                	add	a2,a2,a5
    80004ce4:	85be                	mv	a1,a5
    80004ce6:	855a                	mv	a0,s6
    80004ce8:	ffffc097          	auipc	ra,0xffffc
    80004cec:	74a080e7          	jalr	1866(ra) # 80001432 <uvmalloc>
    80004cf0:	8c2a                	mv	s8,a0
  ip = 0;
    80004cf2:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004cf4:	14050463          	beqz	a0,80004e3c <exec+0x2e0>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004cf8:	75f9                	lui	a1,0xffffe
    80004cfa:	95aa                	add	a1,a1,a0
    80004cfc:	855a                	mv	a0,s6
    80004cfe:	ffffd097          	auipc	ra,0xffffd
    80004d02:	95e080e7          	jalr	-1698(ra) # 8000165c <uvmclear>
  stackbase = sp - PGSIZE;
    80004d06:	7afd                	lui	s5,0xfffff
    80004d08:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d0a:	df043783          	ld	a5,-528(s0)
    80004d0e:	6388                	ld	a0,0(a5)
    80004d10:	c925                	beqz	a0,80004d80 <exec+0x224>
    80004d12:	e9040993          	addi	s3,s0,-368
    80004d16:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004d1a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d1c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	130080e7          	jalr	304(ra) # 80000e4e <strlen>
    80004d26:	0015079b          	addiw	a5,a0,1
    80004d2a:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d2e:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004d32:	13596c63          	bltu	s2,s5,80004e6a <exec+0x30e>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d36:	df043d83          	ld	s11,-528(s0)
    80004d3a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004d3e:	8552                	mv	a0,s4
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	10e080e7          	jalr	270(ra) # 80000e4e <strlen>
    80004d48:	0015069b          	addiw	a3,a0,1
    80004d4c:	8652                	mv	a2,s4
    80004d4e:	85ca                	mv	a1,s2
    80004d50:	855a                	mv	a0,s6
    80004d52:	ffffd097          	auipc	ra,0xffffd
    80004d56:	93c080e7          	jalr	-1732(ra) # 8000168e <copyout>
    80004d5a:	10054c63          	bltz	a0,80004e72 <exec+0x316>
    ustack[argc] = sp;
    80004d5e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d62:	0485                	addi	s1,s1,1
    80004d64:	008d8793          	addi	a5,s11,8
    80004d68:	def43823          	sd	a5,-528(s0)
    80004d6c:	008db503          	ld	a0,8(s11)
    80004d70:	c911                	beqz	a0,80004d84 <exec+0x228>
    if(argc >= MAXARG)
    80004d72:	09a1                	addi	s3,s3,8
    80004d74:	fb3c95e3          	bne	s9,s3,80004d1e <exec+0x1c2>
  sz = sz1;
    80004d78:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d7c:	4a81                	li	s5,0
    80004d7e:	a87d                	j	80004e3c <exec+0x2e0>
  sp = sz;
    80004d80:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d82:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d84:	00349793          	slli	a5,s1,0x3
    80004d88:	f9078793          	addi	a5,a5,-112
    80004d8c:	97a2                	add	a5,a5,s0
    80004d8e:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004d92:	00148693          	addi	a3,s1,1
    80004d96:	068e                	slli	a3,a3,0x3
    80004d98:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d9c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004da0:	01597663          	bgeu	s2,s5,80004dac <exec+0x250>
  sz = sz1;
    80004da4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004da8:	4a81                	li	s5,0
    80004daa:	a849                	j	80004e3c <exec+0x2e0>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004dac:	e9040613          	addi	a2,s0,-368
    80004db0:	85ca                	mv	a1,s2
    80004db2:	855a                	mv	a0,s6
    80004db4:	ffffd097          	auipc	ra,0xffffd
    80004db8:	8da080e7          	jalr	-1830(ra) # 8000168e <copyout>
    80004dbc:	0a054f63          	bltz	a0,80004e7a <exec+0x31e>
  p->trapframe->a1 = sp;
    80004dc0:	058bb783          	ld	a5,88(s7)
    80004dc4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004dc8:	de843783          	ld	a5,-536(s0)
    80004dcc:	0007c703          	lbu	a4,0(a5)
    80004dd0:	cf11                	beqz	a4,80004dec <exec+0x290>
    80004dd2:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004dd4:	02f00693          	li	a3,47
    80004dd8:	a039                	j	80004de6 <exec+0x28a>
      last = s+1;
    80004dda:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004dde:	0785                	addi	a5,a5,1
    80004de0:	fff7c703          	lbu	a4,-1(a5)
    80004de4:	c701                	beqz	a4,80004dec <exec+0x290>
    if(*s == '/')
    80004de6:	fed71ce3          	bne	a4,a3,80004dde <exec+0x282>
    80004dea:	bfc5                	j	80004dda <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004dec:	4641                	li	a2,16
    80004dee:	de843583          	ld	a1,-536(s0)
    80004df2:	158b8513          	addi	a0,s7,344
    80004df6:	ffffc097          	auipc	ra,0xffffc
    80004dfa:	026080e7          	jalr	38(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004dfe:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e02:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e06:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e0a:	058bb783          	ld	a5,88(s7)
    80004e0e:	e6843703          	ld	a4,-408(s0)
    80004e12:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e14:	058bb783          	ld	a5,88(s7)
    80004e18:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e1c:	85ea                	mv	a1,s10
    80004e1e:	ffffd097          	auipc	ra,0xffffd
    80004e22:	d10080e7          	jalr	-752(ra) # 80001b2e <proc_freepagetable>
  vmprint(p->pagetable);
    80004e26:	050bb503          	ld	a0,80(s7)
    80004e2a:	ffffc097          	auipc	ra,0xffffc
    80004e2e:	164080e7          	jalr	356(ra) # 80000f8e <vmprint>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e32:	0004851b          	sext.w	a0,s1
    80004e36:	b3c9                	j	80004bf8 <exec+0x9c>
    80004e38:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004e3c:	df843583          	ld	a1,-520(s0)
    80004e40:	855a                	mv	a0,s6
    80004e42:	ffffd097          	auipc	ra,0xffffd
    80004e46:	cec080e7          	jalr	-788(ra) # 80001b2e <proc_freepagetable>
  if(ip){
    80004e4a:	d80a9de3          	bnez	s5,80004be4 <exec+0x88>
  return -1;
    80004e4e:	557d                	li	a0,-1
    80004e50:	b365                	j	80004bf8 <exec+0x9c>
    80004e52:	df243c23          	sd	s2,-520(s0)
    80004e56:	b7dd                	j	80004e3c <exec+0x2e0>
    80004e58:	df243c23          	sd	s2,-520(s0)
    80004e5c:	b7c5                	j	80004e3c <exec+0x2e0>
    80004e5e:	df243c23          	sd	s2,-520(s0)
    80004e62:	bfe9                	j	80004e3c <exec+0x2e0>
    80004e64:	df243c23          	sd	s2,-520(s0)
    80004e68:	bfd1                	j	80004e3c <exec+0x2e0>
  sz = sz1;
    80004e6a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e6e:	4a81                	li	s5,0
    80004e70:	b7f1                	j	80004e3c <exec+0x2e0>
  sz = sz1;
    80004e72:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e76:	4a81                	li	s5,0
    80004e78:	b7d1                	j	80004e3c <exec+0x2e0>
  sz = sz1;
    80004e7a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e7e:	4a81                	li	s5,0
    80004e80:	bf75                	j	80004e3c <exec+0x2e0>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004e82:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e86:	e0843783          	ld	a5,-504(s0)
    80004e8a:	0017869b          	addiw	a3,a5,1
    80004e8e:	e0d43423          	sd	a3,-504(s0)
    80004e92:	e0043783          	ld	a5,-512(s0)
    80004e96:	0387879b          	addiw	a5,a5,56
    80004e9a:	e8845703          	lhu	a4,-376(s0)
    80004e9e:	e0e6d9e3          	bge	a3,a4,80004cb0 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ea2:	2781                	sext.w	a5,a5
    80004ea4:	e0f43023          	sd	a5,-512(s0)
    80004ea8:	03800713          	li	a4,56
    80004eac:	86be                	mv	a3,a5
    80004eae:	e1840613          	addi	a2,s0,-488
    80004eb2:	4581                	li	a1,0
    80004eb4:	8556                	mv	a0,s5
    80004eb6:	fffff097          	auipc	ra,0xfffff
    80004eba:	a4c080e7          	jalr	-1460(ra) # 80003902 <readi>
    80004ebe:	03800793          	li	a5,56
    80004ec2:	f6f51be3          	bne	a0,a5,80004e38 <exec+0x2dc>
    if(ph.type != ELF_PROG_LOAD)
    80004ec6:	e1842783          	lw	a5,-488(s0)
    80004eca:	4705                	li	a4,1
    80004ecc:	fae79de3          	bne	a5,a4,80004e86 <exec+0x32a>
    if(ph.memsz < ph.filesz)
    80004ed0:	e4043483          	ld	s1,-448(s0)
    80004ed4:	e3843783          	ld	a5,-456(s0)
    80004ed8:	f6f4ede3          	bltu	s1,a5,80004e52 <exec+0x2f6>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004edc:	e2843783          	ld	a5,-472(s0)
    80004ee0:	94be                	add	s1,s1,a5
    80004ee2:	f6f4ebe3          	bltu	s1,a5,80004e58 <exec+0x2fc>
    if(ph.vaddr % PGSIZE != 0)
    80004ee6:	de043703          	ld	a4,-544(s0)
    80004eea:	8ff9                	and	a5,a5,a4
    80004eec:	fbad                	bnez	a5,80004e5e <exec+0x302>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004eee:	e1c42503          	lw	a0,-484(s0)
    80004ef2:	00000097          	auipc	ra,0x0
    80004ef6:	c50080e7          	jalr	-944(ra) # 80004b42 <flags2perm>
    80004efa:	86aa                	mv	a3,a0
    80004efc:	8626                	mv	a2,s1
    80004efe:	85ca                	mv	a1,s2
    80004f00:	855a                	mv	a0,s6
    80004f02:	ffffc097          	auipc	ra,0xffffc
    80004f06:	530080e7          	jalr	1328(ra) # 80001432 <uvmalloc>
    80004f0a:	dea43c23          	sd	a0,-520(s0)
    80004f0e:	d939                	beqz	a0,80004e64 <exec+0x308>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f10:	e2843c03          	ld	s8,-472(s0)
    80004f14:	e2042c83          	lw	s9,-480(s0)
    80004f18:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f1c:	f60b83e3          	beqz	s7,80004e82 <exec+0x326>
    80004f20:	89de                	mv	s3,s7
    80004f22:	4481                	li	s1,0
    80004f24:	b3ad                	j	80004c8e <exec+0x132>

0000000080004f26 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f26:	7179                	addi	sp,sp,-48
    80004f28:	f406                	sd	ra,40(sp)
    80004f2a:	f022                	sd	s0,32(sp)
    80004f2c:	ec26                	sd	s1,24(sp)
    80004f2e:	e84a                	sd	s2,16(sp)
    80004f30:	1800                	addi	s0,sp,48
    80004f32:	892e                	mv	s2,a1
    80004f34:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004f36:	fdc40593          	addi	a1,s0,-36
    80004f3a:	ffffe097          	auipc	ra,0xffffe
    80004f3e:	baa080e7          	jalr	-1110(ra) # 80002ae4 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f42:	fdc42703          	lw	a4,-36(s0)
    80004f46:	47bd                	li	a5,15
    80004f48:	02e7eb63          	bltu	a5,a4,80004f7e <argfd+0x58>
    80004f4c:	ffffd097          	auipc	ra,0xffffd
    80004f50:	a82080e7          	jalr	-1406(ra) # 800019ce <myproc>
    80004f54:	fdc42703          	lw	a4,-36(s0)
    80004f58:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd2aa>
    80004f5c:	078e                	slli	a5,a5,0x3
    80004f5e:	953e                	add	a0,a0,a5
    80004f60:	611c                	ld	a5,0(a0)
    80004f62:	c385                	beqz	a5,80004f82 <argfd+0x5c>
    return -1;
  if(pfd)
    80004f64:	00090463          	beqz	s2,80004f6c <argfd+0x46>
    *pfd = fd;
    80004f68:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004f6c:	4501                	li	a0,0
  if(pf)
    80004f6e:	c091                	beqz	s1,80004f72 <argfd+0x4c>
    *pf = f;
    80004f70:	e09c                	sd	a5,0(s1)
}
    80004f72:	70a2                	ld	ra,40(sp)
    80004f74:	7402                	ld	s0,32(sp)
    80004f76:	64e2                	ld	s1,24(sp)
    80004f78:	6942                	ld	s2,16(sp)
    80004f7a:	6145                	addi	sp,sp,48
    80004f7c:	8082                	ret
    return -1;
    80004f7e:	557d                	li	a0,-1
    80004f80:	bfcd                	j	80004f72 <argfd+0x4c>
    80004f82:	557d                	li	a0,-1
    80004f84:	b7fd                	j	80004f72 <argfd+0x4c>

0000000080004f86 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f86:	1101                	addi	sp,sp,-32
    80004f88:	ec06                	sd	ra,24(sp)
    80004f8a:	e822                	sd	s0,16(sp)
    80004f8c:	e426                	sd	s1,8(sp)
    80004f8e:	1000                	addi	s0,sp,32
    80004f90:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f92:	ffffd097          	auipc	ra,0xffffd
    80004f96:	a3c080e7          	jalr	-1476(ra) # 800019ce <myproc>
    80004f9a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f9c:	0d050793          	addi	a5,a0,208
    80004fa0:	4501                	li	a0,0
    80004fa2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004fa4:	6398                	ld	a4,0(a5)
    80004fa6:	cb19                	beqz	a4,80004fbc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004fa8:	2505                	addiw	a0,a0,1
    80004faa:	07a1                	addi	a5,a5,8
    80004fac:	fed51ce3          	bne	a0,a3,80004fa4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004fb0:	557d                	li	a0,-1
}
    80004fb2:	60e2                	ld	ra,24(sp)
    80004fb4:	6442                	ld	s0,16(sp)
    80004fb6:	64a2                	ld	s1,8(sp)
    80004fb8:	6105                	addi	sp,sp,32
    80004fba:	8082                	ret
      p->ofile[fd] = f;
    80004fbc:	01a50793          	addi	a5,a0,26
    80004fc0:	078e                	slli	a5,a5,0x3
    80004fc2:	963e                	add	a2,a2,a5
    80004fc4:	e204                	sd	s1,0(a2)
      return fd;
    80004fc6:	b7f5                	j	80004fb2 <fdalloc+0x2c>

0000000080004fc8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004fc8:	715d                	addi	sp,sp,-80
    80004fca:	e486                	sd	ra,72(sp)
    80004fcc:	e0a2                	sd	s0,64(sp)
    80004fce:	fc26                	sd	s1,56(sp)
    80004fd0:	f84a                	sd	s2,48(sp)
    80004fd2:	f44e                	sd	s3,40(sp)
    80004fd4:	f052                	sd	s4,32(sp)
    80004fd6:	ec56                	sd	s5,24(sp)
    80004fd8:	e85a                	sd	s6,16(sp)
    80004fda:	0880                	addi	s0,sp,80
    80004fdc:	8b2e                	mv	s6,a1
    80004fde:	89b2                	mv	s3,a2
    80004fe0:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004fe2:	fb040593          	addi	a1,s0,-80
    80004fe6:	fffff097          	auipc	ra,0xfffff
    80004fea:	e32080e7          	jalr	-462(ra) # 80003e18 <nameiparent>
    80004fee:	84aa                	mv	s1,a0
    80004ff0:	14050f63          	beqz	a0,8000514e <create+0x186>
    return 0;

  ilock(dp);
    80004ff4:	ffffe097          	auipc	ra,0xffffe
    80004ff8:	65a080e7          	jalr	1626(ra) # 8000364e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004ffc:	4601                	li	a2,0
    80004ffe:	fb040593          	addi	a1,s0,-80
    80005002:	8526                	mv	a0,s1
    80005004:	fffff097          	auipc	ra,0xfffff
    80005008:	b2e080e7          	jalr	-1234(ra) # 80003b32 <dirlookup>
    8000500c:	8aaa                	mv	s5,a0
    8000500e:	c931                	beqz	a0,80005062 <create+0x9a>
    iunlockput(dp);
    80005010:	8526                	mv	a0,s1
    80005012:	fffff097          	auipc	ra,0xfffff
    80005016:	89e080e7          	jalr	-1890(ra) # 800038b0 <iunlockput>
    ilock(ip);
    8000501a:	8556                	mv	a0,s5
    8000501c:	ffffe097          	auipc	ra,0xffffe
    80005020:	632080e7          	jalr	1586(ra) # 8000364e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005024:	000b059b          	sext.w	a1,s6
    80005028:	4789                	li	a5,2
    8000502a:	02f59563          	bne	a1,a5,80005054 <create+0x8c>
    8000502e:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd2d4>
    80005032:	37f9                	addiw	a5,a5,-2
    80005034:	17c2                	slli	a5,a5,0x30
    80005036:	93c1                	srli	a5,a5,0x30
    80005038:	4705                	li	a4,1
    8000503a:	00f76d63          	bltu	a4,a5,80005054 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000503e:	8556                	mv	a0,s5
    80005040:	60a6                	ld	ra,72(sp)
    80005042:	6406                	ld	s0,64(sp)
    80005044:	74e2                	ld	s1,56(sp)
    80005046:	7942                	ld	s2,48(sp)
    80005048:	79a2                	ld	s3,40(sp)
    8000504a:	7a02                	ld	s4,32(sp)
    8000504c:	6ae2                	ld	s5,24(sp)
    8000504e:	6b42                	ld	s6,16(sp)
    80005050:	6161                	addi	sp,sp,80
    80005052:	8082                	ret
    iunlockput(ip);
    80005054:	8556                	mv	a0,s5
    80005056:	fffff097          	auipc	ra,0xfffff
    8000505a:	85a080e7          	jalr	-1958(ra) # 800038b0 <iunlockput>
    return 0;
    8000505e:	4a81                	li	s5,0
    80005060:	bff9                	j	8000503e <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005062:	85da                	mv	a1,s6
    80005064:	4088                	lw	a0,0(s1)
    80005066:	ffffe097          	auipc	ra,0xffffe
    8000506a:	44a080e7          	jalr	1098(ra) # 800034b0 <ialloc>
    8000506e:	8a2a                	mv	s4,a0
    80005070:	c539                	beqz	a0,800050be <create+0xf6>
  ilock(ip);
    80005072:	ffffe097          	auipc	ra,0xffffe
    80005076:	5dc080e7          	jalr	1500(ra) # 8000364e <ilock>
  ip->major = major;
    8000507a:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000507e:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005082:	4905                	li	s2,1
    80005084:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005088:	8552                	mv	a0,s4
    8000508a:	ffffe097          	auipc	ra,0xffffe
    8000508e:	4f8080e7          	jalr	1272(ra) # 80003582 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005092:	000b059b          	sext.w	a1,s6
    80005096:	03258b63          	beq	a1,s2,800050cc <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000509a:	004a2603          	lw	a2,4(s4)
    8000509e:	fb040593          	addi	a1,s0,-80
    800050a2:	8526                	mv	a0,s1
    800050a4:	fffff097          	auipc	ra,0xfffff
    800050a8:	ca4080e7          	jalr	-860(ra) # 80003d48 <dirlink>
    800050ac:	06054f63          	bltz	a0,8000512a <create+0x162>
  iunlockput(dp);
    800050b0:	8526                	mv	a0,s1
    800050b2:	ffffe097          	auipc	ra,0xffffe
    800050b6:	7fe080e7          	jalr	2046(ra) # 800038b0 <iunlockput>
  return ip;
    800050ba:	8ad2                	mv	s5,s4
    800050bc:	b749                	j	8000503e <create+0x76>
    iunlockput(dp);
    800050be:	8526                	mv	a0,s1
    800050c0:	ffffe097          	auipc	ra,0xffffe
    800050c4:	7f0080e7          	jalr	2032(ra) # 800038b0 <iunlockput>
    return 0;
    800050c8:	8ad2                	mv	s5,s4
    800050ca:	bf95                	j	8000503e <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800050cc:	004a2603          	lw	a2,4(s4)
    800050d0:	00003597          	auipc	a1,0x3
    800050d4:	63058593          	addi	a1,a1,1584 # 80008700 <syscalls+0x2a0>
    800050d8:	8552                	mv	a0,s4
    800050da:	fffff097          	auipc	ra,0xfffff
    800050de:	c6e080e7          	jalr	-914(ra) # 80003d48 <dirlink>
    800050e2:	04054463          	bltz	a0,8000512a <create+0x162>
    800050e6:	40d0                	lw	a2,4(s1)
    800050e8:	00003597          	auipc	a1,0x3
    800050ec:	62058593          	addi	a1,a1,1568 # 80008708 <syscalls+0x2a8>
    800050f0:	8552                	mv	a0,s4
    800050f2:	fffff097          	auipc	ra,0xfffff
    800050f6:	c56080e7          	jalr	-938(ra) # 80003d48 <dirlink>
    800050fa:	02054863          	bltz	a0,8000512a <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800050fe:	004a2603          	lw	a2,4(s4)
    80005102:	fb040593          	addi	a1,s0,-80
    80005106:	8526                	mv	a0,s1
    80005108:	fffff097          	auipc	ra,0xfffff
    8000510c:	c40080e7          	jalr	-960(ra) # 80003d48 <dirlink>
    80005110:	00054d63          	bltz	a0,8000512a <create+0x162>
    dp->nlink++;  // for ".."
    80005114:	04a4d783          	lhu	a5,74(s1)
    80005118:	2785                	addiw	a5,a5,1
    8000511a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000511e:	8526                	mv	a0,s1
    80005120:	ffffe097          	auipc	ra,0xffffe
    80005124:	462080e7          	jalr	1122(ra) # 80003582 <iupdate>
    80005128:	b761                	j	800050b0 <create+0xe8>
  ip->nlink = 0;
    8000512a:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000512e:	8552                	mv	a0,s4
    80005130:	ffffe097          	auipc	ra,0xffffe
    80005134:	452080e7          	jalr	1106(ra) # 80003582 <iupdate>
  iunlockput(ip);
    80005138:	8552                	mv	a0,s4
    8000513a:	ffffe097          	auipc	ra,0xffffe
    8000513e:	776080e7          	jalr	1910(ra) # 800038b0 <iunlockput>
  iunlockput(dp);
    80005142:	8526                	mv	a0,s1
    80005144:	ffffe097          	auipc	ra,0xffffe
    80005148:	76c080e7          	jalr	1900(ra) # 800038b0 <iunlockput>
  return 0;
    8000514c:	bdcd                	j	8000503e <create+0x76>
    return 0;
    8000514e:	8aaa                	mv	s5,a0
    80005150:	b5fd                	j	8000503e <create+0x76>

0000000080005152 <sys_dup>:
{
    80005152:	7179                	addi	sp,sp,-48
    80005154:	f406                	sd	ra,40(sp)
    80005156:	f022                	sd	s0,32(sp)
    80005158:	ec26                	sd	s1,24(sp)
    8000515a:	e84a                	sd	s2,16(sp)
    8000515c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000515e:	fd840613          	addi	a2,s0,-40
    80005162:	4581                	li	a1,0
    80005164:	4501                	li	a0,0
    80005166:	00000097          	auipc	ra,0x0
    8000516a:	dc0080e7          	jalr	-576(ra) # 80004f26 <argfd>
    return -1;
    8000516e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005170:	02054363          	bltz	a0,80005196 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005174:	fd843903          	ld	s2,-40(s0)
    80005178:	854a                	mv	a0,s2
    8000517a:	00000097          	auipc	ra,0x0
    8000517e:	e0c080e7          	jalr	-500(ra) # 80004f86 <fdalloc>
    80005182:	84aa                	mv	s1,a0
    return -1;
    80005184:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005186:	00054863          	bltz	a0,80005196 <sys_dup+0x44>
  filedup(f);
    8000518a:	854a                	mv	a0,s2
    8000518c:	fffff097          	auipc	ra,0xfffff
    80005190:	304080e7          	jalr	772(ra) # 80004490 <filedup>
  return fd;
    80005194:	87a6                	mv	a5,s1
}
    80005196:	853e                	mv	a0,a5
    80005198:	70a2                	ld	ra,40(sp)
    8000519a:	7402                	ld	s0,32(sp)
    8000519c:	64e2                	ld	s1,24(sp)
    8000519e:	6942                	ld	s2,16(sp)
    800051a0:	6145                	addi	sp,sp,48
    800051a2:	8082                	ret

00000000800051a4 <sys_read>:
{
    800051a4:	7179                	addi	sp,sp,-48
    800051a6:	f406                	sd	ra,40(sp)
    800051a8:	f022                	sd	s0,32(sp)
    800051aa:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800051ac:	fd840593          	addi	a1,s0,-40
    800051b0:	4505                	li	a0,1
    800051b2:	ffffe097          	auipc	ra,0xffffe
    800051b6:	952080e7          	jalr	-1710(ra) # 80002b04 <argaddr>
  argint(2, &n);
    800051ba:	fe440593          	addi	a1,s0,-28
    800051be:	4509                	li	a0,2
    800051c0:	ffffe097          	auipc	ra,0xffffe
    800051c4:	924080e7          	jalr	-1756(ra) # 80002ae4 <argint>
  if(argfd(0, 0, &f) < 0)
    800051c8:	fe840613          	addi	a2,s0,-24
    800051cc:	4581                	li	a1,0
    800051ce:	4501                	li	a0,0
    800051d0:	00000097          	auipc	ra,0x0
    800051d4:	d56080e7          	jalr	-682(ra) # 80004f26 <argfd>
    800051d8:	87aa                	mv	a5,a0
    return -1;
    800051da:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800051dc:	0007cc63          	bltz	a5,800051f4 <sys_read+0x50>
  return fileread(f, p, n);
    800051e0:	fe442603          	lw	a2,-28(s0)
    800051e4:	fd843583          	ld	a1,-40(s0)
    800051e8:	fe843503          	ld	a0,-24(s0)
    800051ec:	fffff097          	auipc	ra,0xfffff
    800051f0:	430080e7          	jalr	1072(ra) # 8000461c <fileread>
}
    800051f4:	70a2                	ld	ra,40(sp)
    800051f6:	7402                	ld	s0,32(sp)
    800051f8:	6145                	addi	sp,sp,48
    800051fa:	8082                	ret

00000000800051fc <sys_write>:
{
    800051fc:	7179                	addi	sp,sp,-48
    800051fe:	f406                	sd	ra,40(sp)
    80005200:	f022                	sd	s0,32(sp)
    80005202:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005204:	fd840593          	addi	a1,s0,-40
    80005208:	4505                	li	a0,1
    8000520a:	ffffe097          	auipc	ra,0xffffe
    8000520e:	8fa080e7          	jalr	-1798(ra) # 80002b04 <argaddr>
  argint(2, &n);
    80005212:	fe440593          	addi	a1,s0,-28
    80005216:	4509                	li	a0,2
    80005218:	ffffe097          	auipc	ra,0xffffe
    8000521c:	8cc080e7          	jalr	-1844(ra) # 80002ae4 <argint>
  if(argfd(0, 0, &f) < 0)
    80005220:	fe840613          	addi	a2,s0,-24
    80005224:	4581                	li	a1,0
    80005226:	4501                	li	a0,0
    80005228:	00000097          	auipc	ra,0x0
    8000522c:	cfe080e7          	jalr	-770(ra) # 80004f26 <argfd>
    80005230:	87aa                	mv	a5,a0
    return -1;
    80005232:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005234:	0007cc63          	bltz	a5,8000524c <sys_write+0x50>
  return filewrite(f, p, n);
    80005238:	fe442603          	lw	a2,-28(s0)
    8000523c:	fd843583          	ld	a1,-40(s0)
    80005240:	fe843503          	ld	a0,-24(s0)
    80005244:	fffff097          	auipc	ra,0xfffff
    80005248:	49a080e7          	jalr	1178(ra) # 800046de <filewrite>
}
    8000524c:	70a2                	ld	ra,40(sp)
    8000524e:	7402                	ld	s0,32(sp)
    80005250:	6145                	addi	sp,sp,48
    80005252:	8082                	ret

0000000080005254 <sys_close>:
{
    80005254:	1101                	addi	sp,sp,-32
    80005256:	ec06                	sd	ra,24(sp)
    80005258:	e822                	sd	s0,16(sp)
    8000525a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000525c:	fe040613          	addi	a2,s0,-32
    80005260:	fec40593          	addi	a1,s0,-20
    80005264:	4501                	li	a0,0
    80005266:	00000097          	auipc	ra,0x0
    8000526a:	cc0080e7          	jalr	-832(ra) # 80004f26 <argfd>
    return -1;
    8000526e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005270:	02054463          	bltz	a0,80005298 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005274:	ffffc097          	auipc	ra,0xffffc
    80005278:	75a080e7          	jalr	1882(ra) # 800019ce <myproc>
    8000527c:	fec42783          	lw	a5,-20(s0)
    80005280:	07e9                	addi	a5,a5,26
    80005282:	078e                	slli	a5,a5,0x3
    80005284:	953e                	add	a0,a0,a5
    80005286:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000528a:	fe043503          	ld	a0,-32(s0)
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	254080e7          	jalr	596(ra) # 800044e2 <fileclose>
  return 0;
    80005296:	4781                	li	a5,0
}
    80005298:	853e                	mv	a0,a5
    8000529a:	60e2                	ld	ra,24(sp)
    8000529c:	6442                	ld	s0,16(sp)
    8000529e:	6105                	addi	sp,sp,32
    800052a0:	8082                	ret

00000000800052a2 <sys_fstat>:
{
    800052a2:	1101                	addi	sp,sp,-32
    800052a4:	ec06                	sd	ra,24(sp)
    800052a6:	e822                	sd	s0,16(sp)
    800052a8:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800052aa:	fe040593          	addi	a1,s0,-32
    800052ae:	4505                	li	a0,1
    800052b0:	ffffe097          	auipc	ra,0xffffe
    800052b4:	854080e7          	jalr	-1964(ra) # 80002b04 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800052b8:	fe840613          	addi	a2,s0,-24
    800052bc:	4581                	li	a1,0
    800052be:	4501                	li	a0,0
    800052c0:	00000097          	auipc	ra,0x0
    800052c4:	c66080e7          	jalr	-922(ra) # 80004f26 <argfd>
    800052c8:	87aa                	mv	a5,a0
    return -1;
    800052ca:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052cc:	0007ca63          	bltz	a5,800052e0 <sys_fstat+0x3e>
  return filestat(f, st);
    800052d0:	fe043583          	ld	a1,-32(s0)
    800052d4:	fe843503          	ld	a0,-24(s0)
    800052d8:	fffff097          	auipc	ra,0xfffff
    800052dc:	2d2080e7          	jalr	722(ra) # 800045aa <filestat>
}
    800052e0:	60e2                	ld	ra,24(sp)
    800052e2:	6442                	ld	s0,16(sp)
    800052e4:	6105                	addi	sp,sp,32
    800052e6:	8082                	ret

00000000800052e8 <sys_link>:
{
    800052e8:	7169                	addi	sp,sp,-304
    800052ea:	f606                	sd	ra,296(sp)
    800052ec:	f222                	sd	s0,288(sp)
    800052ee:	ee26                	sd	s1,280(sp)
    800052f0:	ea4a                	sd	s2,272(sp)
    800052f2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052f4:	08000613          	li	a2,128
    800052f8:	ed040593          	addi	a1,s0,-304
    800052fc:	4501                	li	a0,0
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	826080e7          	jalr	-2010(ra) # 80002b24 <argstr>
    return -1;
    80005306:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005308:	10054e63          	bltz	a0,80005424 <sys_link+0x13c>
    8000530c:	08000613          	li	a2,128
    80005310:	f5040593          	addi	a1,s0,-176
    80005314:	4505                	li	a0,1
    80005316:	ffffe097          	auipc	ra,0xffffe
    8000531a:	80e080e7          	jalr	-2034(ra) # 80002b24 <argstr>
    return -1;
    8000531e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005320:	10054263          	bltz	a0,80005424 <sys_link+0x13c>
  begin_op();
    80005324:	fffff097          	auipc	ra,0xfffff
    80005328:	cf6080e7          	jalr	-778(ra) # 8000401a <begin_op>
  if((ip = namei(old)) == 0){
    8000532c:	ed040513          	addi	a0,s0,-304
    80005330:	fffff097          	auipc	ra,0xfffff
    80005334:	aca080e7          	jalr	-1334(ra) # 80003dfa <namei>
    80005338:	84aa                	mv	s1,a0
    8000533a:	c551                	beqz	a0,800053c6 <sys_link+0xde>
  ilock(ip);
    8000533c:	ffffe097          	auipc	ra,0xffffe
    80005340:	312080e7          	jalr	786(ra) # 8000364e <ilock>
  if(ip->type == T_DIR){
    80005344:	04449703          	lh	a4,68(s1)
    80005348:	4785                	li	a5,1
    8000534a:	08f70463          	beq	a4,a5,800053d2 <sys_link+0xea>
  ip->nlink++;
    8000534e:	04a4d783          	lhu	a5,74(s1)
    80005352:	2785                	addiw	a5,a5,1
    80005354:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005358:	8526                	mv	a0,s1
    8000535a:	ffffe097          	auipc	ra,0xffffe
    8000535e:	228080e7          	jalr	552(ra) # 80003582 <iupdate>
  iunlock(ip);
    80005362:	8526                	mv	a0,s1
    80005364:	ffffe097          	auipc	ra,0xffffe
    80005368:	3ac080e7          	jalr	940(ra) # 80003710 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000536c:	fd040593          	addi	a1,s0,-48
    80005370:	f5040513          	addi	a0,s0,-176
    80005374:	fffff097          	auipc	ra,0xfffff
    80005378:	aa4080e7          	jalr	-1372(ra) # 80003e18 <nameiparent>
    8000537c:	892a                	mv	s2,a0
    8000537e:	c935                	beqz	a0,800053f2 <sys_link+0x10a>
  ilock(dp);
    80005380:	ffffe097          	auipc	ra,0xffffe
    80005384:	2ce080e7          	jalr	718(ra) # 8000364e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005388:	00092703          	lw	a4,0(s2)
    8000538c:	409c                	lw	a5,0(s1)
    8000538e:	04f71d63          	bne	a4,a5,800053e8 <sys_link+0x100>
    80005392:	40d0                	lw	a2,4(s1)
    80005394:	fd040593          	addi	a1,s0,-48
    80005398:	854a                	mv	a0,s2
    8000539a:	fffff097          	auipc	ra,0xfffff
    8000539e:	9ae080e7          	jalr	-1618(ra) # 80003d48 <dirlink>
    800053a2:	04054363          	bltz	a0,800053e8 <sys_link+0x100>
  iunlockput(dp);
    800053a6:	854a                	mv	a0,s2
    800053a8:	ffffe097          	auipc	ra,0xffffe
    800053ac:	508080e7          	jalr	1288(ra) # 800038b0 <iunlockput>
  iput(ip);
    800053b0:	8526                	mv	a0,s1
    800053b2:	ffffe097          	auipc	ra,0xffffe
    800053b6:	456080e7          	jalr	1110(ra) # 80003808 <iput>
  end_op();
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	cde080e7          	jalr	-802(ra) # 80004098 <end_op>
  return 0;
    800053c2:	4781                	li	a5,0
    800053c4:	a085                	j	80005424 <sys_link+0x13c>
    end_op();
    800053c6:	fffff097          	auipc	ra,0xfffff
    800053ca:	cd2080e7          	jalr	-814(ra) # 80004098 <end_op>
    return -1;
    800053ce:	57fd                	li	a5,-1
    800053d0:	a891                	j	80005424 <sys_link+0x13c>
    iunlockput(ip);
    800053d2:	8526                	mv	a0,s1
    800053d4:	ffffe097          	auipc	ra,0xffffe
    800053d8:	4dc080e7          	jalr	1244(ra) # 800038b0 <iunlockput>
    end_op();
    800053dc:	fffff097          	auipc	ra,0xfffff
    800053e0:	cbc080e7          	jalr	-836(ra) # 80004098 <end_op>
    return -1;
    800053e4:	57fd                	li	a5,-1
    800053e6:	a83d                	j	80005424 <sys_link+0x13c>
    iunlockput(dp);
    800053e8:	854a                	mv	a0,s2
    800053ea:	ffffe097          	auipc	ra,0xffffe
    800053ee:	4c6080e7          	jalr	1222(ra) # 800038b0 <iunlockput>
  ilock(ip);
    800053f2:	8526                	mv	a0,s1
    800053f4:	ffffe097          	auipc	ra,0xffffe
    800053f8:	25a080e7          	jalr	602(ra) # 8000364e <ilock>
  ip->nlink--;
    800053fc:	04a4d783          	lhu	a5,74(s1)
    80005400:	37fd                	addiw	a5,a5,-1
    80005402:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005406:	8526                	mv	a0,s1
    80005408:	ffffe097          	auipc	ra,0xffffe
    8000540c:	17a080e7          	jalr	378(ra) # 80003582 <iupdate>
  iunlockput(ip);
    80005410:	8526                	mv	a0,s1
    80005412:	ffffe097          	auipc	ra,0xffffe
    80005416:	49e080e7          	jalr	1182(ra) # 800038b0 <iunlockput>
  end_op();
    8000541a:	fffff097          	auipc	ra,0xfffff
    8000541e:	c7e080e7          	jalr	-898(ra) # 80004098 <end_op>
  return -1;
    80005422:	57fd                	li	a5,-1
}
    80005424:	853e                	mv	a0,a5
    80005426:	70b2                	ld	ra,296(sp)
    80005428:	7412                	ld	s0,288(sp)
    8000542a:	64f2                	ld	s1,280(sp)
    8000542c:	6952                	ld	s2,272(sp)
    8000542e:	6155                	addi	sp,sp,304
    80005430:	8082                	ret

0000000080005432 <sys_unlink>:
{
    80005432:	7151                	addi	sp,sp,-240
    80005434:	f586                	sd	ra,232(sp)
    80005436:	f1a2                	sd	s0,224(sp)
    80005438:	eda6                	sd	s1,216(sp)
    8000543a:	e9ca                	sd	s2,208(sp)
    8000543c:	e5ce                	sd	s3,200(sp)
    8000543e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005440:	08000613          	li	a2,128
    80005444:	f3040593          	addi	a1,s0,-208
    80005448:	4501                	li	a0,0
    8000544a:	ffffd097          	auipc	ra,0xffffd
    8000544e:	6da080e7          	jalr	1754(ra) # 80002b24 <argstr>
    80005452:	18054163          	bltz	a0,800055d4 <sys_unlink+0x1a2>
  begin_op();
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	bc4080e7          	jalr	-1084(ra) # 8000401a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000545e:	fb040593          	addi	a1,s0,-80
    80005462:	f3040513          	addi	a0,s0,-208
    80005466:	fffff097          	auipc	ra,0xfffff
    8000546a:	9b2080e7          	jalr	-1614(ra) # 80003e18 <nameiparent>
    8000546e:	84aa                	mv	s1,a0
    80005470:	c979                	beqz	a0,80005546 <sys_unlink+0x114>
  ilock(dp);
    80005472:	ffffe097          	auipc	ra,0xffffe
    80005476:	1dc080e7          	jalr	476(ra) # 8000364e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000547a:	00003597          	auipc	a1,0x3
    8000547e:	28658593          	addi	a1,a1,646 # 80008700 <syscalls+0x2a0>
    80005482:	fb040513          	addi	a0,s0,-80
    80005486:	ffffe097          	auipc	ra,0xffffe
    8000548a:	692080e7          	jalr	1682(ra) # 80003b18 <namecmp>
    8000548e:	14050a63          	beqz	a0,800055e2 <sys_unlink+0x1b0>
    80005492:	00003597          	auipc	a1,0x3
    80005496:	27658593          	addi	a1,a1,630 # 80008708 <syscalls+0x2a8>
    8000549a:	fb040513          	addi	a0,s0,-80
    8000549e:	ffffe097          	auipc	ra,0xffffe
    800054a2:	67a080e7          	jalr	1658(ra) # 80003b18 <namecmp>
    800054a6:	12050e63          	beqz	a0,800055e2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054aa:	f2c40613          	addi	a2,s0,-212
    800054ae:	fb040593          	addi	a1,s0,-80
    800054b2:	8526                	mv	a0,s1
    800054b4:	ffffe097          	auipc	ra,0xffffe
    800054b8:	67e080e7          	jalr	1662(ra) # 80003b32 <dirlookup>
    800054bc:	892a                	mv	s2,a0
    800054be:	12050263          	beqz	a0,800055e2 <sys_unlink+0x1b0>
  ilock(ip);
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	18c080e7          	jalr	396(ra) # 8000364e <ilock>
  if(ip->nlink < 1)
    800054ca:	04a91783          	lh	a5,74(s2)
    800054ce:	08f05263          	blez	a5,80005552 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800054d2:	04491703          	lh	a4,68(s2)
    800054d6:	4785                	li	a5,1
    800054d8:	08f70563          	beq	a4,a5,80005562 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800054dc:	4641                	li	a2,16
    800054de:	4581                	li	a1,0
    800054e0:	fc040513          	addi	a0,s0,-64
    800054e4:	ffffb097          	auipc	ra,0xffffb
    800054e8:	7ee080e7          	jalr	2030(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054ec:	4741                	li	a4,16
    800054ee:	f2c42683          	lw	a3,-212(s0)
    800054f2:	fc040613          	addi	a2,s0,-64
    800054f6:	4581                	li	a1,0
    800054f8:	8526                	mv	a0,s1
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	500080e7          	jalr	1280(ra) # 800039fa <writei>
    80005502:	47c1                	li	a5,16
    80005504:	0af51563          	bne	a0,a5,800055ae <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005508:	04491703          	lh	a4,68(s2)
    8000550c:	4785                	li	a5,1
    8000550e:	0af70863          	beq	a4,a5,800055be <sys_unlink+0x18c>
  iunlockput(dp);
    80005512:	8526                	mv	a0,s1
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	39c080e7          	jalr	924(ra) # 800038b0 <iunlockput>
  ip->nlink--;
    8000551c:	04a95783          	lhu	a5,74(s2)
    80005520:	37fd                	addiw	a5,a5,-1
    80005522:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005526:	854a                	mv	a0,s2
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	05a080e7          	jalr	90(ra) # 80003582 <iupdate>
  iunlockput(ip);
    80005530:	854a                	mv	a0,s2
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	37e080e7          	jalr	894(ra) # 800038b0 <iunlockput>
  end_op();
    8000553a:	fffff097          	auipc	ra,0xfffff
    8000553e:	b5e080e7          	jalr	-1186(ra) # 80004098 <end_op>
  return 0;
    80005542:	4501                	li	a0,0
    80005544:	a84d                	j	800055f6 <sys_unlink+0x1c4>
    end_op();
    80005546:	fffff097          	auipc	ra,0xfffff
    8000554a:	b52080e7          	jalr	-1198(ra) # 80004098 <end_op>
    return -1;
    8000554e:	557d                	li	a0,-1
    80005550:	a05d                	j	800055f6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005552:	00003517          	auipc	a0,0x3
    80005556:	1be50513          	addi	a0,a0,446 # 80008710 <syscalls+0x2b0>
    8000555a:	ffffb097          	auipc	ra,0xffffb
    8000555e:	fe6080e7          	jalr	-26(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005562:	04c92703          	lw	a4,76(s2)
    80005566:	02000793          	li	a5,32
    8000556a:	f6e7f9e3          	bgeu	a5,a4,800054dc <sys_unlink+0xaa>
    8000556e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005572:	4741                	li	a4,16
    80005574:	86ce                	mv	a3,s3
    80005576:	f1840613          	addi	a2,s0,-232
    8000557a:	4581                	li	a1,0
    8000557c:	854a                	mv	a0,s2
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	384080e7          	jalr	900(ra) # 80003902 <readi>
    80005586:	47c1                	li	a5,16
    80005588:	00f51b63          	bne	a0,a5,8000559e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000558c:	f1845783          	lhu	a5,-232(s0)
    80005590:	e7a1                	bnez	a5,800055d8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005592:	29c1                	addiw	s3,s3,16
    80005594:	04c92783          	lw	a5,76(s2)
    80005598:	fcf9ede3          	bltu	s3,a5,80005572 <sys_unlink+0x140>
    8000559c:	b781                	j	800054dc <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000559e:	00003517          	auipc	a0,0x3
    800055a2:	18a50513          	addi	a0,a0,394 # 80008728 <syscalls+0x2c8>
    800055a6:	ffffb097          	auipc	ra,0xffffb
    800055aa:	f9a080e7          	jalr	-102(ra) # 80000540 <panic>
    panic("unlink: writei");
    800055ae:	00003517          	auipc	a0,0x3
    800055b2:	19250513          	addi	a0,a0,402 # 80008740 <syscalls+0x2e0>
    800055b6:	ffffb097          	auipc	ra,0xffffb
    800055ba:	f8a080e7          	jalr	-118(ra) # 80000540 <panic>
    dp->nlink--;
    800055be:	04a4d783          	lhu	a5,74(s1)
    800055c2:	37fd                	addiw	a5,a5,-1
    800055c4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055c8:	8526                	mv	a0,s1
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	fb8080e7          	jalr	-72(ra) # 80003582 <iupdate>
    800055d2:	b781                	j	80005512 <sys_unlink+0xe0>
    return -1;
    800055d4:	557d                	li	a0,-1
    800055d6:	a005                	j	800055f6 <sys_unlink+0x1c4>
    iunlockput(ip);
    800055d8:	854a                	mv	a0,s2
    800055da:	ffffe097          	auipc	ra,0xffffe
    800055de:	2d6080e7          	jalr	726(ra) # 800038b0 <iunlockput>
  iunlockput(dp);
    800055e2:	8526                	mv	a0,s1
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	2cc080e7          	jalr	716(ra) # 800038b0 <iunlockput>
  end_op();
    800055ec:	fffff097          	auipc	ra,0xfffff
    800055f0:	aac080e7          	jalr	-1364(ra) # 80004098 <end_op>
  return -1;
    800055f4:	557d                	li	a0,-1
}
    800055f6:	70ae                	ld	ra,232(sp)
    800055f8:	740e                	ld	s0,224(sp)
    800055fa:	64ee                	ld	s1,216(sp)
    800055fc:	694e                	ld	s2,208(sp)
    800055fe:	69ae                	ld	s3,200(sp)
    80005600:	616d                	addi	sp,sp,240
    80005602:	8082                	ret

0000000080005604 <sys_open>:

uint64
sys_open(void)
{
    80005604:	7131                	addi	sp,sp,-192
    80005606:	fd06                	sd	ra,184(sp)
    80005608:	f922                	sd	s0,176(sp)
    8000560a:	f526                	sd	s1,168(sp)
    8000560c:	f14a                	sd	s2,160(sp)
    8000560e:	ed4e                	sd	s3,152(sp)
    80005610:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005612:	f4c40593          	addi	a1,s0,-180
    80005616:	4505                	li	a0,1
    80005618:	ffffd097          	auipc	ra,0xffffd
    8000561c:	4cc080e7          	jalr	1228(ra) # 80002ae4 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005620:	08000613          	li	a2,128
    80005624:	f5040593          	addi	a1,s0,-176
    80005628:	4501                	li	a0,0
    8000562a:	ffffd097          	auipc	ra,0xffffd
    8000562e:	4fa080e7          	jalr	1274(ra) # 80002b24 <argstr>
    80005632:	87aa                	mv	a5,a0
    return -1;
    80005634:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005636:	0a07c963          	bltz	a5,800056e8 <sys_open+0xe4>

  begin_op();
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	9e0080e7          	jalr	-1568(ra) # 8000401a <begin_op>

  if(omode & O_CREATE){
    80005642:	f4c42783          	lw	a5,-180(s0)
    80005646:	2007f793          	andi	a5,a5,512
    8000564a:	cfc5                	beqz	a5,80005702 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000564c:	4681                	li	a3,0
    8000564e:	4601                	li	a2,0
    80005650:	4589                	li	a1,2
    80005652:	f5040513          	addi	a0,s0,-176
    80005656:	00000097          	auipc	ra,0x0
    8000565a:	972080e7          	jalr	-1678(ra) # 80004fc8 <create>
    8000565e:	84aa                	mv	s1,a0
    if(ip == 0){
    80005660:	c959                	beqz	a0,800056f6 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005662:	04449703          	lh	a4,68(s1)
    80005666:	478d                	li	a5,3
    80005668:	00f71763          	bne	a4,a5,80005676 <sys_open+0x72>
    8000566c:	0464d703          	lhu	a4,70(s1)
    80005670:	47a5                	li	a5,9
    80005672:	0ce7ed63          	bltu	a5,a4,8000574c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	db0080e7          	jalr	-592(ra) # 80004426 <filealloc>
    8000567e:	89aa                	mv	s3,a0
    80005680:	10050363          	beqz	a0,80005786 <sys_open+0x182>
    80005684:	00000097          	auipc	ra,0x0
    80005688:	902080e7          	jalr	-1790(ra) # 80004f86 <fdalloc>
    8000568c:	892a                	mv	s2,a0
    8000568e:	0e054763          	bltz	a0,8000577c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005692:	04449703          	lh	a4,68(s1)
    80005696:	478d                	li	a5,3
    80005698:	0cf70563          	beq	a4,a5,80005762 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000569c:	4789                	li	a5,2
    8000569e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056a2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056a6:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056aa:	f4c42783          	lw	a5,-180(s0)
    800056ae:	0017c713          	xori	a4,a5,1
    800056b2:	8b05                	andi	a4,a4,1
    800056b4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800056b8:	0037f713          	andi	a4,a5,3
    800056bc:	00e03733          	snez	a4,a4
    800056c0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800056c4:	4007f793          	andi	a5,a5,1024
    800056c8:	c791                	beqz	a5,800056d4 <sys_open+0xd0>
    800056ca:	04449703          	lh	a4,68(s1)
    800056ce:	4789                	li	a5,2
    800056d0:	0af70063          	beq	a4,a5,80005770 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800056d4:	8526                	mv	a0,s1
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	03a080e7          	jalr	58(ra) # 80003710 <iunlock>
  end_op();
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	9ba080e7          	jalr	-1606(ra) # 80004098 <end_op>

  return fd;
    800056e6:	854a                	mv	a0,s2
}
    800056e8:	70ea                	ld	ra,184(sp)
    800056ea:	744a                	ld	s0,176(sp)
    800056ec:	74aa                	ld	s1,168(sp)
    800056ee:	790a                	ld	s2,160(sp)
    800056f0:	69ea                	ld	s3,152(sp)
    800056f2:	6129                	addi	sp,sp,192
    800056f4:	8082                	ret
      end_op();
    800056f6:	fffff097          	auipc	ra,0xfffff
    800056fa:	9a2080e7          	jalr	-1630(ra) # 80004098 <end_op>
      return -1;
    800056fe:	557d                	li	a0,-1
    80005700:	b7e5                	j	800056e8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005702:	f5040513          	addi	a0,s0,-176
    80005706:	ffffe097          	auipc	ra,0xffffe
    8000570a:	6f4080e7          	jalr	1780(ra) # 80003dfa <namei>
    8000570e:	84aa                	mv	s1,a0
    80005710:	c905                	beqz	a0,80005740 <sys_open+0x13c>
    ilock(ip);
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	f3c080e7          	jalr	-196(ra) # 8000364e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000571a:	04449703          	lh	a4,68(s1)
    8000571e:	4785                	li	a5,1
    80005720:	f4f711e3          	bne	a4,a5,80005662 <sys_open+0x5e>
    80005724:	f4c42783          	lw	a5,-180(s0)
    80005728:	d7b9                	beqz	a5,80005676 <sys_open+0x72>
      iunlockput(ip);
    8000572a:	8526                	mv	a0,s1
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	184080e7          	jalr	388(ra) # 800038b0 <iunlockput>
      end_op();
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	964080e7          	jalr	-1692(ra) # 80004098 <end_op>
      return -1;
    8000573c:	557d                	li	a0,-1
    8000573e:	b76d                	j	800056e8 <sys_open+0xe4>
      end_op();
    80005740:	fffff097          	auipc	ra,0xfffff
    80005744:	958080e7          	jalr	-1704(ra) # 80004098 <end_op>
      return -1;
    80005748:	557d                	li	a0,-1
    8000574a:	bf79                	j	800056e8 <sys_open+0xe4>
    iunlockput(ip);
    8000574c:	8526                	mv	a0,s1
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	162080e7          	jalr	354(ra) # 800038b0 <iunlockput>
    end_op();
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	942080e7          	jalr	-1726(ra) # 80004098 <end_op>
    return -1;
    8000575e:	557d                	li	a0,-1
    80005760:	b761                	j	800056e8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005762:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005766:	04649783          	lh	a5,70(s1)
    8000576a:	02f99223          	sh	a5,36(s3)
    8000576e:	bf25                	j	800056a6 <sys_open+0xa2>
    itrunc(ip);
    80005770:	8526                	mv	a0,s1
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	fea080e7          	jalr	-22(ra) # 8000375c <itrunc>
    8000577a:	bfa9                	j	800056d4 <sys_open+0xd0>
      fileclose(f);
    8000577c:	854e                	mv	a0,s3
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	d64080e7          	jalr	-668(ra) # 800044e2 <fileclose>
    iunlockput(ip);
    80005786:	8526                	mv	a0,s1
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	128080e7          	jalr	296(ra) # 800038b0 <iunlockput>
    end_op();
    80005790:	fffff097          	auipc	ra,0xfffff
    80005794:	908080e7          	jalr	-1784(ra) # 80004098 <end_op>
    return -1;
    80005798:	557d                	li	a0,-1
    8000579a:	b7b9                	j	800056e8 <sys_open+0xe4>

000000008000579c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000579c:	7175                	addi	sp,sp,-144
    8000579e:	e506                	sd	ra,136(sp)
    800057a0:	e122                	sd	s0,128(sp)
    800057a2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	876080e7          	jalr	-1930(ra) # 8000401a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057ac:	08000613          	li	a2,128
    800057b0:	f7040593          	addi	a1,s0,-144
    800057b4:	4501                	li	a0,0
    800057b6:	ffffd097          	auipc	ra,0xffffd
    800057ba:	36e080e7          	jalr	878(ra) # 80002b24 <argstr>
    800057be:	02054963          	bltz	a0,800057f0 <sys_mkdir+0x54>
    800057c2:	4681                	li	a3,0
    800057c4:	4601                	li	a2,0
    800057c6:	4585                	li	a1,1
    800057c8:	f7040513          	addi	a0,s0,-144
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	7fc080e7          	jalr	2044(ra) # 80004fc8 <create>
    800057d4:	cd11                	beqz	a0,800057f0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	0da080e7          	jalr	218(ra) # 800038b0 <iunlockput>
  end_op();
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	8ba080e7          	jalr	-1862(ra) # 80004098 <end_op>
  return 0;
    800057e6:	4501                	li	a0,0
}
    800057e8:	60aa                	ld	ra,136(sp)
    800057ea:	640a                	ld	s0,128(sp)
    800057ec:	6149                	addi	sp,sp,144
    800057ee:	8082                	ret
    end_op();
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	8a8080e7          	jalr	-1880(ra) # 80004098 <end_op>
    return -1;
    800057f8:	557d                	li	a0,-1
    800057fa:	b7fd                	j	800057e8 <sys_mkdir+0x4c>

00000000800057fc <sys_mknod>:

uint64
sys_mknod(void)
{
    800057fc:	7135                	addi	sp,sp,-160
    800057fe:	ed06                	sd	ra,152(sp)
    80005800:	e922                	sd	s0,144(sp)
    80005802:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	816080e7          	jalr	-2026(ra) # 8000401a <begin_op>
  argint(1, &major);
    8000580c:	f6c40593          	addi	a1,s0,-148
    80005810:	4505                	li	a0,1
    80005812:	ffffd097          	auipc	ra,0xffffd
    80005816:	2d2080e7          	jalr	722(ra) # 80002ae4 <argint>
  argint(2, &minor);
    8000581a:	f6840593          	addi	a1,s0,-152
    8000581e:	4509                	li	a0,2
    80005820:	ffffd097          	auipc	ra,0xffffd
    80005824:	2c4080e7          	jalr	708(ra) # 80002ae4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005828:	08000613          	li	a2,128
    8000582c:	f7040593          	addi	a1,s0,-144
    80005830:	4501                	li	a0,0
    80005832:	ffffd097          	auipc	ra,0xffffd
    80005836:	2f2080e7          	jalr	754(ra) # 80002b24 <argstr>
    8000583a:	02054b63          	bltz	a0,80005870 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000583e:	f6841683          	lh	a3,-152(s0)
    80005842:	f6c41603          	lh	a2,-148(s0)
    80005846:	458d                	li	a1,3
    80005848:	f7040513          	addi	a0,s0,-144
    8000584c:	fffff097          	auipc	ra,0xfffff
    80005850:	77c080e7          	jalr	1916(ra) # 80004fc8 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005854:	cd11                	beqz	a0,80005870 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	05a080e7          	jalr	90(ra) # 800038b0 <iunlockput>
  end_op();
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	83a080e7          	jalr	-1990(ra) # 80004098 <end_op>
  return 0;
    80005866:	4501                	li	a0,0
}
    80005868:	60ea                	ld	ra,152(sp)
    8000586a:	644a                	ld	s0,144(sp)
    8000586c:	610d                	addi	sp,sp,160
    8000586e:	8082                	ret
    end_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	828080e7          	jalr	-2008(ra) # 80004098 <end_op>
    return -1;
    80005878:	557d                	li	a0,-1
    8000587a:	b7fd                	j	80005868 <sys_mknod+0x6c>

000000008000587c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000587c:	7135                	addi	sp,sp,-160
    8000587e:	ed06                	sd	ra,152(sp)
    80005880:	e922                	sd	s0,144(sp)
    80005882:	e526                	sd	s1,136(sp)
    80005884:	e14a                	sd	s2,128(sp)
    80005886:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005888:	ffffc097          	auipc	ra,0xffffc
    8000588c:	146080e7          	jalr	326(ra) # 800019ce <myproc>
    80005890:	892a                	mv	s2,a0
  
  begin_op();
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	788080e7          	jalr	1928(ra) # 8000401a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000589a:	08000613          	li	a2,128
    8000589e:	f6040593          	addi	a1,s0,-160
    800058a2:	4501                	li	a0,0
    800058a4:	ffffd097          	auipc	ra,0xffffd
    800058a8:	280080e7          	jalr	640(ra) # 80002b24 <argstr>
    800058ac:	04054b63          	bltz	a0,80005902 <sys_chdir+0x86>
    800058b0:	f6040513          	addi	a0,s0,-160
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	546080e7          	jalr	1350(ra) # 80003dfa <namei>
    800058bc:	84aa                	mv	s1,a0
    800058be:	c131                	beqz	a0,80005902 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	d8e080e7          	jalr	-626(ra) # 8000364e <ilock>
  if(ip->type != T_DIR){
    800058c8:	04449703          	lh	a4,68(s1)
    800058cc:	4785                	li	a5,1
    800058ce:	04f71063          	bne	a4,a5,8000590e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800058d2:	8526                	mv	a0,s1
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	e3c080e7          	jalr	-452(ra) # 80003710 <iunlock>
  iput(p->cwd);
    800058dc:	15093503          	ld	a0,336(s2)
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	f28080e7          	jalr	-216(ra) # 80003808 <iput>
  end_op();
    800058e8:	ffffe097          	auipc	ra,0xffffe
    800058ec:	7b0080e7          	jalr	1968(ra) # 80004098 <end_op>
  p->cwd = ip;
    800058f0:	14993823          	sd	s1,336(s2)
  return 0;
    800058f4:	4501                	li	a0,0
}
    800058f6:	60ea                	ld	ra,152(sp)
    800058f8:	644a                	ld	s0,144(sp)
    800058fa:	64aa                	ld	s1,136(sp)
    800058fc:	690a                	ld	s2,128(sp)
    800058fe:	610d                	addi	sp,sp,160
    80005900:	8082                	ret
    end_op();
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	796080e7          	jalr	1942(ra) # 80004098 <end_op>
    return -1;
    8000590a:	557d                	li	a0,-1
    8000590c:	b7ed                	j	800058f6 <sys_chdir+0x7a>
    iunlockput(ip);
    8000590e:	8526                	mv	a0,s1
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	fa0080e7          	jalr	-96(ra) # 800038b0 <iunlockput>
    end_op();
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	780080e7          	jalr	1920(ra) # 80004098 <end_op>
    return -1;
    80005920:	557d                	li	a0,-1
    80005922:	bfd1                	j	800058f6 <sys_chdir+0x7a>

0000000080005924 <sys_exec>:

uint64
sys_exec(void)
{
    80005924:	7145                	addi	sp,sp,-464
    80005926:	e786                	sd	ra,456(sp)
    80005928:	e3a2                	sd	s0,448(sp)
    8000592a:	ff26                	sd	s1,440(sp)
    8000592c:	fb4a                	sd	s2,432(sp)
    8000592e:	f74e                	sd	s3,424(sp)
    80005930:	f352                	sd	s4,416(sp)
    80005932:	ef56                	sd	s5,408(sp)
    80005934:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005936:	e3840593          	addi	a1,s0,-456
    8000593a:	4505                	li	a0,1
    8000593c:	ffffd097          	auipc	ra,0xffffd
    80005940:	1c8080e7          	jalr	456(ra) # 80002b04 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005944:	08000613          	li	a2,128
    80005948:	f4040593          	addi	a1,s0,-192
    8000594c:	4501                	li	a0,0
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	1d6080e7          	jalr	470(ra) # 80002b24 <argstr>
    80005956:	87aa                	mv	a5,a0
    return -1;
    80005958:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000595a:	0c07c363          	bltz	a5,80005a20 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    8000595e:	10000613          	li	a2,256
    80005962:	4581                	li	a1,0
    80005964:	e4040513          	addi	a0,s0,-448
    80005968:	ffffb097          	auipc	ra,0xffffb
    8000596c:	36a080e7          	jalr	874(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005970:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005974:	89a6                	mv	s3,s1
    80005976:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005978:	02000a13          	li	s4,32
    8000597c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005980:	00391513          	slli	a0,s2,0x3
    80005984:	e3040593          	addi	a1,s0,-464
    80005988:	e3843783          	ld	a5,-456(s0)
    8000598c:	953e                	add	a0,a0,a5
    8000598e:	ffffd097          	auipc	ra,0xffffd
    80005992:	0b8080e7          	jalr	184(ra) # 80002a46 <fetchaddr>
    80005996:	02054a63          	bltz	a0,800059ca <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    8000599a:	e3043783          	ld	a5,-464(s0)
    8000599e:	c3b9                	beqz	a5,800059e4 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059a0:	ffffb097          	auipc	ra,0xffffb
    800059a4:	146080e7          	jalr	326(ra) # 80000ae6 <kalloc>
    800059a8:	85aa                	mv	a1,a0
    800059aa:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800059ae:	cd11                	beqz	a0,800059ca <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059b0:	6605                	lui	a2,0x1
    800059b2:	e3043503          	ld	a0,-464(s0)
    800059b6:	ffffd097          	auipc	ra,0xffffd
    800059ba:	0e2080e7          	jalr	226(ra) # 80002a98 <fetchstr>
    800059be:	00054663          	bltz	a0,800059ca <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800059c2:	0905                	addi	s2,s2,1
    800059c4:	09a1                	addi	s3,s3,8
    800059c6:	fb491be3          	bne	s2,s4,8000597c <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059ca:	f4040913          	addi	s2,s0,-192
    800059ce:	6088                	ld	a0,0(s1)
    800059d0:	c539                	beqz	a0,80005a1e <sys_exec+0xfa>
    kfree(argv[i]);
    800059d2:	ffffb097          	auipc	ra,0xffffb
    800059d6:	016080e7          	jalr	22(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059da:	04a1                	addi	s1,s1,8
    800059dc:	ff2499e3          	bne	s1,s2,800059ce <sys_exec+0xaa>
  return -1;
    800059e0:	557d                	li	a0,-1
    800059e2:	a83d                	j	80005a20 <sys_exec+0xfc>
      argv[i] = 0;
    800059e4:	0a8e                	slli	s5,s5,0x3
    800059e6:	fc0a8793          	addi	a5,s5,-64
    800059ea:	00878ab3          	add	s5,a5,s0
    800059ee:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800059f2:	e4040593          	addi	a1,s0,-448
    800059f6:	f4040513          	addi	a0,s0,-192
    800059fa:	fffff097          	auipc	ra,0xfffff
    800059fe:	162080e7          	jalr	354(ra) # 80004b5c <exec>
    80005a02:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a04:	f4040993          	addi	s3,s0,-192
    80005a08:	6088                	ld	a0,0(s1)
    80005a0a:	c901                	beqz	a0,80005a1a <sys_exec+0xf6>
    kfree(argv[i]);
    80005a0c:	ffffb097          	auipc	ra,0xffffb
    80005a10:	fdc080e7          	jalr	-36(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a14:	04a1                	addi	s1,s1,8
    80005a16:	ff3499e3          	bne	s1,s3,80005a08 <sys_exec+0xe4>
  return ret;
    80005a1a:	854a                	mv	a0,s2
    80005a1c:	a011                	j	80005a20 <sys_exec+0xfc>
  return -1;
    80005a1e:	557d                	li	a0,-1
}
    80005a20:	60be                	ld	ra,456(sp)
    80005a22:	641e                	ld	s0,448(sp)
    80005a24:	74fa                	ld	s1,440(sp)
    80005a26:	795a                	ld	s2,432(sp)
    80005a28:	79ba                	ld	s3,424(sp)
    80005a2a:	7a1a                	ld	s4,416(sp)
    80005a2c:	6afa                	ld	s5,408(sp)
    80005a2e:	6179                	addi	sp,sp,464
    80005a30:	8082                	ret

0000000080005a32 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a32:	7139                	addi	sp,sp,-64
    80005a34:	fc06                	sd	ra,56(sp)
    80005a36:	f822                	sd	s0,48(sp)
    80005a38:	f426                	sd	s1,40(sp)
    80005a3a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a3c:	ffffc097          	auipc	ra,0xffffc
    80005a40:	f92080e7          	jalr	-110(ra) # 800019ce <myproc>
    80005a44:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005a46:	fd840593          	addi	a1,s0,-40
    80005a4a:	4501                	li	a0,0
    80005a4c:	ffffd097          	auipc	ra,0xffffd
    80005a50:	0b8080e7          	jalr	184(ra) # 80002b04 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005a54:	fc840593          	addi	a1,s0,-56
    80005a58:	fd040513          	addi	a0,s0,-48
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	db6080e7          	jalr	-586(ra) # 80004812 <pipealloc>
    return -1;
    80005a64:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005a66:	0c054463          	bltz	a0,80005b2e <sys_pipe+0xfc>
  fd0 = -1;
    80005a6a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a6e:	fd043503          	ld	a0,-48(s0)
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	514080e7          	jalr	1300(ra) # 80004f86 <fdalloc>
    80005a7a:	fca42223          	sw	a0,-60(s0)
    80005a7e:	08054b63          	bltz	a0,80005b14 <sys_pipe+0xe2>
    80005a82:	fc843503          	ld	a0,-56(s0)
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	500080e7          	jalr	1280(ra) # 80004f86 <fdalloc>
    80005a8e:	fca42023          	sw	a0,-64(s0)
    80005a92:	06054863          	bltz	a0,80005b02 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a96:	4691                	li	a3,4
    80005a98:	fc440613          	addi	a2,s0,-60
    80005a9c:	fd843583          	ld	a1,-40(s0)
    80005aa0:	68a8                	ld	a0,80(s1)
    80005aa2:	ffffc097          	auipc	ra,0xffffc
    80005aa6:	bec080e7          	jalr	-1044(ra) # 8000168e <copyout>
    80005aaa:	02054063          	bltz	a0,80005aca <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005aae:	4691                	li	a3,4
    80005ab0:	fc040613          	addi	a2,s0,-64
    80005ab4:	fd843583          	ld	a1,-40(s0)
    80005ab8:	0591                	addi	a1,a1,4
    80005aba:	68a8                	ld	a0,80(s1)
    80005abc:	ffffc097          	auipc	ra,0xffffc
    80005ac0:	bd2080e7          	jalr	-1070(ra) # 8000168e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ac4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ac6:	06055463          	bgez	a0,80005b2e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005aca:	fc442783          	lw	a5,-60(s0)
    80005ace:	07e9                	addi	a5,a5,26
    80005ad0:	078e                	slli	a5,a5,0x3
    80005ad2:	97a6                	add	a5,a5,s1
    80005ad4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ad8:	fc042783          	lw	a5,-64(s0)
    80005adc:	07e9                	addi	a5,a5,26
    80005ade:	078e                	slli	a5,a5,0x3
    80005ae0:	94be                	add	s1,s1,a5
    80005ae2:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005ae6:	fd043503          	ld	a0,-48(s0)
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	9f8080e7          	jalr	-1544(ra) # 800044e2 <fileclose>
    fileclose(wf);
    80005af2:	fc843503          	ld	a0,-56(s0)
    80005af6:	fffff097          	auipc	ra,0xfffff
    80005afa:	9ec080e7          	jalr	-1556(ra) # 800044e2 <fileclose>
    return -1;
    80005afe:	57fd                	li	a5,-1
    80005b00:	a03d                	j	80005b2e <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005b02:	fc442783          	lw	a5,-60(s0)
    80005b06:	0007c763          	bltz	a5,80005b14 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005b0a:	07e9                	addi	a5,a5,26
    80005b0c:	078e                	slli	a5,a5,0x3
    80005b0e:	97a6                	add	a5,a5,s1
    80005b10:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005b14:	fd043503          	ld	a0,-48(s0)
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	9ca080e7          	jalr	-1590(ra) # 800044e2 <fileclose>
    fileclose(wf);
    80005b20:	fc843503          	ld	a0,-56(s0)
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	9be080e7          	jalr	-1602(ra) # 800044e2 <fileclose>
    return -1;
    80005b2c:	57fd                	li	a5,-1
}
    80005b2e:	853e                	mv	a0,a5
    80005b30:	70e2                	ld	ra,56(sp)
    80005b32:	7442                	ld	s0,48(sp)
    80005b34:	74a2                	ld	s1,40(sp)
    80005b36:	6121                	addi	sp,sp,64
    80005b38:	8082                	ret
    80005b3a:	0000                	unimp
    80005b3c:	0000                	unimp
	...

0000000080005b40 <kernelvec>:
    80005b40:	7111                	addi	sp,sp,-256
    80005b42:	e006                	sd	ra,0(sp)
    80005b44:	e40a                	sd	sp,8(sp)
    80005b46:	e80e                	sd	gp,16(sp)
    80005b48:	ec12                	sd	tp,24(sp)
    80005b4a:	f016                	sd	t0,32(sp)
    80005b4c:	f41a                	sd	t1,40(sp)
    80005b4e:	f81e                	sd	t2,48(sp)
    80005b50:	fc22                	sd	s0,56(sp)
    80005b52:	e0a6                	sd	s1,64(sp)
    80005b54:	e4aa                	sd	a0,72(sp)
    80005b56:	e8ae                	sd	a1,80(sp)
    80005b58:	ecb2                	sd	a2,88(sp)
    80005b5a:	f0b6                	sd	a3,96(sp)
    80005b5c:	f4ba                	sd	a4,104(sp)
    80005b5e:	f8be                	sd	a5,112(sp)
    80005b60:	fcc2                	sd	a6,120(sp)
    80005b62:	e146                	sd	a7,128(sp)
    80005b64:	e54a                	sd	s2,136(sp)
    80005b66:	e94e                	sd	s3,144(sp)
    80005b68:	ed52                	sd	s4,152(sp)
    80005b6a:	f156                	sd	s5,160(sp)
    80005b6c:	f55a                	sd	s6,168(sp)
    80005b6e:	f95e                	sd	s7,176(sp)
    80005b70:	fd62                	sd	s8,184(sp)
    80005b72:	e1e6                	sd	s9,192(sp)
    80005b74:	e5ea                	sd	s10,200(sp)
    80005b76:	e9ee                	sd	s11,208(sp)
    80005b78:	edf2                	sd	t3,216(sp)
    80005b7a:	f1f6                	sd	t4,224(sp)
    80005b7c:	f5fa                	sd	t5,232(sp)
    80005b7e:	f9fe                	sd	t6,240(sp)
    80005b80:	d93fc0ef          	jal	ra,80002912 <kerneltrap>
    80005b84:	6082                	ld	ra,0(sp)
    80005b86:	6122                	ld	sp,8(sp)
    80005b88:	61c2                	ld	gp,16(sp)
    80005b8a:	7282                	ld	t0,32(sp)
    80005b8c:	7322                	ld	t1,40(sp)
    80005b8e:	73c2                	ld	t2,48(sp)
    80005b90:	7462                	ld	s0,56(sp)
    80005b92:	6486                	ld	s1,64(sp)
    80005b94:	6526                	ld	a0,72(sp)
    80005b96:	65c6                	ld	a1,80(sp)
    80005b98:	6666                	ld	a2,88(sp)
    80005b9a:	7686                	ld	a3,96(sp)
    80005b9c:	7726                	ld	a4,104(sp)
    80005b9e:	77c6                	ld	a5,112(sp)
    80005ba0:	7866                	ld	a6,120(sp)
    80005ba2:	688a                	ld	a7,128(sp)
    80005ba4:	692a                	ld	s2,136(sp)
    80005ba6:	69ca                	ld	s3,144(sp)
    80005ba8:	6a6a                	ld	s4,152(sp)
    80005baa:	7a8a                	ld	s5,160(sp)
    80005bac:	7b2a                	ld	s6,168(sp)
    80005bae:	7bca                	ld	s7,176(sp)
    80005bb0:	7c6a                	ld	s8,184(sp)
    80005bb2:	6c8e                	ld	s9,192(sp)
    80005bb4:	6d2e                	ld	s10,200(sp)
    80005bb6:	6dce                	ld	s11,208(sp)
    80005bb8:	6e6e                	ld	t3,216(sp)
    80005bba:	7e8e                	ld	t4,224(sp)
    80005bbc:	7f2e                	ld	t5,232(sp)
    80005bbe:	7fce                	ld	t6,240(sp)
    80005bc0:	6111                	addi	sp,sp,256
    80005bc2:	10200073          	sret
    80005bc6:	00000013          	nop
    80005bca:	00000013          	nop
    80005bce:	0001                	nop

0000000080005bd0 <timervec>:
    80005bd0:	34051573          	csrrw	a0,mscratch,a0
    80005bd4:	e10c                	sd	a1,0(a0)
    80005bd6:	e510                	sd	a2,8(a0)
    80005bd8:	e914                	sd	a3,16(a0)
    80005bda:	6d0c                	ld	a1,24(a0)
    80005bdc:	7110                	ld	a2,32(a0)
    80005bde:	6194                	ld	a3,0(a1)
    80005be0:	96b2                	add	a3,a3,a2
    80005be2:	e194                	sd	a3,0(a1)
    80005be4:	4589                	li	a1,2
    80005be6:	14459073          	csrw	sip,a1
    80005bea:	6914                	ld	a3,16(a0)
    80005bec:	6510                	ld	a2,8(a0)
    80005bee:	610c                	ld	a1,0(a0)
    80005bf0:	34051573          	csrrw	a0,mscratch,a0
    80005bf4:	30200073          	mret
	...

0000000080005bfa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005bfa:	1141                	addi	sp,sp,-16
    80005bfc:	e422                	sd	s0,8(sp)
    80005bfe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c00:	0c0007b7          	lui	a5,0xc000
    80005c04:	4705                	li	a4,1
    80005c06:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c08:	c3d8                	sw	a4,4(a5)
}
    80005c0a:	6422                	ld	s0,8(sp)
    80005c0c:	0141                	addi	sp,sp,16
    80005c0e:	8082                	ret

0000000080005c10 <plicinithart>:

void
plicinithart(void)
{
    80005c10:	1141                	addi	sp,sp,-16
    80005c12:	e406                	sd	ra,8(sp)
    80005c14:	e022                	sd	s0,0(sp)
    80005c16:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c18:	ffffc097          	auipc	ra,0xffffc
    80005c1c:	d8a080e7          	jalr	-630(ra) # 800019a2 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c20:	0085171b          	slliw	a4,a0,0x8
    80005c24:	0c0027b7          	lui	a5,0xc002
    80005c28:	97ba                	add	a5,a5,a4
    80005c2a:	40200713          	li	a4,1026
    80005c2e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c32:	00d5151b          	slliw	a0,a0,0xd
    80005c36:	0c2017b7          	lui	a5,0xc201
    80005c3a:	97aa                	add	a5,a5,a0
    80005c3c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005c40:	60a2                	ld	ra,8(sp)
    80005c42:	6402                	ld	s0,0(sp)
    80005c44:	0141                	addi	sp,sp,16
    80005c46:	8082                	ret

0000000080005c48 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c48:	1141                	addi	sp,sp,-16
    80005c4a:	e406                	sd	ra,8(sp)
    80005c4c:	e022                	sd	s0,0(sp)
    80005c4e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c50:	ffffc097          	auipc	ra,0xffffc
    80005c54:	d52080e7          	jalr	-686(ra) # 800019a2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c58:	00d5151b          	slliw	a0,a0,0xd
    80005c5c:	0c2017b7          	lui	a5,0xc201
    80005c60:	97aa                	add	a5,a5,a0
  return irq;
}
    80005c62:	43c8                	lw	a0,4(a5)
    80005c64:	60a2                	ld	ra,8(sp)
    80005c66:	6402                	ld	s0,0(sp)
    80005c68:	0141                	addi	sp,sp,16
    80005c6a:	8082                	ret

0000000080005c6c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c6c:	1101                	addi	sp,sp,-32
    80005c6e:	ec06                	sd	ra,24(sp)
    80005c70:	e822                	sd	s0,16(sp)
    80005c72:	e426                	sd	s1,8(sp)
    80005c74:	1000                	addi	s0,sp,32
    80005c76:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c78:	ffffc097          	auipc	ra,0xffffc
    80005c7c:	d2a080e7          	jalr	-726(ra) # 800019a2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c80:	00d5151b          	slliw	a0,a0,0xd
    80005c84:	0c2017b7          	lui	a5,0xc201
    80005c88:	97aa                	add	a5,a5,a0
    80005c8a:	c3c4                	sw	s1,4(a5)
}
    80005c8c:	60e2                	ld	ra,24(sp)
    80005c8e:	6442                	ld	s0,16(sp)
    80005c90:	64a2                	ld	s1,8(sp)
    80005c92:	6105                	addi	sp,sp,32
    80005c94:	8082                	ret

0000000080005c96 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c96:	1141                	addi	sp,sp,-16
    80005c98:	e406                	sd	ra,8(sp)
    80005c9a:	e022                	sd	s0,0(sp)
    80005c9c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c9e:	479d                	li	a5,7
    80005ca0:	04a7cc63          	blt	a5,a0,80005cf8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005ca4:	0001c797          	auipc	a5,0x1c
    80005ca8:	f8c78793          	addi	a5,a5,-116 # 80021c30 <disk>
    80005cac:	97aa                	add	a5,a5,a0
    80005cae:	0187c783          	lbu	a5,24(a5)
    80005cb2:	ebb9                	bnez	a5,80005d08 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005cb4:	00451693          	slli	a3,a0,0x4
    80005cb8:	0001c797          	auipc	a5,0x1c
    80005cbc:	f7878793          	addi	a5,a5,-136 # 80021c30 <disk>
    80005cc0:	6398                	ld	a4,0(a5)
    80005cc2:	9736                	add	a4,a4,a3
    80005cc4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005cc8:	6398                	ld	a4,0(a5)
    80005cca:	9736                	add	a4,a4,a3
    80005ccc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005cd0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005cd4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005cd8:	97aa                	add	a5,a5,a0
    80005cda:	4705                	li	a4,1
    80005cdc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005ce0:	0001c517          	auipc	a0,0x1c
    80005ce4:	f6850513          	addi	a0,a0,-152 # 80021c48 <disk+0x18>
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	3f2080e7          	jalr	1010(ra) # 800020da <wakeup>
}
    80005cf0:	60a2                	ld	ra,8(sp)
    80005cf2:	6402                	ld	s0,0(sp)
    80005cf4:	0141                	addi	sp,sp,16
    80005cf6:	8082                	ret
    panic("free_desc 1");
    80005cf8:	00003517          	auipc	a0,0x3
    80005cfc:	a5850513          	addi	a0,a0,-1448 # 80008750 <syscalls+0x2f0>
    80005d00:	ffffb097          	auipc	ra,0xffffb
    80005d04:	840080e7          	jalr	-1984(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005d08:	00003517          	auipc	a0,0x3
    80005d0c:	a5850513          	addi	a0,a0,-1448 # 80008760 <syscalls+0x300>
    80005d10:	ffffb097          	auipc	ra,0xffffb
    80005d14:	830080e7          	jalr	-2000(ra) # 80000540 <panic>

0000000080005d18 <virtio_disk_init>:
{
    80005d18:	1101                	addi	sp,sp,-32
    80005d1a:	ec06                	sd	ra,24(sp)
    80005d1c:	e822                	sd	s0,16(sp)
    80005d1e:	e426                	sd	s1,8(sp)
    80005d20:	e04a                	sd	s2,0(sp)
    80005d22:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d24:	00003597          	auipc	a1,0x3
    80005d28:	a4c58593          	addi	a1,a1,-1460 # 80008770 <syscalls+0x310>
    80005d2c:	0001c517          	auipc	a0,0x1c
    80005d30:	02c50513          	addi	a0,a0,44 # 80021d58 <disk+0x128>
    80005d34:	ffffb097          	auipc	ra,0xffffb
    80005d38:	e12080e7          	jalr	-494(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d3c:	100017b7          	lui	a5,0x10001
    80005d40:	4398                	lw	a4,0(a5)
    80005d42:	2701                	sext.w	a4,a4
    80005d44:	747277b7          	lui	a5,0x74727
    80005d48:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d4c:	14f71b63          	bne	a4,a5,80005ea2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005d50:	100017b7          	lui	a5,0x10001
    80005d54:	43dc                	lw	a5,4(a5)
    80005d56:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d58:	4709                	li	a4,2
    80005d5a:	14e79463          	bne	a5,a4,80005ea2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d5e:	100017b7          	lui	a5,0x10001
    80005d62:	479c                	lw	a5,8(a5)
    80005d64:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005d66:	12e79e63          	bne	a5,a4,80005ea2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d6a:	100017b7          	lui	a5,0x10001
    80005d6e:	47d8                	lw	a4,12(a5)
    80005d70:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d72:	554d47b7          	lui	a5,0x554d4
    80005d76:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d7a:	12f71463          	bne	a4,a5,80005ea2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d7e:	100017b7          	lui	a5,0x10001
    80005d82:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d86:	4705                	li	a4,1
    80005d88:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d8a:	470d                	li	a4,3
    80005d8c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d8e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d90:	c7ffe6b7          	lui	a3,0xc7ffe
    80005d94:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc9ef>
    80005d98:	8f75                	and	a4,a4,a3
    80005d9a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d9c:	472d                	li	a4,11
    80005d9e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005da0:	5bbc                	lw	a5,112(a5)
    80005da2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005da6:	8ba1                	andi	a5,a5,8
    80005da8:	10078563          	beqz	a5,80005eb2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005dac:	100017b7          	lui	a5,0x10001
    80005db0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005db4:	43fc                	lw	a5,68(a5)
    80005db6:	2781                	sext.w	a5,a5
    80005db8:	10079563          	bnez	a5,80005ec2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005dbc:	100017b7          	lui	a5,0x10001
    80005dc0:	5bdc                	lw	a5,52(a5)
    80005dc2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005dc4:	10078763          	beqz	a5,80005ed2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005dc8:	471d                	li	a4,7
    80005dca:	10f77c63          	bgeu	a4,a5,80005ee2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005dce:	ffffb097          	auipc	ra,0xffffb
    80005dd2:	d18080e7          	jalr	-744(ra) # 80000ae6 <kalloc>
    80005dd6:	0001c497          	auipc	s1,0x1c
    80005dda:	e5a48493          	addi	s1,s1,-422 # 80021c30 <disk>
    80005dde:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005de0:	ffffb097          	auipc	ra,0xffffb
    80005de4:	d06080e7          	jalr	-762(ra) # 80000ae6 <kalloc>
    80005de8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005dea:	ffffb097          	auipc	ra,0xffffb
    80005dee:	cfc080e7          	jalr	-772(ra) # 80000ae6 <kalloc>
    80005df2:	87aa                	mv	a5,a0
    80005df4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005df6:	6088                	ld	a0,0(s1)
    80005df8:	cd6d                	beqz	a0,80005ef2 <virtio_disk_init+0x1da>
    80005dfa:	0001c717          	auipc	a4,0x1c
    80005dfe:	e3e73703          	ld	a4,-450(a4) # 80021c38 <disk+0x8>
    80005e02:	cb65                	beqz	a4,80005ef2 <virtio_disk_init+0x1da>
    80005e04:	c7fd                	beqz	a5,80005ef2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005e06:	6605                	lui	a2,0x1
    80005e08:	4581                	li	a1,0
    80005e0a:	ffffb097          	auipc	ra,0xffffb
    80005e0e:	ec8080e7          	jalr	-312(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005e12:	0001c497          	auipc	s1,0x1c
    80005e16:	e1e48493          	addi	s1,s1,-482 # 80021c30 <disk>
    80005e1a:	6605                	lui	a2,0x1
    80005e1c:	4581                	li	a1,0
    80005e1e:	6488                	ld	a0,8(s1)
    80005e20:	ffffb097          	auipc	ra,0xffffb
    80005e24:	eb2080e7          	jalr	-334(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005e28:	6605                	lui	a2,0x1
    80005e2a:	4581                	li	a1,0
    80005e2c:	6888                	ld	a0,16(s1)
    80005e2e:	ffffb097          	auipc	ra,0xffffb
    80005e32:	ea4080e7          	jalr	-348(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e36:	100017b7          	lui	a5,0x10001
    80005e3a:	4721                	li	a4,8
    80005e3c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005e3e:	4098                	lw	a4,0(s1)
    80005e40:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005e44:	40d8                	lw	a4,4(s1)
    80005e46:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005e4a:	6498                	ld	a4,8(s1)
    80005e4c:	0007069b          	sext.w	a3,a4
    80005e50:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005e54:	9701                	srai	a4,a4,0x20
    80005e56:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005e5a:	6898                	ld	a4,16(s1)
    80005e5c:	0007069b          	sext.w	a3,a4
    80005e60:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005e64:	9701                	srai	a4,a4,0x20
    80005e66:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005e6a:	4705                	li	a4,1
    80005e6c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005e6e:	00e48c23          	sb	a4,24(s1)
    80005e72:	00e48ca3          	sb	a4,25(s1)
    80005e76:	00e48d23          	sb	a4,26(s1)
    80005e7a:	00e48da3          	sb	a4,27(s1)
    80005e7e:	00e48e23          	sb	a4,28(s1)
    80005e82:	00e48ea3          	sb	a4,29(s1)
    80005e86:	00e48f23          	sb	a4,30(s1)
    80005e8a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005e8e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e92:	0727a823          	sw	s2,112(a5)
}
    80005e96:	60e2                	ld	ra,24(sp)
    80005e98:	6442                	ld	s0,16(sp)
    80005e9a:	64a2                	ld	s1,8(sp)
    80005e9c:	6902                	ld	s2,0(sp)
    80005e9e:	6105                	addi	sp,sp,32
    80005ea0:	8082                	ret
    panic("could not find virtio disk");
    80005ea2:	00003517          	auipc	a0,0x3
    80005ea6:	8de50513          	addi	a0,a0,-1826 # 80008780 <syscalls+0x320>
    80005eaa:	ffffa097          	auipc	ra,0xffffa
    80005eae:	696080e7          	jalr	1686(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005eb2:	00003517          	auipc	a0,0x3
    80005eb6:	8ee50513          	addi	a0,a0,-1810 # 800087a0 <syscalls+0x340>
    80005eba:	ffffa097          	auipc	ra,0xffffa
    80005ebe:	686080e7          	jalr	1670(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005ec2:	00003517          	auipc	a0,0x3
    80005ec6:	8fe50513          	addi	a0,a0,-1794 # 800087c0 <syscalls+0x360>
    80005eca:	ffffa097          	auipc	ra,0xffffa
    80005ece:	676080e7          	jalr	1654(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80005ed2:	00003517          	auipc	a0,0x3
    80005ed6:	90e50513          	addi	a0,a0,-1778 # 800087e0 <syscalls+0x380>
    80005eda:	ffffa097          	auipc	ra,0xffffa
    80005ede:	666080e7          	jalr	1638(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80005ee2:	00003517          	auipc	a0,0x3
    80005ee6:	91e50513          	addi	a0,a0,-1762 # 80008800 <syscalls+0x3a0>
    80005eea:	ffffa097          	auipc	ra,0xffffa
    80005eee:	656080e7          	jalr	1622(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80005ef2:	00003517          	auipc	a0,0x3
    80005ef6:	92e50513          	addi	a0,a0,-1746 # 80008820 <syscalls+0x3c0>
    80005efa:	ffffa097          	auipc	ra,0xffffa
    80005efe:	646080e7          	jalr	1606(ra) # 80000540 <panic>

0000000080005f02 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f02:	7119                	addi	sp,sp,-128
    80005f04:	fc86                	sd	ra,120(sp)
    80005f06:	f8a2                	sd	s0,112(sp)
    80005f08:	f4a6                	sd	s1,104(sp)
    80005f0a:	f0ca                	sd	s2,96(sp)
    80005f0c:	ecce                	sd	s3,88(sp)
    80005f0e:	e8d2                	sd	s4,80(sp)
    80005f10:	e4d6                	sd	s5,72(sp)
    80005f12:	e0da                	sd	s6,64(sp)
    80005f14:	fc5e                	sd	s7,56(sp)
    80005f16:	f862                	sd	s8,48(sp)
    80005f18:	f466                	sd	s9,40(sp)
    80005f1a:	f06a                	sd	s10,32(sp)
    80005f1c:	ec6e                	sd	s11,24(sp)
    80005f1e:	0100                	addi	s0,sp,128
    80005f20:	8aaa                	mv	s5,a0
    80005f22:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f24:	00c52d03          	lw	s10,12(a0)
    80005f28:	001d1d1b          	slliw	s10,s10,0x1
    80005f2c:	1d02                	slli	s10,s10,0x20
    80005f2e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80005f32:	0001c517          	auipc	a0,0x1c
    80005f36:	e2650513          	addi	a0,a0,-474 # 80021d58 <disk+0x128>
    80005f3a:	ffffb097          	auipc	ra,0xffffb
    80005f3e:	c9c080e7          	jalr	-868(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80005f42:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f44:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f46:	0001cb97          	auipc	s7,0x1c
    80005f4a:	ceab8b93          	addi	s7,s7,-790 # 80021c30 <disk>
  for(int i = 0; i < 3; i++){
    80005f4e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f50:	0001cc97          	auipc	s9,0x1c
    80005f54:	e08c8c93          	addi	s9,s9,-504 # 80021d58 <disk+0x128>
    80005f58:	a08d                	j	80005fba <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80005f5a:	00fb8733          	add	a4,s7,a5
    80005f5e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f62:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f64:	0207c563          	bltz	a5,80005f8e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80005f68:	2905                	addiw	s2,s2,1
    80005f6a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80005f6c:	05690c63          	beq	s2,s6,80005fc4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80005f70:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f72:	0001c717          	auipc	a4,0x1c
    80005f76:	cbe70713          	addi	a4,a4,-834 # 80021c30 <disk>
    80005f7a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f7c:	01874683          	lbu	a3,24(a4)
    80005f80:	fee9                	bnez	a3,80005f5a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80005f82:	2785                	addiw	a5,a5,1
    80005f84:	0705                	addi	a4,a4,1
    80005f86:	fe979be3          	bne	a5,s1,80005f7c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80005f8a:	57fd                	li	a5,-1
    80005f8c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005f8e:	01205d63          	blez	s2,80005fa8 <virtio_disk_rw+0xa6>
    80005f92:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005f94:	000a2503          	lw	a0,0(s4)
    80005f98:	00000097          	auipc	ra,0x0
    80005f9c:	cfe080e7          	jalr	-770(ra) # 80005c96 <free_desc>
      for(int j = 0; j < i; j++)
    80005fa0:	2d85                	addiw	s11,s11,1
    80005fa2:	0a11                	addi	s4,s4,4
    80005fa4:	ff2d98e3          	bne	s11,s2,80005f94 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fa8:	85e6                	mv	a1,s9
    80005faa:	0001c517          	auipc	a0,0x1c
    80005fae:	c9e50513          	addi	a0,a0,-866 # 80021c48 <disk+0x18>
    80005fb2:	ffffc097          	auipc	ra,0xffffc
    80005fb6:	0c4080e7          	jalr	196(ra) # 80002076 <sleep>
  for(int i = 0; i < 3; i++){
    80005fba:	f8040a13          	addi	s4,s0,-128
{
    80005fbe:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005fc0:	894e                	mv	s2,s3
    80005fc2:	b77d                	j	80005f70 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005fc4:	f8042503          	lw	a0,-128(s0)
    80005fc8:	00a50713          	addi	a4,a0,10
    80005fcc:	0712                	slli	a4,a4,0x4

  if(write)
    80005fce:	0001c797          	auipc	a5,0x1c
    80005fd2:	c6278793          	addi	a5,a5,-926 # 80021c30 <disk>
    80005fd6:	00e786b3          	add	a3,a5,a4
    80005fda:	01803633          	snez	a2,s8
    80005fde:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005fe0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80005fe4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005fe8:	f6070613          	addi	a2,a4,-160
    80005fec:	6394                	ld	a3,0(a5)
    80005fee:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005ff0:	00870593          	addi	a1,a4,8
    80005ff4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005ff6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005ff8:	0007b803          	ld	a6,0(a5)
    80005ffc:	9642                	add	a2,a2,a6
    80005ffe:	46c1                	li	a3,16
    80006000:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006002:	4585                	li	a1,1
    80006004:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006008:	f8442683          	lw	a3,-124(s0)
    8000600c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006010:	0692                	slli	a3,a3,0x4
    80006012:	9836                	add	a6,a6,a3
    80006014:	058a8613          	addi	a2,s5,88
    80006018:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000601c:	0007b803          	ld	a6,0(a5)
    80006020:	96c2                	add	a3,a3,a6
    80006022:	40000613          	li	a2,1024
    80006026:	c690                	sw	a2,8(a3)
  if(write)
    80006028:	001c3613          	seqz	a2,s8
    8000602c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006030:	00166613          	ori	a2,a2,1
    80006034:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006038:	f8842603          	lw	a2,-120(s0)
    8000603c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006040:	00250693          	addi	a3,a0,2
    80006044:	0692                	slli	a3,a3,0x4
    80006046:	96be                	add	a3,a3,a5
    80006048:	58fd                	li	a7,-1
    8000604a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000604e:	0612                	slli	a2,a2,0x4
    80006050:	9832                	add	a6,a6,a2
    80006052:	f9070713          	addi	a4,a4,-112
    80006056:	973e                	add	a4,a4,a5
    80006058:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000605c:	6398                	ld	a4,0(a5)
    8000605e:	9732                	add	a4,a4,a2
    80006060:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006062:	4609                	li	a2,2
    80006064:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006068:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000606c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006070:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006074:	6794                	ld	a3,8(a5)
    80006076:	0026d703          	lhu	a4,2(a3)
    8000607a:	8b1d                	andi	a4,a4,7
    8000607c:	0706                	slli	a4,a4,0x1
    8000607e:	96ba                	add	a3,a3,a4
    80006080:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006084:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006088:	6798                	ld	a4,8(a5)
    8000608a:	00275783          	lhu	a5,2(a4)
    8000608e:	2785                	addiw	a5,a5,1
    80006090:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006094:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006098:	100017b7          	lui	a5,0x10001
    8000609c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800060a0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800060a4:	0001c917          	auipc	s2,0x1c
    800060a8:	cb490913          	addi	s2,s2,-844 # 80021d58 <disk+0x128>
  while(b->disk == 1) {
    800060ac:	4485                	li	s1,1
    800060ae:	00b79c63          	bne	a5,a1,800060c6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800060b2:	85ca                	mv	a1,s2
    800060b4:	8556                	mv	a0,s5
    800060b6:	ffffc097          	auipc	ra,0xffffc
    800060ba:	fc0080e7          	jalr	-64(ra) # 80002076 <sleep>
  while(b->disk == 1) {
    800060be:	004aa783          	lw	a5,4(s5)
    800060c2:	fe9788e3          	beq	a5,s1,800060b2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800060c6:	f8042903          	lw	s2,-128(s0)
    800060ca:	00290713          	addi	a4,s2,2
    800060ce:	0712                	slli	a4,a4,0x4
    800060d0:	0001c797          	auipc	a5,0x1c
    800060d4:	b6078793          	addi	a5,a5,-1184 # 80021c30 <disk>
    800060d8:	97ba                	add	a5,a5,a4
    800060da:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800060de:	0001c997          	auipc	s3,0x1c
    800060e2:	b5298993          	addi	s3,s3,-1198 # 80021c30 <disk>
    800060e6:	00491713          	slli	a4,s2,0x4
    800060ea:	0009b783          	ld	a5,0(s3)
    800060ee:	97ba                	add	a5,a5,a4
    800060f0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800060f4:	854a                	mv	a0,s2
    800060f6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800060fa:	00000097          	auipc	ra,0x0
    800060fe:	b9c080e7          	jalr	-1124(ra) # 80005c96 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006102:	8885                	andi	s1,s1,1
    80006104:	f0ed                	bnez	s1,800060e6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006106:	0001c517          	auipc	a0,0x1c
    8000610a:	c5250513          	addi	a0,a0,-942 # 80021d58 <disk+0x128>
    8000610e:	ffffb097          	auipc	ra,0xffffb
    80006112:	b7c080e7          	jalr	-1156(ra) # 80000c8a <release>
}
    80006116:	70e6                	ld	ra,120(sp)
    80006118:	7446                	ld	s0,112(sp)
    8000611a:	74a6                	ld	s1,104(sp)
    8000611c:	7906                	ld	s2,96(sp)
    8000611e:	69e6                	ld	s3,88(sp)
    80006120:	6a46                	ld	s4,80(sp)
    80006122:	6aa6                	ld	s5,72(sp)
    80006124:	6b06                	ld	s6,64(sp)
    80006126:	7be2                	ld	s7,56(sp)
    80006128:	7c42                	ld	s8,48(sp)
    8000612a:	7ca2                	ld	s9,40(sp)
    8000612c:	7d02                	ld	s10,32(sp)
    8000612e:	6de2                	ld	s11,24(sp)
    80006130:	6109                	addi	sp,sp,128
    80006132:	8082                	ret

0000000080006134 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006134:	1101                	addi	sp,sp,-32
    80006136:	ec06                	sd	ra,24(sp)
    80006138:	e822                	sd	s0,16(sp)
    8000613a:	e426                	sd	s1,8(sp)
    8000613c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000613e:	0001c497          	auipc	s1,0x1c
    80006142:	af248493          	addi	s1,s1,-1294 # 80021c30 <disk>
    80006146:	0001c517          	auipc	a0,0x1c
    8000614a:	c1250513          	addi	a0,a0,-1006 # 80021d58 <disk+0x128>
    8000614e:	ffffb097          	auipc	ra,0xffffb
    80006152:	a88080e7          	jalr	-1400(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006156:	10001737          	lui	a4,0x10001
    8000615a:	533c                	lw	a5,96(a4)
    8000615c:	8b8d                	andi	a5,a5,3
    8000615e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006160:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006164:	689c                	ld	a5,16(s1)
    80006166:	0204d703          	lhu	a4,32(s1)
    8000616a:	0027d783          	lhu	a5,2(a5)
    8000616e:	04f70863          	beq	a4,a5,800061be <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006172:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006176:	6898                	ld	a4,16(s1)
    80006178:	0204d783          	lhu	a5,32(s1)
    8000617c:	8b9d                	andi	a5,a5,7
    8000617e:	078e                	slli	a5,a5,0x3
    80006180:	97ba                	add	a5,a5,a4
    80006182:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006184:	00278713          	addi	a4,a5,2
    80006188:	0712                	slli	a4,a4,0x4
    8000618a:	9726                	add	a4,a4,s1
    8000618c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006190:	e721                	bnez	a4,800061d8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006192:	0789                	addi	a5,a5,2
    80006194:	0792                	slli	a5,a5,0x4
    80006196:	97a6                	add	a5,a5,s1
    80006198:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000619a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000619e:	ffffc097          	auipc	ra,0xffffc
    800061a2:	f3c080e7          	jalr	-196(ra) # 800020da <wakeup>

    disk.used_idx += 1;
    800061a6:	0204d783          	lhu	a5,32(s1)
    800061aa:	2785                	addiw	a5,a5,1
    800061ac:	17c2                	slli	a5,a5,0x30
    800061ae:	93c1                	srli	a5,a5,0x30
    800061b0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800061b4:	6898                	ld	a4,16(s1)
    800061b6:	00275703          	lhu	a4,2(a4)
    800061ba:	faf71ce3          	bne	a4,a5,80006172 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800061be:	0001c517          	auipc	a0,0x1c
    800061c2:	b9a50513          	addi	a0,a0,-1126 # 80021d58 <disk+0x128>
    800061c6:	ffffb097          	auipc	ra,0xffffb
    800061ca:	ac4080e7          	jalr	-1340(ra) # 80000c8a <release>
}
    800061ce:	60e2                	ld	ra,24(sp)
    800061d0:	6442                	ld	s0,16(sp)
    800061d2:	64a2                	ld	s1,8(sp)
    800061d4:	6105                	addi	sp,sp,32
    800061d6:	8082                	ret
      panic("virtio_disk_intr status");
    800061d8:	00002517          	auipc	a0,0x2
    800061dc:	66050513          	addi	a0,a0,1632 # 80008838 <syscalls+0x3d8>
    800061e0:	ffffa097          	auipc	ra,0xffffa
    800061e4:	360080e7          	jalr	864(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
