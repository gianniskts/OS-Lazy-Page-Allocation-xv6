
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	8c070713          	addi	a4,a4,-1856 # 80008910 <timer_scratch>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca7f>
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
    8000012e:	3a8080e7          	jalr	936(ra) # 800024d2 <either_copyin>
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
    8000018e:	8c650513          	addi	a0,a0,-1850 # 80010a50 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8b648493          	addi	s1,s1,-1866 # 80010a50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	94690913          	addi	s2,s2,-1722 # 80010ae8 <cons+0x98>
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
    800001c4:	80c080e7          	jalr	-2036(ra) # 800019cc <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	154080e7          	jalr	340(ra) # 8000231c <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e9e080e7          	jalr	-354(ra) # 80002074 <sleep>
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
    80000216:	26a080e7          	jalr	618(ra) # 8000247c <either_copyout>
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
    8000022a:	82a50513          	addi	a0,a0,-2006 # 80010a50 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	81450513          	addi	a0,a0,-2028 # 80010a50 <cons>
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
    80000276:	86f72b23          	sw	a5,-1930(a4) # 80010ae8 <cons+0x98>
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
    800002d0:	78450513          	addi	a0,a0,1924 # 80010a50 <cons>
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
    800002f6:	236080e7          	jalr	566(ra) # 80002528 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	75650513          	addi	a0,a0,1878 # 80010a50 <cons>
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
    80000322:	73270713          	addi	a4,a4,1842 # 80010a50 <cons>
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
    8000034c:	70878793          	addi	a5,a5,1800 # 80010a50 <cons>
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
    8000037a:	7727a783          	lw	a5,1906(a5) # 80010ae8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6c670713          	addi	a4,a4,1734 # 80010a50 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6b648493          	addi	s1,s1,1718 # 80010a50 <cons>
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
    800003da:	67a70713          	addi	a4,a4,1658 # 80010a50 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72223          	sw	a5,1796(a4) # 80010af0 <cons+0xa0>
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
    80000416:	63e78793          	addi	a5,a5,1598 # 80010a50 <cons>
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
    8000043a:	6ac7ab23          	sw	a2,1718(a5) # 80010aec <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6aa50513          	addi	a0,a0,1706 # 80010ae8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c92080e7          	jalr	-878(ra) # 800020d8 <wakeup>
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
    80000464:	5f050513          	addi	a0,a0,1520 # 80010a50 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00020797          	auipc	a5,0x20
    8000047c:	77078793          	addi	a5,a5,1904 # 80020be8 <devsw>
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
    80000550:	5c07a223          	sw	zero,1476(a5) # 80010b10 <pr+0x18>
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
    80000584:	34f72823          	sw	a5,848(a4) # 800088d0 <panicked>
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
    800005c0:	554dad83          	lw	s11,1364(s11) # 80010b10 <pr+0x18>
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
    800005fe:	4fe50513          	addi	a0,a0,1278 # 80010af8 <pr>
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
    8000075c:	3a050513          	addi	a0,a0,928 # 80010af8 <pr>
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
    80000778:	38448493          	addi	s1,s1,900 # 80010af8 <pr>
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
    800007d8:	34450513          	addi	a0,a0,836 # 80010b18 <uart_tx_lock>
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
    80000804:	0d07a783          	lw	a5,208(a5) # 800088d0 <panicked>
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
    8000083c:	0a07b783          	ld	a5,160(a5) # 800088d8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0a073703          	ld	a4,160(a4) # 800088e0 <uart_tx_w>
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
    80000866:	2b6a0a13          	addi	s4,s4,694 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	06e48493          	addi	s1,s1,110 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	06e98993          	addi	s3,s3,110 # 800088e0 <uart_tx_w>
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
    80000898:	844080e7          	jalr	-1980(ra) # 800020d8 <wakeup>
    
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
    800008d4:	24850513          	addi	a0,a0,584 # 80010b18 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	ff07a783          	lw	a5,-16(a5) # 800088d0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	ff673703          	ld	a4,-10(a4) # 800088e0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fe67b783          	ld	a5,-26(a5) # 800088d8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	21a98993          	addi	s3,s3,538 # 80010b18 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fd248493          	addi	s1,s1,-46 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fd290913          	addi	s2,s2,-46 # 800088e0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	756080e7          	jalr	1878(ra) # 80002074 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1e448493          	addi	s1,s1,484 # 80010b18 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	f8e7bc23          	sd	a4,-104(a5) # 800088e0 <uart_tx_w>
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
    800009be:	15e48493          	addi	s1,s1,350 # 80010b18 <uart_tx_lock>
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
    80000a00:	38478793          	addi	a5,a5,900 # 80021d80 <end>
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
    80000a20:	13490913          	addi	s2,s2,308 # 80010b50 <kmem>
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
    80000abe:	09650513          	addi	a0,a0,150 # 80010b50 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	2b250513          	addi	a0,a0,690 # 80021d80 <end>
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
    80000af4:	06048493          	addi	s1,s1,96 # 80010b50 <kmem>
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
    80000b0c:	04850513          	addi	a0,a0,72 # 80010b50 <kmem>
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
    80000b38:	01c50513          	addi	a0,a0,28 # 80010b50 <kmem>
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
    80000b74:	e40080e7          	jalr	-448(ra) # 800019b0 <mycpu>
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
    80000ba6:	e0e080e7          	jalr	-498(ra) # 800019b0 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	e02080e7          	jalr	-510(ra) # 800019b0 <mycpu>
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
    80000bca:	dea080e7          	jalr	-534(ra) # 800019b0 <mycpu>
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
    80000c0a:	daa080e7          	jalr	-598(ra) # 800019b0 <mycpu>
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
    80000c36:	d7e080e7          	jalr	-642(ra) # 800019b0 <mycpu>
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
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd281>
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
    80000e84:	b20080e7          	jalr	-1248(ra) # 800019a0 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a6070713          	addi	a4,a4,-1440 # 800088e8 <started>
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
    80000ea0:	b04080e7          	jalr	-1276(ra) # 800019a0 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0f8080e7          	jalr	248(ra) # 80000fae <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00001097          	auipc	ra,0x1
    80000ec2:	7ac080e7          	jalr	1964(ra) # 8000266a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	d4a080e7          	jalr	-694(ra) # 80005c10 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	ff4080e7          	jalr	-12(ra) # 80001ec2 <scheduler>
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
    80000f22:	346080e7          	jalr	838(ra) # 80001264 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	088080e7          	jalr	136(ra) # 80000fae <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	9be080e7          	jalr	-1602(ra) # 800018ec <procinit>
    trapinit();      // trap vectors
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	70c080e7          	jalr	1804(ra) # 80002642 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	72c080e7          	jalr	1836(ra) # 8000266a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	cb4080e7          	jalr	-844(ra) # 80005bfa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	cc2080e7          	jalr	-830(ra) # 80005c10 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	e50080e7          	jalr	-432(ra) # 80002da6 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	4f0080e7          	jalr	1264(ra) # 8000344e <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	496080e7          	jalr	1174(ra) # 800043fc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	daa080e7          	jalr	-598(ra) # 80005d18 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d2e080e7          	jalr	-722(ra) # 80001ca4 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72223          	sw	a5,-1692(a4) # 800088e8 <started>
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
  printf("vmprint not implemented");
    80000f96:	00007517          	auipc	a0,0x7
    80000f9a:	13a50513          	addi	a0,a0,314 # 800080d0 <digits+0x90>
    80000f9e:	fffff097          	auipc	ra,0xfffff
    80000fa2:	5ec080e7          	jalr	1516(ra) # 8000058a <printf>
}
    80000fa6:	60a2                	ld	ra,8(sp)
    80000fa8:	6402                	ld	s0,0(sp)
    80000faa:	0141                	addi	sp,sp,16
    80000fac:	8082                	ret

0000000080000fae <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fae:	1141                	addi	sp,sp,-16
    80000fb0:	e422                	sd	s0,8(sp)
    80000fb2:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb4:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb8:	00008797          	auipc	a5,0x8
    80000fbc:	9387b783          	ld	a5,-1736(a5) # 800088f0 <kernel_pagetable>
    80000fc0:	83b1                	srli	a5,a5,0xc
    80000fc2:	577d                	li	a4,-1
    80000fc4:	177e                	slli	a4,a4,0x3f
    80000fc6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fcc:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fd0:	6422                	ld	s0,8(sp)
    80000fd2:	0141                	addi	sp,sp,16
    80000fd4:	8082                	ret

0000000080000fd6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd6:	7139                	addi	sp,sp,-64
    80000fd8:	fc06                	sd	ra,56(sp)
    80000fda:	f822                	sd	s0,48(sp)
    80000fdc:	f426                	sd	s1,40(sp)
    80000fde:	f04a                	sd	s2,32(sp)
    80000fe0:	ec4e                	sd	s3,24(sp)
    80000fe2:	e852                	sd	s4,16(sp)
    80000fe4:	e456                	sd	s5,8(sp)
    80000fe6:	e05a                	sd	s6,0(sp)
    80000fe8:	0080                	addi	s0,sp,64
    80000fea:	84aa                	mv	s1,a0
    80000fec:	89ae                	mv	s3,a1
    80000fee:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000ff0:	57fd                	li	a5,-1
    80000ff2:	83e9                	srli	a5,a5,0x1a
    80000ff4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff8:	04b7f263          	bgeu	a5,a1,8000103c <walk+0x66>
    panic("walk");
    80000ffc:	00007517          	auipc	a0,0x7
    80001000:	0ec50513          	addi	a0,a0,236 # 800080e8 <digits+0xa8>
    80001004:	fffff097          	auipc	ra,0xfffff
    80001008:	53c080e7          	jalr	1340(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000100c:	060a8663          	beqz	s5,80001078 <walk+0xa2>
    80001010:	00000097          	auipc	ra,0x0
    80001014:	ad6080e7          	jalr	-1322(ra) # 80000ae6 <kalloc>
    80001018:	84aa                	mv	s1,a0
    8000101a:	c529                	beqz	a0,80001064 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000101c:	6605                	lui	a2,0x1
    8000101e:	4581                	li	a1,0
    80001020:	00000097          	auipc	ra,0x0
    80001024:	cb2080e7          	jalr	-846(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001028:	00c4d793          	srli	a5,s1,0xc
    8000102c:	07aa                	slli	a5,a5,0xa
    8000102e:	0017e793          	ori	a5,a5,1
    80001032:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001036:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd277>
    80001038:	036a0063          	beq	s4,s6,80001058 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000103c:	0149d933          	srl	s2,s3,s4
    80001040:	1ff97913          	andi	s2,s2,511
    80001044:	090e                	slli	s2,s2,0x3
    80001046:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001048:	00093483          	ld	s1,0(s2)
    8000104c:	0014f793          	andi	a5,s1,1
    80001050:	dfd5                	beqz	a5,8000100c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001052:	80a9                	srli	s1,s1,0xa
    80001054:	04b2                	slli	s1,s1,0xc
    80001056:	b7c5                	j	80001036 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001058:	00c9d513          	srli	a0,s3,0xc
    8000105c:	1ff57513          	andi	a0,a0,511
    80001060:	050e                	slli	a0,a0,0x3
    80001062:	9526                	add	a0,a0,s1
}
    80001064:	70e2                	ld	ra,56(sp)
    80001066:	7442                	ld	s0,48(sp)
    80001068:	74a2                	ld	s1,40(sp)
    8000106a:	7902                	ld	s2,32(sp)
    8000106c:	69e2                	ld	s3,24(sp)
    8000106e:	6a42                	ld	s4,16(sp)
    80001070:	6aa2                	ld	s5,8(sp)
    80001072:	6b02                	ld	s6,0(sp)
    80001074:	6121                	addi	sp,sp,64
    80001076:	8082                	ret
        return 0;
    80001078:	4501                	li	a0,0
    8000107a:	b7ed                	j	80001064 <walk+0x8e>

000000008000107c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000107c:	57fd                	li	a5,-1
    8000107e:	83e9                	srli	a5,a5,0x1a
    80001080:	00b7f463          	bgeu	a5,a1,80001088 <walkaddr+0xc>
    return 0;
    80001084:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001086:	8082                	ret
{
    80001088:	1141                	addi	sp,sp,-16
    8000108a:	e406                	sd	ra,8(sp)
    8000108c:	e022                	sd	s0,0(sp)
    8000108e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001090:	4601                	li	a2,0
    80001092:	00000097          	auipc	ra,0x0
    80001096:	f44080e7          	jalr	-188(ra) # 80000fd6 <walk>
  if(pte == 0)
    8000109a:	c105                	beqz	a0,800010ba <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000109c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109e:	0117f693          	andi	a3,a5,17
    800010a2:	4745                	li	a4,17
    return 0;
    800010a4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a6:	00e68663          	beq	a3,a4,800010b2 <walkaddr+0x36>
}
    800010aa:	60a2                	ld	ra,8(sp)
    800010ac:	6402                	ld	s0,0(sp)
    800010ae:	0141                	addi	sp,sp,16
    800010b0:	8082                	ret
  pa = PTE2PA(*pte);
    800010b2:	83a9                	srli	a5,a5,0xa
    800010b4:	00c79513          	slli	a0,a5,0xc
  return pa;
    800010b8:	bfcd                	j	800010aa <walkaddr+0x2e>
    return 0;
    800010ba:	4501                	li	a0,0
    800010bc:	b7fd                	j	800010aa <walkaddr+0x2e>

00000000800010be <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010be:	715d                	addi	sp,sp,-80
    800010c0:	e486                	sd	ra,72(sp)
    800010c2:	e0a2                	sd	s0,64(sp)
    800010c4:	fc26                	sd	s1,56(sp)
    800010c6:	f84a                	sd	s2,48(sp)
    800010c8:	f44e                	sd	s3,40(sp)
    800010ca:	f052                	sd	s4,32(sp)
    800010cc:	ec56                	sd	s5,24(sp)
    800010ce:	e85a                	sd	s6,16(sp)
    800010d0:	e45e                	sd	s7,8(sp)
    800010d2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d4:	c639                	beqz	a2,80001122 <mappages+0x64>
    800010d6:	8aaa                	mv	s5,a0
    800010d8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010da:	777d                	lui	a4,0xfffff
    800010dc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010e0:	fff58993          	addi	s3,a1,-1
    800010e4:	99b2                	add	s3,s3,a2
    800010e6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ea:	893e                	mv	s2,a5
    800010ec:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010f0:	6b85                	lui	s7,0x1
    800010f2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	4605                	li	a2,1
    800010f8:	85ca                	mv	a1,s2
    800010fa:	8556                	mv	a0,s5
    800010fc:	00000097          	auipc	ra,0x0
    80001100:	eda080e7          	jalr	-294(ra) # 80000fd6 <walk>
    80001104:	cd1d                	beqz	a0,80001142 <mappages+0x84>
    if(*pte & PTE_V)
    80001106:	611c                	ld	a5,0(a0)
    80001108:	8b85                	andi	a5,a5,1
    8000110a:	e785                	bnez	a5,80001132 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000110c:	80b1                	srli	s1,s1,0xc
    8000110e:	04aa                	slli	s1,s1,0xa
    80001110:	0164e4b3          	or	s1,s1,s6
    80001114:	0014e493          	ori	s1,s1,1
    80001118:	e104                	sd	s1,0(a0)
    if(a == last)
    8000111a:	05390063          	beq	s2,s3,8000115a <mappages+0x9c>
    a += PGSIZE;
    8000111e:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001120:	bfc9                	j	800010f2 <mappages+0x34>
    panic("mappages: size");
    80001122:	00007517          	auipc	a0,0x7
    80001126:	fce50513          	addi	a0,a0,-50 # 800080f0 <digits+0xb0>
    8000112a:	fffff097          	auipc	ra,0xfffff
    8000112e:	416080e7          	jalr	1046(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001132:	00007517          	auipc	a0,0x7
    80001136:	fce50513          	addi	a0,a0,-50 # 80008100 <digits+0xc0>
    8000113a:	fffff097          	auipc	ra,0xfffff
    8000113e:	406080e7          	jalr	1030(ra) # 80000540 <panic>
      return -1;
    80001142:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret
  return 0;
    8000115a:	4501                	li	a0,0
    8000115c:	b7e5                	j	80001144 <mappages+0x86>

000000008000115e <kvmmap>:
{
    8000115e:	1141                	addi	sp,sp,-16
    80001160:	e406                	sd	ra,8(sp)
    80001162:	e022                	sd	s0,0(sp)
    80001164:	0800                	addi	s0,sp,16
    80001166:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001168:	86b2                	mv	a3,a2
    8000116a:	863e                	mv	a2,a5
    8000116c:	00000097          	auipc	ra,0x0
    80001170:	f52080e7          	jalr	-174(ra) # 800010be <mappages>
    80001174:	e509                	bnez	a0,8000117e <kvmmap+0x20>
}
    80001176:	60a2                	ld	ra,8(sp)
    80001178:	6402                	ld	s0,0(sp)
    8000117a:	0141                	addi	sp,sp,16
    8000117c:	8082                	ret
    panic("kvmmap");
    8000117e:	00007517          	auipc	a0,0x7
    80001182:	f9250513          	addi	a0,a0,-110 # 80008110 <digits+0xd0>
    80001186:	fffff097          	auipc	ra,0xfffff
    8000118a:	3ba080e7          	jalr	954(ra) # 80000540 <panic>

000000008000118e <kvmmake>:
{
    8000118e:	1101                	addi	sp,sp,-32
    80001190:	ec06                	sd	ra,24(sp)
    80001192:	e822                	sd	s0,16(sp)
    80001194:	e426                	sd	s1,8(sp)
    80001196:	e04a                	sd	s2,0(sp)
    80001198:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	94c080e7          	jalr	-1716(ra) # 80000ae6 <kalloc>
    800011a2:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a4:	6605                	lui	a2,0x1
    800011a6:	4581                	li	a1,0
    800011a8:	00000097          	auipc	ra,0x0
    800011ac:	b2a080e7          	jalr	-1238(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011b0:	4719                	li	a4,6
    800011b2:	6685                	lui	a3,0x1
    800011b4:	10000637          	lui	a2,0x10000
    800011b8:	100005b7          	lui	a1,0x10000
    800011bc:	8526                	mv	a0,s1
    800011be:	00000097          	auipc	ra,0x0
    800011c2:	fa0080e7          	jalr	-96(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c6:	4719                	li	a4,6
    800011c8:	6685                	lui	a3,0x1
    800011ca:	10001637          	lui	a2,0x10001
    800011ce:	100015b7          	lui	a1,0x10001
    800011d2:	8526                	mv	a0,s1
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	f8a080e7          	jalr	-118(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011dc:	4719                	li	a4,6
    800011de:	004006b7          	lui	a3,0x400
    800011e2:	0c000637          	lui	a2,0xc000
    800011e6:	0c0005b7          	lui	a1,0xc000
    800011ea:	8526                	mv	a0,s1
    800011ec:	00000097          	auipc	ra,0x0
    800011f0:	f72080e7          	jalr	-142(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f4:	00007917          	auipc	s2,0x7
    800011f8:	e0c90913          	addi	s2,s2,-500 # 80008000 <etext>
    800011fc:	4729                	li	a4,10
    800011fe:	80007697          	auipc	a3,0x80007
    80001202:	e0268693          	addi	a3,a3,-510 # 8000 <_entry-0x7fff8000>
    80001206:	4605                	li	a2,1
    80001208:	067e                	slli	a2,a2,0x1f
    8000120a:	85b2                	mv	a1,a2
    8000120c:	8526                	mv	a0,s1
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f50080e7          	jalr	-176(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001216:	4719                	li	a4,6
    80001218:	46c5                	li	a3,17
    8000121a:	06ee                	slli	a3,a3,0x1b
    8000121c:	412686b3          	sub	a3,a3,s2
    80001220:	864a                	mv	a2,s2
    80001222:	85ca                	mv	a1,s2
    80001224:	8526                	mv	a0,s1
    80001226:	00000097          	auipc	ra,0x0
    8000122a:	f38080e7          	jalr	-200(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122e:	4729                	li	a4,10
    80001230:	6685                	lui	a3,0x1
    80001232:	00006617          	auipc	a2,0x6
    80001236:	dce60613          	addi	a2,a2,-562 # 80007000 <_trampoline>
    8000123a:	040005b7          	lui	a1,0x4000
    8000123e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001240:	05b2                	slli	a1,a1,0xc
    80001242:	8526                	mv	a0,s1
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f1a080e7          	jalr	-230(ra) # 8000115e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000124c:	8526                	mv	a0,s1
    8000124e:	00000097          	auipc	ra,0x0
    80001252:	608080e7          	jalr	1544(ra) # 80001856 <proc_mapstacks>
}
    80001256:	8526                	mv	a0,s1
    80001258:	60e2                	ld	ra,24(sp)
    8000125a:	6442                	ld	s0,16(sp)
    8000125c:	64a2                	ld	s1,8(sp)
    8000125e:	6902                	ld	s2,0(sp)
    80001260:	6105                	addi	sp,sp,32
    80001262:	8082                	ret

0000000080001264 <kvminit>:
{
    80001264:	1141                	addi	sp,sp,-16
    80001266:	e406                	sd	ra,8(sp)
    80001268:	e022                	sd	s0,0(sp)
    8000126a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	f22080e7          	jalr	-222(ra) # 8000118e <kvmmake>
    80001274:	00007797          	auipc	a5,0x7
    80001278:	66a7be23          	sd	a0,1660(a5) # 800088f0 <kernel_pagetable>
}
    8000127c:	60a2                	ld	ra,8(sp)
    8000127e:	6402                	ld	s0,0(sp)
    80001280:	0141                	addi	sp,sp,16
    80001282:	8082                	ret

0000000080001284 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001284:	715d                	addi	sp,sp,-80
    80001286:	e486                	sd	ra,72(sp)
    80001288:	e0a2                	sd	s0,64(sp)
    8000128a:	fc26                	sd	s1,56(sp)
    8000128c:	f84a                	sd	s2,48(sp)
    8000128e:	f44e                	sd	s3,40(sp)
    80001290:	f052                	sd	s4,32(sp)
    80001292:	ec56                	sd	s5,24(sp)
    80001294:	e85a                	sd	s6,16(sp)
    80001296:	e45e                	sd	s7,8(sp)
    80001298:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000129a:	03459793          	slli	a5,a1,0x34
    8000129e:	e795                	bnez	a5,800012ca <uvmunmap+0x46>
    800012a0:	8a2a                	mv	s4,a0
    800012a2:	892e                	mv	s2,a1
    800012a4:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a6:	0632                	slli	a2,a2,0xc
    800012a8:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ac:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ae:	6b05                	lui	s6,0x1
    800012b0:	0735e263          	bltu	a1,s3,80001314 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b4:	60a6                	ld	ra,72(sp)
    800012b6:	6406                	ld	s0,64(sp)
    800012b8:	74e2                	ld	s1,56(sp)
    800012ba:	7942                	ld	s2,48(sp)
    800012bc:	79a2                	ld	s3,40(sp)
    800012be:	7a02                	ld	s4,32(sp)
    800012c0:	6ae2                	ld	s5,24(sp)
    800012c2:	6b42                	ld	s6,16(sp)
    800012c4:	6ba2                	ld	s7,8(sp)
    800012c6:	6161                	addi	sp,sp,80
    800012c8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e4e50513          	addi	a0,a0,-434 # 80008118 <digits+0xd8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e5650513          	addi	a0,a0,-426 # 80008130 <digits+0xf0>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ea:	00007517          	auipc	a0,0x7
    800012ee:	e5650513          	addi	a0,a0,-426 # 80008140 <digits+0x100>
    800012f2:	fffff097          	auipc	ra,0xfffff
    800012f6:	24e080e7          	jalr	590(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012fa:	00007517          	auipc	a0,0x7
    800012fe:	e5e50513          	addi	a0,a0,-418 # 80008158 <digits+0x118>
    80001302:	fffff097          	auipc	ra,0xfffff
    80001306:	23e080e7          	jalr	574(ra) # 80000540 <panic>
    *pte = 0;
    8000130a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130e:	995a                	add	s2,s2,s6
    80001310:	fb3972e3          	bgeu	s2,s3,800012b4 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001314:	4601                	li	a2,0
    80001316:	85ca                	mv	a1,s2
    80001318:	8552                	mv	a0,s4
    8000131a:	00000097          	auipc	ra,0x0
    8000131e:	cbc080e7          	jalr	-836(ra) # 80000fd6 <walk>
    80001322:	84aa                	mv	s1,a0
    80001324:	d95d                	beqz	a0,800012da <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001326:	6108                	ld	a0,0(a0)
    80001328:	00157793          	andi	a5,a0,1
    8000132c:	dfdd                	beqz	a5,800012ea <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132e:	3ff57793          	andi	a5,a0,1023
    80001332:	fd7784e3          	beq	a5,s7,800012fa <uvmunmap+0x76>
    if(do_free){
    80001336:	fc0a8ae3          	beqz	s5,8000130a <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000133a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000133c:	0532                	slli	a0,a0,0xc
    8000133e:	fffff097          	auipc	ra,0xfffff
    80001342:	6aa080e7          	jalr	1706(ra) # 800009e8 <kfree>
    80001346:	b7d1                	j	8000130a <uvmunmap+0x86>

0000000080001348 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001348:	1101                	addi	sp,sp,-32
    8000134a:	ec06                	sd	ra,24(sp)
    8000134c:	e822                	sd	s0,16(sp)
    8000134e:	e426                	sd	s1,8(sp)
    80001350:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001352:	fffff097          	auipc	ra,0xfffff
    80001356:	794080e7          	jalr	1940(ra) # 80000ae6 <kalloc>
    8000135a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000135c:	c519                	beqz	a0,8000136a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135e:	6605                	lui	a2,0x1
    80001360:	4581                	li	a1,0
    80001362:	00000097          	auipc	ra,0x0
    80001366:	970080e7          	jalr	-1680(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000136a:	8526                	mv	a0,s1
    8000136c:	60e2                	ld	ra,24(sp)
    8000136e:	6442                	ld	s0,16(sp)
    80001370:	64a2                	ld	s1,8(sp)
    80001372:	6105                	addi	sp,sp,32
    80001374:	8082                	ret

0000000080001376 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001376:	7179                	addi	sp,sp,-48
    80001378:	f406                	sd	ra,40(sp)
    8000137a:	f022                	sd	s0,32(sp)
    8000137c:	ec26                	sd	s1,24(sp)
    8000137e:	e84a                	sd	s2,16(sp)
    80001380:	e44e                	sd	s3,8(sp)
    80001382:	e052                	sd	s4,0(sp)
    80001384:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001386:	6785                	lui	a5,0x1
    80001388:	04f67863          	bgeu	a2,a5,800013d8 <uvmfirst+0x62>
    8000138c:	8a2a                	mv	s4,a0
    8000138e:	89ae                	mv	s3,a1
    80001390:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001392:	fffff097          	auipc	ra,0xfffff
    80001396:	754080e7          	jalr	1876(ra) # 80000ae6 <kalloc>
    8000139a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000139c:	6605                	lui	a2,0x1
    8000139e:	4581                	li	a1,0
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	932080e7          	jalr	-1742(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a8:	4779                	li	a4,30
    800013aa:	86ca                	mv	a3,s2
    800013ac:	6605                	lui	a2,0x1
    800013ae:	4581                	li	a1,0
    800013b0:	8552                	mv	a0,s4
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	d0c080e7          	jalr	-756(ra) # 800010be <mappages>
  memmove(mem, src, sz);
    800013ba:	8626                	mv	a2,s1
    800013bc:	85ce                	mv	a1,s3
    800013be:	854a                	mv	a0,s2
    800013c0:	00000097          	auipc	ra,0x0
    800013c4:	96e080e7          	jalr	-1682(ra) # 80000d2e <memmove>
}
    800013c8:	70a2                	ld	ra,40(sp)
    800013ca:	7402                	ld	s0,32(sp)
    800013cc:	64e2                	ld	s1,24(sp)
    800013ce:	6942                	ld	s2,16(sp)
    800013d0:	69a2                	ld	s3,8(sp)
    800013d2:	6a02                	ld	s4,0(sp)
    800013d4:	6145                	addi	sp,sp,48
    800013d6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d8:	00007517          	auipc	a0,0x7
    800013dc:	d9850513          	addi	a0,a0,-616 # 80008170 <digits+0x130>
    800013e0:	fffff097          	auipc	ra,0xfffff
    800013e4:	160080e7          	jalr	352(ra) # 80000540 <panic>

00000000800013e8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e8:	1101                	addi	sp,sp,-32
    800013ea:	ec06                	sd	ra,24(sp)
    800013ec:	e822                	sd	s0,16(sp)
    800013ee:	e426                	sd	s1,8(sp)
    800013f0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013f2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f4:	00b67d63          	bgeu	a2,a1,8000140e <uvmdealloc+0x26>
    800013f8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013fa:	6785                	lui	a5,0x1
    800013fc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013fe:	00f60733          	add	a4,a2,a5
    80001402:	76fd                	lui	a3,0xfffff
    80001404:	8f75                	and	a4,a4,a3
    80001406:	97ae                	add	a5,a5,a1
    80001408:	8ff5                	and	a5,a5,a3
    8000140a:	00f76863          	bltu	a4,a5,8000141a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140e:	8526                	mv	a0,s1
    80001410:	60e2                	ld	ra,24(sp)
    80001412:	6442                	ld	s0,16(sp)
    80001414:	64a2                	ld	s1,8(sp)
    80001416:	6105                	addi	sp,sp,32
    80001418:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000141a:	8f99                	sub	a5,a5,a4
    8000141c:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141e:	4685                	li	a3,1
    80001420:	0007861b          	sext.w	a2,a5
    80001424:	85ba                	mv	a1,a4
    80001426:	00000097          	auipc	ra,0x0
    8000142a:	e5e080e7          	jalr	-418(ra) # 80001284 <uvmunmap>
    8000142e:	b7c5                	j	8000140e <uvmdealloc+0x26>

0000000080001430 <uvmalloc>:
  if(newsz < oldsz)
    80001430:	0ab66563          	bltu	a2,a1,800014da <uvmalloc+0xaa>
{
    80001434:	7139                	addi	sp,sp,-64
    80001436:	fc06                	sd	ra,56(sp)
    80001438:	f822                	sd	s0,48(sp)
    8000143a:	f426                	sd	s1,40(sp)
    8000143c:	f04a                	sd	s2,32(sp)
    8000143e:	ec4e                	sd	s3,24(sp)
    80001440:	e852                	sd	s4,16(sp)
    80001442:	e456                	sd	s5,8(sp)
    80001444:	e05a                	sd	s6,0(sp)
    80001446:	0080                	addi	s0,sp,64
    80001448:	8aaa                	mv	s5,a0
    8000144a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000144c:	6785                	lui	a5,0x1
    8000144e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001450:	95be                	add	a1,a1,a5
    80001452:	77fd                	lui	a5,0xfffff
    80001454:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001458:	08c9f363          	bgeu	s3,a2,800014de <uvmalloc+0xae>
    8000145c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001462:	fffff097          	auipc	ra,0xfffff
    80001466:	684080e7          	jalr	1668(ra) # 80000ae6 <kalloc>
    8000146a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000146c:	c51d                	beqz	a0,8000149a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000146e:	6605                	lui	a2,0x1
    80001470:	4581                	li	a1,0
    80001472:	00000097          	auipc	ra,0x0
    80001476:	860080e7          	jalr	-1952(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000147a:	875a                	mv	a4,s6
    8000147c:	86a6                	mv	a3,s1
    8000147e:	6605                	lui	a2,0x1
    80001480:	85ca                	mv	a1,s2
    80001482:	8556                	mv	a0,s5
    80001484:	00000097          	auipc	ra,0x0
    80001488:	c3a080e7          	jalr	-966(ra) # 800010be <mappages>
    8000148c:	e90d                	bnez	a0,800014be <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148e:	6785                	lui	a5,0x1
    80001490:	993e                	add	s2,s2,a5
    80001492:	fd4968e3          	bltu	s2,s4,80001462 <uvmalloc+0x32>
  return newsz;
    80001496:	8552                	mv	a0,s4
    80001498:	a809                	j	800014aa <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000149a:	864e                	mv	a2,s3
    8000149c:	85ca                	mv	a1,s2
    8000149e:	8556                	mv	a0,s5
    800014a0:	00000097          	auipc	ra,0x0
    800014a4:	f48080e7          	jalr	-184(ra) # 800013e8 <uvmdealloc>
      return 0;
    800014a8:	4501                	li	a0,0
}
    800014aa:	70e2                	ld	ra,56(sp)
    800014ac:	7442                	ld	s0,48(sp)
    800014ae:	74a2                	ld	s1,40(sp)
    800014b0:	7902                	ld	s2,32(sp)
    800014b2:	69e2                	ld	s3,24(sp)
    800014b4:	6a42                	ld	s4,16(sp)
    800014b6:	6aa2                	ld	s5,8(sp)
    800014b8:	6b02                	ld	s6,0(sp)
    800014ba:	6121                	addi	sp,sp,64
    800014bc:	8082                	ret
      kfree(mem);
    800014be:	8526                	mv	a0,s1
    800014c0:	fffff097          	auipc	ra,0xfffff
    800014c4:	528080e7          	jalr	1320(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c8:	864e                	mv	a2,s3
    800014ca:	85ca                	mv	a1,s2
    800014cc:	8556                	mv	a0,s5
    800014ce:	00000097          	auipc	ra,0x0
    800014d2:	f1a080e7          	jalr	-230(ra) # 800013e8 <uvmdealloc>
      return 0;
    800014d6:	4501                	li	a0,0
    800014d8:	bfc9                	j	800014aa <uvmalloc+0x7a>
    return oldsz;
    800014da:	852e                	mv	a0,a1
}
    800014dc:	8082                	ret
  return newsz;
    800014de:	8532                	mv	a0,a2
    800014e0:	b7e9                	j	800014aa <uvmalloc+0x7a>

00000000800014e2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014e2:	7179                	addi	sp,sp,-48
    800014e4:	f406                	sd	ra,40(sp)
    800014e6:	f022                	sd	s0,32(sp)
    800014e8:	ec26                	sd	s1,24(sp)
    800014ea:	e84a                	sd	s2,16(sp)
    800014ec:	e44e                	sd	s3,8(sp)
    800014ee:	e052                	sd	s4,0(sp)
    800014f0:	1800                	addi	s0,sp,48
    800014f2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f4:	84aa                	mv	s1,a0
    800014f6:	6905                	lui	s2,0x1
    800014f8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014fa:	4985                	li	s3,1
    800014fc:	a829                	j	80001516 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fe:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001500:	00c79513          	slli	a0,a5,0xc
    80001504:	00000097          	auipc	ra,0x0
    80001508:	fde080e7          	jalr	-34(ra) # 800014e2 <freewalk>
      pagetable[i] = 0;
    8000150c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001510:	04a1                	addi	s1,s1,8
    80001512:	03248163          	beq	s1,s2,80001534 <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001516:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001518:	00f7f713          	andi	a4,a5,15
    8000151c:	ff3701e3          	beq	a4,s3,800014fe <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001520:	8b85                	andi	a5,a5,1
    80001522:	d7fd                	beqz	a5,80001510 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001524:	00007517          	auipc	a0,0x7
    80001528:	c6c50513          	addi	a0,a0,-916 # 80008190 <digits+0x150>
    8000152c:	fffff097          	auipc	ra,0xfffff
    80001530:	014080e7          	jalr	20(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001534:	8552                	mv	a0,s4
    80001536:	fffff097          	auipc	ra,0xfffff
    8000153a:	4b2080e7          	jalr	1202(ra) # 800009e8 <kfree>
}
    8000153e:	70a2                	ld	ra,40(sp)
    80001540:	7402                	ld	s0,32(sp)
    80001542:	64e2                	ld	s1,24(sp)
    80001544:	6942                	ld	s2,16(sp)
    80001546:	69a2                	ld	s3,8(sp)
    80001548:	6a02                	ld	s4,0(sp)
    8000154a:	6145                	addi	sp,sp,48
    8000154c:	8082                	ret

000000008000154e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000154e:	1101                	addi	sp,sp,-32
    80001550:	ec06                	sd	ra,24(sp)
    80001552:	e822                	sd	s0,16(sp)
    80001554:	e426                	sd	s1,8(sp)
    80001556:	1000                	addi	s0,sp,32
    80001558:	84aa                	mv	s1,a0
  if(sz > 0)
    8000155a:	e999                	bnez	a1,80001570 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000155c:	8526                	mv	a0,s1
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	f84080e7          	jalr	-124(ra) # 800014e2 <freewalk>
}
    80001566:	60e2                	ld	ra,24(sp)
    80001568:	6442                	ld	s0,16(sp)
    8000156a:	64a2                	ld	s1,8(sp)
    8000156c:	6105                	addi	sp,sp,32
    8000156e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001570:	6785                	lui	a5,0x1
    80001572:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001574:	95be                	add	a1,a1,a5
    80001576:	4685                	li	a3,1
    80001578:	00c5d613          	srli	a2,a1,0xc
    8000157c:	4581                	li	a1,0
    8000157e:	00000097          	auipc	ra,0x0
    80001582:	d06080e7          	jalr	-762(ra) # 80001284 <uvmunmap>
    80001586:	bfd9                	j	8000155c <uvmfree+0xe>

0000000080001588 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001588:	c679                	beqz	a2,80001656 <uvmcopy+0xce>
{
    8000158a:	715d                	addi	sp,sp,-80
    8000158c:	e486                	sd	ra,72(sp)
    8000158e:	e0a2                	sd	s0,64(sp)
    80001590:	fc26                	sd	s1,56(sp)
    80001592:	f84a                	sd	s2,48(sp)
    80001594:	f44e                	sd	s3,40(sp)
    80001596:	f052                	sd	s4,32(sp)
    80001598:	ec56                	sd	s5,24(sp)
    8000159a:	e85a                	sd	s6,16(sp)
    8000159c:	e45e                	sd	s7,8(sp)
    8000159e:	0880                	addi	s0,sp,80
    800015a0:	8b2a                	mv	s6,a0
    800015a2:	8aae                	mv	s5,a1
    800015a4:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015a6:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a8:	4601                	li	a2,0
    800015aa:	85ce                	mv	a1,s3
    800015ac:	855a                	mv	a0,s6
    800015ae:	00000097          	auipc	ra,0x0
    800015b2:	a28080e7          	jalr	-1496(ra) # 80000fd6 <walk>
    800015b6:	c531                	beqz	a0,80001602 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b8:	6118                	ld	a4,0(a0)
    800015ba:	00177793          	andi	a5,a4,1
    800015be:	cbb1                	beqz	a5,80001612 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015c0:	00a75593          	srli	a1,a4,0xa
    800015c4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015cc:	fffff097          	auipc	ra,0xfffff
    800015d0:	51a080e7          	jalr	1306(ra) # 80000ae6 <kalloc>
    800015d4:	892a                	mv	s2,a0
    800015d6:	c939                	beqz	a0,8000162c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d8:	6605                	lui	a2,0x1
    800015da:	85de                	mv	a1,s7
    800015dc:	fffff097          	auipc	ra,0xfffff
    800015e0:	752080e7          	jalr	1874(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015e4:	8726                	mv	a4,s1
    800015e6:	86ca                	mv	a3,s2
    800015e8:	6605                	lui	a2,0x1
    800015ea:	85ce                	mv	a1,s3
    800015ec:	8556                	mv	a0,s5
    800015ee:	00000097          	auipc	ra,0x0
    800015f2:	ad0080e7          	jalr	-1328(ra) # 800010be <mappages>
    800015f6:	e515                	bnez	a0,80001622 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f8:	6785                	lui	a5,0x1
    800015fa:	99be                	add	s3,s3,a5
    800015fc:	fb49e6e3          	bltu	s3,s4,800015a8 <uvmcopy+0x20>
    80001600:	a081                	j	80001640 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001602:	00007517          	auipc	a0,0x7
    80001606:	b9e50513          	addi	a0,a0,-1122 # 800081a0 <digits+0x160>
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	f36080e7          	jalr	-202(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    80001612:	00007517          	auipc	a0,0x7
    80001616:	bae50513          	addi	a0,a0,-1106 # 800081c0 <digits+0x180>
    8000161a:	fffff097          	auipc	ra,0xfffff
    8000161e:	f26080e7          	jalr	-218(ra) # 80000540 <panic>
      kfree(mem);
    80001622:	854a                	mv	a0,s2
    80001624:	fffff097          	auipc	ra,0xfffff
    80001628:	3c4080e7          	jalr	964(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000162c:	4685                	li	a3,1
    8000162e:	00c9d613          	srli	a2,s3,0xc
    80001632:	4581                	li	a1,0
    80001634:	8556                	mv	a0,s5
    80001636:	00000097          	auipc	ra,0x0
    8000163a:	c4e080e7          	jalr	-946(ra) # 80001284 <uvmunmap>
  return -1;
    8000163e:	557d                	li	a0,-1
}
    80001640:	60a6                	ld	ra,72(sp)
    80001642:	6406                	ld	s0,64(sp)
    80001644:	74e2                	ld	s1,56(sp)
    80001646:	7942                	ld	s2,48(sp)
    80001648:	79a2                	ld	s3,40(sp)
    8000164a:	7a02                	ld	s4,32(sp)
    8000164c:	6ae2                	ld	s5,24(sp)
    8000164e:	6b42                	ld	s6,16(sp)
    80001650:	6ba2                	ld	s7,8(sp)
    80001652:	6161                	addi	sp,sp,80
    80001654:	8082                	ret
  return 0;
    80001656:	4501                	li	a0,0
}
    80001658:	8082                	ret

000000008000165a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000165a:	1141                	addi	sp,sp,-16
    8000165c:	e406                	sd	ra,8(sp)
    8000165e:	e022                	sd	s0,0(sp)
    80001660:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001662:	4601                	li	a2,0
    80001664:	00000097          	auipc	ra,0x0
    80001668:	972080e7          	jalr	-1678(ra) # 80000fd6 <walk>
  if(pte == 0)
    8000166c:	c901                	beqz	a0,8000167c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000166e:	611c                	ld	a5,0(a0)
    80001670:	9bbd                	andi	a5,a5,-17
    80001672:	e11c                	sd	a5,0(a0)
}
    80001674:	60a2                	ld	ra,8(sp)
    80001676:	6402                	ld	s0,0(sp)
    80001678:	0141                	addi	sp,sp,16
    8000167a:	8082                	ret
    panic("uvmclear");
    8000167c:	00007517          	auipc	a0,0x7
    80001680:	b6450513          	addi	a0,a0,-1180 # 800081e0 <digits+0x1a0>
    80001684:	fffff097          	auipc	ra,0xfffff
    80001688:	ebc080e7          	jalr	-324(ra) # 80000540 <panic>

000000008000168c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000168c:	c6bd                	beqz	a3,800016fa <copyout+0x6e>
{
    8000168e:	715d                	addi	sp,sp,-80
    80001690:	e486                	sd	ra,72(sp)
    80001692:	e0a2                	sd	s0,64(sp)
    80001694:	fc26                	sd	s1,56(sp)
    80001696:	f84a                	sd	s2,48(sp)
    80001698:	f44e                	sd	s3,40(sp)
    8000169a:	f052                	sd	s4,32(sp)
    8000169c:	ec56                	sd	s5,24(sp)
    8000169e:	e85a                	sd	s6,16(sp)
    800016a0:	e45e                	sd	s7,8(sp)
    800016a2:	e062                	sd	s8,0(sp)
    800016a4:	0880                	addi	s0,sp,80
    800016a6:	8b2a                	mv	s6,a0
    800016a8:	8c2e                	mv	s8,a1
    800016aa:	8a32                	mv	s4,a2
    800016ac:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016ae:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016b0:	6a85                	lui	s5,0x1
    800016b2:	a015                	j	800016d6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016b4:	9562                	add	a0,a0,s8
    800016b6:	0004861b          	sext.w	a2,s1
    800016ba:	85d2                	mv	a1,s4
    800016bc:	41250533          	sub	a0,a0,s2
    800016c0:	fffff097          	auipc	ra,0xfffff
    800016c4:	66e080e7          	jalr	1646(ra) # 80000d2e <memmove>

    len -= n;
    800016c8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016cc:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ce:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016d2:	02098263          	beqz	s3,800016f6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016d6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016da:	85ca                	mv	a1,s2
    800016dc:	855a                	mv	a0,s6
    800016de:	00000097          	auipc	ra,0x0
    800016e2:	99e080e7          	jalr	-1634(ra) # 8000107c <walkaddr>
    if(pa0 == 0)
    800016e6:	cd01                	beqz	a0,800016fe <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e8:	418904b3          	sub	s1,s2,s8
    800016ec:	94d6                	add	s1,s1,s5
    800016ee:	fc99f3e3          	bgeu	s3,s1,800016b4 <copyout+0x28>
    800016f2:	84ce                	mv	s1,s3
    800016f4:	b7c1                	j	800016b4 <copyout+0x28>
  }
  return 0;
    800016f6:	4501                	li	a0,0
    800016f8:	a021                	j	80001700 <copyout+0x74>
    800016fa:	4501                	li	a0,0
}
    800016fc:	8082                	ret
      return -1;
    800016fe:	557d                	li	a0,-1
}
    80001700:	60a6                	ld	ra,72(sp)
    80001702:	6406                	ld	s0,64(sp)
    80001704:	74e2                	ld	s1,56(sp)
    80001706:	7942                	ld	s2,48(sp)
    80001708:	79a2                	ld	s3,40(sp)
    8000170a:	7a02                	ld	s4,32(sp)
    8000170c:	6ae2                	ld	s5,24(sp)
    8000170e:	6b42                	ld	s6,16(sp)
    80001710:	6ba2                	ld	s7,8(sp)
    80001712:	6c02                	ld	s8,0(sp)
    80001714:	6161                	addi	sp,sp,80
    80001716:	8082                	ret

0000000080001718 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001718:	caa5                	beqz	a3,80001788 <copyin+0x70>
{
    8000171a:	715d                	addi	sp,sp,-80
    8000171c:	e486                	sd	ra,72(sp)
    8000171e:	e0a2                	sd	s0,64(sp)
    80001720:	fc26                	sd	s1,56(sp)
    80001722:	f84a                	sd	s2,48(sp)
    80001724:	f44e                	sd	s3,40(sp)
    80001726:	f052                	sd	s4,32(sp)
    80001728:	ec56                	sd	s5,24(sp)
    8000172a:	e85a                	sd	s6,16(sp)
    8000172c:	e45e                	sd	s7,8(sp)
    8000172e:	e062                	sd	s8,0(sp)
    80001730:	0880                	addi	s0,sp,80
    80001732:	8b2a                	mv	s6,a0
    80001734:	8a2e                	mv	s4,a1
    80001736:	8c32                	mv	s8,a2
    80001738:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000173a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000173c:	6a85                	lui	s5,0x1
    8000173e:	a01d                	j	80001764 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001740:	018505b3          	add	a1,a0,s8
    80001744:	0004861b          	sext.w	a2,s1
    80001748:	412585b3          	sub	a1,a1,s2
    8000174c:	8552                	mv	a0,s4
    8000174e:	fffff097          	auipc	ra,0xfffff
    80001752:	5e0080e7          	jalr	1504(ra) # 80000d2e <memmove>

    len -= n;
    80001756:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000175a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000175c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001760:	02098263          	beqz	s3,80001784 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001764:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001768:	85ca                	mv	a1,s2
    8000176a:	855a                	mv	a0,s6
    8000176c:	00000097          	auipc	ra,0x0
    80001770:	910080e7          	jalr	-1776(ra) # 8000107c <walkaddr>
    if(pa0 == 0)
    80001774:	cd01                	beqz	a0,8000178c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001776:	418904b3          	sub	s1,s2,s8
    8000177a:	94d6                	add	s1,s1,s5
    8000177c:	fc99f2e3          	bgeu	s3,s1,80001740 <copyin+0x28>
    80001780:	84ce                	mv	s1,s3
    80001782:	bf7d                	j	80001740 <copyin+0x28>
  }
  return 0;
    80001784:	4501                	li	a0,0
    80001786:	a021                	j	8000178e <copyin+0x76>
    80001788:	4501                	li	a0,0
}
    8000178a:	8082                	ret
      return -1;
    8000178c:	557d                	li	a0,-1
}
    8000178e:	60a6                	ld	ra,72(sp)
    80001790:	6406                	ld	s0,64(sp)
    80001792:	74e2                	ld	s1,56(sp)
    80001794:	7942                	ld	s2,48(sp)
    80001796:	79a2                	ld	s3,40(sp)
    80001798:	7a02                	ld	s4,32(sp)
    8000179a:	6ae2                	ld	s5,24(sp)
    8000179c:	6b42                	ld	s6,16(sp)
    8000179e:	6ba2                	ld	s7,8(sp)
    800017a0:	6c02                	ld	s8,0(sp)
    800017a2:	6161                	addi	sp,sp,80
    800017a4:	8082                	ret

00000000800017a6 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017a6:	c2dd                	beqz	a3,8000184c <copyinstr+0xa6>
{
    800017a8:	715d                	addi	sp,sp,-80
    800017aa:	e486                	sd	ra,72(sp)
    800017ac:	e0a2                	sd	s0,64(sp)
    800017ae:	fc26                	sd	s1,56(sp)
    800017b0:	f84a                	sd	s2,48(sp)
    800017b2:	f44e                	sd	s3,40(sp)
    800017b4:	f052                	sd	s4,32(sp)
    800017b6:	ec56                	sd	s5,24(sp)
    800017b8:	e85a                	sd	s6,16(sp)
    800017ba:	e45e                	sd	s7,8(sp)
    800017bc:	0880                	addi	s0,sp,80
    800017be:	8a2a                	mv	s4,a0
    800017c0:	8b2e                	mv	s6,a1
    800017c2:	8bb2                	mv	s7,a2
    800017c4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017c6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017c8:	6985                	lui	s3,0x1
    800017ca:	a02d                	j	800017f4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017cc:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017d0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017d2:	37fd                	addiw	a5,a5,-1
    800017d4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d8:	60a6                	ld	ra,72(sp)
    800017da:	6406                	ld	s0,64(sp)
    800017dc:	74e2                	ld	s1,56(sp)
    800017de:	7942                	ld	s2,48(sp)
    800017e0:	79a2                	ld	s3,40(sp)
    800017e2:	7a02                	ld	s4,32(sp)
    800017e4:	6ae2                	ld	s5,24(sp)
    800017e6:	6b42                	ld	s6,16(sp)
    800017e8:	6ba2                	ld	s7,8(sp)
    800017ea:	6161                	addi	sp,sp,80
    800017ec:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ee:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017f2:	c8a9                	beqz	s1,80001844 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017f4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f8:	85ca                	mv	a1,s2
    800017fa:	8552                	mv	a0,s4
    800017fc:	00000097          	auipc	ra,0x0
    80001800:	880080e7          	jalr	-1920(ra) # 8000107c <walkaddr>
    if(pa0 == 0)
    80001804:	c131                	beqz	a0,80001848 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001806:	417906b3          	sub	a3,s2,s7
    8000180a:	96ce                	add	a3,a3,s3
    8000180c:	00d4f363          	bgeu	s1,a3,80001812 <copyinstr+0x6c>
    80001810:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001812:	955e                	add	a0,a0,s7
    80001814:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001818:	daf9                	beqz	a3,800017ee <copyinstr+0x48>
    8000181a:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000181c:	41650633          	sub	a2,a0,s6
    80001820:	fff48593          	addi	a1,s1,-1
    80001824:	95da                	add	a1,a1,s6
    while(n > 0){
    80001826:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001828:	00f60733          	add	a4,a2,a5
    8000182c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd280>
    80001830:	df51                	beqz	a4,800017cc <copyinstr+0x26>
        *dst = *p;
    80001832:	00e78023          	sb	a4,0(a5)
      --max;
    80001836:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000183a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000183c:	fed796e3          	bne	a5,a3,80001828 <copyinstr+0x82>
      dst++;
    80001840:	8b3e                	mv	s6,a5
    80001842:	b775                	j	800017ee <copyinstr+0x48>
    80001844:	4781                	li	a5,0
    80001846:	b771                	j	800017d2 <copyinstr+0x2c>
      return -1;
    80001848:	557d                	li	a0,-1
    8000184a:	b779                	j	800017d8 <copyinstr+0x32>
  int got_null = 0;
    8000184c:	4781                	li	a5,0
  if(got_null){
    8000184e:	37fd                	addiw	a5,a5,-1
    80001850:	0007851b          	sext.w	a0,a5
}
    80001854:	8082                	ret

0000000080001856 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001856:	7139                	addi	sp,sp,-64
    80001858:	fc06                	sd	ra,56(sp)
    8000185a:	f822                	sd	s0,48(sp)
    8000185c:	f426                	sd	s1,40(sp)
    8000185e:	f04a                	sd	s2,32(sp)
    80001860:	ec4e                	sd	s3,24(sp)
    80001862:	e852                	sd	s4,16(sp)
    80001864:	e456                	sd	s5,8(sp)
    80001866:	e05a                	sd	s6,0(sp)
    80001868:	0080                	addi	s0,sp,64
    8000186a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186c:	0000f497          	auipc	s1,0xf
    80001870:	73448493          	addi	s1,s1,1844 # 80010fa0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001874:	8b26                	mv	s6,s1
    80001876:	00006a97          	auipc	s5,0x6
    8000187a:	78aa8a93          	addi	s5,s5,1930 # 80008000 <etext>
    8000187e:	04000937          	lui	s2,0x4000
    80001882:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001884:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001886:	00015a17          	auipc	s4,0x15
    8000188a:	11aa0a13          	addi	s4,s4,282 # 800169a0 <tickslock>
    char *pa = kalloc();
    8000188e:	fffff097          	auipc	ra,0xfffff
    80001892:	258080e7          	jalr	600(ra) # 80000ae6 <kalloc>
    80001896:	862a                	mv	a2,a0
    if(pa == 0)
    80001898:	c131                	beqz	a0,800018dc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000189a:	416485b3          	sub	a1,s1,s6
    8000189e:	858d                	srai	a1,a1,0x3
    800018a0:	000ab783          	ld	a5,0(s5)
    800018a4:	02f585b3          	mul	a1,a1,a5
    800018a8:	2585                	addiw	a1,a1,1
    800018aa:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018ae:	4719                	li	a4,6
    800018b0:	6685                	lui	a3,0x1
    800018b2:	40b905b3          	sub	a1,s2,a1
    800018b6:	854e                	mv	a0,s3
    800018b8:	00000097          	auipc	ra,0x0
    800018bc:	8a6080e7          	jalr	-1882(ra) # 8000115e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c0:	16848493          	addi	s1,s1,360
    800018c4:	fd4495e3          	bne	s1,s4,8000188e <proc_mapstacks+0x38>
  }
}
    800018c8:	70e2                	ld	ra,56(sp)
    800018ca:	7442                	ld	s0,48(sp)
    800018cc:	74a2                	ld	s1,40(sp)
    800018ce:	7902                	ld	s2,32(sp)
    800018d0:	69e2                	ld	s3,24(sp)
    800018d2:	6a42                	ld	s4,16(sp)
    800018d4:	6aa2                	ld	s5,8(sp)
    800018d6:	6b02                	ld	s6,0(sp)
    800018d8:	6121                	addi	sp,sp,64
    800018da:	8082                	ret
      panic("kalloc");
    800018dc:	00007517          	auipc	a0,0x7
    800018e0:	91450513          	addi	a0,a0,-1772 # 800081f0 <digits+0x1b0>
    800018e4:	fffff097          	auipc	ra,0xfffff
    800018e8:	c5c080e7          	jalr	-932(ra) # 80000540 <panic>

00000000800018ec <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018ec:	7139                	addi	sp,sp,-64
    800018ee:	fc06                	sd	ra,56(sp)
    800018f0:	f822                	sd	s0,48(sp)
    800018f2:	f426                	sd	s1,40(sp)
    800018f4:	f04a                	sd	s2,32(sp)
    800018f6:	ec4e                	sd	s3,24(sp)
    800018f8:	e852                	sd	s4,16(sp)
    800018fa:	e456                	sd	s5,8(sp)
    800018fc:	e05a                	sd	s6,0(sp)
    800018fe:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8f858593          	addi	a1,a1,-1800 # 800081f8 <digits+0x1b8>
    80001908:	0000f517          	auipc	a0,0xf
    8000190c:	26850513          	addi	a0,a0,616 # 80010b70 <pid_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	236080e7          	jalr	566(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001918:	00007597          	auipc	a1,0x7
    8000191c:	8e858593          	addi	a1,a1,-1816 # 80008200 <digits+0x1c0>
    80001920:	0000f517          	auipc	a0,0xf
    80001924:	26850513          	addi	a0,a0,616 # 80010b88 <wait_lock>
    80001928:	fffff097          	auipc	ra,0xfffff
    8000192c:	21e080e7          	jalr	542(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001930:	0000f497          	auipc	s1,0xf
    80001934:	67048493          	addi	s1,s1,1648 # 80010fa0 <proc>
      initlock(&p->lock, "proc");
    80001938:	00007b17          	auipc	s6,0x7
    8000193c:	8d8b0b13          	addi	s6,s6,-1832 # 80008210 <digits+0x1d0>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001940:	8aa6                	mv	s5,s1
    80001942:	00006a17          	auipc	s4,0x6
    80001946:	6bea0a13          	addi	s4,s4,1726 # 80008000 <etext>
    8000194a:	04000937          	lui	s2,0x4000
    8000194e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001950:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001952:	00015997          	auipc	s3,0x15
    80001956:	04e98993          	addi	s3,s3,78 # 800169a0 <tickslock>
      initlock(&p->lock, "proc");
    8000195a:	85da                	mv	a1,s6
    8000195c:	8526                	mv	a0,s1
    8000195e:	fffff097          	auipc	ra,0xfffff
    80001962:	1e8080e7          	jalr	488(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001966:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000196a:	415487b3          	sub	a5,s1,s5
    8000196e:	878d                	srai	a5,a5,0x3
    80001970:	000a3703          	ld	a4,0(s4)
    80001974:	02e787b3          	mul	a5,a5,a4
    80001978:	2785                	addiw	a5,a5,1
    8000197a:	00d7979b          	slliw	a5,a5,0xd
    8000197e:	40f907b3          	sub	a5,s2,a5
    80001982:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001984:	16848493          	addi	s1,s1,360
    80001988:	fd3499e3          	bne	s1,s3,8000195a <procinit+0x6e>
  }
}
    8000198c:	70e2                	ld	ra,56(sp)
    8000198e:	7442                	ld	s0,48(sp)
    80001990:	74a2                	ld	s1,40(sp)
    80001992:	7902                	ld	s2,32(sp)
    80001994:	69e2                	ld	s3,24(sp)
    80001996:	6a42                	ld	s4,16(sp)
    80001998:	6aa2                	ld	s5,8(sp)
    8000199a:	6b02                	ld	s6,0(sp)
    8000199c:	6121                	addi	sp,sp,64
    8000199e:	8082                	ret

00000000800019a0 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019a0:	1141                	addi	sp,sp,-16
    800019a2:	e422                	sd	s0,8(sp)
    800019a4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a6:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a8:	2501                	sext.w	a0,a0
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019b0:	1141                	addi	sp,sp,-16
    800019b2:	e422                	sd	s0,8(sp)
    800019b4:	0800                	addi	s0,sp,16
    800019b6:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b8:	2781                	sext.w	a5,a5
    800019ba:	079e                	slli	a5,a5,0x7
  return c;
}
    800019bc:	0000f517          	auipc	a0,0xf
    800019c0:	1e450513          	addi	a0,a0,484 # 80010ba0 <cpus>
    800019c4:	953e                	add	a0,a0,a5
    800019c6:	6422                	ld	s0,8(sp)
    800019c8:	0141                	addi	sp,sp,16
    800019ca:	8082                	ret

00000000800019cc <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019cc:	1101                	addi	sp,sp,-32
    800019ce:	ec06                	sd	ra,24(sp)
    800019d0:	e822                	sd	s0,16(sp)
    800019d2:	e426                	sd	s1,8(sp)
    800019d4:	1000                	addi	s0,sp,32
  push_off();
    800019d6:	fffff097          	auipc	ra,0xfffff
    800019da:	1b4080e7          	jalr	436(ra) # 80000b8a <push_off>
    800019de:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019e0:	2781                	sext.w	a5,a5
    800019e2:	079e                	slli	a5,a5,0x7
    800019e4:	0000f717          	auipc	a4,0xf
    800019e8:	18c70713          	addi	a4,a4,396 # 80010b70 <pid_lock>
    800019ec:	97ba                	add	a5,a5,a4
    800019ee:	7b84                	ld	s1,48(a5)
  pop_off();
    800019f0:	fffff097          	auipc	ra,0xfffff
    800019f4:	23a080e7          	jalr	570(ra) # 80000c2a <pop_off>
  return p;
}
    800019f8:	8526                	mv	a0,s1
    800019fa:	60e2                	ld	ra,24(sp)
    800019fc:	6442                	ld	s0,16(sp)
    800019fe:	64a2                	ld	s1,8(sp)
    80001a00:	6105                	addi	sp,sp,32
    80001a02:	8082                	ret

0000000080001a04 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a04:	1141                	addi	sp,sp,-16
    80001a06:	e406                	sd	ra,8(sp)
    80001a08:	e022                	sd	s0,0(sp)
    80001a0a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a0c:	00000097          	auipc	ra,0x0
    80001a10:	fc0080e7          	jalr	-64(ra) # 800019cc <myproc>
    80001a14:	fffff097          	auipc	ra,0xfffff
    80001a18:	276080e7          	jalr	630(ra) # 80000c8a <release>

  if (first) {
    80001a1c:	00007797          	auipc	a5,0x7
    80001a20:	e447a783          	lw	a5,-444(a5) # 80008860 <first.1>
    80001a24:	eb89                	bnez	a5,80001a36 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a26:	00001097          	auipc	ra,0x1
    80001a2a:	c5c080e7          	jalr	-932(ra) # 80002682 <usertrapret>
}
    80001a2e:	60a2                	ld	ra,8(sp)
    80001a30:	6402                	ld	s0,0(sp)
    80001a32:	0141                	addi	sp,sp,16
    80001a34:	8082                	ret
    first = 0;
    80001a36:	00007797          	auipc	a5,0x7
    80001a3a:	e207a523          	sw	zero,-470(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a3e:	4505                	li	a0,1
    80001a40:	00002097          	auipc	ra,0x2
    80001a44:	98e080e7          	jalr	-1650(ra) # 800033ce <fsinit>
    80001a48:	bff9                	j	80001a26 <forkret+0x22>

0000000080001a4a <allocpid>:
{
    80001a4a:	1101                	addi	sp,sp,-32
    80001a4c:	ec06                	sd	ra,24(sp)
    80001a4e:	e822                	sd	s0,16(sp)
    80001a50:	e426                	sd	s1,8(sp)
    80001a52:	e04a                	sd	s2,0(sp)
    80001a54:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a56:	0000f917          	auipc	s2,0xf
    80001a5a:	11a90913          	addi	s2,s2,282 # 80010b70 <pid_lock>
    80001a5e:	854a                	mv	a0,s2
    80001a60:	fffff097          	auipc	ra,0xfffff
    80001a64:	176080e7          	jalr	374(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a68:	00007797          	auipc	a5,0x7
    80001a6c:	dfc78793          	addi	a5,a5,-516 # 80008864 <nextpid>
    80001a70:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a72:	0014871b          	addiw	a4,s1,1
    80001a76:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a78:	854a                	mv	a0,s2
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	210080e7          	jalr	528(ra) # 80000c8a <release>
}
    80001a82:	8526                	mv	a0,s1
    80001a84:	60e2                	ld	ra,24(sp)
    80001a86:	6442                	ld	s0,16(sp)
    80001a88:	64a2                	ld	s1,8(sp)
    80001a8a:	6902                	ld	s2,0(sp)
    80001a8c:	6105                	addi	sp,sp,32
    80001a8e:	8082                	ret

0000000080001a90 <proc_pagetable>:
{
    80001a90:	1101                	addi	sp,sp,-32
    80001a92:	ec06                	sd	ra,24(sp)
    80001a94:	e822                	sd	s0,16(sp)
    80001a96:	e426                	sd	s1,8(sp)
    80001a98:	e04a                	sd	s2,0(sp)
    80001a9a:	1000                	addi	s0,sp,32
    80001a9c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a9e:	00000097          	auipc	ra,0x0
    80001aa2:	8aa080e7          	jalr	-1878(ra) # 80001348 <uvmcreate>
    80001aa6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aa8:	c121                	beqz	a0,80001ae8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aaa:	4729                	li	a4,10
    80001aac:	00005697          	auipc	a3,0x5
    80001ab0:	55468693          	addi	a3,a3,1364 # 80007000 <_trampoline>
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	040005b7          	lui	a1,0x4000
    80001aba:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001abc:	05b2                	slli	a1,a1,0xc
    80001abe:	fffff097          	auipc	ra,0xfffff
    80001ac2:	600080e7          	jalr	1536(ra) # 800010be <mappages>
    80001ac6:	02054863          	bltz	a0,80001af6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aca:	4719                	li	a4,6
    80001acc:	05893683          	ld	a3,88(s2)
    80001ad0:	6605                	lui	a2,0x1
    80001ad2:	020005b7          	lui	a1,0x2000
    80001ad6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ad8:	05b6                	slli	a1,a1,0xd
    80001ada:	8526                	mv	a0,s1
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	5e2080e7          	jalr	1506(ra) # 800010be <mappages>
    80001ae4:	02054163          	bltz	a0,80001b06 <proc_pagetable+0x76>
}
    80001ae8:	8526                	mv	a0,s1
    80001aea:	60e2                	ld	ra,24(sp)
    80001aec:	6442                	ld	s0,16(sp)
    80001aee:	64a2                	ld	s1,8(sp)
    80001af0:	6902                	ld	s2,0(sp)
    80001af2:	6105                	addi	sp,sp,32
    80001af4:	8082                	ret
    uvmfree(pagetable, 0);
    80001af6:	4581                	li	a1,0
    80001af8:	8526                	mv	a0,s1
    80001afa:	00000097          	auipc	ra,0x0
    80001afe:	a54080e7          	jalr	-1452(ra) # 8000154e <uvmfree>
    return 0;
    80001b02:	4481                	li	s1,0
    80001b04:	b7d5                	j	80001ae8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b06:	4681                	li	a3,0
    80001b08:	4605                	li	a2,1
    80001b0a:	040005b7          	lui	a1,0x4000
    80001b0e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b10:	05b2                	slli	a1,a1,0xc
    80001b12:	8526                	mv	a0,s1
    80001b14:	fffff097          	auipc	ra,0xfffff
    80001b18:	770080e7          	jalr	1904(ra) # 80001284 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b1c:	4581                	li	a1,0
    80001b1e:	8526                	mv	a0,s1
    80001b20:	00000097          	auipc	ra,0x0
    80001b24:	a2e080e7          	jalr	-1490(ra) # 8000154e <uvmfree>
    return 0;
    80001b28:	4481                	li	s1,0
    80001b2a:	bf7d                	j	80001ae8 <proc_pagetable+0x58>

0000000080001b2c <proc_freepagetable>:
{
    80001b2c:	1101                	addi	sp,sp,-32
    80001b2e:	ec06                	sd	ra,24(sp)
    80001b30:	e822                	sd	s0,16(sp)
    80001b32:	e426                	sd	s1,8(sp)
    80001b34:	e04a                	sd	s2,0(sp)
    80001b36:	1000                	addi	s0,sp,32
    80001b38:	84aa                	mv	s1,a0
    80001b3a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b3c:	4681                	li	a3,0
    80001b3e:	4605                	li	a2,1
    80001b40:	040005b7          	lui	a1,0x4000
    80001b44:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b46:	05b2                	slli	a1,a1,0xc
    80001b48:	fffff097          	auipc	ra,0xfffff
    80001b4c:	73c080e7          	jalr	1852(ra) # 80001284 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b50:	4681                	li	a3,0
    80001b52:	4605                	li	a2,1
    80001b54:	020005b7          	lui	a1,0x2000
    80001b58:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b5a:	05b6                	slli	a1,a1,0xd
    80001b5c:	8526                	mv	a0,s1
    80001b5e:	fffff097          	auipc	ra,0xfffff
    80001b62:	726080e7          	jalr	1830(ra) # 80001284 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b66:	85ca                	mv	a1,s2
    80001b68:	8526                	mv	a0,s1
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	9e4080e7          	jalr	-1564(ra) # 8000154e <uvmfree>
}
    80001b72:	60e2                	ld	ra,24(sp)
    80001b74:	6442                	ld	s0,16(sp)
    80001b76:	64a2                	ld	s1,8(sp)
    80001b78:	6902                	ld	s2,0(sp)
    80001b7a:	6105                	addi	sp,sp,32
    80001b7c:	8082                	ret

0000000080001b7e <freeproc>:
{
    80001b7e:	1101                	addi	sp,sp,-32
    80001b80:	ec06                	sd	ra,24(sp)
    80001b82:	e822                	sd	s0,16(sp)
    80001b84:	e426                	sd	s1,8(sp)
    80001b86:	1000                	addi	s0,sp,32
    80001b88:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b8a:	6d28                	ld	a0,88(a0)
    80001b8c:	c509                	beqz	a0,80001b96 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b8e:	fffff097          	auipc	ra,0xfffff
    80001b92:	e5a080e7          	jalr	-422(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b96:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b9a:	68a8                	ld	a0,80(s1)
    80001b9c:	c511                	beqz	a0,80001ba8 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b9e:	64ac                	ld	a1,72(s1)
    80001ba0:	00000097          	auipc	ra,0x0
    80001ba4:	f8c080e7          	jalr	-116(ra) # 80001b2c <proc_freepagetable>
  p->pagetable = 0;
    80001ba8:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bac:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bb0:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bb4:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bb8:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bbc:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bc0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bc4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc8:	0004ac23          	sw	zero,24(s1)
}
    80001bcc:	60e2                	ld	ra,24(sp)
    80001bce:	6442                	ld	s0,16(sp)
    80001bd0:	64a2                	ld	s1,8(sp)
    80001bd2:	6105                	addi	sp,sp,32
    80001bd4:	8082                	ret

0000000080001bd6 <allocproc>:
{
    80001bd6:	1101                	addi	sp,sp,-32
    80001bd8:	ec06                	sd	ra,24(sp)
    80001bda:	e822                	sd	s0,16(sp)
    80001bdc:	e426                	sd	s1,8(sp)
    80001bde:	e04a                	sd	s2,0(sp)
    80001be0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be2:	0000f497          	auipc	s1,0xf
    80001be6:	3be48493          	addi	s1,s1,958 # 80010fa0 <proc>
    80001bea:	00015917          	auipc	s2,0x15
    80001bee:	db690913          	addi	s2,s2,-586 # 800169a0 <tickslock>
    acquire(&p->lock);
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	fe2080e7          	jalr	-30(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bfc:	4c9c                	lw	a5,24(s1)
    80001bfe:	cf81                	beqz	a5,80001c16 <allocproc+0x40>
      release(&p->lock);
    80001c00:	8526                	mv	a0,s1
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	088080e7          	jalr	136(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0a:	16848493          	addi	s1,s1,360
    80001c0e:	ff2492e3          	bne	s1,s2,80001bf2 <allocproc+0x1c>
  return 0;
    80001c12:	4481                	li	s1,0
    80001c14:	a889                	j	80001c66 <allocproc+0x90>
  p->pid = allocpid();
    80001c16:	00000097          	auipc	ra,0x0
    80001c1a:	e34080e7          	jalr	-460(ra) # 80001a4a <allocpid>
    80001c1e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c20:	4785                	li	a5,1
    80001c22:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	ec2080e7          	jalr	-318(ra) # 80000ae6 <kalloc>
    80001c2c:	892a                	mv	s2,a0
    80001c2e:	eca8                	sd	a0,88(s1)
    80001c30:	c131                	beqz	a0,80001c74 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c32:	8526                	mv	a0,s1
    80001c34:	00000097          	auipc	ra,0x0
    80001c38:	e5c080e7          	jalr	-420(ra) # 80001a90 <proc_pagetable>
    80001c3c:	892a                	mv	s2,a0
    80001c3e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c40:	c531                	beqz	a0,80001c8c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c42:	07000613          	li	a2,112
    80001c46:	4581                	li	a1,0
    80001c48:	06048513          	addi	a0,s1,96
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	086080e7          	jalr	134(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c54:	00000797          	auipc	a5,0x0
    80001c58:	db078793          	addi	a5,a5,-592 # 80001a04 <forkret>
    80001c5c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c5e:	60bc                	ld	a5,64(s1)
    80001c60:	6705                	lui	a4,0x1
    80001c62:	97ba                	add	a5,a5,a4
    80001c64:	f4bc                	sd	a5,104(s1)
}
    80001c66:	8526                	mv	a0,s1
    80001c68:	60e2                	ld	ra,24(sp)
    80001c6a:	6442                	ld	s0,16(sp)
    80001c6c:	64a2                	ld	s1,8(sp)
    80001c6e:	6902                	ld	s2,0(sp)
    80001c70:	6105                	addi	sp,sp,32
    80001c72:	8082                	ret
    freeproc(p);
    80001c74:	8526                	mv	a0,s1
    80001c76:	00000097          	auipc	ra,0x0
    80001c7a:	f08080e7          	jalr	-248(ra) # 80001b7e <freeproc>
    release(&p->lock);
    80001c7e:	8526                	mv	a0,s1
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	00a080e7          	jalr	10(ra) # 80000c8a <release>
    return 0;
    80001c88:	84ca                	mv	s1,s2
    80001c8a:	bff1                	j	80001c66 <allocproc+0x90>
    freeproc(p);
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	ef0080e7          	jalr	-272(ra) # 80001b7e <freeproc>
    release(&p->lock);
    80001c96:	8526                	mv	a0,s1
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	ff2080e7          	jalr	-14(ra) # 80000c8a <release>
    return 0;
    80001ca0:	84ca                	mv	s1,s2
    80001ca2:	b7d1                	j	80001c66 <allocproc+0x90>

0000000080001ca4 <userinit>:
{
    80001ca4:	1101                	addi	sp,sp,-32
    80001ca6:	ec06                	sd	ra,24(sp)
    80001ca8:	e822                	sd	s0,16(sp)
    80001caa:	e426                	sd	s1,8(sp)
    80001cac:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cae:	00000097          	auipc	ra,0x0
    80001cb2:	f28080e7          	jalr	-216(ra) # 80001bd6 <allocproc>
    80001cb6:	84aa                	mv	s1,a0
  initproc = p;
    80001cb8:	00007797          	auipc	a5,0x7
    80001cbc:	c4a7b023          	sd	a0,-960(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cc0:	03400613          	li	a2,52
    80001cc4:	00007597          	auipc	a1,0x7
    80001cc8:	bac58593          	addi	a1,a1,-1108 # 80008870 <initcode>
    80001ccc:	6928                	ld	a0,80(a0)
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	6a8080e7          	jalr	1704(ra) # 80001376 <uvmfirst>
  p->sz = PGSIZE;
    80001cd6:	6785                	lui	a5,0x1
    80001cd8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cda:	6cb8                	ld	a4,88(s1)
    80001cdc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ce0:	6cb8                	ld	a4,88(s1)
    80001ce2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ce4:	4641                	li	a2,16
    80001ce6:	00006597          	auipc	a1,0x6
    80001cea:	53258593          	addi	a1,a1,1330 # 80008218 <digits+0x1d8>
    80001cee:	15848513          	addi	a0,s1,344
    80001cf2:	fffff097          	auipc	ra,0xfffff
    80001cf6:	12a080e7          	jalr	298(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cfa:	00006517          	auipc	a0,0x6
    80001cfe:	52e50513          	addi	a0,a0,1326 # 80008228 <digits+0x1e8>
    80001d02:	00002097          	auipc	ra,0x2
    80001d06:	0f6080e7          	jalr	246(ra) # 80003df8 <namei>
    80001d0a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d0e:	478d                	li	a5,3
    80001d10:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d12:	8526                	mv	a0,s1
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	f76080e7          	jalr	-138(ra) # 80000c8a <release>
}
    80001d1c:	60e2                	ld	ra,24(sp)
    80001d1e:	6442                	ld	s0,16(sp)
    80001d20:	64a2                	ld	s1,8(sp)
    80001d22:	6105                	addi	sp,sp,32
    80001d24:	8082                	ret

0000000080001d26 <growproc>:
{
    80001d26:	1101                	addi	sp,sp,-32
    80001d28:	ec06                	sd	ra,24(sp)
    80001d2a:	e822                	sd	s0,16(sp)
    80001d2c:	e426                	sd	s1,8(sp)
    80001d2e:	e04a                	sd	s2,0(sp)
    80001d30:	1000                	addi	s0,sp,32
    80001d32:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d34:	00000097          	auipc	ra,0x0
    80001d38:	c98080e7          	jalr	-872(ra) # 800019cc <myproc>
    80001d3c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d3e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d40:	01204c63          	bgtz	s2,80001d58 <growproc+0x32>
  } else if(n < 0){
    80001d44:	02094663          	bltz	s2,80001d70 <growproc+0x4a>
  p->sz = sz;
    80001d48:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d4a:	4501                	li	a0,0
}
    80001d4c:	60e2                	ld	ra,24(sp)
    80001d4e:	6442                	ld	s0,16(sp)
    80001d50:	64a2                	ld	s1,8(sp)
    80001d52:	6902                	ld	s2,0(sp)
    80001d54:	6105                	addi	sp,sp,32
    80001d56:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d58:	4691                	li	a3,4
    80001d5a:	00b90633          	add	a2,s2,a1
    80001d5e:	6928                	ld	a0,80(a0)
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	6d0080e7          	jalr	1744(ra) # 80001430 <uvmalloc>
    80001d68:	85aa                	mv	a1,a0
    80001d6a:	fd79                	bnez	a0,80001d48 <growproc+0x22>
      return -1;
    80001d6c:	557d                	li	a0,-1
    80001d6e:	bff9                	j	80001d4c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d70:	00b90633          	add	a2,s2,a1
    80001d74:	6928                	ld	a0,80(a0)
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	672080e7          	jalr	1650(ra) # 800013e8 <uvmdealloc>
    80001d7e:	85aa                	mv	a1,a0
    80001d80:	b7e1                	j	80001d48 <growproc+0x22>

0000000080001d82 <fork>:
{
    80001d82:	7139                	addi	sp,sp,-64
    80001d84:	fc06                	sd	ra,56(sp)
    80001d86:	f822                	sd	s0,48(sp)
    80001d88:	f426                	sd	s1,40(sp)
    80001d8a:	f04a                	sd	s2,32(sp)
    80001d8c:	ec4e                	sd	s3,24(sp)
    80001d8e:	e852                	sd	s4,16(sp)
    80001d90:	e456                	sd	s5,8(sp)
    80001d92:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d94:	00000097          	auipc	ra,0x0
    80001d98:	c38080e7          	jalr	-968(ra) # 800019cc <myproc>
    80001d9c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d9e:	00000097          	auipc	ra,0x0
    80001da2:	e38080e7          	jalr	-456(ra) # 80001bd6 <allocproc>
    80001da6:	10050c63          	beqz	a0,80001ebe <fork+0x13c>
    80001daa:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dac:	048ab603          	ld	a2,72(s5)
    80001db0:	692c                	ld	a1,80(a0)
    80001db2:	050ab503          	ld	a0,80(s5)
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	7d2080e7          	jalr	2002(ra) # 80001588 <uvmcopy>
    80001dbe:	04054863          	bltz	a0,80001e0e <fork+0x8c>
  np->sz = p->sz;
    80001dc2:	048ab783          	ld	a5,72(s5)
    80001dc6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dca:	058ab683          	ld	a3,88(s5)
    80001dce:	87b6                	mv	a5,a3
    80001dd0:	058a3703          	ld	a4,88(s4)
    80001dd4:	12068693          	addi	a3,a3,288
    80001dd8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ddc:	6788                	ld	a0,8(a5)
    80001dde:	6b8c                	ld	a1,16(a5)
    80001de0:	6f90                	ld	a2,24(a5)
    80001de2:	01073023          	sd	a6,0(a4)
    80001de6:	e708                	sd	a0,8(a4)
    80001de8:	eb0c                	sd	a1,16(a4)
    80001dea:	ef10                	sd	a2,24(a4)
    80001dec:	02078793          	addi	a5,a5,32
    80001df0:	02070713          	addi	a4,a4,32
    80001df4:	fed792e3          	bne	a5,a3,80001dd8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001df8:	058a3783          	ld	a5,88(s4)
    80001dfc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e00:	0d0a8493          	addi	s1,s5,208
    80001e04:	0d0a0913          	addi	s2,s4,208
    80001e08:	150a8993          	addi	s3,s5,336
    80001e0c:	a00d                	j	80001e2e <fork+0xac>
    freeproc(np);
    80001e0e:	8552                	mv	a0,s4
    80001e10:	00000097          	auipc	ra,0x0
    80001e14:	d6e080e7          	jalr	-658(ra) # 80001b7e <freeproc>
    release(&np->lock);
    80001e18:	8552                	mv	a0,s4
    80001e1a:	fffff097          	auipc	ra,0xfffff
    80001e1e:	e70080e7          	jalr	-400(ra) # 80000c8a <release>
    return -1;
    80001e22:	597d                	li	s2,-1
    80001e24:	a059                	j	80001eaa <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e26:	04a1                	addi	s1,s1,8
    80001e28:	0921                	addi	s2,s2,8
    80001e2a:	01348b63          	beq	s1,s3,80001e40 <fork+0xbe>
    if(p->ofile[i])
    80001e2e:	6088                	ld	a0,0(s1)
    80001e30:	d97d                	beqz	a0,80001e26 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e32:	00002097          	auipc	ra,0x2
    80001e36:	65c080e7          	jalr	1628(ra) # 8000448e <filedup>
    80001e3a:	00a93023          	sd	a0,0(s2)
    80001e3e:	b7e5                	j	80001e26 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e40:	150ab503          	ld	a0,336(s5)
    80001e44:	00001097          	auipc	ra,0x1
    80001e48:	7ca080e7          	jalr	1994(ra) # 8000360e <idup>
    80001e4c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e50:	4641                	li	a2,16
    80001e52:	158a8593          	addi	a1,s5,344
    80001e56:	158a0513          	addi	a0,s4,344
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	fc2080e7          	jalr	-62(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e62:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e66:	8552                	mv	a0,s4
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e22080e7          	jalr	-478(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e70:	0000f497          	auipc	s1,0xf
    80001e74:	d1848493          	addi	s1,s1,-744 # 80010b88 <wait_lock>
    80001e78:	8526                	mv	a0,s1
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	d5c080e7          	jalr	-676(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e82:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	e02080e7          	jalr	-510(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e90:	8552                	mv	a0,s4
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	d44080e7          	jalr	-700(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e9a:	478d                	li	a5,3
    80001e9c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ea0:	8552                	mv	a0,s4
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	de8080e7          	jalr	-536(ra) # 80000c8a <release>
}
    80001eaa:	854a                	mv	a0,s2
    80001eac:	70e2                	ld	ra,56(sp)
    80001eae:	7442                	ld	s0,48(sp)
    80001eb0:	74a2                	ld	s1,40(sp)
    80001eb2:	7902                	ld	s2,32(sp)
    80001eb4:	69e2                	ld	s3,24(sp)
    80001eb6:	6a42                	ld	s4,16(sp)
    80001eb8:	6aa2                	ld	s5,8(sp)
    80001eba:	6121                	addi	sp,sp,64
    80001ebc:	8082                	ret
    return -1;
    80001ebe:	597d                	li	s2,-1
    80001ec0:	b7ed                	j	80001eaa <fork+0x128>

0000000080001ec2 <scheduler>:
{
    80001ec2:	7139                	addi	sp,sp,-64
    80001ec4:	fc06                	sd	ra,56(sp)
    80001ec6:	f822                	sd	s0,48(sp)
    80001ec8:	f426                	sd	s1,40(sp)
    80001eca:	f04a                	sd	s2,32(sp)
    80001ecc:	ec4e                	sd	s3,24(sp)
    80001ece:	e852                	sd	s4,16(sp)
    80001ed0:	e456                	sd	s5,8(sp)
    80001ed2:	e05a                	sd	s6,0(sp)
    80001ed4:	0080                	addi	s0,sp,64
    80001ed6:	8792                	mv	a5,tp
  int id = r_tp();
    80001ed8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eda:	00779a93          	slli	s5,a5,0x7
    80001ede:	0000f717          	auipc	a4,0xf
    80001ee2:	c9270713          	addi	a4,a4,-878 # 80010b70 <pid_lock>
    80001ee6:	9756                	add	a4,a4,s5
    80001ee8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001eec:	0000f717          	auipc	a4,0xf
    80001ef0:	cbc70713          	addi	a4,a4,-836 # 80010ba8 <cpus+0x8>
    80001ef4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ef6:	498d                	li	s3,3
        p->state = RUNNING;
    80001ef8:	4b11                	li	s6,4
        c->proc = p;
    80001efa:	079e                	slli	a5,a5,0x7
    80001efc:	0000fa17          	auipc	s4,0xf
    80001f00:	c74a0a13          	addi	s4,s4,-908 # 80010b70 <pid_lock>
    80001f04:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f06:	00015917          	auipc	s2,0x15
    80001f0a:	a9a90913          	addi	s2,s2,-1382 # 800169a0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f0e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f12:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f16:	10079073          	csrw	sstatus,a5
    80001f1a:	0000f497          	auipc	s1,0xf
    80001f1e:	08648493          	addi	s1,s1,134 # 80010fa0 <proc>
    80001f22:	a811                	j	80001f36 <scheduler+0x74>
      release(&p->lock);
    80001f24:	8526                	mv	a0,s1
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	d64080e7          	jalr	-668(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f2e:	16848493          	addi	s1,s1,360
    80001f32:	fd248ee3          	beq	s1,s2,80001f0e <scheduler+0x4c>
      acquire(&p->lock);
    80001f36:	8526                	mv	a0,s1
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	c9e080e7          	jalr	-866(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f40:	4c9c                	lw	a5,24(s1)
    80001f42:	ff3791e3          	bne	a5,s3,80001f24 <scheduler+0x62>
        p->state = RUNNING;
    80001f46:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f4a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f4e:	06048593          	addi	a1,s1,96
    80001f52:	8556                	mv	a0,s5
    80001f54:	00000097          	auipc	ra,0x0
    80001f58:	684080e7          	jalr	1668(ra) # 800025d8 <swtch>
        c->proc = 0;
    80001f5c:	020a3823          	sd	zero,48(s4)
    80001f60:	b7d1                	j	80001f24 <scheduler+0x62>

0000000080001f62 <sched>:
{
    80001f62:	7179                	addi	sp,sp,-48
    80001f64:	f406                	sd	ra,40(sp)
    80001f66:	f022                	sd	s0,32(sp)
    80001f68:	ec26                	sd	s1,24(sp)
    80001f6a:	e84a                	sd	s2,16(sp)
    80001f6c:	e44e                	sd	s3,8(sp)
    80001f6e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f70:	00000097          	auipc	ra,0x0
    80001f74:	a5c080e7          	jalr	-1444(ra) # 800019cc <myproc>
    80001f78:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	be2080e7          	jalr	-1054(ra) # 80000b5c <holding>
    80001f82:	c93d                	beqz	a0,80001ff8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f84:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f86:	2781                	sext.w	a5,a5
    80001f88:	079e                	slli	a5,a5,0x7
    80001f8a:	0000f717          	auipc	a4,0xf
    80001f8e:	be670713          	addi	a4,a4,-1050 # 80010b70 <pid_lock>
    80001f92:	97ba                	add	a5,a5,a4
    80001f94:	0a87a703          	lw	a4,168(a5)
    80001f98:	4785                	li	a5,1
    80001f9a:	06f71763          	bne	a4,a5,80002008 <sched+0xa6>
  if(p->state == RUNNING)
    80001f9e:	4c98                	lw	a4,24(s1)
    80001fa0:	4791                	li	a5,4
    80001fa2:	06f70b63          	beq	a4,a5,80002018 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fa6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001faa:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fac:	efb5                	bnez	a5,80002028 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fae:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fb0:	0000f917          	auipc	s2,0xf
    80001fb4:	bc090913          	addi	s2,s2,-1088 # 80010b70 <pid_lock>
    80001fb8:	2781                	sext.w	a5,a5
    80001fba:	079e                	slli	a5,a5,0x7
    80001fbc:	97ca                	add	a5,a5,s2
    80001fbe:	0ac7a983          	lw	s3,172(a5)
    80001fc2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fc4:	2781                	sext.w	a5,a5
    80001fc6:	079e                	slli	a5,a5,0x7
    80001fc8:	0000f597          	auipc	a1,0xf
    80001fcc:	be058593          	addi	a1,a1,-1056 # 80010ba8 <cpus+0x8>
    80001fd0:	95be                	add	a1,a1,a5
    80001fd2:	06048513          	addi	a0,s1,96
    80001fd6:	00000097          	auipc	ra,0x0
    80001fda:	602080e7          	jalr	1538(ra) # 800025d8 <swtch>
    80001fde:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fe0:	2781                	sext.w	a5,a5
    80001fe2:	079e                	slli	a5,a5,0x7
    80001fe4:	993e                	add	s2,s2,a5
    80001fe6:	0b392623          	sw	s3,172(s2)
}
    80001fea:	70a2                	ld	ra,40(sp)
    80001fec:	7402                	ld	s0,32(sp)
    80001fee:	64e2                	ld	s1,24(sp)
    80001ff0:	6942                	ld	s2,16(sp)
    80001ff2:	69a2                	ld	s3,8(sp)
    80001ff4:	6145                	addi	sp,sp,48
    80001ff6:	8082                	ret
    panic("sched p->lock");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	23850513          	addi	a0,a0,568 # 80008230 <digits+0x1f0>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	540080e7          	jalr	1344(ra) # 80000540 <panic>
    panic("sched locks");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	23850513          	addi	a0,a0,568 # 80008240 <digits+0x200>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	530080e7          	jalr	1328(ra) # 80000540 <panic>
    panic("sched running");
    80002018:	00006517          	auipc	a0,0x6
    8000201c:	23850513          	addi	a0,a0,568 # 80008250 <digits+0x210>
    80002020:	ffffe097          	auipc	ra,0xffffe
    80002024:	520080e7          	jalr	1312(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002028:	00006517          	auipc	a0,0x6
    8000202c:	23850513          	addi	a0,a0,568 # 80008260 <digits+0x220>
    80002030:	ffffe097          	auipc	ra,0xffffe
    80002034:	510080e7          	jalr	1296(ra) # 80000540 <panic>

0000000080002038 <yield>:
{
    80002038:	1101                	addi	sp,sp,-32
    8000203a:	ec06                	sd	ra,24(sp)
    8000203c:	e822                	sd	s0,16(sp)
    8000203e:	e426                	sd	s1,8(sp)
    80002040:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002042:	00000097          	auipc	ra,0x0
    80002046:	98a080e7          	jalr	-1654(ra) # 800019cc <myproc>
    8000204a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	b8a080e7          	jalr	-1142(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002054:	478d                	li	a5,3
    80002056:	cc9c                	sw	a5,24(s1)
  sched();
    80002058:	00000097          	auipc	ra,0x0
    8000205c:	f0a080e7          	jalr	-246(ra) # 80001f62 <sched>
  release(&p->lock);
    80002060:	8526                	mv	a0,s1
    80002062:	fffff097          	auipc	ra,0xfffff
    80002066:	c28080e7          	jalr	-984(ra) # 80000c8a <release>
}
    8000206a:	60e2                	ld	ra,24(sp)
    8000206c:	6442                	ld	s0,16(sp)
    8000206e:	64a2                	ld	s1,8(sp)
    80002070:	6105                	addi	sp,sp,32
    80002072:	8082                	ret

0000000080002074 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002074:	7179                	addi	sp,sp,-48
    80002076:	f406                	sd	ra,40(sp)
    80002078:	f022                	sd	s0,32(sp)
    8000207a:	ec26                	sd	s1,24(sp)
    8000207c:	e84a                	sd	s2,16(sp)
    8000207e:	e44e                	sd	s3,8(sp)
    80002080:	1800                	addi	s0,sp,48
    80002082:	89aa                	mv	s3,a0
    80002084:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002086:	00000097          	auipc	ra,0x0
    8000208a:	946080e7          	jalr	-1722(ra) # 800019cc <myproc>
    8000208e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	b46080e7          	jalr	-1210(ra) # 80000bd6 <acquire>
  release(lk);
    80002098:	854a                	mv	a0,s2
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	bf0080e7          	jalr	-1040(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800020a2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020a6:	4789                	li	a5,2
    800020a8:	cc9c                	sw	a5,24(s1)

  sched();
    800020aa:	00000097          	auipc	ra,0x0
    800020ae:	eb8080e7          	jalr	-328(ra) # 80001f62 <sched>

  // Tidy up.
  p->chan = 0;
    800020b2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020b6:	8526                	mv	a0,s1
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	bd2080e7          	jalr	-1070(ra) # 80000c8a <release>
  acquire(lk);
    800020c0:	854a                	mv	a0,s2
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	b14080e7          	jalr	-1260(ra) # 80000bd6 <acquire>
}
    800020ca:	70a2                	ld	ra,40(sp)
    800020cc:	7402                	ld	s0,32(sp)
    800020ce:	64e2                	ld	s1,24(sp)
    800020d0:	6942                	ld	s2,16(sp)
    800020d2:	69a2                	ld	s3,8(sp)
    800020d4:	6145                	addi	sp,sp,48
    800020d6:	8082                	ret

00000000800020d8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020d8:	7139                	addi	sp,sp,-64
    800020da:	fc06                	sd	ra,56(sp)
    800020dc:	f822                	sd	s0,48(sp)
    800020de:	f426                	sd	s1,40(sp)
    800020e0:	f04a                	sd	s2,32(sp)
    800020e2:	ec4e                	sd	s3,24(sp)
    800020e4:	e852                	sd	s4,16(sp)
    800020e6:	e456                	sd	s5,8(sp)
    800020e8:	0080                	addi	s0,sp,64
    800020ea:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020ec:	0000f497          	auipc	s1,0xf
    800020f0:	eb448493          	addi	s1,s1,-332 # 80010fa0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020f4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020f6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020f8:	00015917          	auipc	s2,0x15
    800020fc:	8a890913          	addi	s2,s2,-1880 # 800169a0 <tickslock>
    80002100:	a811                	j	80002114 <wakeup+0x3c>
      }
      release(&p->lock);
    80002102:	8526                	mv	a0,s1
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	b86080e7          	jalr	-1146(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000210c:	16848493          	addi	s1,s1,360
    80002110:	03248663          	beq	s1,s2,8000213c <wakeup+0x64>
    if(p != myproc()){
    80002114:	00000097          	auipc	ra,0x0
    80002118:	8b8080e7          	jalr	-1864(ra) # 800019cc <myproc>
    8000211c:	fea488e3          	beq	s1,a0,8000210c <wakeup+0x34>
      acquire(&p->lock);
    80002120:	8526                	mv	a0,s1
    80002122:	fffff097          	auipc	ra,0xfffff
    80002126:	ab4080e7          	jalr	-1356(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000212a:	4c9c                	lw	a5,24(s1)
    8000212c:	fd379be3          	bne	a5,s3,80002102 <wakeup+0x2a>
    80002130:	709c                	ld	a5,32(s1)
    80002132:	fd4798e3          	bne	a5,s4,80002102 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002136:	0154ac23          	sw	s5,24(s1)
    8000213a:	b7e1                	j	80002102 <wakeup+0x2a>
    }
  }
}
    8000213c:	70e2                	ld	ra,56(sp)
    8000213e:	7442                	ld	s0,48(sp)
    80002140:	74a2                	ld	s1,40(sp)
    80002142:	7902                	ld	s2,32(sp)
    80002144:	69e2                	ld	s3,24(sp)
    80002146:	6a42                	ld	s4,16(sp)
    80002148:	6aa2                	ld	s5,8(sp)
    8000214a:	6121                	addi	sp,sp,64
    8000214c:	8082                	ret

000000008000214e <reparent>:
{
    8000214e:	7179                	addi	sp,sp,-48
    80002150:	f406                	sd	ra,40(sp)
    80002152:	f022                	sd	s0,32(sp)
    80002154:	ec26                	sd	s1,24(sp)
    80002156:	e84a                	sd	s2,16(sp)
    80002158:	e44e                	sd	s3,8(sp)
    8000215a:	e052                	sd	s4,0(sp)
    8000215c:	1800                	addi	s0,sp,48
    8000215e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002160:	0000f497          	auipc	s1,0xf
    80002164:	e4048493          	addi	s1,s1,-448 # 80010fa0 <proc>
      pp->parent = initproc;
    80002168:	00006a17          	auipc	s4,0x6
    8000216c:	790a0a13          	addi	s4,s4,1936 # 800088f8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002170:	00015997          	auipc	s3,0x15
    80002174:	83098993          	addi	s3,s3,-2000 # 800169a0 <tickslock>
    80002178:	a029                	j	80002182 <reparent+0x34>
    8000217a:	16848493          	addi	s1,s1,360
    8000217e:	01348d63          	beq	s1,s3,80002198 <reparent+0x4a>
    if(pp->parent == p){
    80002182:	7c9c                	ld	a5,56(s1)
    80002184:	ff279be3          	bne	a5,s2,8000217a <reparent+0x2c>
      pp->parent = initproc;
    80002188:	000a3503          	ld	a0,0(s4)
    8000218c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000218e:	00000097          	auipc	ra,0x0
    80002192:	f4a080e7          	jalr	-182(ra) # 800020d8 <wakeup>
    80002196:	b7d5                	j	8000217a <reparent+0x2c>
}
    80002198:	70a2                	ld	ra,40(sp)
    8000219a:	7402                	ld	s0,32(sp)
    8000219c:	64e2                	ld	s1,24(sp)
    8000219e:	6942                	ld	s2,16(sp)
    800021a0:	69a2                	ld	s3,8(sp)
    800021a2:	6a02                	ld	s4,0(sp)
    800021a4:	6145                	addi	sp,sp,48
    800021a6:	8082                	ret

00000000800021a8 <exit>:
{
    800021a8:	7179                	addi	sp,sp,-48
    800021aa:	f406                	sd	ra,40(sp)
    800021ac:	f022                	sd	s0,32(sp)
    800021ae:	ec26                	sd	s1,24(sp)
    800021b0:	e84a                	sd	s2,16(sp)
    800021b2:	e44e                	sd	s3,8(sp)
    800021b4:	e052                	sd	s4,0(sp)
    800021b6:	1800                	addi	s0,sp,48
    800021b8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021ba:	00000097          	auipc	ra,0x0
    800021be:	812080e7          	jalr	-2030(ra) # 800019cc <myproc>
    800021c2:	89aa                	mv	s3,a0
  if(p == initproc)
    800021c4:	00006797          	auipc	a5,0x6
    800021c8:	7347b783          	ld	a5,1844(a5) # 800088f8 <initproc>
    800021cc:	0d050493          	addi	s1,a0,208
    800021d0:	15050913          	addi	s2,a0,336
    800021d4:	02a79363          	bne	a5,a0,800021fa <exit+0x52>
    panic("init exiting");
    800021d8:	00006517          	auipc	a0,0x6
    800021dc:	0a050513          	addi	a0,a0,160 # 80008278 <digits+0x238>
    800021e0:	ffffe097          	auipc	ra,0xffffe
    800021e4:	360080e7          	jalr	864(ra) # 80000540 <panic>
      fileclose(f);
    800021e8:	00002097          	auipc	ra,0x2
    800021ec:	2f8080e7          	jalr	760(ra) # 800044e0 <fileclose>
      p->ofile[fd] = 0;
    800021f0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021f4:	04a1                	addi	s1,s1,8
    800021f6:	01248563          	beq	s1,s2,80002200 <exit+0x58>
    if(p->ofile[fd]){
    800021fa:	6088                	ld	a0,0(s1)
    800021fc:	f575                	bnez	a0,800021e8 <exit+0x40>
    800021fe:	bfdd                	j	800021f4 <exit+0x4c>
  begin_op();
    80002200:	00002097          	auipc	ra,0x2
    80002204:	e18080e7          	jalr	-488(ra) # 80004018 <begin_op>
  iput(p->cwd);
    80002208:	1509b503          	ld	a0,336(s3)
    8000220c:	00001097          	auipc	ra,0x1
    80002210:	5fa080e7          	jalr	1530(ra) # 80003806 <iput>
  end_op();
    80002214:	00002097          	auipc	ra,0x2
    80002218:	e82080e7          	jalr	-382(ra) # 80004096 <end_op>
  p->cwd = 0;
    8000221c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002220:	0000f497          	auipc	s1,0xf
    80002224:	96848493          	addi	s1,s1,-1688 # 80010b88 <wait_lock>
    80002228:	8526                	mv	a0,s1
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9ac080e7          	jalr	-1620(ra) # 80000bd6 <acquire>
  reparent(p);
    80002232:	854e                	mv	a0,s3
    80002234:	00000097          	auipc	ra,0x0
    80002238:	f1a080e7          	jalr	-230(ra) # 8000214e <reparent>
  wakeup(p->parent);
    8000223c:	0389b503          	ld	a0,56(s3)
    80002240:	00000097          	auipc	ra,0x0
    80002244:	e98080e7          	jalr	-360(ra) # 800020d8 <wakeup>
  acquire(&p->lock);
    80002248:	854e                	mv	a0,s3
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	98c080e7          	jalr	-1652(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002252:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002256:	4795                	li	a5,5
    80002258:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000225c:	8526                	mv	a0,s1
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	a2c080e7          	jalr	-1492(ra) # 80000c8a <release>
  sched();
    80002266:	00000097          	auipc	ra,0x0
    8000226a:	cfc080e7          	jalr	-772(ra) # 80001f62 <sched>
  panic("zombie exit");
    8000226e:	00006517          	auipc	a0,0x6
    80002272:	01a50513          	addi	a0,a0,26 # 80008288 <digits+0x248>
    80002276:	ffffe097          	auipc	ra,0xffffe
    8000227a:	2ca080e7          	jalr	714(ra) # 80000540 <panic>

000000008000227e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000227e:	7179                	addi	sp,sp,-48
    80002280:	f406                	sd	ra,40(sp)
    80002282:	f022                	sd	s0,32(sp)
    80002284:	ec26                	sd	s1,24(sp)
    80002286:	e84a                	sd	s2,16(sp)
    80002288:	e44e                	sd	s3,8(sp)
    8000228a:	1800                	addi	s0,sp,48
    8000228c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000228e:	0000f497          	auipc	s1,0xf
    80002292:	d1248493          	addi	s1,s1,-750 # 80010fa0 <proc>
    80002296:	00014997          	auipc	s3,0x14
    8000229a:	70a98993          	addi	s3,s3,1802 # 800169a0 <tickslock>
    acquire(&p->lock);
    8000229e:	8526                	mv	a0,s1
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	936080e7          	jalr	-1738(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    800022a8:	589c                	lw	a5,48(s1)
    800022aa:	01278d63          	beq	a5,s2,800022c4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022ae:	8526                	mv	a0,s1
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	9da080e7          	jalr	-1574(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022b8:	16848493          	addi	s1,s1,360
    800022bc:	ff3491e3          	bne	s1,s3,8000229e <kill+0x20>
  }
  return -1;
    800022c0:	557d                	li	a0,-1
    800022c2:	a829                	j	800022dc <kill+0x5e>
      p->killed = 1;
    800022c4:	4785                	li	a5,1
    800022c6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022c8:	4c98                	lw	a4,24(s1)
    800022ca:	4789                	li	a5,2
    800022cc:	00f70f63          	beq	a4,a5,800022ea <kill+0x6c>
      release(&p->lock);
    800022d0:	8526                	mv	a0,s1
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	9b8080e7          	jalr	-1608(ra) # 80000c8a <release>
      return 0;
    800022da:	4501                	li	a0,0
}
    800022dc:	70a2                	ld	ra,40(sp)
    800022de:	7402                	ld	s0,32(sp)
    800022e0:	64e2                	ld	s1,24(sp)
    800022e2:	6942                	ld	s2,16(sp)
    800022e4:	69a2                	ld	s3,8(sp)
    800022e6:	6145                	addi	sp,sp,48
    800022e8:	8082                	ret
        p->state = RUNNABLE;
    800022ea:	478d                	li	a5,3
    800022ec:	cc9c                	sw	a5,24(s1)
    800022ee:	b7cd                	j	800022d0 <kill+0x52>

00000000800022f0 <setkilled>:

void
setkilled(struct proc *p)
{
    800022f0:	1101                	addi	sp,sp,-32
    800022f2:	ec06                	sd	ra,24(sp)
    800022f4:	e822                	sd	s0,16(sp)
    800022f6:	e426                	sd	s1,8(sp)
    800022f8:	1000                	addi	s0,sp,32
    800022fa:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	8da080e7          	jalr	-1830(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002304:	4785                	li	a5,1
    80002306:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002308:	8526                	mv	a0,s1
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	980080e7          	jalr	-1664(ra) # 80000c8a <release>
}
    80002312:	60e2                	ld	ra,24(sp)
    80002314:	6442                	ld	s0,16(sp)
    80002316:	64a2                	ld	s1,8(sp)
    80002318:	6105                	addi	sp,sp,32
    8000231a:	8082                	ret

000000008000231c <killed>:

int
killed(struct proc *p)
{
    8000231c:	1101                	addi	sp,sp,-32
    8000231e:	ec06                	sd	ra,24(sp)
    80002320:	e822                	sd	s0,16(sp)
    80002322:	e426                	sd	s1,8(sp)
    80002324:	e04a                	sd	s2,0(sp)
    80002326:	1000                	addi	s0,sp,32
    80002328:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	8ac080e7          	jalr	-1876(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002332:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002336:	8526                	mv	a0,s1
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	952080e7          	jalr	-1710(ra) # 80000c8a <release>
  return k;
}
    80002340:	854a                	mv	a0,s2
    80002342:	60e2                	ld	ra,24(sp)
    80002344:	6442                	ld	s0,16(sp)
    80002346:	64a2                	ld	s1,8(sp)
    80002348:	6902                	ld	s2,0(sp)
    8000234a:	6105                	addi	sp,sp,32
    8000234c:	8082                	ret

000000008000234e <wait>:
{
    8000234e:	715d                	addi	sp,sp,-80
    80002350:	e486                	sd	ra,72(sp)
    80002352:	e0a2                	sd	s0,64(sp)
    80002354:	fc26                	sd	s1,56(sp)
    80002356:	f84a                	sd	s2,48(sp)
    80002358:	f44e                	sd	s3,40(sp)
    8000235a:	f052                	sd	s4,32(sp)
    8000235c:	ec56                	sd	s5,24(sp)
    8000235e:	e85a                	sd	s6,16(sp)
    80002360:	e45e                	sd	s7,8(sp)
    80002362:	e062                	sd	s8,0(sp)
    80002364:	0880                	addi	s0,sp,80
    80002366:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	664080e7          	jalr	1636(ra) # 800019cc <myproc>
    80002370:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002372:	0000f517          	auipc	a0,0xf
    80002376:	81650513          	addi	a0,a0,-2026 # 80010b88 <wait_lock>
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	85c080e7          	jalr	-1956(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002382:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002384:	4a15                	li	s4,5
        havekids = 1;
    80002386:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002388:	00014997          	auipc	s3,0x14
    8000238c:	61898993          	addi	s3,s3,1560 # 800169a0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002390:	0000ec17          	auipc	s8,0xe
    80002394:	7f8c0c13          	addi	s8,s8,2040 # 80010b88 <wait_lock>
    havekids = 0;
    80002398:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000239a:	0000f497          	auipc	s1,0xf
    8000239e:	c0648493          	addi	s1,s1,-1018 # 80010fa0 <proc>
    800023a2:	a0bd                	j	80002410 <wait+0xc2>
          pid = pp->pid;
    800023a4:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023a8:	000b0e63          	beqz	s6,800023c4 <wait+0x76>
    800023ac:	4691                	li	a3,4
    800023ae:	02c48613          	addi	a2,s1,44
    800023b2:	85da                	mv	a1,s6
    800023b4:	05093503          	ld	a0,80(s2)
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	2d4080e7          	jalr	724(ra) # 8000168c <copyout>
    800023c0:	02054563          	bltz	a0,800023ea <wait+0x9c>
          freeproc(pp);
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	7b8080e7          	jalr	1976(ra) # 80001b7e <freeproc>
          release(&pp->lock);
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	8ba080e7          	jalr	-1862(ra) # 80000c8a <release>
          release(&wait_lock);
    800023d8:	0000e517          	auipc	a0,0xe
    800023dc:	7b050513          	addi	a0,a0,1968 # 80010b88 <wait_lock>
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8aa080e7          	jalr	-1878(ra) # 80000c8a <release>
          return pid;
    800023e8:	a0b5                	j	80002454 <wait+0x106>
            release(&pp->lock);
    800023ea:	8526                	mv	a0,s1
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	89e080e7          	jalr	-1890(ra) # 80000c8a <release>
            release(&wait_lock);
    800023f4:	0000e517          	auipc	a0,0xe
    800023f8:	79450513          	addi	a0,a0,1940 # 80010b88 <wait_lock>
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	88e080e7          	jalr	-1906(ra) # 80000c8a <release>
            return -1;
    80002404:	59fd                	li	s3,-1
    80002406:	a0b9                	j	80002454 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002408:	16848493          	addi	s1,s1,360
    8000240c:	03348463          	beq	s1,s3,80002434 <wait+0xe6>
      if(pp->parent == p){
    80002410:	7c9c                	ld	a5,56(s1)
    80002412:	ff279be3          	bne	a5,s2,80002408 <wait+0xba>
        acquire(&pp->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	ffffe097          	auipc	ra,0xffffe
    8000241c:	7be080e7          	jalr	1982(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    80002420:	4c9c                	lw	a5,24(s1)
    80002422:	f94781e3          	beq	a5,s4,800023a4 <wait+0x56>
        release(&pp->lock);
    80002426:	8526                	mv	a0,s1
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	862080e7          	jalr	-1950(ra) # 80000c8a <release>
        havekids = 1;
    80002430:	8756                	mv	a4,s5
    80002432:	bfd9                	j	80002408 <wait+0xba>
    if(!havekids || killed(p)){
    80002434:	c719                	beqz	a4,80002442 <wait+0xf4>
    80002436:	854a                	mv	a0,s2
    80002438:	00000097          	auipc	ra,0x0
    8000243c:	ee4080e7          	jalr	-284(ra) # 8000231c <killed>
    80002440:	c51d                	beqz	a0,8000246e <wait+0x120>
      release(&wait_lock);
    80002442:	0000e517          	auipc	a0,0xe
    80002446:	74650513          	addi	a0,a0,1862 # 80010b88 <wait_lock>
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	840080e7          	jalr	-1984(ra) # 80000c8a <release>
      return -1;
    80002452:	59fd                	li	s3,-1
}
    80002454:	854e                	mv	a0,s3
    80002456:	60a6                	ld	ra,72(sp)
    80002458:	6406                	ld	s0,64(sp)
    8000245a:	74e2                	ld	s1,56(sp)
    8000245c:	7942                	ld	s2,48(sp)
    8000245e:	79a2                	ld	s3,40(sp)
    80002460:	7a02                	ld	s4,32(sp)
    80002462:	6ae2                	ld	s5,24(sp)
    80002464:	6b42                	ld	s6,16(sp)
    80002466:	6ba2                	ld	s7,8(sp)
    80002468:	6c02                	ld	s8,0(sp)
    8000246a:	6161                	addi	sp,sp,80
    8000246c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000246e:	85e2                	mv	a1,s8
    80002470:	854a                	mv	a0,s2
    80002472:	00000097          	auipc	ra,0x0
    80002476:	c02080e7          	jalr	-1022(ra) # 80002074 <sleep>
    havekids = 0;
    8000247a:	bf39                	j	80002398 <wait+0x4a>

000000008000247c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000247c:	7179                	addi	sp,sp,-48
    8000247e:	f406                	sd	ra,40(sp)
    80002480:	f022                	sd	s0,32(sp)
    80002482:	ec26                	sd	s1,24(sp)
    80002484:	e84a                	sd	s2,16(sp)
    80002486:	e44e                	sd	s3,8(sp)
    80002488:	e052                	sd	s4,0(sp)
    8000248a:	1800                	addi	s0,sp,48
    8000248c:	84aa                	mv	s1,a0
    8000248e:	892e                	mv	s2,a1
    80002490:	89b2                	mv	s3,a2
    80002492:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	538080e7          	jalr	1336(ra) # 800019cc <myproc>
  if(user_dst){
    8000249c:	c08d                	beqz	s1,800024be <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000249e:	86d2                	mv	a3,s4
    800024a0:	864e                	mv	a2,s3
    800024a2:	85ca                	mv	a1,s2
    800024a4:	6928                	ld	a0,80(a0)
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	1e6080e7          	jalr	486(ra) # 8000168c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024ae:	70a2                	ld	ra,40(sp)
    800024b0:	7402                	ld	s0,32(sp)
    800024b2:	64e2                	ld	s1,24(sp)
    800024b4:	6942                	ld	s2,16(sp)
    800024b6:	69a2                	ld	s3,8(sp)
    800024b8:	6a02                	ld	s4,0(sp)
    800024ba:	6145                	addi	sp,sp,48
    800024bc:	8082                	ret
    memmove((char *)dst, src, len);
    800024be:	000a061b          	sext.w	a2,s4
    800024c2:	85ce                	mv	a1,s3
    800024c4:	854a                	mv	a0,s2
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	868080e7          	jalr	-1944(ra) # 80000d2e <memmove>
    return 0;
    800024ce:	8526                	mv	a0,s1
    800024d0:	bff9                	j	800024ae <either_copyout+0x32>

00000000800024d2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024d2:	7179                	addi	sp,sp,-48
    800024d4:	f406                	sd	ra,40(sp)
    800024d6:	f022                	sd	s0,32(sp)
    800024d8:	ec26                	sd	s1,24(sp)
    800024da:	e84a                	sd	s2,16(sp)
    800024dc:	e44e                	sd	s3,8(sp)
    800024de:	e052                	sd	s4,0(sp)
    800024e0:	1800                	addi	s0,sp,48
    800024e2:	892a                	mv	s2,a0
    800024e4:	84ae                	mv	s1,a1
    800024e6:	89b2                	mv	s3,a2
    800024e8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ea:	fffff097          	auipc	ra,0xfffff
    800024ee:	4e2080e7          	jalr	1250(ra) # 800019cc <myproc>
  if(user_src){
    800024f2:	c08d                	beqz	s1,80002514 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024f4:	86d2                	mv	a3,s4
    800024f6:	864e                	mv	a2,s3
    800024f8:	85ca                	mv	a1,s2
    800024fa:	6928                	ld	a0,80(a0)
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	21c080e7          	jalr	540(ra) # 80001718 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002504:	70a2                	ld	ra,40(sp)
    80002506:	7402                	ld	s0,32(sp)
    80002508:	64e2                	ld	s1,24(sp)
    8000250a:	6942                	ld	s2,16(sp)
    8000250c:	69a2                	ld	s3,8(sp)
    8000250e:	6a02                	ld	s4,0(sp)
    80002510:	6145                	addi	sp,sp,48
    80002512:	8082                	ret
    memmove(dst, (char*)src, len);
    80002514:	000a061b          	sext.w	a2,s4
    80002518:	85ce                	mv	a1,s3
    8000251a:	854a                	mv	a0,s2
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	812080e7          	jalr	-2030(ra) # 80000d2e <memmove>
    return 0;
    80002524:	8526                	mv	a0,s1
    80002526:	bff9                	j	80002504 <either_copyin+0x32>

0000000080002528 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002528:	715d                	addi	sp,sp,-80
    8000252a:	e486                	sd	ra,72(sp)
    8000252c:	e0a2                	sd	s0,64(sp)
    8000252e:	fc26                	sd	s1,56(sp)
    80002530:	f84a                	sd	s2,48(sp)
    80002532:	f44e                	sd	s3,40(sp)
    80002534:	f052                	sd	s4,32(sp)
    80002536:	ec56                	sd	s5,24(sp)
    80002538:	e85a                	sd	s6,16(sp)
    8000253a:	e45e                	sd	s7,8(sp)
    8000253c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000253e:	00006517          	auipc	a0,0x6
    80002542:	b8a50513          	addi	a0,a0,-1142 # 800080c8 <digits+0x88>
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	044080e7          	jalr	68(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000254e:	0000f497          	auipc	s1,0xf
    80002552:	baa48493          	addi	s1,s1,-1110 # 800110f8 <proc+0x158>
    80002556:	00014917          	auipc	s2,0x14
    8000255a:	5a290913          	addi	s2,s2,1442 # 80016af8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000255e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002560:	00006997          	auipc	s3,0x6
    80002564:	d3898993          	addi	s3,s3,-712 # 80008298 <digits+0x258>
    printf("%d %s %s", p->pid, state, p->name);
    80002568:	00006a97          	auipc	s5,0x6
    8000256c:	d38a8a93          	addi	s5,s5,-712 # 800082a0 <digits+0x260>
    printf("\n");
    80002570:	00006a17          	auipc	s4,0x6
    80002574:	b58a0a13          	addi	s4,s4,-1192 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002578:	00006b97          	auipc	s7,0x6
    8000257c:	d68b8b93          	addi	s7,s7,-664 # 800082e0 <states.0>
    80002580:	a00d                	j	800025a2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002582:	ed86a583          	lw	a1,-296(a3)
    80002586:	8556                	mv	a0,s5
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	002080e7          	jalr	2(ra) # 8000058a <printf>
    printf("\n");
    80002590:	8552                	mv	a0,s4
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	ff8080e7          	jalr	-8(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000259a:	16848493          	addi	s1,s1,360
    8000259e:	03248263          	beq	s1,s2,800025c2 <procdump+0x9a>
    if(p->state == UNUSED)
    800025a2:	86a6                	mv	a3,s1
    800025a4:	ec04a783          	lw	a5,-320(s1)
    800025a8:	dbed                	beqz	a5,8000259a <procdump+0x72>
      state = "???";
    800025aa:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ac:	fcfb6be3          	bltu	s6,a5,80002582 <procdump+0x5a>
    800025b0:	02079713          	slli	a4,a5,0x20
    800025b4:	01d75793          	srli	a5,a4,0x1d
    800025b8:	97de                	add	a5,a5,s7
    800025ba:	6390                	ld	a2,0(a5)
    800025bc:	f279                	bnez	a2,80002582 <procdump+0x5a>
      state = "???";
    800025be:	864e                	mv	a2,s3
    800025c0:	b7c9                	j	80002582 <procdump+0x5a>
  }
}
    800025c2:	60a6                	ld	ra,72(sp)
    800025c4:	6406                	ld	s0,64(sp)
    800025c6:	74e2                	ld	s1,56(sp)
    800025c8:	7942                	ld	s2,48(sp)
    800025ca:	79a2                	ld	s3,40(sp)
    800025cc:	7a02                	ld	s4,32(sp)
    800025ce:	6ae2                	ld	s5,24(sp)
    800025d0:	6b42                	ld	s6,16(sp)
    800025d2:	6ba2                	ld	s7,8(sp)
    800025d4:	6161                	addi	sp,sp,80
    800025d6:	8082                	ret

00000000800025d8 <swtch>:
    800025d8:	00153023          	sd	ra,0(a0)
    800025dc:	00253423          	sd	sp,8(a0)
    800025e0:	e900                	sd	s0,16(a0)
    800025e2:	ed04                	sd	s1,24(a0)
    800025e4:	03253023          	sd	s2,32(a0)
    800025e8:	03353423          	sd	s3,40(a0)
    800025ec:	03453823          	sd	s4,48(a0)
    800025f0:	03553c23          	sd	s5,56(a0)
    800025f4:	05653023          	sd	s6,64(a0)
    800025f8:	05753423          	sd	s7,72(a0)
    800025fc:	05853823          	sd	s8,80(a0)
    80002600:	05953c23          	sd	s9,88(a0)
    80002604:	07a53023          	sd	s10,96(a0)
    80002608:	07b53423          	sd	s11,104(a0)
    8000260c:	0005b083          	ld	ra,0(a1)
    80002610:	0085b103          	ld	sp,8(a1)
    80002614:	6980                	ld	s0,16(a1)
    80002616:	6d84                	ld	s1,24(a1)
    80002618:	0205b903          	ld	s2,32(a1)
    8000261c:	0285b983          	ld	s3,40(a1)
    80002620:	0305ba03          	ld	s4,48(a1)
    80002624:	0385ba83          	ld	s5,56(a1)
    80002628:	0405bb03          	ld	s6,64(a1)
    8000262c:	0485bb83          	ld	s7,72(a1)
    80002630:	0505bc03          	ld	s8,80(a1)
    80002634:	0585bc83          	ld	s9,88(a1)
    80002638:	0605bd03          	ld	s10,96(a1)
    8000263c:	0685bd83          	ld	s11,104(a1)
    80002640:	8082                	ret

0000000080002642 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002642:	1141                	addi	sp,sp,-16
    80002644:	e406                	sd	ra,8(sp)
    80002646:	e022                	sd	s0,0(sp)
    80002648:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000264a:	00006597          	auipc	a1,0x6
    8000264e:	cc658593          	addi	a1,a1,-826 # 80008310 <states.0+0x30>
    80002652:	00014517          	auipc	a0,0x14
    80002656:	34e50513          	addi	a0,a0,846 # 800169a0 <tickslock>
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	4ec080e7          	jalr	1260(ra) # 80000b46 <initlock>
}
    80002662:	60a2                	ld	ra,8(sp)
    80002664:	6402                	ld	s0,0(sp)
    80002666:	0141                	addi	sp,sp,16
    80002668:	8082                	ret

000000008000266a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000266a:	1141                	addi	sp,sp,-16
    8000266c:	e422                	sd	s0,8(sp)
    8000266e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002670:	00003797          	auipc	a5,0x3
    80002674:	4d078793          	addi	a5,a5,1232 # 80005b40 <kernelvec>
    80002678:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000267c:	6422                	ld	s0,8(sp)
    8000267e:	0141                	addi	sp,sp,16
    80002680:	8082                	ret

0000000080002682 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002682:	1141                	addi	sp,sp,-16
    80002684:	e406                	sd	ra,8(sp)
    80002686:	e022                	sd	s0,0(sp)
    80002688:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000268a:	fffff097          	auipc	ra,0xfffff
    8000268e:	342080e7          	jalr	834(ra) # 800019cc <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002692:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002696:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002698:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000269c:	00005697          	auipc	a3,0x5
    800026a0:	96468693          	addi	a3,a3,-1692 # 80007000 <_trampoline>
    800026a4:	00005717          	auipc	a4,0x5
    800026a8:	95c70713          	addi	a4,a4,-1700 # 80007000 <_trampoline>
    800026ac:	8f15                	sub	a4,a4,a3
    800026ae:	040007b7          	lui	a5,0x4000
    800026b2:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800026b4:	07b2                	slli	a5,a5,0xc
    800026b6:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026b8:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026bc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026be:	18002673          	csrr	a2,satp
    800026c2:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026c4:	6d30                	ld	a2,88(a0)
    800026c6:	6138                	ld	a4,64(a0)
    800026c8:	6585                	lui	a1,0x1
    800026ca:	972e                	add	a4,a4,a1
    800026cc:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026ce:	6d38                	ld	a4,88(a0)
    800026d0:	00000617          	auipc	a2,0x0
    800026d4:	13060613          	addi	a2,a2,304 # 80002800 <usertrap>
    800026d8:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026da:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026dc:	8612                	mv	a2,tp
    800026de:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026e0:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026e4:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026e8:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026ec:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026f0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026f2:	6f18                	ld	a4,24(a4)
    800026f4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026f8:	6928                	ld	a0,80(a0)
    800026fa:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800026fc:	00005717          	auipc	a4,0x5
    80002700:	9a070713          	addi	a4,a4,-1632 # 8000709c <userret>
    80002704:	8f15                	sub	a4,a4,a3
    80002706:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002708:	577d                	li	a4,-1
    8000270a:	177e                	slli	a4,a4,0x3f
    8000270c:	8d59                	or	a0,a0,a4
    8000270e:	9782                	jalr	a5
}
    80002710:	60a2                	ld	ra,8(sp)
    80002712:	6402                	ld	s0,0(sp)
    80002714:	0141                	addi	sp,sp,16
    80002716:	8082                	ret

0000000080002718 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002718:	1101                	addi	sp,sp,-32
    8000271a:	ec06                	sd	ra,24(sp)
    8000271c:	e822                	sd	s0,16(sp)
    8000271e:	e426                	sd	s1,8(sp)
    80002720:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002722:	00014497          	auipc	s1,0x14
    80002726:	27e48493          	addi	s1,s1,638 # 800169a0 <tickslock>
    8000272a:	8526                	mv	a0,s1
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	4aa080e7          	jalr	1194(ra) # 80000bd6 <acquire>
  ticks++;
    80002734:	00006517          	auipc	a0,0x6
    80002738:	1cc50513          	addi	a0,a0,460 # 80008900 <ticks>
    8000273c:	411c                	lw	a5,0(a0)
    8000273e:	2785                	addiw	a5,a5,1
    80002740:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002742:	00000097          	auipc	ra,0x0
    80002746:	996080e7          	jalr	-1642(ra) # 800020d8 <wakeup>
  release(&tickslock);
    8000274a:	8526                	mv	a0,s1
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	53e080e7          	jalr	1342(ra) # 80000c8a <release>
}
    80002754:	60e2                	ld	ra,24(sp)
    80002756:	6442                	ld	s0,16(sp)
    80002758:	64a2                	ld	s1,8(sp)
    8000275a:	6105                	addi	sp,sp,32
    8000275c:	8082                	ret

000000008000275e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000275e:	1101                	addi	sp,sp,-32
    80002760:	ec06                	sd	ra,24(sp)
    80002762:	e822                	sd	s0,16(sp)
    80002764:	e426                	sd	s1,8(sp)
    80002766:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002768:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000276c:	00074d63          	bltz	a4,80002786 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002770:	57fd                	li	a5,-1
    80002772:	17fe                	slli	a5,a5,0x3f
    80002774:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002776:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002778:	06f70363          	beq	a4,a5,800027de <devintr+0x80>
  }
}
    8000277c:	60e2                	ld	ra,24(sp)
    8000277e:	6442                	ld	s0,16(sp)
    80002780:	64a2                	ld	s1,8(sp)
    80002782:	6105                	addi	sp,sp,32
    80002784:	8082                	ret
     (scause & 0xff) == 9){
    80002786:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    8000278a:	46a5                	li	a3,9
    8000278c:	fed792e3          	bne	a5,a3,80002770 <devintr+0x12>
    int irq = plic_claim();
    80002790:	00003097          	auipc	ra,0x3
    80002794:	4b8080e7          	jalr	1208(ra) # 80005c48 <plic_claim>
    80002798:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000279a:	47a9                	li	a5,10
    8000279c:	02f50763          	beq	a0,a5,800027ca <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027a0:	4785                	li	a5,1
    800027a2:	02f50963          	beq	a0,a5,800027d4 <devintr+0x76>
    return 1;
    800027a6:	4505                	li	a0,1
    } else if(irq){
    800027a8:	d8f1                	beqz	s1,8000277c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027aa:	85a6                	mv	a1,s1
    800027ac:	00006517          	auipc	a0,0x6
    800027b0:	b6c50513          	addi	a0,a0,-1172 # 80008318 <states.0+0x38>
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	dd6080e7          	jalr	-554(ra) # 8000058a <printf>
      plic_complete(irq);
    800027bc:	8526                	mv	a0,s1
    800027be:	00003097          	auipc	ra,0x3
    800027c2:	4ae080e7          	jalr	1198(ra) # 80005c6c <plic_complete>
    return 1;
    800027c6:	4505                	li	a0,1
    800027c8:	bf55                	j	8000277c <devintr+0x1e>
      uartintr();
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	1ce080e7          	jalr	462(ra) # 80000998 <uartintr>
    800027d2:	b7ed                	j	800027bc <devintr+0x5e>
      virtio_disk_intr();
    800027d4:	00004097          	auipc	ra,0x4
    800027d8:	960080e7          	jalr	-1696(ra) # 80006134 <virtio_disk_intr>
    800027dc:	b7c5                	j	800027bc <devintr+0x5e>
    if(cpuid() == 0){
    800027de:	fffff097          	auipc	ra,0xfffff
    800027e2:	1c2080e7          	jalr	450(ra) # 800019a0 <cpuid>
    800027e6:	c901                	beqz	a0,800027f6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027e8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027ec:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027ee:	14479073          	csrw	sip,a5
    return 2;
    800027f2:	4509                	li	a0,2
    800027f4:	b761                	j	8000277c <devintr+0x1e>
      clockintr();
    800027f6:	00000097          	auipc	ra,0x0
    800027fa:	f22080e7          	jalr	-222(ra) # 80002718 <clockintr>
    800027fe:	b7ed                	j	800027e8 <devintr+0x8a>

0000000080002800 <usertrap>:
{
    80002800:	1101                	addi	sp,sp,-32
    80002802:	ec06                	sd	ra,24(sp)
    80002804:	e822                	sd	s0,16(sp)
    80002806:	e426                	sd	s1,8(sp)
    80002808:	e04a                	sd	s2,0(sp)
    8000280a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000280c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002810:	1007f793          	andi	a5,a5,256
    80002814:	e3b1                	bnez	a5,80002858 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002816:	00003797          	auipc	a5,0x3
    8000281a:	32a78793          	addi	a5,a5,810 # 80005b40 <kernelvec>
    8000281e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002822:	fffff097          	auipc	ra,0xfffff
    80002826:	1aa080e7          	jalr	426(ra) # 800019cc <myproc>
    8000282a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000282c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000282e:	14102773          	csrr	a4,sepc
    80002832:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002834:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002838:	47a1                	li	a5,8
    8000283a:	02f70763          	beq	a4,a5,80002868 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000283e:	00000097          	auipc	ra,0x0
    80002842:	f20080e7          	jalr	-224(ra) # 8000275e <devintr>
    80002846:	892a                	mv	s2,a0
    80002848:	c151                	beqz	a0,800028cc <usertrap+0xcc>
  if(killed(p))
    8000284a:	8526                	mv	a0,s1
    8000284c:	00000097          	auipc	ra,0x0
    80002850:	ad0080e7          	jalr	-1328(ra) # 8000231c <killed>
    80002854:	c929                	beqz	a0,800028a6 <usertrap+0xa6>
    80002856:	a099                	j	8000289c <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002858:	00006517          	auipc	a0,0x6
    8000285c:	ae050513          	addi	a0,a0,-1312 # 80008338 <states.0+0x58>
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	ce0080e7          	jalr	-800(ra) # 80000540 <panic>
    if(killed(p))
    80002868:	00000097          	auipc	ra,0x0
    8000286c:	ab4080e7          	jalr	-1356(ra) # 8000231c <killed>
    80002870:	e921                	bnez	a0,800028c0 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002872:	6cb8                	ld	a4,88(s1)
    80002874:	6f1c                	ld	a5,24(a4)
    80002876:	0791                	addi	a5,a5,4
    80002878:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000287a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000287e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002882:	10079073          	csrw	sstatus,a5
    syscall();
    80002886:	00000097          	auipc	ra,0x0
    8000288a:	2d4080e7          	jalr	724(ra) # 80002b5a <syscall>
  if(killed(p))
    8000288e:	8526                	mv	a0,s1
    80002890:	00000097          	auipc	ra,0x0
    80002894:	a8c080e7          	jalr	-1396(ra) # 8000231c <killed>
    80002898:	c911                	beqz	a0,800028ac <usertrap+0xac>
    8000289a:	4901                	li	s2,0
    exit(-1);
    8000289c:	557d                	li	a0,-1
    8000289e:	00000097          	auipc	ra,0x0
    800028a2:	90a080e7          	jalr	-1782(ra) # 800021a8 <exit>
  if(which_dev == 2)
    800028a6:	4789                	li	a5,2
    800028a8:	04f90f63          	beq	s2,a5,80002906 <usertrap+0x106>
  usertrapret();
    800028ac:	00000097          	auipc	ra,0x0
    800028b0:	dd6080e7          	jalr	-554(ra) # 80002682 <usertrapret>
}
    800028b4:	60e2                	ld	ra,24(sp)
    800028b6:	6442                	ld	s0,16(sp)
    800028b8:	64a2                	ld	s1,8(sp)
    800028ba:	6902                	ld	s2,0(sp)
    800028bc:	6105                	addi	sp,sp,32
    800028be:	8082                	ret
      exit(-1);
    800028c0:	557d                	li	a0,-1
    800028c2:	00000097          	auipc	ra,0x0
    800028c6:	8e6080e7          	jalr	-1818(ra) # 800021a8 <exit>
    800028ca:	b765                	j	80002872 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028cc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028d0:	5890                	lw	a2,48(s1)
    800028d2:	00006517          	auipc	a0,0x6
    800028d6:	a8650513          	addi	a0,a0,-1402 # 80008358 <states.0+0x78>
    800028da:	ffffe097          	auipc	ra,0xffffe
    800028de:	cb0080e7          	jalr	-848(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028e2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028e6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028ea:	00006517          	auipc	a0,0x6
    800028ee:	a9e50513          	addi	a0,a0,-1378 # 80008388 <states.0+0xa8>
    800028f2:	ffffe097          	auipc	ra,0xffffe
    800028f6:	c98080e7          	jalr	-872(ra) # 8000058a <printf>
    setkilled(p);
    800028fa:	8526                	mv	a0,s1
    800028fc:	00000097          	auipc	ra,0x0
    80002900:	9f4080e7          	jalr	-1548(ra) # 800022f0 <setkilled>
    80002904:	b769                	j	8000288e <usertrap+0x8e>
    yield();
    80002906:	fffff097          	auipc	ra,0xfffff
    8000290a:	732080e7          	jalr	1842(ra) # 80002038 <yield>
    8000290e:	bf79                	j	800028ac <usertrap+0xac>

0000000080002910 <kerneltrap>:
{
    80002910:	7179                	addi	sp,sp,-48
    80002912:	f406                	sd	ra,40(sp)
    80002914:	f022                	sd	s0,32(sp)
    80002916:	ec26                	sd	s1,24(sp)
    80002918:	e84a                	sd	s2,16(sp)
    8000291a:	e44e                	sd	s3,8(sp)
    8000291c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000291e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002922:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002926:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000292a:	1004f793          	andi	a5,s1,256
    8000292e:	cb85                	beqz	a5,8000295e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002930:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002934:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002936:	ef85                	bnez	a5,8000296e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002938:	00000097          	auipc	ra,0x0
    8000293c:	e26080e7          	jalr	-474(ra) # 8000275e <devintr>
    80002940:	cd1d                	beqz	a0,8000297e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002942:	4789                	li	a5,2
    80002944:	06f50a63          	beq	a0,a5,800029b8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002948:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000294c:	10049073          	csrw	sstatus,s1
}
    80002950:	70a2                	ld	ra,40(sp)
    80002952:	7402                	ld	s0,32(sp)
    80002954:	64e2                	ld	s1,24(sp)
    80002956:	6942                	ld	s2,16(sp)
    80002958:	69a2                	ld	s3,8(sp)
    8000295a:	6145                	addi	sp,sp,48
    8000295c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000295e:	00006517          	auipc	a0,0x6
    80002962:	a4a50513          	addi	a0,a0,-1462 # 800083a8 <states.0+0xc8>
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	bda080e7          	jalr	-1062(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    8000296e:	00006517          	auipc	a0,0x6
    80002972:	a6250513          	addi	a0,a0,-1438 # 800083d0 <states.0+0xf0>
    80002976:	ffffe097          	auipc	ra,0xffffe
    8000297a:	bca080e7          	jalr	-1078(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    8000297e:	85ce                	mv	a1,s3
    80002980:	00006517          	auipc	a0,0x6
    80002984:	a7050513          	addi	a0,a0,-1424 # 800083f0 <states.0+0x110>
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	c02080e7          	jalr	-1022(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002990:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002994:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002998:	00006517          	auipc	a0,0x6
    8000299c:	a6850513          	addi	a0,a0,-1432 # 80008400 <states.0+0x120>
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	bea080e7          	jalr	-1046(ra) # 8000058a <printf>
    panic("kerneltrap");
    800029a8:	00006517          	auipc	a0,0x6
    800029ac:	a7050513          	addi	a0,a0,-1424 # 80008418 <states.0+0x138>
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	b90080e7          	jalr	-1136(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029b8:	fffff097          	auipc	ra,0xfffff
    800029bc:	014080e7          	jalr	20(ra) # 800019cc <myproc>
    800029c0:	d541                	beqz	a0,80002948 <kerneltrap+0x38>
    800029c2:	fffff097          	auipc	ra,0xfffff
    800029c6:	00a080e7          	jalr	10(ra) # 800019cc <myproc>
    800029ca:	4d18                	lw	a4,24(a0)
    800029cc:	4791                	li	a5,4
    800029ce:	f6f71de3          	bne	a4,a5,80002948 <kerneltrap+0x38>
    yield();
    800029d2:	fffff097          	auipc	ra,0xfffff
    800029d6:	666080e7          	jalr	1638(ra) # 80002038 <yield>
    800029da:	b7bd                	j	80002948 <kerneltrap+0x38>

00000000800029dc <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029dc:	1101                	addi	sp,sp,-32
    800029de:	ec06                	sd	ra,24(sp)
    800029e0:	e822                	sd	s0,16(sp)
    800029e2:	e426                	sd	s1,8(sp)
    800029e4:	1000                	addi	s0,sp,32
    800029e6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029e8:	fffff097          	auipc	ra,0xfffff
    800029ec:	fe4080e7          	jalr	-28(ra) # 800019cc <myproc>
  switch (n) {
    800029f0:	4795                	li	a5,5
    800029f2:	0497e163          	bltu	a5,s1,80002a34 <argraw+0x58>
    800029f6:	048a                	slli	s1,s1,0x2
    800029f8:	00006717          	auipc	a4,0x6
    800029fc:	a5870713          	addi	a4,a4,-1448 # 80008450 <states.0+0x170>
    80002a00:	94ba                	add	s1,s1,a4
    80002a02:	409c                	lw	a5,0(s1)
    80002a04:	97ba                	add	a5,a5,a4
    80002a06:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a08:	6d3c                	ld	a5,88(a0)
    80002a0a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a0c:	60e2                	ld	ra,24(sp)
    80002a0e:	6442                	ld	s0,16(sp)
    80002a10:	64a2                	ld	s1,8(sp)
    80002a12:	6105                	addi	sp,sp,32
    80002a14:	8082                	ret
    return p->trapframe->a1;
    80002a16:	6d3c                	ld	a5,88(a0)
    80002a18:	7fa8                	ld	a0,120(a5)
    80002a1a:	bfcd                	j	80002a0c <argraw+0x30>
    return p->trapframe->a2;
    80002a1c:	6d3c                	ld	a5,88(a0)
    80002a1e:	63c8                	ld	a0,128(a5)
    80002a20:	b7f5                	j	80002a0c <argraw+0x30>
    return p->trapframe->a3;
    80002a22:	6d3c                	ld	a5,88(a0)
    80002a24:	67c8                	ld	a0,136(a5)
    80002a26:	b7dd                	j	80002a0c <argraw+0x30>
    return p->trapframe->a4;
    80002a28:	6d3c                	ld	a5,88(a0)
    80002a2a:	6bc8                	ld	a0,144(a5)
    80002a2c:	b7c5                	j	80002a0c <argraw+0x30>
    return p->trapframe->a5;
    80002a2e:	6d3c                	ld	a5,88(a0)
    80002a30:	6fc8                	ld	a0,152(a5)
    80002a32:	bfe9                	j	80002a0c <argraw+0x30>
  panic("argraw");
    80002a34:	00006517          	auipc	a0,0x6
    80002a38:	9f450513          	addi	a0,a0,-1548 # 80008428 <states.0+0x148>
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	b04080e7          	jalr	-1276(ra) # 80000540 <panic>

0000000080002a44 <fetchaddr>:
{
    80002a44:	1101                	addi	sp,sp,-32
    80002a46:	ec06                	sd	ra,24(sp)
    80002a48:	e822                	sd	s0,16(sp)
    80002a4a:	e426                	sd	s1,8(sp)
    80002a4c:	e04a                	sd	s2,0(sp)
    80002a4e:	1000                	addi	s0,sp,32
    80002a50:	84aa                	mv	s1,a0
    80002a52:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a54:	fffff097          	auipc	ra,0xfffff
    80002a58:	f78080e7          	jalr	-136(ra) # 800019cc <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a5c:	653c                	ld	a5,72(a0)
    80002a5e:	02f4f863          	bgeu	s1,a5,80002a8e <fetchaddr+0x4a>
    80002a62:	00848713          	addi	a4,s1,8
    80002a66:	02e7e663          	bltu	a5,a4,80002a92 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a6a:	46a1                	li	a3,8
    80002a6c:	8626                	mv	a2,s1
    80002a6e:	85ca                	mv	a1,s2
    80002a70:	6928                	ld	a0,80(a0)
    80002a72:	fffff097          	auipc	ra,0xfffff
    80002a76:	ca6080e7          	jalr	-858(ra) # 80001718 <copyin>
    80002a7a:	00a03533          	snez	a0,a0
    80002a7e:	40a00533          	neg	a0,a0
}
    80002a82:	60e2                	ld	ra,24(sp)
    80002a84:	6442                	ld	s0,16(sp)
    80002a86:	64a2                	ld	s1,8(sp)
    80002a88:	6902                	ld	s2,0(sp)
    80002a8a:	6105                	addi	sp,sp,32
    80002a8c:	8082                	ret
    return -1;
    80002a8e:	557d                	li	a0,-1
    80002a90:	bfcd                	j	80002a82 <fetchaddr+0x3e>
    80002a92:	557d                	li	a0,-1
    80002a94:	b7fd                	j	80002a82 <fetchaddr+0x3e>

0000000080002a96 <fetchstr>:
{
    80002a96:	7179                	addi	sp,sp,-48
    80002a98:	f406                	sd	ra,40(sp)
    80002a9a:	f022                	sd	s0,32(sp)
    80002a9c:	ec26                	sd	s1,24(sp)
    80002a9e:	e84a                	sd	s2,16(sp)
    80002aa0:	e44e                	sd	s3,8(sp)
    80002aa2:	1800                	addi	s0,sp,48
    80002aa4:	892a                	mv	s2,a0
    80002aa6:	84ae                	mv	s1,a1
    80002aa8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002aaa:	fffff097          	auipc	ra,0xfffff
    80002aae:	f22080e7          	jalr	-222(ra) # 800019cc <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ab2:	86ce                	mv	a3,s3
    80002ab4:	864a                	mv	a2,s2
    80002ab6:	85a6                	mv	a1,s1
    80002ab8:	6928                	ld	a0,80(a0)
    80002aba:	fffff097          	auipc	ra,0xfffff
    80002abe:	cec080e7          	jalr	-788(ra) # 800017a6 <copyinstr>
    80002ac2:	00054e63          	bltz	a0,80002ade <fetchstr+0x48>
  return strlen(buf);
    80002ac6:	8526                	mv	a0,s1
    80002ac8:	ffffe097          	auipc	ra,0xffffe
    80002acc:	386080e7          	jalr	902(ra) # 80000e4e <strlen>
}
    80002ad0:	70a2                	ld	ra,40(sp)
    80002ad2:	7402                	ld	s0,32(sp)
    80002ad4:	64e2                	ld	s1,24(sp)
    80002ad6:	6942                	ld	s2,16(sp)
    80002ad8:	69a2                	ld	s3,8(sp)
    80002ada:	6145                	addi	sp,sp,48
    80002adc:	8082                	ret
    return -1;
    80002ade:	557d                	li	a0,-1
    80002ae0:	bfc5                	j	80002ad0 <fetchstr+0x3a>

0000000080002ae2 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002ae2:	1101                	addi	sp,sp,-32
    80002ae4:	ec06                	sd	ra,24(sp)
    80002ae6:	e822                	sd	s0,16(sp)
    80002ae8:	e426                	sd	s1,8(sp)
    80002aea:	1000                	addi	s0,sp,32
    80002aec:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aee:	00000097          	auipc	ra,0x0
    80002af2:	eee080e7          	jalr	-274(ra) # 800029dc <argraw>
    80002af6:	c088                	sw	a0,0(s1)
}
    80002af8:	60e2                	ld	ra,24(sp)
    80002afa:	6442                	ld	s0,16(sp)
    80002afc:	64a2                	ld	s1,8(sp)
    80002afe:	6105                	addi	sp,sp,32
    80002b00:	8082                	ret

0000000080002b02 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b02:	1101                	addi	sp,sp,-32
    80002b04:	ec06                	sd	ra,24(sp)
    80002b06:	e822                	sd	s0,16(sp)
    80002b08:	e426                	sd	s1,8(sp)
    80002b0a:	1000                	addi	s0,sp,32
    80002b0c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b0e:	00000097          	auipc	ra,0x0
    80002b12:	ece080e7          	jalr	-306(ra) # 800029dc <argraw>
    80002b16:	e088                	sd	a0,0(s1)
}
    80002b18:	60e2                	ld	ra,24(sp)
    80002b1a:	6442                	ld	s0,16(sp)
    80002b1c:	64a2                	ld	s1,8(sp)
    80002b1e:	6105                	addi	sp,sp,32
    80002b20:	8082                	ret

0000000080002b22 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b22:	7179                	addi	sp,sp,-48
    80002b24:	f406                	sd	ra,40(sp)
    80002b26:	f022                	sd	s0,32(sp)
    80002b28:	ec26                	sd	s1,24(sp)
    80002b2a:	e84a                	sd	s2,16(sp)
    80002b2c:	1800                	addi	s0,sp,48
    80002b2e:	84ae                	mv	s1,a1
    80002b30:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b32:	fd840593          	addi	a1,s0,-40
    80002b36:	00000097          	auipc	ra,0x0
    80002b3a:	fcc080e7          	jalr	-52(ra) # 80002b02 <argaddr>
  return fetchstr(addr, buf, max);
    80002b3e:	864a                	mv	a2,s2
    80002b40:	85a6                	mv	a1,s1
    80002b42:	fd843503          	ld	a0,-40(s0)
    80002b46:	00000097          	auipc	ra,0x0
    80002b4a:	f50080e7          	jalr	-176(ra) # 80002a96 <fetchstr>
}
    80002b4e:	70a2                	ld	ra,40(sp)
    80002b50:	7402                	ld	s0,32(sp)
    80002b52:	64e2                	ld	s1,24(sp)
    80002b54:	6942                	ld	s2,16(sp)
    80002b56:	6145                	addi	sp,sp,48
    80002b58:	8082                	ret

0000000080002b5a <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002b5a:	1101                	addi	sp,sp,-32
    80002b5c:	ec06                	sd	ra,24(sp)
    80002b5e:	e822                	sd	s0,16(sp)
    80002b60:	e426                	sd	s1,8(sp)
    80002b62:	e04a                	sd	s2,0(sp)
    80002b64:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	e66080e7          	jalr	-410(ra) # 800019cc <myproc>
    80002b6e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b70:	05853903          	ld	s2,88(a0)
    80002b74:	0a893783          	ld	a5,168(s2)
    80002b78:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b7c:	37fd                	addiw	a5,a5,-1
    80002b7e:	4751                	li	a4,20
    80002b80:	00f76f63          	bltu	a4,a5,80002b9e <syscall+0x44>
    80002b84:	00369713          	slli	a4,a3,0x3
    80002b88:	00006797          	auipc	a5,0x6
    80002b8c:	8e078793          	addi	a5,a5,-1824 # 80008468 <syscalls>
    80002b90:	97ba                	add	a5,a5,a4
    80002b92:	639c                	ld	a5,0(a5)
    80002b94:	c789                	beqz	a5,80002b9e <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002b96:	9782                	jalr	a5
    80002b98:	06a93823          	sd	a0,112(s2)
    80002b9c:	a839                	j	80002bba <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b9e:	15848613          	addi	a2,s1,344
    80002ba2:	588c                	lw	a1,48(s1)
    80002ba4:	00006517          	auipc	a0,0x6
    80002ba8:	88c50513          	addi	a0,a0,-1908 # 80008430 <states.0+0x150>
    80002bac:	ffffe097          	auipc	ra,0xffffe
    80002bb0:	9de080e7          	jalr	-1570(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bb4:	6cbc                	ld	a5,88(s1)
    80002bb6:	577d                	li	a4,-1
    80002bb8:	fbb8                	sd	a4,112(a5)
  }
}
    80002bba:	60e2                	ld	ra,24(sp)
    80002bbc:	6442                	ld	s0,16(sp)
    80002bbe:	64a2                	ld	s1,8(sp)
    80002bc0:	6902                	ld	s2,0(sp)
    80002bc2:	6105                	addi	sp,sp,32
    80002bc4:	8082                	ret

0000000080002bc6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002bc6:	1101                	addi	sp,sp,-32
    80002bc8:	ec06                	sd	ra,24(sp)
    80002bca:	e822                	sd	s0,16(sp)
    80002bcc:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002bce:	fec40593          	addi	a1,s0,-20
    80002bd2:	4501                	li	a0,0
    80002bd4:	00000097          	auipc	ra,0x0
    80002bd8:	f0e080e7          	jalr	-242(ra) # 80002ae2 <argint>
  exit(n);
    80002bdc:	fec42503          	lw	a0,-20(s0)
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	5c8080e7          	jalr	1480(ra) # 800021a8 <exit>
  return 0;  // not reached
}
    80002be8:	4501                	li	a0,0
    80002bea:	60e2                	ld	ra,24(sp)
    80002bec:	6442                	ld	s0,16(sp)
    80002bee:	6105                	addi	sp,sp,32
    80002bf0:	8082                	ret

0000000080002bf2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bf2:	1141                	addi	sp,sp,-16
    80002bf4:	e406                	sd	ra,8(sp)
    80002bf6:	e022                	sd	s0,0(sp)
    80002bf8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bfa:	fffff097          	auipc	ra,0xfffff
    80002bfe:	dd2080e7          	jalr	-558(ra) # 800019cc <myproc>
}
    80002c02:	5908                	lw	a0,48(a0)
    80002c04:	60a2                	ld	ra,8(sp)
    80002c06:	6402                	ld	s0,0(sp)
    80002c08:	0141                	addi	sp,sp,16
    80002c0a:	8082                	ret

0000000080002c0c <sys_fork>:

uint64
sys_fork(void)
{
    80002c0c:	1141                	addi	sp,sp,-16
    80002c0e:	e406                	sd	ra,8(sp)
    80002c10:	e022                	sd	s0,0(sp)
    80002c12:	0800                	addi	s0,sp,16
  return fork();
    80002c14:	fffff097          	auipc	ra,0xfffff
    80002c18:	16e080e7          	jalr	366(ra) # 80001d82 <fork>
}
    80002c1c:	60a2                	ld	ra,8(sp)
    80002c1e:	6402                	ld	s0,0(sp)
    80002c20:	0141                	addi	sp,sp,16
    80002c22:	8082                	ret

0000000080002c24 <sys_wait>:

uint64
sys_wait(void)
{
    80002c24:	1101                	addi	sp,sp,-32
    80002c26:	ec06                	sd	ra,24(sp)
    80002c28:	e822                	sd	s0,16(sp)
    80002c2a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002c2c:	fe840593          	addi	a1,s0,-24
    80002c30:	4501                	li	a0,0
    80002c32:	00000097          	auipc	ra,0x0
    80002c36:	ed0080e7          	jalr	-304(ra) # 80002b02 <argaddr>
  return wait(p);
    80002c3a:	fe843503          	ld	a0,-24(s0)
    80002c3e:	fffff097          	auipc	ra,0xfffff
    80002c42:	710080e7          	jalr	1808(ra) # 8000234e <wait>
}
    80002c46:	60e2                	ld	ra,24(sp)
    80002c48:	6442                	ld	s0,16(sp)
    80002c4a:	6105                	addi	sp,sp,32
    80002c4c:	8082                	ret

0000000080002c4e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c4e:	7179                	addi	sp,sp,-48
    80002c50:	f406                	sd	ra,40(sp)
    80002c52:	f022                	sd	s0,32(sp)
    80002c54:	ec26                	sd	s1,24(sp)
    80002c56:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002c58:	fdc40593          	addi	a1,s0,-36
    80002c5c:	4501                	li	a0,0
    80002c5e:	00000097          	auipc	ra,0x0
    80002c62:	e84080e7          	jalr	-380(ra) # 80002ae2 <argint>
  addr = myproc()->sz;
    80002c66:	fffff097          	auipc	ra,0xfffff
    80002c6a:	d66080e7          	jalr	-666(ra) # 800019cc <myproc>
    80002c6e:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002c70:	fdc42503          	lw	a0,-36(s0)
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	0b2080e7          	jalr	178(ra) # 80001d26 <growproc>
    80002c7c:	00054863          	bltz	a0,80002c8c <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002c80:	8526                	mv	a0,s1
    80002c82:	70a2                	ld	ra,40(sp)
    80002c84:	7402                	ld	s0,32(sp)
    80002c86:	64e2                	ld	s1,24(sp)
    80002c88:	6145                	addi	sp,sp,48
    80002c8a:	8082                	ret
    return -1;
    80002c8c:	54fd                	li	s1,-1
    80002c8e:	bfcd                	j	80002c80 <sys_sbrk+0x32>

0000000080002c90 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c90:	7139                	addi	sp,sp,-64
    80002c92:	fc06                	sd	ra,56(sp)
    80002c94:	f822                	sd	s0,48(sp)
    80002c96:	f426                	sd	s1,40(sp)
    80002c98:	f04a                	sd	s2,32(sp)
    80002c9a:	ec4e                	sd	s3,24(sp)
    80002c9c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002c9e:	fcc40593          	addi	a1,s0,-52
    80002ca2:	4501                	li	a0,0
    80002ca4:	00000097          	auipc	ra,0x0
    80002ca8:	e3e080e7          	jalr	-450(ra) # 80002ae2 <argint>
  acquire(&tickslock);
    80002cac:	00014517          	auipc	a0,0x14
    80002cb0:	cf450513          	addi	a0,a0,-780 # 800169a0 <tickslock>
    80002cb4:	ffffe097          	auipc	ra,0xffffe
    80002cb8:	f22080e7          	jalr	-222(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002cbc:	00006917          	auipc	s2,0x6
    80002cc0:	c4492903          	lw	s2,-956(s2) # 80008900 <ticks>
  while(ticks - ticks0 < n){
    80002cc4:	fcc42783          	lw	a5,-52(s0)
    80002cc8:	cf9d                	beqz	a5,80002d06 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002cca:	00014997          	auipc	s3,0x14
    80002cce:	cd698993          	addi	s3,s3,-810 # 800169a0 <tickslock>
    80002cd2:	00006497          	auipc	s1,0x6
    80002cd6:	c2e48493          	addi	s1,s1,-978 # 80008900 <ticks>
    if(killed(myproc())){
    80002cda:	fffff097          	auipc	ra,0xfffff
    80002cde:	cf2080e7          	jalr	-782(ra) # 800019cc <myproc>
    80002ce2:	fffff097          	auipc	ra,0xfffff
    80002ce6:	63a080e7          	jalr	1594(ra) # 8000231c <killed>
    80002cea:	ed15                	bnez	a0,80002d26 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002cec:	85ce                	mv	a1,s3
    80002cee:	8526                	mv	a0,s1
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	384080e7          	jalr	900(ra) # 80002074 <sleep>
  while(ticks - ticks0 < n){
    80002cf8:	409c                	lw	a5,0(s1)
    80002cfa:	412787bb          	subw	a5,a5,s2
    80002cfe:	fcc42703          	lw	a4,-52(s0)
    80002d02:	fce7ece3          	bltu	a5,a4,80002cda <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d06:	00014517          	auipc	a0,0x14
    80002d0a:	c9a50513          	addi	a0,a0,-870 # 800169a0 <tickslock>
    80002d0e:	ffffe097          	auipc	ra,0xffffe
    80002d12:	f7c080e7          	jalr	-132(ra) # 80000c8a <release>
  return 0;
    80002d16:	4501                	li	a0,0
}
    80002d18:	70e2                	ld	ra,56(sp)
    80002d1a:	7442                	ld	s0,48(sp)
    80002d1c:	74a2                	ld	s1,40(sp)
    80002d1e:	7902                	ld	s2,32(sp)
    80002d20:	69e2                	ld	s3,24(sp)
    80002d22:	6121                	addi	sp,sp,64
    80002d24:	8082                	ret
      release(&tickslock);
    80002d26:	00014517          	auipc	a0,0x14
    80002d2a:	c7a50513          	addi	a0,a0,-902 # 800169a0 <tickslock>
    80002d2e:	ffffe097          	auipc	ra,0xffffe
    80002d32:	f5c080e7          	jalr	-164(ra) # 80000c8a <release>
      return -1;
    80002d36:	557d                	li	a0,-1
    80002d38:	b7c5                	j	80002d18 <sys_sleep+0x88>

0000000080002d3a <sys_kill>:

uint64
sys_kill(void)
{
    80002d3a:	1101                	addi	sp,sp,-32
    80002d3c:	ec06                	sd	ra,24(sp)
    80002d3e:	e822                	sd	s0,16(sp)
    80002d40:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002d42:	fec40593          	addi	a1,s0,-20
    80002d46:	4501                	li	a0,0
    80002d48:	00000097          	auipc	ra,0x0
    80002d4c:	d9a080e7          	jalr	-614(ra) # 80002ae2 <argint>
  return kill(pid);
    80002d50:	fec42503          	lw	a0,-20(s0)
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	52a080e7          	jalr	1322(ra) # 8000227e <kill>
}
    80002d5c:	60e2                	ld	ra,24(sp)
    80002d5e:	6442                	ld	s0,16(sp)
    80002d60:	6105                	addi	sp,sp,32
    80002d62:	8082                	ret

0000000080002d64 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d64:	1101                	addi	sp,sp,-32
    80002d66:	ec06                	sd	ra,24(sp)
    80002d68:	e822                	sd	s0,16(sp)
    80002d6a:	e426                	sd	s1,8(sp)
    80002d6c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d6e:	00014517          	auipc	a0,0x14
    80002d72:	c3250513          	addi	a0,a0,-974 # 800169a0 <tickslock>
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	e60080e7          	jalr	-416(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002d7e:	00006497          	auipc	s1,0x6
    80002d82:	b824a483          	lw	s1,-1150(s1) # 80008900 <ticks>
  release(&tickslock);
    80002d86:	00014517          	auipc	a0,0x14
    80002d8a:	c1a50513          	addi	a0,a0,-998 # 800169a0 <tickslock>
    80002d8e:	ffffe097          	auipc	ra,0xffffe
    80002d92:	efc080e7          	jalr	-260(ra) # 80000c8a <release>
  return xticks;
}
    80002d96:	02049513          	slli	a0,s1,0x20
    80002d9a:	9101                	srli	a0,a0,0x20
    80002d9c:	60e2                	ld	ra,24(sp)
    80002d9e:	6442                	ld	s0,16(sp)
    80002da0:	64a2                	ld	s1,8(sp)
    80002da2:	6105                	addi	sp,sp,32
    80002da4:	8082                	ret

0000000080002da6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002da6:	7179                	addi	sp,sp,-48
    80002da8:	f406                	sd	ra,40(sp)
    80002daa:	f022                	sd	s0,32(sp)
    80002dac:	ec26                	sd	s1,24(sp)
    80002dae:	e84a                	sd	s2,16(sp)
    80002db0:	e44e                	sd	s3,8(sp)
    80002db2:	e052                	sd	s4,0(sp)
    80002db4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002db6:	00005597          	auipc	a1,0x5
    80002dba:	76258593          	addi	a1,a1,1890 # 80008518 <syscalls+0xb0>
    80002dbe:	00014517          	auipc	a0,0x14
    80002dc2:	bfa50513          	addi	a0,a0,-1030 # 800169b8 <bcache>
    80002dc6:	ffffe097          	auipc	ra,0xffffe
    80002dca:	d80080e7          	jalr	-640(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002dce:	0001c797          	auipc	a5,0x1c
    80002dd2:	bea78793          	addi	a5,a5,-1046 # 8001e9b8 <bcache+0x8000>
    80002dd6:	0001c717          	auipc	a4,0x1c
    80002dda:	e4a70713          	addi	a4,a4,-438 # 8001ec20 <bcache+0x8268>
    80002dde:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002de2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002de6:	00014497          	auipc	s1,0x14
    80002dea:	bea48493          	addi	s1,s1,-1046 # 800169d0 <bcache+0x18>
    b->next = bcache.head.next;
    80002dee:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002df0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002df2:	00005a17          	auipc	s4,0x5
    80002df6:	72ea0a13          	addi	s4,s4,1838 # 80008520 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002dfa:	2b893783          	ld	a5,696(s2)
    80002dfe:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e00:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e04:	85d2                	mv	a1,s4
    80002e06:	01048513          	addi	a0,s1,16
    80002e0a:	00001097          	auipc	ra,0x1
    80002e0e:	4c8080e7          	jalr	1224(ra) # 800042d2 <initsleeplock>
    bcache.head.next->prev = b;
    80002e12:	2b893783          	ld	a5,696(s2)
    80002e16:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e18:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e1c:	45848493          	addi	s1,s1,1112
    80002e20:	fd349de3          	bne	s1,s3,80002dfa <binit+0x54>
  }
}
    80002e24:	70a2                	ld	ra,40(sp)
    80002e26:	7402                	ld	s0,32(sp)
    80002e28:	64e2                	ld	s1,24(sp)
    80002e2a:	6942                	ld	s2,16(sp)
    80002e2c:	69a2                	ld	s3,8(sp)
    80002e2e:	6a02                	ld	s4,0(sp)
    80002e30:	6145                	addi	sp,sp,48
    80002e32:	8082                	ret

0000000080002e34 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e34:	7179                	addi	sp,sp,-48
    80002e36:	f406                	sd	ra,40(sp)
    80002e38:	f022                	sd	s0,32(sp)
    80002e3a:	ec26                	sd	s1,24(sp)
    80002e3c:	e84a                	sd	s2,16(sp)
    80002e3e:	e44e                	sd	s3,8(sp)
    80002e40:	1800                	addi	s0,sp,48
    80002e42:	892a                	mv	s2,a0
    80002e44:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002e46:	00014517          	auipc	a0,0x14
    80002e4a:	b7250513          	addi	a0,a0,-1166 # 800169b8 <bcache>
    80002e4e:	ffffe097          	auipc	ra,0xffffe
    80002e52:	d88080e7          	jalr	-632(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e56:	0001c497          	auipc	s1,0x1c
    80002e5a:	e1a4b483          	ld	s1,-486(s1) # 8001ec70 <bcache+0x82b8>
    80002e5e:	0001c797          	auipc	a5,0x1c
    80002e62:	dc278793          	addi	a5,a5,-574 # 8001ec20 <bcache+0x8268>
    80002e66:	02f48f63          	beq	s1,a5,80002ea4 <bread+0x70>
    80002e6a:	873e                	mv	a4,a5
    80002e6c:	a021                	j	80002e74 <bread+0x40>
    80002e6e:	68a4                	ld	s1,80(s1)
    80002e70:	02e48a63          	beq	s1,a4,80002ea4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e74:	449c                	lw	a5,8(s1)
    80002e76:	ff279ce3          	bne	a5,s2,80002e6e <bread+0x3a>
    80002e7a:	44dc                	lw	a5,12(s1)
    80002e7c:	ff3799e3          	bne	a5,s3,80002e6e <bread+0x3a>
      b->refcnt++;
    80002e80:	40bc                	lw	a5,64(s1)
    80002e82:	2785                	addiw	a5,a5,1
    80002e84:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e86:	00014517          	auipc	a0,0x14
    80002e8a:	b3250513          	addi	a0,a0,-1230 # 800169b8 <bcache>
    80002e8e:	ffffe097          	auipc	ra,0xffffe
    80002e92:	dfc080e7          	jalr	-516(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002e96:	01048513          	addi	a0,s1,16
    80002e9a:	00001097          	auipc	ra,0x1
    80002e9e:	472080e7          	jalr	1138(ra) # 8000430c <acquiresleep>
      return b;
    80002ea2:	a8b9                	j	80002f00 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ea4:	0001c497          	auipc	s1,0x1c
    80002ea8:	dc44b483          	ld	s1,-572(s1) # 8001ec68 <bcache+0x82b0>
    80002eac:	0001c797          	auipc	a5,0x1c
    80002eb0:	d7478793          	addi	a5,a5,-652 # 8001ec20 <bcache+0x8268>
    80002eb4:	00f48863          	beq	s1,a5,80002ec4 <bread+0x90>
    80002eb8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002eba:	40bc                	lw	a5,64(s1)
    80002ebc:	cf81                	beqz	a5,80002ed4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ebe:	64a4                	ld	s1,72(s1)
    80002ec0:	fee49de3          	bne	s1,a4,80002eba <bread+0x86>
  panic("bget: no buffers");
    80002ec4:	00005517          	auipc	a0,0x5
    80002ec8:	66450513          	addi	a0,a0,1636 # 80008528 <syscalls+0xc0>
    80002ecc:	ffffd097          	auipc	ra,0xffffd
    80002ed0:	674080e7          	jalr	1652(ra) # 80000540 <panic>
      b->dev = dev;
    80002ed4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002ed8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002edc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ee0:	4785                	li	a5,1
    80002ee2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ee4:	00014517          	auipc	a0,0x14
    80002ee8:	ad450513          	addi	a0,a0,-1324 # 800169b8 <bcache>
    80002eec:	ffffe097          	auipc	ra,0xffffe
    80002ef0:	d9e080e7          	jalr	-610(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002ef4:	01048513          	addi	a0,s1,16
    80002ef8:	00001097          	auipc	ra,0x1
    80002efc:	414080e7          	jalr	1044(ra) # 8000430c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f00:	409c                	lw	a5,0(s1)
    80002f02:	cb89                	beqz	a5,80002f14 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f04:	8526                	mv	a0,s1
    80002f06:	70a2                	ld	ra,40(sp)
    80002f08:	7402                	ld	s0,32(sp)
    80002f0a:	64e2                	ld	s1,24(sp)
    80002f0c:	6942                	ld	s2,16(sp)
    80002f0e:	69a2                	ld	s3,8(sp)
    80002f10:	6145                	addi	sp,sp,48
    80002f12:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f14:	4581                	li	a1,0
    80002f16:	8526                	mv	a0,s1
    80002f18:	00003097          	auipc	ra,0x3
    80002f1c:	fea080e7          	jalr	-22(ra) # 80005f02 <virtio_disk_rw>
    b->valid = 1;
    80002f20:	4785                	li	a5,1
    80002f22:	c09c                	sw	a5,0(s1)
  return b;
    80002f24:	b7c5                	j	80002f04 <bread+0xd0>

0000000080002f26 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f26:	1101                	addi	sp,sp,-32
    80002f28:	ec06                	sd	ra,24(sp)
    80002f2a:	e822                	sd	s0,16(sp)
    80002f2c:	e426                	sd	s1,8(sp)
    80002f2e:	1000                	addi	s0,sp,32
    80002f30:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f32:	0541                	addi	a0,a0,16
    80002f34:	00001097          	auipc	ra,0x1
    80002f38:	472080e7          	jalr	1138(ra) # 800043a6 <holdingsleep>
    80002f3c:	cd01                	beqz	a0,80002f54 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f3e:	4585                	li	a1,1
    80002f40:	8526                	mv	a0,s1
    80002f42:	00003097          	auipc	ra,0x3
    80002f46:	fc0080e7          	jalr	-64(ra) # 80005f02 <virtio_disk_rw>
}
    80002f4a:	60e2                	ld	ra,24(sp)
    80002f4c:	6442                	ld	s0,16(sp)
    80002f4e:	64a2                	ld	s1,8(sp)
    80002f50:	6105                	addi	sp,sp,32
    80002f52:	8082                	ret
    panic("bwrite");
    80002f54:	00005517          	auipc	a0,0x5
    80002f58:	5ec50513          	addi	a0,a0,1516 # 80008540 <syscalls+0xd8>
    80002f5c:	ffffd097          	auipc	ra,0xffffd
    80002f60:	5e4080e7          	jalr	1508(ra) # 80000540 <panic>

0000000080002f64 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f64:	1101                	addi	sp,sp,-32
    80002f66:	ec06                	sd	ra,24(sp)
    80002f68:	e822                	sd	s0,16(sp)
    80002f6a:	e426                	sd	s1,8(sp)
    80002f6c:	e04a                	sd	s2,0(sp)
    80002f6e:	1000                	addi	s0,sp,32
    80002f70:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f72:	01050913          	addi	s2,a0,16
    80002f76:	854a                	mv	a0,s2
    80002f78:	00001097          	auipc	ra,0x1
    80002f7c:	42e080e7          	jalr	1070(ra) # 800043a6 <holdingsleep>
    80002f80:	c92d                	beqz	a0,80002ff2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f82:	854a                	mv	a0,s2
    80002f84:	00001097          	auipc	ra,0x1
    80002f88:	3de080e7          	jalr	990(ra) # 80004362 <releasesleep>

  acquire(&bcache.lock);
    80002f8c:	00014517          	auipc	a0,0x14
    80002f90:	a2c50513          	addi	a0,a0,-1492 # 800169b8 <bcache>
    80002f94:	ffffe097          	auipc	ra,0xffffe
    80002f98:	c42080e7          	jalr	-958(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80002f9c:	40bc                	lw	a5,64(s1)
    80002f9e:	37fd                	addiw	a5,a5,-1
    80002fa0:	0007871b          	sext.w	a4,a5
    80002fa4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002fa6:	eb05                	bnez	a4,80002fd6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002fa8:	68bc                	ld	a5,80(s1)
    80002faa:	64b8                	ld	a4,72(s1)
    80002fac:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002fae:	64bc                	ld	a5,72(s1)
    80002fb0:	68b8                	ld	a4,80(s1)
    80002fb2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002fb4:	0001c797          	auipc	a5,0x1c
    80002fb8:	a0478793          	addi	a5,a5,-1532 # 8001e9b8 <bcache+0x8000>
    80002fbc:	2b87b703          	ld	a4,696(a5)
    80002fc0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002fc2:	0001c717          	auipc	a4,0x1c
    80002fc6:	c5e70713          	addi	a4,a4,-930 # 8001ec20 <bcache+0x8268>
    80002fca:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002fcc:	2b87b703          	ld	a4,696(a5)
    80002fd0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002fd2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002fd6:	00014517          	auipc	a0,0x14
    80002fda:	9e250513          	addi	a0,a0,-1566 # 800169b8 <bcache>
    80002fde:	ffffe097          	auipc	ra,0xffffe
    80002fe2:	cac080e7          	jalr	-852(ra) # 80000c8a <release>
}
    80002fe6:	60e2                	ld	ra,24(sp)
    80002fe8:	6442                	ld	s0,16(sp)
    80002fea:	64a2                	ld	s1,8(sp)
    80002fec:	6902                	ld	s2,0(sp)
    80002fee:	6105                	addi	sp,sp,32
    80002ff0:	8082                	ret
    panic("brelse");
    80002ff2:	00005517          	auipc	a0,0x5
    80002ff6:	55650513          	addi	a0,a0,1366 # 80008548 <syscalls+0xe0>
    80002ffa:	ffffd097          	auipc	ra,0xffffd
    80002ffe:	546080e7          	jalr	1350(ra) # 80000540 <panic>

0000000080003002 <bpin>:

void
bpin(struct buf *b) {
    80003002:	1101                	addi	sp,sp,-32
    80003004:	ec06                	sd	ra,24(sp)
    80003006:	e822                	sd	s0,16(sp)
    80003008:	e426                	sd	s1,8(sp)
    8000300a:	1000                	addi	s0,sp,32
    8000300c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000300e:	00014517          	auipc	a0,0x14
    80003012:	9aa50513          	addi	a0,a0,-1622 # 800169b8 <bcache>
    80003016:	ffffe097          	auipc	ra,0xffffe
    8000301a:	bc0080e7          	jalr	-1088(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000301e:	40bc                	lw	a5,64(s1)
    80003020:	2785                	addiw	a5,a5,1
    80003022:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003024:	00014517          	auipc	a0,0x14
    80003028:	99450513          	addi	a0,a0,-1644 # 800169b8 <bcache>
    8000302c:	ffffe097          	auipc	ra,0xffffe
    80003030:	c5e080e7          	jalr	-930(ra) # 80000c8a <release>
}
    80003034:	60e2                	ld	ra,24(sp)
    80003036:	6442                	ld	s0,16(sp)
    80003038:	64a2                	ld	s1,8(sp)
    8000303a:	6105                	addi	sp,sp,32
    8000303c:	8082                	ret

000000008000303e <bunpin>:

void
bunpin(struct buf *b) {
    8000303e:	1101                	addi	sp,sp,-32
    80003040:	ec06                	sd	ra,24(sp)
    80003042:	e822                	sd	s0,16(sp)
    80003044:	e426                	sd	s1,8(sp)
    80003046:	1000                	addi	s0,sp,32
    80003048:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000304a:	00014517          	auipc	a0,0x14
    8000304e:	96e50513          	addi	a0,a0,-1682 # 800169b8 <bcache>
    80003052:	ffffe097          	auipc	ra,0xffffe
    80003056:	b84080e7          	jalr	-1148(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000305a:	40bc                	lw	a5,64(s1)
    8000305c:	37fd                	addiw	a5,a5,-1
    8000305e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003060:	00014517          	auipc	a0,0x14
    80003064:	95850513          	addi	a0,a0,-1704 # 800169b8 <bcache>
    80003068:	ffffe097          	auipc	ra,0xffffe
    8000306c:	c22080e7          	jalr	-990(ra) # 80000c8a <release>
}
    80003070:	60e2                	ld	ra,24(sp)
    80003072:	6442                	ld	s0,16(sp)
    80003074:	64a2                	ld	s1,8(sp)
    80003076:	6105                	addi	sp,sp,32
    80003078:	8082                	ret

000000008000307a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000307a:	1101                	addi	sp,sp,-32
    8000307c:	ec06                	sd	ra,24(sp)
    8000307e:	e822                	sd	s0,16(sp)
    80003080:	e426                	sd	s1,8(sp)
    80003082:	e04a                	sd	s2,0(sp)
    80003084:	1000                	addi	s0,sp,32
    80003086:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003088:	00d5d59b          	srliw	a1,a1,0xd
    8000308c:	0001c797          	auipc	a5,0x1c
    80003090:	0087a783          	lw	a5,8(a5) # 8001f094 <sb+0x1c>
    80003094:	9dbd                	addw	a1,a1,a5
    80003096:	00000097          	auipc	ra,0x0
    8000309a:	d9e080e7          	jalr	-610(ra) # 80002e34 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000309e:	0074f713          	andi	a4,s1,7
    800030a2:	4785                	li	a5,1
    800030a4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030a8:	14ce                	slli	s1,s1,0x33
    800030aa:	90d9                	srli	s1,s1,0x36
    800030ac:	00950733          	add	a4,a0,s1
    800030b0:	05874703          	lbu	a4,88(a4)
    800030b4:	00e7f6b3          	and	a3,a5,a4
    800030b8:	c69d                	beqz	a3,800030e6 <bfree+0x6c>
    800030ba:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030bc:	94aa                	add	s1,s1,a0
    800030be:	fff7c793          	not	a5,a5
    800030c2:	8f7d                	and	a4,a4,a5
    800030c4:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800030c8:	00001097          	auipc	ra,0x1
    800030cc:	126080e7          	jalr	294(ra) # 800041ee <log_write>
  brelse(bp);
    800030d0:	854a                	mv	a0,s2
    800030d2:	00000097          	auipc	ra,0x0
    800030d6:	e92080e7          	jalr	-366(ra) # 80002f64 <brelse>
}
    800030da:	60e2                	ld	ra,24(sp)
    800030dc:	6442                	ld	s0,16(sp)
    800030de:	64a2                	ld	s1,8(sp)
    800030e0:	6902                	ld	s2,0(sp)
    800030e2:	6105                	addi	sp,sp,32
    800030e4:	8082                	ret
    panic("freeing free block");
    800030e6:	00005517          	auipc	a0,0x5
    800030ea:	46a50513          	addi	a0,a0,1130 # 80008550 <syscalls+0xe8>
    800030ee:	ffffd097          	auipc	ra,0xffffd
    800030f2:	452080e7          	jalr	1106(ra) # 80000540 <panic>

00000000800030f6 <balloc>:
{
    800030f6:	711d                	addi	sp,sp,-96
    800030f8:	ec86                	sd	ra,88(sp)
    800030fa:	e8a2                	sd	s0,80(sp)
    800030fc:	e4a6                	sd	s1,72(sp)
    800030fe:	e0ca                	sd	s2,64(sp)
    80003100:	fc4e                	sd	s3,56(sp)
    80003102:	f852                	sd	s4,48(sp)
    80003104:	f456                	sd	s5,40(sp)
    80003106:	f05a                	sd	s6,32(sp)
    80003108:	ec5e                	sd	s7,24(sp)
    8000310a:	e862                	sd	s8,16(sp)
    8000310c:	e466                	sd	s9,8(sp)
    8000310e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003110:	0001c797          	auipc	a5,0x1c
    80003114:	f6c7a783          	lw	a5,-148(a5) # 8001f07c <sb+0x4>
    80003118:	cff5                	beqz	a5,80003214 <balloc+0x11e>
    8000311a:	8baa                	mv	s7,a0
    8000311c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000311e:	0001cb17          	auipc	s6,0x1c
    80003122:	f5ab0b13          	addi	s6,s6,-166 # 8001f078 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003126:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003128:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000312a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000312c:	6c89                	lui	s9,0x2
    8000312e:	a061                	j	800031b6 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003130:	97ca                	add	a5,a5,s2
    80003132:	8e55                	or	a2,a2,a3
    80003134:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003138:	854a                	mv	a0,s2
    8000313a:	00001097          	auipc	ra,0x1
    8000313e:	0b4080e7          	jalr	180(ra) # 800041ee <log_write>
        brelse(bp);
    80003142:	854a                	mv	a0,s2
    80003144:	00000097          	auipc	ra,0x0
    80003148:	e20080e7          	jalr	-480(ra) # 80002f64 <brelse>
  bp = bread(dev, bno);
    8000314c:	85a6                	mv	a1,s1
    8000314e:	855e                	mv	a0,s7
    80003150:	00000097          	auipc	ra,0x0
    80003154:	ce4080e7          	jalr	-796(ra) # 80002e34 <bread>
    80003158:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000315a:	40000613          	li	a2,1024
    8000315e:	4581                	li	a1,0
    80003160:	05850513          	addi	a0,a0,88
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	b6e080e7          	jalr	-1170(ra) # 80000cd2 <memset>
  log_write(bp);
    8000316c:	854a                	mv	a0,s2
    8000316e:	00001097          	auipc	ra,0x1
    80003172:	080080e7          	jalr	128(ra) # 800041ee <log_write>
  brelse(bp);
    80003176:	854a                	mv	a0,s2
    80003178:	00000097          	auipc	ra,0x0
    8000317c:	dec080e7          	jalr	-532(ra) # 80002f64 <brelse>
}
    80003180:	8526                	mv	a0,s1
    80003182:	60e6                	ld	ra,88(sp)
    80003184:	6446                	ld	s0,80(sp)
    80003186:	64a6                	ld	s1,72(sp)
    80003188:	6906                	ld	s2,64(sp)
    8000318a:	79e2                	ld	s3,56(sp)
    8000318c:	7a42                	ld	s4,48(sp)
    8000318e:	7aa2                	ld	s5,40(sp)
    80003190:	7b02                	ld	s6,32(sp)
    80003192:	6be2                	ld	s7,24(sp)
    80003194:	6c42                	ld	s8,16(sp)
    80003196:	6ca2                	ld	s9,8(sp)
    80003198:	6125                	addi	sp,sp,96
    8000319a:	8082                	ret
    brelse(bp);
    8000319c:	854a                	mv	a0,s2
    8000319e:	00000097          	auipc	ra,0x0
    800031a2:	dc6080e7          	jalr	-570(ra) # 80002f64 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031a6:	015c87bb          	addw	a5,s9,s5
    800031aa:	00078a9b          	sext.w	s5,a5
    800031ae:	004b2703          	lw	a4,4(s6)
    800031b2:	06eaf163          	bgeu	s5,a4,80003214 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800031b6:	41fad79b          	sraiw	a5,s5,0x1f
    800031ba:	0137d79b          	srliw	a5,a5,0x13
    800031be:	015787bb          	addw	a5,a5,s5
    800031c2:	40d7d79b          	sraiw	a5,a5,0xd
    800031c6:	01cb2583          	lw	a1,28(s6)
    800031ca:	9dbd                	addw	a1,a1,a5
    800031cc:	855e                	mv	a0,s7
    800031ce:	00000097          	auipc	ra,0x0
    800031d2:	c66080e7          	jalr	-922(ra) # 80002e34 <bread>
    800031d6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031d8:	004b2503          	lw	a0,4(s6)
    800031dc:	000a849b          	sext.w	s1,s5
    800031e0:	8762                	mv	a4,s8
    800031e2:	faa4fde3          	bgeu	s1,a0,8000319c <balloc+0xa6>
      m = 1 << (bi % 8);
    800031e6:	00777693          	andi	a3,a4,7
    800031ea:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031ee:	41f7579b          	sraiw	a5,a4,0x1f
    800031f2:	01d7d79b          	srliw	a5,a5,0x1d
    800031f6:	9fb9                	addw	a5,a5,a4
    800031f8:	4037d79b          	sraiw	a5,a5,0x3
    800031fc:	00f90633          	add	a2,s2,a5
    80003200:	05864603          	lbu	a2,88(a2)
    80003204:	00c6f5b3          	and	a1,a3,a2
    80003208:	d585                	beqz	a1,80003130 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000320a:	2705                	addiw	a4,a4,1
    8000320c:	2485                	addiw	s1,s1,1
    8000320e:	fd471ae3          	bne	a4,s4,800031e2 <balloc+0xec>
    80003212:	b769                	j	8000319c <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003214:	00005517          	auipc	a0,0x5
    80003218:	35450513          	addi	a0,a0,852 # 80008568 <syscalls+0x100>
    8000321c:	ffffd097          	auipc	ra,0xffffd
    80003220:	36e080e7          	jalr	878(ra) # 8000058a <printf>
  return 0;
    80003224:	4481                	li	s1,0
    80003226:	bfa9                	j	80003180 <balloc+0x8a>

0000000080003228 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003228:	7179                	addi	sp,sp,-48
    8000322a:	f406                	sd	ra,40(sp)
    8000322c:	f022                	sd	s0,32(sp)
    8000322e:	ec26                	sd	s1,24(sp)
    80003230:	e84a                	sd	s2,16(sp)
    80003232:	e44e                	sd	s3,8(sp)
    80003234:	e052                	sd	s4,0(sp)
    80003236:	1800                	addi	s0,sp,48
    80003238:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000323a:	47ad                	li	a5,11
    8000323c:	02b7e863          	bltu	a5,a1,8000326c <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003240:	02059793          	slli	a5,a1,0x20
    80003244:	01e7d593          	srli	a1,a5,0x1e
    80003248:	00b504b3          	add	s1,a0,a1
    8000324c:	0504a903          	lw	s2,80(s1)
    80003250:	06091e63          	bnez	s2,800032cc <bmap+0xa4>
      addr = balloc(ip->dev);
    80003254:	4108                	lw	a0,0(a0)
    80003256:	00000097          	auipc	ra,0x0
    8000325a:	ea0080e7          	jalr	-352(ra) # 800030f6 <balloc>
    8000325e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003262:	06090563          	beqz	s2,800032cc <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003266:	0524a823          	sw	s2,80(s1)
    8000326a:	a08d                	j	800032cc <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000326c:	ff45849b          	addiw	s1,a1,-12
    80003270:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003274:	0ff00793          	li	a5,255
    80003278:	08e7e563          	bltu	a5,a4,80003302 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000327c:	08052903          	lw	s2,128(a0)
    80003280:	00091d63          	bnez	s2,8000329a <bmap+0x72>
      addr = balloc(ip->dev);
    80003284:	4108                	lw	a0,0(a0)
    80003286:	00000097          	auipc	ra,0x0
    8000328a:	e70080e7          	jalr	-400(ra) # 800030f6 <balloc>
    8000328e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003292:	02090d63          	beqz	s2,800032cc <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003296:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000329a:	85ca                	mv	a1,s2
    8000329c:	0009a503          	lw	a0,0(s3)
    800032a0:	00000097          	auipc	ra,0x0
    800032a4:	b94080e7          	jalr	-1132(ra) # 80002e34 <bread>
    800032a8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032aa:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032ae:	02049713          	slli	a4,s1,0x20
    800032b2:	01e75593          	srli	a1,a4,0x1e
    800032b6:	00b784b3          	add	s1,a5,a1
    800032ba:	0004a903          	lw	s2,0(s1)
    800032be:	02090063          	beqz	s2,800032de <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800032c2:	8552                	mv	a0,s4
    800032c4:	00000097          	auipc	ra,0x0
    800032c8:	ca0080e7          	jalr	-864(ra) # 80002f64 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032cc:	854a                	mv	a0,s2
    800032ce:	70a2                	ld	ra,40(sp)
    800032d0:	7402                	ld	s0,32(sp)
    800032d2:	64e2                	ld	s1,24(sp)
    800032d4:	6942                	ld	s2,16(sp)
    800032d6:	69a2                	ld	s3,8(sp)
    800032d8:	6a02                	ld	s4,0(sp)
    800032da:	6145                	addi	sp,sp,48
    800032dc:	8082                	ret
      addr = balloc(ip->dev);
    800032de:	0009a503          	lw	a0,0(s3)
    800032e2:	00000097          	auipc	ra,0x0
    800032e6:	e14080e7          	jalr	-492(ra) # 800030f6 <balloc>
    800032ea:	0005091b          	sext.w	s2,a0
      if(addr){
    800032ee:	fc090ae3          	beqz	s2,800032c2 <bmap+0x9a>
        a[bn] = addr;
    800032f2:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800032f6:	8552                	mv	a0,s4
    800032f8:	00001097          	auipc	ra,0x1
    800032fc:	ef6080e7          	jalr	-266(ra) # 800041ee <log_write>
    80003300:	b7c9                	j	800032c2 <bmap+0x9a>
  panic("bmap: out of range");
    80003302:	00005517          	auipc	a0,0x5
    80003306:	27e50513          	addi	a0,a0,638 # 80008580 <syscalls+0x118>
    8000330a:	ffffd097          	auipc	ra,0xffffd
    8000330e:	236080e7          	jalr	566(ra) # 80000540 <panic>

0000000080003312 <iget>:
{
    80003312:	7179                	addi	sp,sp,-48
    80003314:	f406                	sd	ra,40(sp)
    80003316:	f022                	sd	s0,32(sp)
    80003318:	ec26                	sd	s1,24(sp)
    8000331a:	e84a                	sd	s2,16(sp)
    8000331c:	e44e                	sd	s3,8(sp)
    8000331e:	e052                	sd	s4,0(sp)
    80003320:	1800                	addi	s0,sp,48
    80003322:	89aa                	mv	s3,a0
    80003324:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003326:	0001c517          	auipc	a0,0x1c
    8000332a:	d7250513          	addi	a0,a0,-654 # 8001f098 <itable>
    8000332e:	ffffe097          	auipc	ra,0xffffe
    80003332:	8a8080e7          	jalr	-1880(ra) # 80000bd6 <acquire>
  empty = 0;
    80003336:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003338:	0001c497          	auipc	s1,0x1c
    8000333c:	d7848493          	addi	s1,s1,-648 # 8001f0b0 <itable+0x18>
    80003340:	0001e697          	auipc	a3,0x1e
    80003344:	80068693          	addi	a3,a3,-2048 # 80020b40 <log>
    80003348:	a039                	j	80003356 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000334a:	02090b63          	beqz	s2,80003380 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000334e:	08848493          	addi	s1,s1,136
    80003352:	02d48a63          	beq	s1,a3,80003386 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003356:	449c                	lw	a5,8(s1)
    80003358:	fef059e3          	blez	a5,8000334a <iget+0x38>
    8000335c:	4098                	lw	a4,0(s1)
    8000335e:	ff3716e3          	bne	a4,s3,8000334a <iget+0x38>
    80003362:	40d8                	lw	a4,4(s1)
    80003364:	ff4713e3          	bne	a4,s4,8000334a <iget+0x38>
      ip->ref++;
    80003368:	2785                	addiw	a5,a5,1
    8000336a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000336c:	0001c517          	auipc	a0,0x1c
    80003370:	d2c50513          	addi	a0,a0,-724 # 8001f098 <itable>
    80003374:	ffffe097          	auipc	ra,0xffffe
    80003378:	916080e7          	jalr	-1770(ra) # 80000c8a <release>
      return ip;
    8000337c:	8926                	mv	s2,s1
    8000337e:	a03d                	j	800033ac <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003380:	f7f9                	bnez	a5,8000334e <iget+0x3c>
    80003382:	8926                	mv	s2,s1
    80003384:	b7e9                	j	8000334e <iget+0x3c>
  if(empty == 0)
    80003386:	02090c63          	beqz	s2,800033be <iget+0xac>
  ip->dev = dev;
    8000338a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000338e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003392:	4785                	li	a5,1
    80003394:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003398:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000339c:	0001c517          	auipc	a0,0x1c
    800033a0:	cfc50513          	addi	a0,a0,-772 # 8001f098 <itable>
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	8e6080e7          	jalr	-1818(ra) # 80000c8a <release>
}
    800033ac:	854a                	mv	a0,s2
    800033ae:	70a2                	ld	ra,40(sp)
    800033b0:	7402                	ld	s0,32(sp)
    800033b2:	64e2                	ld	s1,24(sp)
    800033b4:	6942                	ld	s2,16(sp)
    800033b6:	69a2                	ld	s3,8(sp)
    800033b8:	6a02                	ld	s4,0(sp)
    800033ba:	6145                	addi	sp,sp,48
    800033bc:	8082                	ret
    panic("iget: no inodes");
    800033be:	00005517          	auipc	a0,0x5
    800033c2:	1da50513          	addi	a0,a0,474 # 80008598 <syscalls+0x130>
    800033c6:	ffffd097          	auipc	ra,0xffffd
    800033ca:	17a080e7          	jalr	378(ra) # 80000540 <panic>

00000000800033ce <fsinit>:
fsinit(int dev) {
    800033ce:	7179                	addi	sp,sp,-48
    800033d0:	f406                	sd	ra,40(sp)
    800033d2:	f022                	sd	s0,32(sp)
    800033d4:	ec26                	sd	s1,24(sp)
    800033d6:	e84a                	sd	s2,16(sp)
    800033d8:	e44e                	sd	s3,8(sp)
    800033da:	1800                	addi	s0,sp,48
    800033dc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033de:	4585                	li	a1,1
    800033e0:	00000097          	auipc	ra,0x0
    800033e4:	a54080e7          	jalr	-1452(ra) # 80002e34 <bread>
    800033e8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033ea:	0001c997          	auipc	s3,0x1c
    800033ee:	c8e98993          	addi	s3,s3,-882 # 8001f078 <sb>
    800033f2:	02000613          	li	a2,32
    800033f6:	05850593          	addi	a1,a0,88
    800033fa:	854e                	mv	a0,s3
    800033fc:	ffffe097          	auipc	ra,0xffffe
    80003400:	932080e7          	jalr	-1742(ra) # 80000d2e <memmove>
  brelse(bp);
    80003404:	8526                	mv	a0,s1
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	b5e080e7          	jalr	-1186(ra) # 80002f64 <brelse>
  if(sb.magic != FSMAGIC)
    8000340e:	0009a703          	lw	a4,0(s3)
    80003412:	102037b7          	lui	a5,0x10203
    80003416:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000341a:	02f71263          	bne	a4,a5,8000343e <fsinit+0x70>
  initlog(dev, &sb);
    8000341e:	0001c597          	auipc	a1,0x1c
    80003422:	c5a58593          	addi	a1,a1,-934 # 8001f078 <sb>
    80003426:	854a                	mv	a0,s2
    80003428:	00001097          	auipc	ra,0x1
    8000342c:	b4a080e7          	jalr	-1206(ra) # 80003f72 <initlog>
}
    80003430:	70a2                	ld	ra,40(sp)
    80003432:	7402                	ld	s0,32(sp)
    80003434:	64e2                	ld	s1,24(sp)
    80003436:	6942                	ld	s2,16(sp)
    80003438:	69a2                	ld	s3,8(sp)
    8000343a:	6145                	addi	sp,sp,48
    8000343c:	8082                	ret
    panic("invalid file system");
    8000343e:	00005517          	auipc	a0,0x5
    80003442:	16a50513          	addi	a0,a0,362 # 800085a8 <syscalls+0x140>
    80003446:	ffffd097          	auipc	ra,0xffffd
    8000344a:	0fa080e7          	jalr	250(ra) # 80000540 <panic>

000000008000344e <iinit>:
{
    8000344e:	7179                	addi	sp,sp,-48
    80003450:	f406                	sd	ra,40(sp)
    80003452:	f022                	sd	s0,32(sp)
    80003454:	ec26                	sd	s1,24(sp)
    80003456:	e84a                	sd	s2,16(sp)
    80003458:	e44e                	sd	s3,8(sp)
    8000345a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000345c:	00005597          	auipc	a1,0x5
    80003460:	16458593          	addi	a1,a1,356 # 800085c0 <syscalls+0x158>
    80003464:	0001c517          	auipc	a0,0x1c
    80003468:	c3450513          	addi	a0,a0,-972 # 8001f098 <itable>
    8000346c:	ffffd097          	auipc	ra,0xffffd
    80003470:	6da080e7          	jalr	1754(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003474:	0001c497          	auipc	s1,0x1c
    80003478:	c4c48493          	addi	s1,s1,-948 # 8001f0c0 <itable+0x28>
    8000347c:	0001d997          	auipc	s3,0x1d
    80003480:	6d498993          	addi	s3,s3,1748 # 80020b50 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003484:	00005917          	auipc	s2,0x5
    80003488:	14490913          	addi	s2,s2,324 # 800085c8 <syscalls+0x160>
    8000348c:	85ca                	mv	a1,s2
    8000348e:	8526                	mv	a0,s1
    80003490:	00001097          	auipc	ra,0x1
    80003494:	e42080e7          	jalr	-446(ra) # 800042d2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003498:	08848493          	addi	s1,s1,136
    8000349c:	ff3498e3          	bne	s1,s3,8000348c <iinit+0x3e>
}
    800034a0:	70a2                	ld	ra,40(sp)
    800034a2:	7402                	ld	s0,32(sp)
    800034a4:	64e2                	ld	s1,24(sp)
    800034a6:	6942                	ld	s2,16(sp)
    800034a8:	69a2                	ld	s3,8(sp)
    800034aa:	6145                	addi	sp,sp,48
    800034ac:	8082                	ret

00000000800034ae <ialloc>:
{
    800034ae:	715d                	addi	sp,sp,-80
    800034b0:	e486                	sd	ra,72(sp)
    800034b2:	e0a2                	sd	s0,64(sp)
    800034b4:	fc26                	sd	s1,56(sp)
    800034b6:	f84a                	sd	s2,48(sp)
    800034b8:	f44e                	sd	s3,40(sp)
    800034ba:	f052                	sd	s4,32(sp)
    800034bc:	ec56                	sd	s5,24(sp)
    800034be:	e85a                	sd	s6,16(sp)
    800034c0:	e45e                	sd	s7,8(sp)
    800034c2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800034c4:	0001c717          	auipc	a4,0x1c
    800034c8:	bc072703          	lw	a4,-1088(a4) # 8001f084 <sb+0xc>
    800034cc:	4785                	li	a5,1
    800034ce:	04e7fa63          	bgeu	a5,a4,80003522 <ialloc+0x74>
    800034d2:	8aaa                	mv	s5,a0
    800034d4:	8bae                	mv	s7,a1
    800034d6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034d8:	0001ca17          	auipc	s4,0x1c
    800034dc:	ba0a0a13          	addi	s4,s4,-1120 # 8001f078 <sb>
    800034e0:	00048b1b          	sext.w	s6,s1
    800034e4:	0044d593          	srli	a1,s1,0x4
    800034e8:	018a2783          	lw	a5,24(s4)
    800034ec:	9dbd                	addw	a1,a1,a5
    800034ee:	8556                	mv	a0,s5
    800034f0:	00000097          	auipc	ra,0x0
    800034f4:	944080e7          	jalr	-1724(ra) # 80002e34 <bread>
    800034f8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034fa:	05850993          	addi	s3,a0,88
    800034fe:	00f4f793          	andi	a5,s1,15
    80003502:	079a                	slli	a5,a5,0x6
    80003504:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003506:	00099783          	lh	a5,0(s3)
    8000350a:	c3a1                	beqz	a5,8000354a <ialloc+0x9c>
    brelse(bp);
    8000350c:	00000097          	auipc	ra,0x0
    80003510:	a58080e7          	jalr	-1448(ra) # 80002f64 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003514:	0485                	addi	s1,s1,1
    80003516:	00ca2703          	lw	a4,12(s4)
    8000351a:	0004879b          	sext.w	a5,s1
    8000351e:	fce7e1e3          	bltu	a5,a4,800034e0 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003522:	00005517          	auipc	a0,0x5
    80003526:	0ae50513          	addi	a0,a0,174 # 800085d0 <syscalls+0x168>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	060080e7          	jalr	96(ra) # 8000058a <printf>
  return 0;
    80003532:	4501                	li	a0,0
}
    80003534:	60a6                	ld	ra,72(sp)
    80003536:	6406                	ld	s0,64(sp)
    80003538:	74e2                	ld	s1,56(sp)
    8000353a:	7942                	ld	s2,48(sp)
    8000353c:	79a2                	ld	s3,40(sp)
    8000353e:	7a02                	ld	s4,32(sp)
    80003540:	6ae2                	ld	s5,24(sp)
    80003542:	6b42                	ld	s6,16(sp)
    80003544:	6ba2                	ld	s7,8(sp)
    80003546:	6161                	addi	sp,sp,80
    80003548:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000354a:	04000613          	li	a2,64
    8000354e:	4581                	li	a1,0
    80003550:	854e                	mv	a0,s3
    80003552:	ffffd097          	auipc	ra,0xffffd
    80003556:	780080e7          	jalr	1920(ra) # 80000cd2 <memset>
      dip->type = type;
    8000355a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000355e:	854a                	mv	a0,s2
    80003560:	00001097          	auipc	ra,0x1
    80003564:	c8e080e7          	jalr	-882(ra) # 800041ee <log_write>
      brelse(bp);
    80003568:	854a                	mv	a0,s2
    8000356a:	00000097          	auipc	ra,0x0
    8000356e:	9fa080e7          	jalr	-1542(ra) # 80002f64 <brelse>
      return iget(dev, inum);
    80003572:	85da                	mv	a1,s6
    80003574:	8556                	mv	a0,s5
    80003576:	00000097          	auipc	ra,0x0
    8000357a:	d9c080e7          	jalr	-612(ra) # 80003312 <iget>
    8000357e:	bf5d                	j	80003534 <ialloc+0x86>

0000000080003580 <iupdate>:
{
    80003580:	1101                	addi	sp,sp,-32
    80003582:	ec06                	sd	ra,24(sp)
    80003584:	e822                	sd	s0,16(sp)
    80003586:	e426                	sd	s1,8(sp)
    80003588:	e04a                	sd	s2,0(sp)
    8000358a:	1000                	addi	s0,sp,32
    8000358c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000358e:	415c                	lw	a5,4(a0)
    80003590:	0047d79b          	srliw	a5,a5,0x4
    80003594:	0001c597          	auipc	a1,0x1c
    80003598:	afc5a583          	lw	a1,-1284(a1) # 8001f090 <sb+0x18>
    8000359c:	9dbd                	addw	a1,a1,a5
    8000359e:	4108                	lw	a0,0(a0)
    800035a0:	00000097          	auipc	ra,0x0
    800035a4:	894080e7          	jalr	-1900(ra) # 80002e34 <bread>
    800035a8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035aa:	05850793          	addi	a5,a0,88
    800035ae:	40d8                	lw	a4,4(s1)
    800035b0:	8b3d                	andi	a4,a4,15
    800035b2:	071a                	slli	a4,a4,0x6
    800035b4:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800035b6:	04449703          	lh	a4,68(s1)
    800035ba:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800035be:	04649703          	lh	a4,70(s1)
    800035c2:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800035c6:	04849703          	lh	a4,72(s1)
    800035ca:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800035ce:	04a49703          	lh	a4,74(s1)
    800035d2:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800035d6:	44f8                	lw	a4,76(s1)
    800035d8:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035da:	03400613          	li	a2,52
    800035de:	05048593          	addi	a1,s1,80
    800035e2:	00c78513          	addi	a0,a5,12
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	748080e7          	jalr	1864(ra) # 80000d2e <memmove>
  log_write(bp);
    800035ee:	854a                	mv	a0,s2
    800035f0:	00001097          	auipc	ra,0x1
    800035f4:	bfe080e7          	jalr	-1026(ra) # 800041ee <log_write>
  brelse(bp);
    800035f8:	854a                	mv	a0,s2
    800035fa:	00000097          	auipc	ra,0x0
    800035fe:	96a080e7          	jalr	-1686(ra) # 80002f64 <brelse>
}
    80003602:	60e2                	ld	ra,24(sp)
    80003604:	6442                	ld	s0,16(sp)
    80003606:	64a2                	ld	s1,8(sp)
    80003608:	6902                	ld	s2,0(sp)
    8000360a:	6105                	addi	sp,sp,32
    8000360c:	8082                	ret

000000008000360e <idup>:
{
    8000360e:	1101                	addi	sp,sp,-32
    80003610:	ec06                	sd	ra,24(sp)
    80003612:	e822                	sd	s0,16(sp)
    80003614:	e426                	sd	s1,8(sp)
    80003616:	1000                	addi	s0,sp,32
    80003618:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000361a:	0001c517          	auipc	a0,0x1c
    8000361e:	a7e50513          	addi	a0,a0,-1410 # 8001f098 <itable>
    80003622:	ffffd097          	auipc	ra,0xffffd
    80003626:	5b4080e7          	jalr	1460(ra) # 80000bd6 <acquire>
  ip->ref++;
    8000362a:	449c                	lw	a5,8(s1)
    8000362c:	2785                	addiw	a5,a5,1
    8000362e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003630:	0001c517          	auipc	a0,0x1c
    80003634:	a6850513          	addi	a0,a0,-1432 # 8001f098 <itable>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	652080e7          	jalr	1618(ra) # 80000c8a <release>
}
    80003640:	8526                	mv	a0,s1
    80003642:	60e2                	ld	ra,24(sp)
    80003644:	6442                	ld	s0,16(sp)
    80003646:	64a2                	ld	s1,8(sp)
    80003648:	6105                	addi	sp,sp,32
    8000364a:	8082                	ret

000000008000364c <ilock>:
{
    8000364c:	1101                	addi	sp,sp,-32
    8000364e:	ec06                	sd	ra,24(sp)
    80003650:	e822                	sd	s0,16(sp)
    80003652:	e426                	sd	s1,8(sp)
    80003654:	e04a                	sd	s2,0(sp)
    80003656:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003658:	c115                	beqz	a0,8000367c <ilock+0x30>
    8000365a:	84aa                	mv	s1,a0
    8000365c:	451c                	lw	a5,8(a0)
    8000365e:	00f05f63          	blez	a5,8000367c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003662:	0541                	addi	a0,a0,16
    80003664:	00001097          	auipc	ra,0x1
    80003668:	ca8080e7          	jalr	-856(ra) # 8000430c <acquiresleep>
  if(ip->valid == 0){
    8000366c:	40bc                	lw	a5,64(s1)
    8000366e:	cf99                	beqz	a5,8000368c <ilock+0x40>
}
    80003670:	60e2                	ld	ra,24(sp)
    80003672:	6442                	ld	s0,16(sp)
    80003674:	64a2                	ld	s1,8(sp)
    80003676:	6902                	ld	s2,0(sp)
    80003678:	6105                	addi	sp,sp,32
    8000367a:	8082                	ret
    panic("ilock");
    8000367c:	00005517          	auipc	a0,0x5
    80003680:	f6c50513          	addi	a0,a0,-148 # 800085e8 <syscalls+0x180>
    80003684:	ffffd097          	auipc	ra,0xffffd
    80003688:	ebc080e7          	jalr	-324(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000368c:	40dc                	lw	a5,4(s1)
    8000368e:	0047d79b          	srliw	a5,a5,0x4
    80003692:	0001c597          	auipc	a1,0x1c
    80003696:	9fe5a583          	lw	a1,-1538(a1) # 8001f090 <sb+0x18>
    8000369a:	9dbd                	addw	a1,a1,a5
    8000369c:	4088                	lw	a0,0(s1)
    8000369e:	fffff097          	auipc	ra,0xfffff
    800036a2:	796080e7          	jalr	1942(ra) # 80002e34 <bread>
    800036a6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036a8:	05850593          	addi	a1,a0,88
    800036ac:	40dc                	lw	a5,4(s1)
    800036ae:	8bbd                	andi	a5,a5,15
    800036b0:	079a                	slli	a5,a5,0x6
    800036b2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036b4:	00059783          	lh	a5,0(a1)
    800036b8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800036bc:	00259783          	lh	a5,2(a1)
    800036c0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800036c4:	00459783          	lh	a5,4(a1)
    800036c8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036cc:	00659783          	lh	a5,6(a1)
    800036d0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036d4:	459c                	lw	a5,8(a1)
    800036d6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036d8:	03400613          	li	a2,52
    800036dc:	05b1                	addi	a1,a1,12
    800036de:	05048513          	addi	a0,s1,80
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	64c080e7          	jalr	1612(ra) # 80000d2e <memmove>
    brelse(bp);
    800036ea:	854a                	mv	a0,s2
    800036ec:	00000097          	auipc	ra,0x0
    800036f0:	878080e7          	jalr	-1928(ra) # 80002f64 <brelse>
    ip->valid = 1;
    800036f4:	4785                	li	a5,1
    800036f6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036f8:	04449783          	lh	a5,68(s1)
    800036fc:	fbb5                	bnez	a5,80003670 <ilock+0x24>
      panic("ilock: no type");
    800036fe:	00005517          	auipc	a0,0x5
    80003702:	ef250513          	addi	a0,a0,-270 # 800085f0 <syscalls+0x188>
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	e3a080e7          	jalr	-454(ra) # 80000540 <panic>

000000008000370e <iunlock>:
{
    8000370e:	1101                	addi	sp,sp,-32
    80003710:	ec06                	sd	ra,24(sp)
    80003712:	e822                	sd	s0,16(sp)
    80003714:	e426                	sd	s1,8(sp)
    80003716:	e04a                	sd	s2,0(sp)
    80003718:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000371a:	c905                	beqz	a0,8000374a <iunlock+0x3c>
    8000371c:	84aa                	mv	s1,a0
    8000371e:	01050913          	addi	s2,a0,16
    80003722:	854a                	mv	a0,s2
    80003724:	00001097          	auipc	ra,0x1
    80003728:	c82080e7          	jalr	-894(ra) # 800043a6 <holdingsleep>
    8000372c:	cd19                	beqz	a0,8000374a <iunlock+0x3c>
    8000372e:	449c                	lw	a5,8(s1)
    80003730:	00f05d63          	blez	a5,8000374a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003734:	854a                	mv	a0,s2
    80003736:	00001097          	auipc	ra,0x1
    8000373a:	c2c080e7          	jalr	-980(ra) # 80004362 <releasesleep>
}
    8000373e:	60e2                	ld	ra,24(sp)
    80003740:	6442                	ld	s0,16(sp)
    80003742:	64a2                	ld	s1,8(sp)
    80003744:	6902                	ld	s2,0(sp)
    80003746:	6105                	addi	sp,sp,32
    80003748:	8082                	ret
    panic("iunlock");
    8000374a:	00005517          	auipc	a0,0x5
    8000374e:	eb650513          	addi	a0,a0,-330 # 80008600 <syscalls+0x198>
    80003752:	ffffd097          	auipc	ra,0xffffd
    80003756:	dee080e7          	jalr	-530(ra) # 80000540 <panic>

000000008000375a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000375a:	7179                	addi	sp,sp,-48
    8000375c:	f406                	sd	ra,40(sp)
    8000375e:	f022                	sd	s0,32(sp)
    80003760:	ec26                	sd	s1,24(sp)
    80003762:	e84a                	sd	s2,16(sp)
    80003764:	e44e                	sd	s3,8(sp)
    80003766:	e052                	sd	s4,0(sp)
    80003768:	1800                	addi	s0,sp,48
    8000376a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000376c:	05050493          	addi	s1,a0,80
    80003770:	08050913          	addi	s2,a0,128
    80003774:	a021                	j	8000377c <itrunc+0x22>
    80003776:	0491                	addi	s1,s1,4
    80003778:	01248d63          	beq	s1,s2,80003792 <itrunc+0x38>
    if(ip->addrs[i]){
    8000377c:	408c                	lw	a1,0(s1)
    8000377e:	dde5                	beqz	a1,80003776 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003780:	0009a503          	lw	a0,0(s3)
    80003784:	00000097          	auipc	ra,0x0
    80003788:	8f6080e7          	jalr	-1802(ra) # 8000307a <bfree>
      ip->addrs[i] = 0;
    8000378c:	0004a023          	sw	zero,0(s1)
    80003790:	b7dd                	j	80003776 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003792:	0809a583          	lw	a1,128(s3)
    80003796:	e185                	bnez	a1,800037b6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003798:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000379c:	854e                	mv	a0,s3
    8000379e:	00000097          	auipc	ra,0x0
    800037a2:	de2080e7          	jalr	-542(ra) # 80003580 <iupdate>
}
    800037a6:	70a2                	ld	ra,40(sp)
    800037a8:	7402                	ld	s0,32(sp)
    800037aa:	64e2                	ld	s1,24(sp)
    800037ac:	6942                	ld	s2,16(sp)
    800037ae:	69a2                	ld	s3,8(sp)
    800037b0:	6a02                	ld	s4,0(sp)
    800037b2:	6145                	addi	sp,sp,48
    800037b4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037b6:	0009a503          	lw	a0,0(s3)
    800037ba:	fffff097          	auipc	ra,0xfffff
    800037be:	67a080e7          	jalr	1658(ra) # 80002e34 <bread>
    800037c2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800037c4:	05850493          	addi	s1,a0,88
    800037c8:	45850913          	addi	s2,a0,1112
    800037cc:	a021                	j	800037d4 <itrunc+0x7a>
    800037ce:	0491                	addi	s1,s1,4
    800037d0:	01248b63          	beq	s1,s2,800037e6 <itrunc+0x8c>
      if(a[j])
    800037d4:	408c                	lw	a1,0(s1)
    800037d6:	dde5                	beqz	a1,800037ce <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800037d8:	0009a503          	lw	a0,0(s3)
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	89e080e7          	jalr	-1890(ra) # 8000307a <bfree>
    800037e4:	b7ed                	j	800037ce <itrunc+0x74>
    brelse(bp);
    800037e6:	8552                	mv	a0,s4
    800037e8:	fffff097          	auipc	ra,0xfffff
    800037ec:	77c080e7          	jalr	1916(ra) # 80002f64 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037f0:	0809a583          	lw	a1,128(s3)
    800037f4:	0009a503          	lw	a0,0(s3)
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	882080e7          	jalr	-1918(ra) # 8000307a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003800:	0809a023          	sw	zero,128(s3)
    80003804:	bf51                	j	80003798 <itrunc+0x3e>

0000000080003806 <iput>:
{
    80003806:	1101                	addi	sp,sp,-32
    80003808:	ec06                	sd	ra,24(sp)
    8000380a:	e822                	sd	s0,16(sp)
    8000380c:	e426                	sd	s1,8(sp)
    8000380e:	e04a                	sd	s2,0(sp)
    80003810:	1000                	addi	s0,sp,32
    80003812:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003814:	0001c517          	auipc	a0,0x1c
    80003818:	88450513          	addi	a0,a0,-1916 # 8001f098 <itable>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	3ba080e7          	jalr	954(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003824:	4498                	lw	a4,8(s1)
    80003826:	4785                	li	a5,1
    80003828:	02f70363          	beq	a4,a5,8000384e <iput+0x48>
  ip->ref--;
    8000382c:	449c                	lw	a5,8(s1)
    8000382e:	37fd                	addiw	a5,a5,-1
    80003830:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003832:	0001c517          	auipc	a0,0x1c
    80003836:	86650513          	addi	a0,a0,-1946 # 8001f098 <itable>
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	450080e7          	jalr	1104(ra) # 80000c8a <release>
}
    80003842:	60e2                	ld	ra,24(sp)
    80003844:	6442                	ld	s0,16(sp)
    80003846:	64a2                	ld	s1,8(sp)
    80003848:	6902                	ld	s2,0(sp)
    8000384a:	6105                	addi	sp,sp,32
    8000384c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000384e:	40bc                	lw	a5,64(s1)
    80003850:	dff1                	beqz	a5,8000382c <iput+0x26>
    80003852:	04a49783          	lh	a5,74(s1)
    80003856:	fbf9                	bnez	a5,8000382c <iput+0x26>
    acquiresleep(&ip->lock);
    80003858:	01048913          	addi	s2,s1,16
    8000385c:	854a                	mv	a0,s2
    8000385e:	00001097          	auipc	ra,0x1
    80003862:	aae080e7          	jalr	-1362(ra) # 8000430c <acquiresleep>
    release(&itable.lock);
    80003866:	0001c517          	auipc	a0,0x1c
    8000386a:	83250513          	addi	a0,a0,-1998 # 8001f098 <itable>
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	41c080e7          	jalr	1052(ra) # 80000c8a <release>
    itrunc(ip);
    80003876:	8526                	mv	a0,s1
    80003878:	00000097          	auipc	ra,0x0
    8000387c:	ee2080e7          	jalr	-286(ra) # 8000375a <itrunc>
    ip->type = 0;
    80003880:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003884:	8526                	mv	a0,s1
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	cfa080e7          	jalr	-774(ra) # 80003580 <iupdate>
    ip->valid = 0;
    8000388e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003892:	854a                	mv	a0,s2
    80003894:	00001097          	auipc	ra,0x1
    80003898:	ace080e7          	jalr	-1330(ra) # 80004362 <releasesleep>
    acquire(&itable.lock);
    8000389c:	0001b517          	auipc	a0,0x1b
    800038a0:	7fc50513          	addi	a0,a0,2044 # 8001f098 <itable>
    800038a4:	ffffd097          	auipc	ra,0xffffd
    800038a8:	332080e7          	jalr	818(ra) # 80000bd6 <acquire>
    800038ac:	b741                	j	8000382c <iput+0x26>

00000000800038ae <iunlockput>:
{
    800038ae:	1101                	addi	sp,sp,-32
    800038b0:	ec06                	sd	ra,24(sp)
    800038b2:	e822                	sd	s0,16(sp)
    800038b4:	e426                	sd	s1,8(sp)
    800038b6:	1000                	addi	s0,sp,32
    800038b8:	84aa                	mv	s1,a0
  iunlock(ip);
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	e54080e7          	jalr	-428(ra) # 8000370e <iunlock>
  iput(ip);
    800038c2:	8526                	mv	a0,s1
    800038c4:	00000097          	auipc	ra,0x0
    800038c8:	f42080e7          	jalr	-190(ra) # 80003806 <iput>
}
    800038cc:	60e2                	ld	ra,24(sp)
    800038ce:	6442                	ld	s0,16(sp)
    800038d0:	64a2                	ld	s1,8(sp)
    800038d2:	6105                	addi	sp,sp,32
    800038d4:	8082                	ret

00000000800038d6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038d6:	1141                	addi	sp,sp,-16
    800038d8:	e422                	sd	s0,8(sp)
    800038da:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800038dc:	411c                	lw	a5,0(a0)
    800038de:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038e0:	415c                	lw	a5,4(a0)
    800038e2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038e4:	04451783          	lh	a5,68(a0)
    800038e8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038ec:	04a51783          	lh	a5,74(a0)
    800038f0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038f4:	04c56783          	lwu	a5,76(a0)
    800038f8:	e99c                	sd	a5,16(a1)
}
    800038fa:	6422                	ld	s0,8(sp)
    800038fc:	0141                	addi	sp,sp,16
    800038fe:	8082                	ret

0000000080003900 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003900:	457c                	lw	a5,76(a0)
    80003902:	0ed7e963          	bltu	a5,a3,800039f4 <readi+0xf4>
{
    80003906:	7159                	addi	sp,sp,-112
    80003908:	f486                	sd	ra,104(sp)
    8000390a:	f0a2                	sd	s0,96(sp)
    8000390c:	eca6                	sd	s1,88(sp)
    8000390e:	e8ca                	sd	s2,80(sp)
    80003910:	e4ce                	sd	s3,72(sp)
    80003912:	e0d2                	sd	s4,64(sp)
    80003914:	fc56                	sd	s5,56(sp)
    80003916:	f85a                	sd	s6,48(sp)
    80003918:	f45e                	sd	s7,40(sp)
    8000391a:	f062                	sd	s8,32(sp)
    8000391c:	ec66                	sd	s9,24(sp)
    8000391e:	e86a                	sd	s10,16(sp)
    80003920:	e46e                	sd	s11,8(sp)
    80003922:	1880                	addi	s0,sp,112
    80003924:	8b2a                	mv	s6,a0
    80003926:	8bae                	mv	s7,a1
    80003928:	8a32                	mv	s4,a2
    8000392a:	84b6                	mv	s1,a3
    8000392c:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000392e:	9f35                	addw	a4,a4,a3
    return 0;
    80003930:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003932:	0ad76063          	bltu	a4,a3,800039d2 <readi+0xd2>
  if(off + n > ip->size)
    80003936:	00e7f463          	bgeu	a5,a4,8000393e <readi+0x3e>
    n = ip->size - off;
    8000393a:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000393e:	0a0a8963          	beqz	s5,800039f0 <readi+0xf0>
    80003942:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003944:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003948:	5c7d                	li	s8,-1
    8000394a:	a82d                	j	80003984 <readi+0x84>
    8000394c:	020d1d93          	slli	s11,s10,0x20
    80003950:	020ddd93          	srli	s11,s11,0x20
    80003954:	05890613          	addi	a2,s2,88
    80003958:	86ee                	mv	a3,s11
    8000395a:	963a                	add	a2,a2,a4
    8000395c:	85d2                	mv	a1,s4
    8000395e:	855e                	mv	a0,s7
    80003960:	fffff097          	auipc	ra,0xfffff
    80003964:	b1c080e7          	jalr	-1252(ra) # 8000247c <either_copyout>
    80003968:	05850d63          	beq	a0,s8,800039c2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000396c:	854a                	mv	a0,s2
    8000396e:	fffff097          	auipc	ra,0xfffff
    80003972:	5f6080e7          	jalr	1526(ra) # 80002f64 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003976:	013d09bb          	addw	s3,s10,s3
    8000397a:	009d04bb          	addw	s1,s10,s1
    8000397e:	9a6e                	add	s4,s4,s11
    80003980:	0559f763          	bgeu	s3,s5,800039ce <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003984:	00a4d59b          	srliw	a1,s1,0xa
    80003988:	855a                	mv	a0,s6
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	89e080e7          	jalr	-1890(ra) # 80003228 <bmap>
    80003992:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003996:	cd85                	beqz	a1,800039ce <readi+0xce>
    bp = bread(ip->dev, addr);
    80003998:	000b2503          	lw	a0,0(s6)
    8000399c:	fffff097          	auipc	ra,0xfffff
    800039a0:	498080e7          	jalr	1176(ra) # 80002e34 <bread>
    800039a4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039a6:	3ff4f713          	andi	a4,s1,1023
    800039aa:	40ec87bb          	subw	a5,s9,a4
    800039ae:	413a86bb          	subw	a3,s5,s3
    800039b2:	8d3e                	mv	s10,a5
    800039b4:	2781                	sext.w	a5,a5
    800039b6:	0006861b          	sext.w	a2,a3
    800039ba:	f8f679e3          	bgeu	a2,a5,8000394c <readi+0x4c>
    800039be:	8d36                	mv	s10,a3
    800039c0:	b771                	j	8000394c <readi+0x4c>
      brelse(bp);
    800039c2:	854a                	mv	a0,s2
    800039c4:	fffff097          	auipc	ra,0xfffff
    800039c8:	5a0080e7          	jalr	1440(ra) # 80002f64 <brelse>
      tot = -1;
    800039cc:	59fd                	li	s3,-1
  }
  return tot;
    800039ce:	0009851b          	sext.w	a0,s3
}
    800039d2:	70a6                	ld	ra,104(sp)
    800039d4:	7406                	ld	s0,96(sp)
    800039d6:	64e6                	ld	s1,88(sp)
    800039d8:	6946                	ld	s2,80(sp)
    800039da:	69a6                	ld	s3,72(sp)
    800039dc:	6a06                	ld	s4,64(sp)
    800039de:	7ae2                	ld	s5,56(sp)
    800039e0:	7b42                	ld	s6,48(sp)
    800039e2:	7ba2                	ld	s7,40(sp)
    800039e4:	7c02                	ld	s8,32(sp)
    800039e6:	6ce2                	ld	s9,24(sp)
    800039e8:	6d42                	ld	s10,16(sp)
    800039ea:	6da2                	ld	s11,8(sp)
    800039ec:	6165                	addi	sp,sp,112
    800039ee:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039f0:	89d6                	mv	s3,s5
    800039f2:	bff1                	j	800039ce <readi+0xce>
    return 0;
    800039f4:	4501                	li	a0,0
}
    800039f6:	8082                	ret

00000000800039f8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039f8:	457c                	lw	a5,76(a0)
    800039fa:	10d7e863          	bltu	a5,a3,80003b0a <writei+0x112>
{
    800039fe:	7159                	addi	sp,sp,-112
    80003a00:	f486                	sd	ra,104(sp)
    80003a02:	f0a2                	sd	s0,96(sp)
    80003a04:	eca6                	sd	s1,88(sp)
    80003a06:	e8ca                	sd	s2,80(sp)
    80003a08:	e4ce                	sd	s3,72(sp)
    80003a0a:	e0d2                	sd	s4,64(sp)
    80003a0c:	fc56                	sd	s5,56(sp)
    80003a0e:	f85a                	sd	s6,48(sp)
    80003a10:	f45e                	sd	s7,40(sp)
    80003a12:	f062                	sd	s8,32(sp)
    80003a14:	ec66                	sd	s9,24(sp)
    80003a16:	e86a                	sd	s10,16(sp)
    80003a18:	e46e                	sd	s11,8(sp)
    80003a1a:	1880                	addi	s0,sp,112
    80003a1c:	8aaa                	mv	s5,a0
    80003a1e:	8bae                	mv	s7,a1
    80003a20:	8a32                	mv	s4,a2
    80003a22:	8936                	mv	s2,a3
    80003a24:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a26:	00e687bb          	addw	a5,a3,a4
    80003a2a:	0ed7e263          	bltu	a5,a3,80003b0e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a2e:	00043737          	lui	a4,0x43
    80003a32:	0ef76063          	bltu	a4,a5,80003b12 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a36:	0c0b0863          	beqz	s6,80003b06 <writei+0x10e>
    80003a3a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a3c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a40:	5c7d                	li	s8,-1
    80003a42:	a091                	j	80003a86 <writei+0x8e>
    80003a44:	020d1d93          	slli	s11,s10,0x20
    80003a48:	020ddd93          	srli	s11,s11,0x20
    80003a4c:	05848513          	addi	a0,s1,88
    80003a50:	86ee                	mv	a3,s11
    80003a52:	8652                	mv	a2,s4
    80003a54:	85de                	mv	a1,s7
    80003a56:	953a                	add	a0,a0,a4
    80003a58:	fffff097          	auipc	ra,0xfffff
    80003a5c:	a7a080e7          	jalr	-1414(ra) # 800024d2 <either_copyin>
    80003a60:	07850263          	beq	a0,s8,80003ac4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a64:	8526                	mv	a0,s1
    80003a66:	00000097          	auipc	ra,0x0
    80003a6a:	788080e7          	jalr	1928(ra) # 800041ee <log_write>
    brelse(bp);
    80003a6e:	8526                	mv	a0,s1
    80003a70:	fffff097          	auipc	ra,0xfffff
    80003a74:	4f4080e7          	jalr	1268(ra) # 80002f64 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a78:	013d09bb          	addw	s3,s10,s3
    80003a7c:	012d093b          	addw	s2,s10,s2
    80003a80:	9a6e                	add	s4,s4,s11
    80003a82:	0569f663          	bgeu	s3,s6,80003ace <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003a86:	00a9559b          	srliw	a1,s2,0xa
    80003a8a:	8556                	mv	a0,s5
    80003a8c:	fffff097          	auipc	ra,0xfffff
    80003a90:	79c080e7          	jalr	1948(ra) # 80003228 <bmap>
    80003a94:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a98:	c99d                	beqz	a1,80003ace <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003a9a:	000aa503          	lw	a0,0(s5)
    80003a9e:	fffff097          	auipc	ra,0xfffff
    80003aa2:	396080e7          	jalr	918(ra) # 80002e34 <bread>
    80003aa6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa8:	3ff97713          	andi	a4,s2,1023
    80003aac:	40ec87bb          	subw	a5,s9,a4
    80003ab0:	413b06bb          	subw	a3,s6,s3
    80003ab4:	8d3e                	mv	s10,a5
    80003ab6:	2781                	sext.w	a5,a5
    80003ab8:	0006861b          	sext.w	a2,a3
    80003abc:	f8f674e3          	bgeu	a2,a5,80003a44 <writei+0x4c>
    80003ac0:	8d36                	mv	s10,a3
    80003ac2:	b749                	j	80003a44 <writei+0x4c>
      brelse(bp);
    80003ac4:	8526                	mv	a0,s1
    80003ac6:	fffff097          	auipc	ra,0xfffff
    80003aca:	49e080e7          	jalr	1182(ra) # 80002f64 <brelse>
  }

  if(off > ip->size)
    80003ace:	04caa783          	lw	a5,76(s5)
    80003ad2:	0127f463          	bgeu	a5,s2,80003ada <writei+0xe2>
    ip->size = off;
    80003ad6:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ada:	8556                	mv	a0,s5
    80003adc:	00000097          	auipc	ra,0x0
    80003ae0:	aa4080e7          	jalr	-1372(ra) # 80003580 <iupdate>

  return tot;
    80003ae4:	0009851b          	sext.w	a0,s3
}
    80003ae8:	70a6                	ld	ra,104(sp)
    80003aea:	7406                	ld	s0,96(sp)
    80003aec:	64e6                	ld	s1,88(sp)
    80003aee:	6946                	ld	s2,80(sp)
    80003af0:	69a6                	ld	s3,72(sp)
    80003af2:	6a06                	ld	s4,64(sp)
    80003af4:	7ae2                	ld	s5,56(sp)
    80003af6:	7b42                	ld	s6,48(sp)
    80003af8:	7ba2                	ld	s7,40(sp)
    80003afa:	7c02                	ld	s8,32(sp)
    80003afc:	6ce2                	ld	s9,24(sp)
    80003afe:	6d42                	ld	s10,16(sp)
    80003b00:	6da2                	ld	s11,8(sp)
    80003b02:	6165                	addi	sp,sp,112
    80003b04:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b06:	89da                	mv	s3,s6
    80003b08:	bfc9                	j	80003ada <writei+0xe2>
    return -1;
    80003b0a:	557d                	li	a0,-1
}
    80003b0c:	8082                	ret
    return -1;
    80003b0e:	557d                	li	a0,-1
    80003b10:	bfe1                	j	80003ae8 <writei+0xf0>
    return -1;
    80003b12:	557d                	li	a0,-1
    80003b14:	bfd1                	j	80003ae8 <writei+0xf0>

0000000080003b16 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b16:	1141                	addi	sp,sp,-16
    80003b18:	e406                	sd	ra,8(sp)
    80003b1a:	e022                	sd	s0,0(sp)
    80003b1c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b1e:	4639                	li	a2,14
    80003b20:	ffffd097          	auipc	ra,0xffffd
    80003b24:	282080e7          	jalr	642(ra) # 80000da2 <strncmp>
}
    80003b28:	60a2                	ld	ra,8(sp)
    80003b2a:	6402                	ld	s0,0(sp)
    80003b2c:	0141                	addi	sp,sp,16
    80003b2e:	8082                	ret

0000000080003b30 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b30:	7139                	addi	sp,sp,-64
    80003b32:	fc06                	sd	ra,56(sp)
    80003b34:	f822                	sd	s0,48(sp)
    80003b36:	f426                	sd	s1,40(sp)
    80003b38:	f04a                	sd	s2,32(sp)
    80003b3a:	ec4e                	sd	s3,24(sp)
    80003b3c:	e852                	sd	s4,16(sp)
    80003b3e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b40:	04451703          	lh	a4,68(a0)
    80003b44:	4785                	li	a5,1
    80003b46:	00f71a63          	bne	a4,a5,80003b5a <dirlookup+0x2a>
    80003b4a:	892a                	mv	s2,a0
    80003b4c:	89ae                	mv	s3,a1
    80003b4e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b50:	457c                	lw	a5,76(a0)
    80003b52:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b54:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b56:	e79d                	bnez	a5,80003b84 <dirlookup+0x54>
    80003b58:	a8a5                	j	80003bd0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b5a:	00005517          	auipc	a0,0x5
    80003b5e:	aae50513          	addi	a0,a0,-1362 # 80008608 <syscalls+0x1a0>
    80003b62:	ffffd097          	auipc	ra,0xffffd
    80003b66:	9de080e7          	jalr	-1570(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003b6a:	00005517          	auipc	a0,0x5
    80003b6e:	ab650513          	addi	a0,a0,-1354 # 80008620 <syscalls+0x1b8>
    80003b72:	ffffd097          	auipc	ra,0xffffd
    80003b76:	9ce080e7          	jalr	-1586(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b7a:	24c1                	addiw	s1,s1,16
    80003b7c:	04c92783          	lw	a5,76(s2)
    80003b80:	04f4f763          	bgeu	s1,a5,80003bce <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b84:	4741                	li	a4,16
    80003b86:	86a6                	mv	a3,s1
    80003b88:	fc040613          	addi	a2,s0,-64
    80003b8c:	4581                	li	a1,0
    80003b8e:	854a                	mv	a0,s2
    80003b90:	00000097          	auipc	ra,0x0
    80003b94:	d70080e7          	jalr	-656(ra) # 80003900 <readi>
    80003b98:	47c1                	li	a5,16
    80003b9a:	fcf518e3          	bne	a0,a5,80003b6a <dirlookup+0x3a>
    if(de.inum == 0)
    80003b9e:	fc045783          	lhu	a5,-64(s0)
    80003ba2:	dfe1                	beqz	a5,80003b7a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ba4:	fc240593          	addi	a1,s0,-62
    80003ba8:	854e                	mv	a0,s3
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	f6c080e7          	jalr	-148(ra) # 80003b16 <namecmp>
    80003bb2:	f561                	bnez	a0,80003b7a <dirlookup+0x4a>
      if(poff)
    80003bb4:	000a0463          	beqz	s4,80003bbc <dirlookup+0x8c>
        *poff = off;
    80003bb8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003bbc:	fc045583          	lhu	a1,-64(s0)
    80003bc0:	00092503          	lw	a0,0(s2)
    80003bc4:	fffff097          	auipc	ra,0xfffff
    80003bc8:	74e080e7          	jalr	1870(ra) # 80003312 <iget>
    80003bcc:	a011                	j	80003bd0 <dirlookup+0xa0>
  return 0;
    80003bce:	4501                	li	a0,0
}
    80003bd0:	70e2                	ld	ra,56(sp)
    80003bd2:	7442                	ld	s0,48(sp)
    80003bd4:	74a2                	ld	s1,40(sp)
    80003bd6:	7902                	ld	s2,32(sp)
    80003bd8:	69e2                	ld	s3,24(sp)
    80003bda:	6a42                	ld	s4,16(sp)
    80003bdc:	6121                	addi	sp,sp,64
    80003bde:	8082                	ret

0000000080003be0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003be0:	711d                	addi	sp,sp,-96
    80003be2:	ec86                	sd	ra,88(sp)
    80003be4:	e8a2                	sd	s0,80(sp)
    80003be6:	e4a6                	sd	s1,72(sp)
    80003be8:	e0ca                	sd	s2,64(sp)
    80003bea:	fc4e                	sd	s3,56(sp)
    80003bec:	f852                	sd	s4,48(sp)
    80003bee:	f456                	sd	s5,40(sp)
    80003bf0:	f05a                	sd	s6,32(sp)
    80003bf2:	ec5e                	sd	s7,24(sp)
    80003bf4:	e862                	sd	s8,16(sp)
    80003bf6:	e466                	sd	s9,8(sp)
    80003bf8:	e06a                	sd	s10,0(sp)
    80003bfa:	1080                	addi	s0,sp,96
    80003bfc:	84aa                	mv	s1,a0
    80003bfe:	8b2e                	mv	s6,a1
    80003c00:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c02:	00054703          	lbu	a4,0(a0)
    80003c06:	02f00793          	li	a5,47
    80003c0a:	02f70363          	beq	a4,a5,80003c30 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c0e:	ffffe097          	auipc	ra,0xffffe
    80003c12:	dbe080e7          	jalr	-578(ra) # 800019cc <myproc>
    80003c16:	15053503          	ld	a0,336(a0)
    80003c1a:	00000097          	auipc	ra,0x0
    80003c1e:	9f4080e7          	jalr	-1548(ra) # 8000360e <idup>
    80003c22:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003c24:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003c28:	4cb5                	li	s9,13
  len = path - s;
    80003c2a:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c2c:	4c05                	li	s8,1
    80003c2e:	a87d                	j	80003cec <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003c30:	4585                	li	a1,1
    80003c32:	4505                	li	a0,1
    80003c34:	fffff097          	auipc	ra,0xfffff
    80003c38:	6de080e7          	jalr	1758(ra) # 80003312 <iget>
    80003c3c:	8a2a                	mv	s4,a0
    80003c3e:	b7dd                	j	80003c24 <namex+0x44>
      iunlockput(ip);
    80003c40:	8552                	mv	a0,s4
    80003c42:	00000097          	auipc	ra,0x0
    80003c46:	c6c080e7          	jalr	-916(ra) # 800038ae <iunlockput>
      return 0;
    80003c4a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c4c:	8552                	mv	a0,s4
    80003c4e:	60e6                	ld	ra,88(sp)
    80003c50:	6446                	ld	s0,80(sp)
    80003c52:	64a6                	ld	s1,72(sp)
    80003c54:	6906                	ld	s2,64(sp)
    80003c56:	79e2                	ld	s3,56(sp)
    80003c58:	7a42                	ld	s4,48(sp)
    80003c5a:	7aa2                	ld	s5,40(sp)
    80003c5c:	7b02                	ld	s6,32(sp)
    80003c5e:	6be2                	ld	s7,24(sp)
    80003c60:	6c42                	ld	s8,16(sp)
    80003c62:	6ca2                	ld	s9,8(sp)
    80003c64:	6d02                	ld	s10,0(sp)
    80003c66:	6125                	addi	sp,sp,96
    80003c68:	8082                	ret
      iunlock(ip);
    80003c6a:	8552                	mv	a0,s4
    80003c6c:	00000097          	auipc	ra,0x0
    80003c70:	aa2080e7          	jalr	-1374(ra) # 8000370e <iunlock>
      return ip;
    80003c74:	bfe1                	j	80003c4c <namex+0x6c>
      iunlockput(ip);
    80003c76:	8552                	mv	a0,s4
    80003c78:	00000097          	auipc	ra,0x0
    80003c7c:	c36080e7          	jalr	-970(ra) # 800038ae <iunlockput>
      return 0;
    80003c80:	8a4e                	mv	s4,s3
    80003c82:	b7e9                	j	80003c4c <namex+0x6c>
  len = path - s;
    80003c84:	40998633          	sub	a2,s3,s1
    80003c88:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003c8c:	09acd863          	bge	s9,s10,80003d1c <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003c90:	4639                	li	a2,14
    80003c92:	85a6                	mv	a1,s1
    80003c94:	8556                	mv	a0,s5
    80003c96:	ffffd097          	auipc	ra,0xffffd
    80003c9a:	098080e7          	jalr	152(ra) # 80000d2e <memmove>
    80003c9e:	84ce                	mv	s1,s3
  while(*path == '/')
    80003ca0:	0004c783          	lbu	a5,0(s1)
    80003ca4:	01279763          	bne	a5,s2,80003cb2 <namex+0xd2>
    path++;
    80003ca8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003caa:	0004c783          	lbu	a5,0(s1)
    80003cae:	ff278de3          	beq	a5,s2,80003ca8 <namex+0xc8>
    ilock(ip);
    80003cb2:	8552                	mv	a0,s4
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	998080e7          	jalr	-1640(ra) # 8000364c <ilock>
    if(ip->type != T_DIR){
    80003cbc:	044a1783          	lh	a5,68(s4)
    80003cc0:	f98790e3          	bne	a5,s8,80003c40 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003cc4:	000b0563          	beqz	s6,80003cce <namex+0xee>
    80003cc8:	0004c783          	lbu	a5,0(s1)
    80003ccc:	dfd9                	beqz	a5,80003c6a <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003cce:	865e                	mv	a2,s7
    80003cd0:	85d6                	mv	a1,s5
    80003cd2:	8552                	mv	a0,s4
    80003cd4:	00000097          	auipc	ra,0x0
    80003cd8:	e5c080e7          	jalr	-420(ra) # 80003b30 <dirlookup>
    80003cdc:	89aa                	mv	s3,a0
    80003cde:	dd41                	beqz	a0,80003c76 <namex+0x96>
    iunlockput(ip);
    80003ce0:	8552                	mv	a0,s4
    80003ce2:	00000097          	auipc	ra,0x0
    80003ce6:	bcc080e7          	jalr	-1076(ra) # 800038ae <iunlockput>
    ip = next;
    80003cea:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003cec:	0004c783          	lbu	a5,0(s1)
    80003cf0:	01279763          	bne	a5,s2,80003cfe <namex+0x11e>
    path++;
    80003cf4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cf6:	0004c783          	lbu	a5,0(s1)
    80003cfa:	ff278de3          	beq	a5,s2,80003cf4 <namex+0x114>
  if(*path == 0)
    80003cfe:	cb9d                	beqz	a5,80003d34 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003d00:	0004c783          	lbu	a5,0(s1)
    80003d04:	89a6                	mv	s3,s1
  len = path - s;
    80003d06:	8d5e                	mv	s10,s7
    80003d08:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d0a:	01278963          	beq	a5,s2,80003d1c <namex+0x13c>
    80003d0e:	dbbd                	beqz	a5,80003c84 <namex+0xa4>
    path++;
    80003d10:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003d12:	0009c783          	lbu	a5,0(s3)
    80003d16:	ff279ce3          	bne	a5,s2,80003d0e <namex+0x12e>
    80003d1a:	b7ad                	j	80003c84 <namex+0xa4>
    memmove(name, s, len);
    80003d1c:	2601                	sext.w	a2,a2
    80003d1e:	85a6                	mv	a1,s1
    80003d20:	8556                	mv	a0,s5
    80003d22:	ffffd097          	auipc	ra,0xffffd
    80003d26:	00c080e7          	jalr	12(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003d2a:	9d56                	add	s10,s10,s5
    80003d2c:	000d0023          	sb	zero,0(s10)
    80003d30:	84ce                	mv	s1,s3
    80003d32:	b7bd                	j	80003ca0 <namex+0xc0>
  if(nameiparent){
    80003d34:	f00b0ce3          	beqz	s6,80003c4c <namex+0x6c>
    iput(ip);
    80003d38:	8552                	mv	a0,s4
    80003d3a:	00000097          	auipc	ra,0x0
    80003d3e:	acc080e7          	jalr	-1332(ra) # 80003806 <iput>
    return 0;
    80003d42:	4a01                	li	s4,0
    80003d44:	b721                	j	80003c4c <namex+0x6c>

0000000080003d46 <dirlink>:
{
    80003d46:	7139                	addi	sp,sp,-64
    80003d48:	fc06                	sd	ra,56(sp)
    80003d4a:	f822                	sd	s0,48(sp)
    80003d4c:	f426                	sd	s1,40(sp)
    80003d4e:	f04a                	sd	s2,32(sp)
    80003d50:	ec4e                	sd	s3,24(sp)
    80003d52:	e852                	sd	s4,16(sp)
    80003d54:	0080                	addi	s0,sp,64
    80003d56:	892a                	mv	s2,a0
    80003d58:	8a2e                	mv	s4,a1
    80003d5a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d5c:	4601                	li	a2,0
    80003d5e:	00000097          	auipc	ra,0x0
    80003d62:	dd2080e7          	jalr	-558(ra) # 80003b30 <dirlookup>
    80003d66:	e93d                	bnez	a0,80003ddc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d68:	04c92483          	lw	s1,76(s2)
    80003d6c:	c49d                	beqz	s1,80003d9a <dirlink+0x54>
    80003d6e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d70:	4741                	li	a4,16
    80003d72:	86a6                	mv	a3,s1
    80003d74:	fc040613          	addi	a2,s0,-64
    80003d78:	4581                	li	a1,0
    80003d7a:	854a                	mv	a0,s2
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	b84080e7          	jalr	-1148(ra) # 80003900 <readi>
    80003d84:	47c1                	li	a5,16
    80003d86:	06f51163          	bne	a0,a5,80003de8 <dirlink+0xa2>
    if(de.inum == 0)
    80003d8a:	fc045783          	lhu	a5,-64(s0)
    80003d8e:	c791                	beqz	a5,80003d9a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d90:	24c1                	addiw	s1,s1,16
    80003d92:	04c92783          	lw	a5,76(s2)
    80003d96:	fcf4ede3          	bltu	s1,a5,80003d70 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d9a:	4639                	li	a2,14
    80003d9c:	85d2                	mv	a1,s4
    80003d9e:	fc240513          	addi	a0,s0,-62
    80003da2:	ffffd097          	auipc	ra,0xffffd
    80003da6:	03c080e7          	jalr	60(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003daa:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dae:	4741                	li	a4,16
    80003db0:	86a6                	mv	a3,s1
    80003db2:	fc040613          	addi	a2,s0,-64
    80003db6:	4581                	li	a1,0
    80003db8:	854a                	mv	a0,s2
    80003dba:	00000097          	auipc	ra,0x0
    80003dbe:	c3e080e7          	jalr	-962(ra) # 800039f8 <writei>
    80003dc2:	1541                	addi	a0,a0,-16
    80003dc4:	00a03533          	snez	a0,a0
    80003dc8:	40a00533          	neg	a0,a0
}
    80003dcc:	70e2                	ld	ra,56(sp)
    80003dce:	7442                	ld	s0,48(sp)
    80003dd0:	74a2                	ld	s1,40(sp)
    80003dd2:	7902                	ld	s2,32(sp)
    80003dd4:	69e2                	ld	s3,24(sp)
    80003dd6:	6a42                	ld	s4,16(sp)
    80003dd8:	6121                	addi	sp,sp,64
    80003dda:	8082                	ret
    iput(ip);
    80003ddc:	00000097          	auipc	ra,0x0
    80003de0:	a2a080e7          	jalr	-1494(ra) # 80003806 <iput>
    return -1;
    80003de4:	557d                	li	a0,-1
    80003de6:	b7dd                	j	80003dcc <dirlink+0x86>
      panic("dirlink read");
    80003de8:	00005517          	auipc	a0,0x5
    80003dec:	84850513          	addi	a0,a0,-1976 # 80008630 <syscalls+0x1c8>
    80003df0:	ffffc097          	auipc	ra,0xffffc
    80003df4:	750080e7          	jalr	1872(ra) # 80000540 <panic>

0000000080003df8 <namei>:

struct inode*
namei(char *path)
{
    80003df8:	1101                	addi	sp,sp,-32
    80003dfa:	ec06                	sd	ra,24(sp)
    80003dfc:	e822                	sd	s0,16(sp)
    80003dfe:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e00:	fe040613          	addi	a2,s0,-32
    80003e04:	4581                	li	a1,0
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	dda080e7          	jalr	-550(ra) # 80003be0 <namex>
}
    80003e0e:	60e2                	ld	ra,24(sp)
    80003e10:	6442                	ld	s0,16(sp)
    80003e12:	6105                	addi	sp,sp,32
    80003e14:	8082                	ret

0000000080003e16 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e16:	1141                	addi	sp,sp,-16
    80003e18:	e406                	sd	ra,8(sp)
    80003e1a:	e022                	sd	s0,0(sp)
    80003e1c:	0800                	addi	s0,sp,16
    80003e1e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e20:	4585                	li	a1,1
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	dbe080e7          	jalr	-578(ra) # 80003be0 <namex>
}
    80003e2a:	60a2                	ld	ra,8(sp)
    80003e2c:	6402                	ld	s0,0(sp)
    80003e2e:	0141                	addi	sp,sp,16
    80003e30:	8082                	ret

0000000080003e32 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e32:	1101                	addi	sp,sp,-32
    80003e34:	ec06                	sd	ra,24(sp)
    80003e36:	e822                	sd	s0,16(sp)
    80003e38:	e426                	sd	s1,8(sp)
    80003e3a:	e04a                	sd	s2,0(sp)
    80003e3c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e3e:	0001d917          	auipc	s2,0x1d
    80003e42:	d0290913          	addi	s2,s2,-766 # 80020b40 <log>
    80003e46:	01892583          	lw	a1,24(s2)
    80003e4a:	02892503          	lw	a0,40(s2)
    80003e4e:	fffff097          	auipc	ra,0xfffff
    80003e52:	fe6080e7          	jalr	-26(ra) # 80002e34 <bread>
    80003e56:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e58:	02c92683          	lw	a3,44(s2)
    80003e5c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e5e:	02d05863          	blez	a3,80003e8e <write_head+0x5c>
    80003e62:	0001d797          	auipc	a5,0x1d
    80003e66:	d0e78793          	addi	a5,a5,-754 # 80020b70 <log+0x30>
    80003e6a:	05c50713          	addi	a4,a0,92
    80003e6e:	36fd                	addiw	a3,a3,-1
    80003e70:	02069613          	slli	a2,a3,0x20
    80003e74:	01e65693          	srli	a3,a2,0x1e
    80003e78:	0001d617          	auipc	a2,0x1d
    80003e7c:	cfc60613          	addi	a2,a2,-772 # 80020b74 <log+0x34>
    80003e80:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e82:	4390                	lw	a2,0(a5)
    80003e84:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e86:	0791                	addi	a5,a5,4
    80003e88:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003e8a:	fed79ce3          	bne	a5,a3,80003e82 <write_head+0x50>
  }
  bwrite(buf);
    80003e8e:	8526                	mv	a0,s1
    80003e90:	fffff097          	auipc	ra,0xfffff
    80003e94:	096080e7          	jalr	150(ra) # 80002f26 <bwrite>
  brelse(buf);
    80003e98:	8526                	mv	a0,s1
    80003e9a:	fffff097          	auipc	ra,0xfffff
    80003e9e:	0ca080e7          	jalr	202(ra) # 80002f64 <brelse>
}
    80003ea2:	60e2                	ld	ra,24(sp)
    80003ea4:	6442                	ld	s0,16(sp)
    80003ea6:	64a2                	ld	s1,8(sp)
    80003ea8:	6902                	ld	s2,0(sp)
    80003eaa:	6105                	addi	sp,sp,32
    80003eac:	8082                	ret

0000000080003eae <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eae:	0001d797          	auipc	a5,0x1d
    80003eb2:	cbe7a783          	lw	a5,-834(a5) # 80020b6c <log+0x2c>
    80003eb6:	0af05d63          	blez	a5,80003f70 <install_trans+0xc2>
{
    80003eba:	7139                	addi	sp,sp,-64
    80003ebc:	fc06                	sd	ra,56(sp)
    80003ebe:	f822                	sd	s0,48(sp)
    80003ec0:	f426                	sd	s1,40(sp)
    80003ec2:	f04a                	sd	s2,32(sp)
    80003ec4:	ec4e                	sd	s3,24(sp)
    80003ec6:	e852                	sd	s4,16(sp)
    80003ec8:	e456                	sd	s5,8(sp)
    80003eca:	e05a                	sd	s6,0(sp)
    80003ecc:	0080                	addi	s0,sp,64
    80003ece:	8b2a                	mv	s6,a0
    80003ed0:	0001da97          	auipc	s5,0x1d
    80003ed4:	ca0a8a93          	addi	s5,s5,-864 # 80020b70 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ed8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003eda:	0001d997          	auipc	s3,0x1d
    80003ede:	c6698993          	addi	s3,s3,-922 # 80020b40 <log>
    80003ee2:	a00d                	j	80003f04 <install_trans+0x56>
    brelse(lbuf);
    80003ee4:	854a                	mv	a0,s2
    80003ee6:	fffff097          	auipc	ra,0xfffff
    80003eea:	07e080e7          	jalr	126(ra) # 80002f64 <brelse>
    brelse(dbuf);
    80003eee:	8526                	mv	a0,s1
    80003ef0:	fffff097          	auipc	ra,0xfffff
    80003ef4:	074080e7          	jalr	116(ra) # 80002f64 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ef8:	2a05                	addiw	s4,s4,1
    80003efa:	0a91                	addi	s5,s5,4
    80003efc:	02c9a783          	lw	a5,44(s3)
    80003f00:	04fa5e63          	bge	s4,a5,80003f5c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f04:	0189a583          	lw	a1,24(s3)
    80003f08:	014585bb          	addw	a1,a1,s4
    80003f0c:	2585                	addiw	a1,a1,1
    80003f0e:	0289a503          	lw	a0,40(s3)
    80003f12:	fffff097          	auipc	ra,0xfffff
    80003f16:	f22080e7          	jalr	-222(ra) # 80002e34 <bread>
    80003f1a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f1c:	000aa583          	lw	a1,0(s5)
    80003f20:	0289a503          	lw	a0,40(s3)
    80003f24:	fffff097          	auipc	ra,0xfffff
    80003f28:	f10080e7          	jalr	-240(ra) # 80002e34 <bread>
    80003f2c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f2e:	40000613          	li	a2,1024
    80003f32:	05890593          	addi	a1,s2,88
    80003f36:	05850513          	addi	a0,a0,88
    80003f3a:	ffffd097          	auipc	ra,0xffffd
    80003f3e:	df4080e7          	jalr	-524(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f42:	8526                	mv	a0,s1
    80003f44:	fffff097          	auipc	ra,0xfffff
    80003f48:	fe2080e7          	jalr	-30(ra) # 80002f26 <bwrite>
    if(recovering == 0)
    80003f4c:	f80b1ce3          	bnez	s6,80003ee4 <install_trans+0x36>
      bunpin(dbuf);
    80003f50:	8526                	mv	a0,s1
    80003f52:	fffff097          	auipc	ra,0xfffff
    80003f56:	0ec080e7          	jalr	236(ra) # 8000303e <bunpin>
    80003f5a:	b769                	j	80003ee4 <install_trans+0x36>
}
    80003f5c:	70e2                	ld	ra,56(sp)
    80003f5e:	7442                	ld	s0,48(sp)
    80003f60:	74a2                	ld	s1,40(sp)
    80003f62:	7902                	ld	s2,32(sp)
    80003f64:	69e2                	ld	s3,24(sp)
    80003f66:	6a42                	ld	s4,16(sp)
    80003f68:	6aa2                	ld	s5,8(sp)
    80003f6a:	6b02                	ld	s6,0(sp)
    80003f6c:	6121                	addi	sp,sp,64
    80003f6e:	8082                	ret
    80003f70:	8082                	ret

0000000080003f72 <initlog>:
{
    80003f72:	7179                	addi	sp,sp,-48
    80003f74:	f406                	sd	ra,40(sp)
    80003f76:	f022                	sd	s0,32(sp)
    80003f78:	ec26                	sd	s1,24(sp)
    80003f7a:	e84a                	sd	s2,16(sp)
    80003f7c:	e44e                	sd	s3,8(sp)
    80003f7e:	1800                	addi	s0,sp,48
    80003f80:	892a                	mv	s2,a0
    80003f82:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f84:	0001d497          	auipc	s1,0x1d
    80003f88:	bbc48493          	addi	s1,s1,-1092 # 80020b40 <log>
    80003f8c:	00004597          	auipc	a1,0x4
    80003f90:	6b458593          	addi	a1,a1,1716 # 80008640 <syscalls+0x1d8>
    80003f94:	8526                	mv	a0,s1
    80003f96:	ffffd097          	auipc	ra,0xffffd
    80003f9a:	bb0080e7          	jalr	-1104(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80003f9e:	0149a583          	lw	a1,20(s3)
    80003fa2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003fa4:	0109a783          	lw	a5,16(s3)
    80003fa8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003faa:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003fae:	854a                	mv	a0,s2
    80003fb0:	fffff097          	auipc	ra,0xfffff
    80003fb4:	e84080e7          	jalr	-380(ra) # 80002e34 <bread>
  log.lh.n = lh->n;
    80003fb8:	4d34                	lw	a3,88(a0)
    80003fba:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003fbc:	02d05663          	blez	a3,80003fe8 <initlog+0x76>
    80003fc0:	05c50793          	addi	a5,a0,92
    80003fc4:	0001d717          	auipc	a4,0x1d
    80003fc8:	bac70713          	addi	a4,a4,-1108 # 80020b70 <log+0x30>
    80003fcc:	36fd                	addiw	a3,a3,-1
    80003fce:	02069613          	slli	a2,a3,0x20
    80003fd2:	01e65693          	srli	a3,a2,0x1e
    80003fd6:	06050613          	addi	a2,a0,96
    80003fda:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80003fdc:	4390                	lw	a2,0(a5)
    80003fde:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fe0:	0791                	addi	a5,a5,4
    80003fe2:	0711                	addi	a4,a4,4
    80003fe4:	fed79ce3          	bne	a5,a3,80003fdc <initlog+0x6a>
  brelse(buf);
    80003fe8:	fffff097          	auipc	ra,0xfffff
    80003fec:	f7c080e7          	jalr	-132(ra) # 80002f64 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003ff0:	4505                	li	a0,1
    80003ff2:	00000097          	auipc	ra,0x0
    80003ff6:	ebc080e7          	jalr	-324(ra) # 80003eae <install_trans>
  log.lh.n = 0;
    80003ffa:	0001d797          	auipc	a5,0x1d
    80003ffe:	b607a923          	sw	zero,-1166(a5) # 80020b6c <log+0x2c>
  write_head(); // clear the log
    80004002:	00000097          	auipc	ra,0x0
    80004006:	e30080e7          	jalr	-464(ra) # 80003e32 <write_head>
}
    8000400a:	70a2                	ld	ra,40(sp)
    8000400c:	7402                	ld	s0,32(sp)
    8000400e:	64e2                	ld	s1,24(sp)
    80004010:	6942                	ld	s2,16(sp)
    80004012:	69a2                	ld	s3,8(sp)
    80004014:	6145                	addi	sp,sp,48
    80004016:	8082                	ret

0000000080004018 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004018:	1101                	addi	sp,sp,-32
    8000401a:	ec06                	sd	ra,24(sp)
    8000401c:	e822                	sd	s0,16(sp)
    8000401e:	e426                	sd	s1,8(sp)
    80004020:	e04a                	sd	s2,0(sp)
    80004022:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004024:	0001d517          	auipc	a0,0x1d
    80004028:	b1c50513          	addi	a0,a0,-1252 # 80020b40 <log>
    8000402c:	ffffd097          	auipc	ra,0xffffd
    80004030:	baa080e7          	jalr	-1110(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004034:	0001d497          	auipc	s1,0x1d
    80004038:	b0c48493          	addi	s1,s1,-1268 # 80020b40 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000403c:	4979                	li	s2,30
    8000403e:	a039                	j	8000404c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004040:	85a6                	mv	a1,s1
    80004042:	8526                	mv	a0,s1
    80004044:	ffffe097          	auipc	ra,0xffffe
    80004048:	030080e7          	jalr	48(ra) # 80002074 <sleep>
    if(log.committing){
    8000404c:	50dc                	lw	a5,36(s1)
    8000404e:	fbed                	bnez	a5,80004040 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004050:	5098                	lw	a4,32(s1)
    80004052:	2705                	addiw	a4,a4,1
    80004054:	0007069b          	sext.w	a3,a4
    80004058:	0027179b          	slliw	a5,a4,0x2
    8000405c:	9fb9                	addw	a5,a5,a4
    8000405e:	0017979b          	slliw	a5,a5,0x1
    80004062:	54d8                	lw	a4,44(s1)
    80004064:	9fb9                	addw	a5,a5,a4
    80004066:	00f95963          	bge	s2,a5,80004078 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000406a:	85a6                	mv	a1,s1
    8000406c:	8526                	mv	a0,s1
    8000406e:	ffffe097          	auipc	ra,0xffffe
    80004072:	006080e7          	jalr	6(ra) # 80002074 <sleep>
    80004076:	bfd9                	j	8000404c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004078:	0001d517          	auipc	a0,0x1d
    8000407c:	ac850513          	addi	a0,a0,-1336 # 80020b40 <log>
    80004080:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004082:	ffffd097          	auipc	ra,0xffffd
    80004086:	c08080e7          	jalr	-1016(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000408a:	60e2                	ld	ra,24(sp)
    8000408c:	6442                	ld	s0,16(sp)
    8000408e:	64a2                	ld	s1,8(sp)
    80004090:	6902                	ld	s2,0(sp)
    80004092:	6105                	addi	sp,sp,32
    80004094:	8082                	ret

0000000080004096 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004096:	7139                	addi	sp,sp,-64
    80004098:	fc06                	sd	ra,56(sp)
    8000409a:	f822                	sd	s0,48(sp)
    8000409c:	f426                	sd	s1,40(sp)
    8000409e:	f04a                	sd	s2,32(sp)
    800040a0:	ec4e                	sd	s3,24(sp)
    800040a2:	e852                	sd	s4,16(sp)
    800040a4:	e456                	sd	s5,8(sp)
    800040a6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040a8:	0001d497          	auipc	s1,0x1d
    800040ac:	a9848493          	addi	s1,s1,-1384 # 80020b40 <log>
    800040b0:	8526                	mv	a0,s1
    800040b2:	ffffd097          	auipc	ra,0xffffd
    800040b6:	b24080e7          	jalr	-1244(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800040ba:	509c                	lw	a5,32(s1)
    800040bc:	37fd                	addiw	a5,a5,-1
    800040be:	0007891b          	sext.w	s2,a5
    800040c2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800040c4:	50dc                	lw	a5,36(s1)
    800040c6:	e7b9                	bnez	a5,80004114 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800040c8:	04091e63          	bnez	s2,80004124 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800040cc:	0001d497          	auipc	s1,0x1d
    800040d0:	a7448493          	addi	s1,s1,-1420 # 80020b40 <log>
    800040d4:	4785                	li	a5,1
    800040d6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040d8:	8526                	mv	a0,s1
    800040da:	ffffd097          	auipc	ra,0xffffd
    800040de:	bb0080e7          	jalr	-1104(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040e2:	54dc                	lw	a5,44(s1)
    800040e4:	06f04763          	bgtz	a5,80004152 <end_op+0xbc>
    acquire(&log.lock);
    800040e8:	0001d497          	auipc	s1,0x1d
    800040ec:	a5848493          	addi	s1,s1,-1448 # 80020b40 <log>
    800040f0:	8526                	mv	a0,s1
    800040f2:	ffffd097          	auipc	ra,0xffffd
    800040f6:	ae4080e7          	jalr	-1308(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800040fa:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800040fe:	8526                	mv	a0,s1
    80004100:	ffffe097          	auipc	ra,0xffffe
    80004104:	fd8080e7          	jalr	-40(ra) # 800020d8 <wakeup>
    release(&log.lock);
    80004108:	8526                	mv	a0,s1
    8000410a:	ffffd097          	auipc	ra,0xffffd
    8000410e:	b80080e7          	jalr	-1152(ra) # 80000c8a <release>
}
    80004112:	a03d                	j	80004140 <end_op+0xaa>
    panic("log.committing");
    80004114:	00004517          	auipc	a0,0x4
    80004118:	53450513          	addi	a0,a0,1332 # 80008648 <syscalls+0x1e0>
    8000411c:	ffffc097          	auipc	ra,0xffffc
    80004120:	424080e7          	jalr	1060(ra) # 80000540 <panic>
    wakeup(&log);
    80004124:	0001d497          	auipc	s1,0x1d
    80004128:	a1c48493          	addi	s1,s1,-1508 # 80020b40 <log>
    8000412c:	8526                	mv	a0,s1
    8000412e:	ffffe097          	auipc	ra,0xffffe
    80004132:	faa080e7          	jalr	-86(ra) # 800020d8 <wakeup>
  release(&log.lock);
    80004136:	8526                	mv	a0,s1
    80004138:	ffffd097          	auipc	ra,0xffffd
    8000413c:	b52080e7          	jalr	-1198(ra) # 80000c8a <release>
}
    80004140:	70e2                	ld	ra,56(sp)
    80004142:	7442                	ld	s0,48(sp)
    80004144:	74a2                	ld	s1,40(sp)
    80004146:	7902                	ld	s2,32(sp)
    80004148:	69e2                	ld	s3,24(sp)
    8000414a:	6a42                	ld	s4,16(sp)
    8000414c:	6aa2                	ld	s5,8(sp)
    8000414e:	6121                	addi	sp,sp,64
    80004150:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004152:	0001da97          	auipc	s5,0x1d
    80004156:	a1ea8a93          	addi	s5,s5,-1506 # 80020b70 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000415a:	0001da17          	auipc	s4,0x1d
    8000415e:	9e6a0a13          	addi	s4,s4,-1562 # 80020b40 <log>
    80004162:	018a2583          	lw	a1,24(s4)
    80004166:	012585bb          	addw	a1,a1,s2
    8000416a:	2585                	addiw	a1,a1,1
    8000416c:	028a2503          	lw	a0,40(s4)
    80004170:	fffff097          	auipc	ra,0xfffff
    80004174:	cc4080e7          	jalr	-828(ra) # 80002e34 <bread>
    80004178:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000417a:	000aa583          	lw	a1,0(s5)
    8000417e:	028a2503          	lw	a0,40(s4)
    80004182:	fffff097          	auipc	ra,0xfffff
    80004186:	cb2080e7          	jalr	-846(ra) # 80002e34 <bread>
    8000418a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000418c:	40000613          	li	a2,1024
    80004190:	05850593          	addi	a1,a0,88
    80004194:	05848513          	addi	a0,s1,88
    80004198:	ffffd097          	auipc	ra,0xffffd
    8000419c:	b96080e7          	jalr	-1130(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800041a0:	8526                	mv	a0,s1
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	d84080e7          	jalr	-636(ra) # 80002f26 <bwrite>
    brelse(from);
    800041aa:	854e                	mv	a0,s3
    800041ac:	fffff097          	auipc	ra,0xfffff
    800041b0:	db8080e7          	jalr	-584(ra) # 80002f64 <brelse>
    brelse(to);
    800041b4:	8526                	mv	a0,s1
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	dae080e7          	jalr	-594(ra) # 80002f64 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041be:	2905                	addiw	s2,s2,1
    800041c0:	0a91                	addi	s5,s5,4
    800041c2:	02ca2783          	lw	a5,44(s4)
    800041c6:	f8f94ee3          	blt	s2,a5,80004162 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800041ca:	00000097          	auipc	ra,0x0
    800041ce:	c68080e7          	jalr	-920(ra) # 80003e32 <write_head>
    install_trans(0); // Now install writes to home locations
    800041d2:	4501                	li	a0,0
    800041d4:	00000097          	auipc	ra,0x0
    800041d8:	cda080e7          	jalr	-806(ra) # 80003eae <install_trans>
    log.lh.n = 0;
    800041dc:	0001d797          	auipc	a5,0x1d
    800041e0:	9807a823          	sw	zero,-1648(a5) # 80020b6c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041e4:	00000097          	auipc	ra,0x0
    800041e8:	c4e080e7          	jalr	-946(ra) # 80003e32 <write_head>
    800041ec:	bdf5                	j	800040e8 <end_op+0x52>

00000000800041ee <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800041ee:	1101                	addi	sp,sp,-32
    800041f0:	ec06                	sd	ra,24(sp)
    800041f2:	e822                	sd	s0,16(sp)
    800041f4:	e426                	sd	s1,8(sp)
    800041f6:	e04a                	sd	s2,0(sp)
    800041f8:	1000                	addi	s0,sp,32
    800041fa:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800041fc:	0001d917          	auipc	s2,0x1d
    80004200:	94490913          	addi	s2,s2,-1724 # 80020b40 <log>
    80004204:	854a                	mv	a0,s2
    80004206:	ffffd097          	auipc	ra,0xffffd
    8000420a:	9d0080e7          	jalr	-1584(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000420e:	02c92603          	lw	a2,44(s2)
    80004212:	47f5                	li	a5,29
    80004214:	06c7c563          	blt	a5,a2,8000427e <log_write+0x90>
    80004218:	0001d797          	auipc	a5,0x1d
    8000421c:	9447a783          	lw	a5,-1724(a5) # 80020b5c <log+0x1c>
    80004220:	37fd                	addiw	a5,a5,-1
    80004222:	04f65e63          	bge	a2,a5,8000427e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004226:	0001d797          	auipc	a5,0x1d
    8000422a:	93a7a783          	lw	a5,-1734(a5) # 80020b60 <log+0x20>
    8000422e:	06f05063          	blez	a5,8000428e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004232:	4781                	li	a5,0
    80004234:	06c05563          	blez	a2,8000429e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004238:	44cc                	lw	a1,12(s1)
    8000423a:	0001d717          	auipc	a4,0x1d
    8000423e:	93670713          	addi	a4,a4,-1738 # 80020b70 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004242:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004244:	4314                	lw	a3,0(a4)
    80004246:	04b68c63          	beq	a3,a1,8000429e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000424a:	2785                	addiw	a5,a5,1
    8000424c:	0711                	addi	a4,a4,4
    8000424e:	fef61be3          	bne	a2,a5,80004244 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004252:	0621                	addi	a2,a2,8
    80004254:	060a                	slli	a2,a2,0x2
    80004256:	0001d797          	auipc	a5,0x1d
    8000425a:	8ea78793          	addi	a5,a5,-1814 # 80020b40 <log>
    8000425e:	97b2                	add	a5,a5,a2
    80004260:	44d8                	lw	a4,12(s1)
    80004262:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004264:	8526                	mv	a0,s1
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	d9c080e7          	jalr	-612(ra) # 80003002 <bpin>
    log.lh.n++;
    8000426e:	0001d717          	auipc	a4,0x1d
    80004272:	8d270713          	addi	a4,a4,-1838 # 80020b40 <log>
    80004276:	575c                	lw	a5,44(a4)
    80004278:	2785                	addiw	a5,a5,1
    8000427a:	d75c                	sw	a5,44(a4)
    8000427c:	a82d                	j	800042b6 <log_write+0xc8>
    panic("too big a transaction");
    8000427e:	00004517          	auipc	a0,0x4
    80004282:	3da50513          	addi	a0,a0,986 # 80008658 <syscalls+0x1f0>
    80004286:	ffffc097          	auipc	ra,0xffffc
    8000428a:	2ba080e7          	jalr	698(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    8000428e:	00004517          	auipc	a0,0x4
    80004292:	3e250513          	addi	a0,a0,994 # 80008670 <syscalls+0x208>
    80004296:	ffffc097          	auipc	ra,0xffffc
    8000429a:	2aa080e7          	jalr	682(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    8000429e:	00878693          	addi	a3,a5,8
    800042a2:	068a                	slli	a3,a3,0x2
    800042a4:	0001d717          	auipc	a4,0x1d
    800042a8:	89c70713          	addi	a4,a4,-1892 # 80020b40 <log>
    800042ac:	9736                	add	a4,a4,a3
    800042ae:	44d4                	lw	a3,12(s1)
    800042b0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800042b2:	faf609e3          	beq	a2,a5,80004264 <log_write+0x76>
  }
  release(&log.lock);
    800042b6:	0001d517          	auipc	a0,0x1d
    800042ba:	88a50513          	addi	a0,a0,-1910 # 80020b40 <log>
    800042be:	ffffd097          	auipc	ra,0xffffd
    800042c2:	9cc080e7          	jalr	-1588(ra) # 80000c8a <release>
}
    800042c6:	60e2                	ld	ra,24(sp)
    800042c8:	6442                	ld	s0,16(sp)
    800042ca:	64a2                	ld	s1,8(sp)
    800042cc:	6902                	ld	s2,0(sp)
    800042ce:	6105                	addi	sp,sp,32
    800042d0:	8082                	ret

00000000800042d2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800042d2:	1101                	addi	sp,sp,-32
    800042d4:	ec06                	sd	ra,24(sp)
    800042d6:	e822                	sd	s0,16(sp)
    800042d8:	e426                	sd	s1,8(sp)
    800042da:	e04a                	sd	s2,0(sp)
    800042dc:	1000                	addi	s0,sp,32
    800042de:	84aa                	mv	s1,a0
    800042e0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800042e2:	00004597          	auipc	a1,0x4
    800042e6:	3ae58593          	addi	a1,a1,942 # 80008690 <syscalls+0x228>
    800042ea:	0521                	addi	a0,a0,8
    800042ec:	ffffd097          	auipc	ra,0xffffd
    800042f0:	85a080e7          	jalr	-1958(ra) # 80000b46 <initlock>
  lk->name = name;
    800042f4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800042f8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800042fc:	0204a423          	sw	zero,40(s1)
}
    80004300:	60e2                	ld	ra,24(sp)
    80004302:	6442                	ld	s0,16(sp)
    80004304:	64a2                	ld	s1,8(sp)
    80004306:	6902                	ld	s2,0(sp)
    80004308:	6105                	addi	sp,sp,32
    8000430a:	8082                	ret

000000008000430c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000430c:	1101                	addi	sp,sp,-32
    8000430e:	ec06                	sd	ra,24(sp)
    80004310:	e822                	sd	s0,16(sp)
    80004312:	e426                	sd	s1,8(sp)
    80004314:	e04a                	sd	s2,0(sp)
    80004316:	1000                	addi	s0,sp,32
    80004318:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000431a:	00850913          	addi	s2,a0,8
    8000431e:	854a                	mv	a0,s2
    80004320:	ffffd097          	auipc	ra,0xffffd
    80004324:	8b6080e7          	jalr	-1866(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004328:	409c                	lw	a5,0(s1)
    8000432a:	cb89                	beqz	a5,8000433c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000432c:	85ca                	mv	a1,s2
    8000432e:	8526                	mv	a0,s1
    80004330:	ffffe097          	auipc	ra,0xffffe
    80004334:	d44080e7          	jalr	-700(ra) # 80002074 <sleep>
  while (lk->locked) {
    80004338:	409c                	lw	a5,0(s1)
    8000433a:	fbed                	bnez	a5,8000432c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000433c:	4785                	li	a5,1
    8000433e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	68c080e7          	jalr	1676(ra) # 800019cc <myproc>
    80004348:	591c                	lw	a5,48(a0)
    8000434a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000434c:	854a                	mv	a0,s2
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	93c080e7          	jalr	-1732(ra) # 80000c8a <release>
}
    80004356:	60e2                	ld	ra,24(sp)
    80004358:	6442                	ld	s0,16(sp)
    8000435a:	64a2                	ld	s1,8(sp)
    8000435c:	6902                	ld	s2,0(sp)
    8000435e:	6105                	addi	sp,sp,32
    80004360:	8082                	ret

0000000080004362 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004362:	1101                	addi	sp,sp,-32
    80004364:	ec06                	sd	ra,24(sp)
    80004366:	e822                	sd	s0,16(sp)
    80004368:	e426                	sd	s1,8(sp)
    8000436a:	e04a                	sd	s2,0(sp)
    8000436c:	1000                	addi	s0,sp,32
    8000436e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004370:	00850913          	addi	s2,a0,8
    80004374:	854a                	mv	a0,s2
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	860080e7          	jalr	-1952(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    8000437e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004382:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004386:	8526                	mv	a0,s1
    80004388:	ffffe097          	auipc	ra,0xffffe
    8000438c:	d50080e7          	jalr	-688(ra) # 800020d8 <wakeup>
  release(&lk->lk);
    80004390:	854a                	mv	a0,s2
    80004392:	ffffd097          	auipc	ra,0xffffd
    80004396:	8f8080e7          	jalr	-1800(ra) # 80000c8a <release>
}
    8000439a:	60e2                	ld	ra,24(sp)
    8000439c:	6442                	ld	s0,16(sp)
    8000439e:	64a2                	ld	s1,8(sp)
    800043a0:	6902                	ld	s2,0(sp)
    800043a2:	6105                	addi	sp,sp,32
    800043a4:	8082                	ret

00000000800043a6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043a6:	7179                	addi	sp,sp,-48
    800043a8:	f406                	sd	ra,40(sp)
    800043aa:	f022                	sd	s0,32(sp)
    800043ac:	ec26                	sd	s1,24(sp)
    800043ae:	e84a                	sd	s2,16(sp)
    800043b0:	e44e                	sd	s3,8(sp)
    800043b2:	1800                	addi	s0,sp,48
    800043b4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043b6:	00850913          	addi	s2,a0,8
    800043ba:	854a                	mv	a0,s2
    800043bc:	ffffd097          	auipc	ra,0xffffd
    800043c0:	81a080e7          	jalr	-2022(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800043c4:	409c                	lw	a5,0(s1)
    800043c6:	ef99                	bnez	a5,800043e4 <holdingsleep+0x3e>
    800043c8:	4481                	li	s1,0
  release(&lk->lk);
    800043ca:	854a                	mv	a0,s2
    800043cc:	ffffd097          	auipc	ra,0xffffd
    800043d0:	8be080e7          	jalr	-1858(ra) # 80000c8a <release>
  return r;
}
    800043d4:	8526                	mv	a0,s1
    800043d6:	70a2                	ld	ra,40(sp)
    800043d8:	7402                	ld	s0,32(sp)
    800043da:	64e2                	ld	s1,24(sp)
    800043dc:	6942                	ld	s2,16(sp)
    800043de:	69a2                	ld	s3,8(sp)
    800043e0:	6145                	addi	sp,sp,48
    800043e2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800043e4:	0284a983          	lw	s3,40(s1)
    800043e8:	ffffd097          	auipc	ra,0xffffd
    800043ec:	5e4080e7          	jalr	1508(ra) # 800019cc <myproc>
    800043f0:	5904                	lw	s1,48(a0)
    800043f2:	413484b3          	sub	s1,s1,s3
    800043f6:	0014b493          	seqz	s1,s1
    800043fa:	bfc1                	j	800043ca <holdingsleep+0x24>

00000000800043fc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800043fc:	1141                	addi	sp,sp,-16
    800043fe:	e406                	sd	ra,8(sp)
    80004400:	e022                	sd	s0,0(sp)
    80004402:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004404:	00004597          	auipc	a1,0x4
    80004408:	29c58593          	addi	a1,a1,668 # 800086a0 <syscalls+0x238>
    8000440c:	0001d517          	auipc	a0,0x1d
    80004410:	87c50513          	addi	a0,a0,-1924 # 80020c88 <ftable>
    80004414:	ffffc097          	auipc	ra,0xffffc
    80004418:	732080e7          	jalr	1842(ra) # 80000b46 <initlock>
}
    8000441c:	60a2                	ld	ra,8(sp)
    8000441e:	6402                	ld	s0,0(sp)
    80004420:	0141                	addi	sp,sp,16
    80004422:	8082                	ret

0000000080004424 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004424:	1101                	addi	sp,sp,-32
    80004426:	ec06                	sd	ra,24(sp)
    80004428:	e822                	sd	s0,16(sp)
    8000442a:	e426                	sd	s1,8(sp)
    8000442c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000442e:	0001d517          	auipc	a0,0x1d
    80004432:	85a50513          	addi	a0,a0,-1958 # 80020c88 <ftable>
    80004436:	ffffc097          	auipc	ra,0xffffc
    8000443a:	7a0080e7          	jalr	1952(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000443e:	0001d497          	auipc	s1,0x1d
    80004442:	86248493          	addi	s1,s1,-1950 # 80020ca0 <ftable+0x18>
    80004446:	0001d717          	auipc	a4,0x1d
    8000444a:	7fa70713          	addi	a4,a4,2042 # 80021c40 <disk>
    if(f->ref == 0){
    8000444e:	40dc                	lw	a5,4(s1)
    80004450:	cf99                	beqz	a5,8000446e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004452:	02848493          	addi	s1,s1,40
    80004456:	fee49ce3          	bne	s1,a4,8000444e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000445a:	0001d517          	auipc	a0,0x1d
    8000445e:	82e50513          	addi	a0,a0,-2002 # 80020c88 <ftable>
    80004462:	ffffd097          	auipc	ra,0xffffd
    80004466:	828080e7          	jalr	-2008(ra) # 80000c8a <release>
  return 0;
    8000446a:	4481                	li	s1,0
    8000446c:	a819                	j	80004482 <filealloc+0x5e>
      f->ref = 1;
    8000446e:	4785                	li	a5,1
    80004470:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004472:	0001d517          	auipc	a0,0x1d
    80004476:	81650513          	addi	a0,a0,-2026 # 80020c88 <ftable>
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	810080e7          	jalr	-2032(ra) # 80000c8a <release>
}
    80004482:	8526                	mv	a0,s1
    80004484:	60e2                	ld	ra,24(sp)
    80004486:	6442                	ld	s0,16(sp)
    80004488:	64a2                	ld	s1,8(sp)
    8000448a:	6105                	addi	sp,sp,32
    8000448c:	8082                	ret

000000008000448e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000448e:	1101                	addi	sp,sp,-32
    80004490:	ec06                	sd	ra,24(sp)
    80004492:	e822                	sd	s0,16(sp)
    80004494:	e426                	sd	s1,8(sp)
    80004496:	1000                	addi	s0,sp,32
    80004498:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000449a:	0001c517          	auipc	a0,0x1c
    8000449e:	7ee50513          	addi	a0,a0,2030 # 80020c88 <ftable>
    800044a2:	ffffc097          	auipc	ra,0xffffc
    800044a6:	734080e7          	jalr	1844(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800044aa:	40dc                	lw	a5,4(s1)
    800044ac:	02f05263          	blez	a5,800044d0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800044b0:	2785                	addiw	a5,a5,1
    800044b2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800044b4:	0001c517          	auipc	a0,0x1c
    800044b8:	7d450513          	addi	a0,a0,2004 # 80020c88 <ftable>
    800044bc:	ffffc097          	auipc	ra,0xffffc
    800044c0:	7ce080e7          	jalr	1998(ra) # 80000c8a <release>
  return f;
}
    800044c4:	8526                	mv	a0,s1
    800044c6:	60e2                	ld	ra,24(sp)
    800044c8:	6442                	ld	s0,16(sp)
    800044ca:	64a2                	ld	s1,8(sp)
    800044cc:	6105                	addi	sp,sp,32
    800044ce:	8082                	ret
    panic("filedup");
    800044d0:	00004517          	auipc	a0,0x4
    800044d4:	1d850513          	addi	a0,a0,472 # 800086a8 <syscalls+0x240>
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	068080e7          	jalr	104(ra) # 80000540 <panic>

00000000800044e0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800044e0:	7139                	addi	sp,sp,-64
    800044e2:	fc06                	sd	ra,56(sp)
    800044e4:	f822                	sd	s0,48(sp)
    800044e6:	f426                	sd	s1,40(sp)
    800044e8:	f04a                	sd	s2,32(sp)
    800044ea:	ec4e                	sd	s3,24(sp)
    800044ec:	e852                	sd	s4,16(sp)
    800044ee:	e456                	sd	s5,8(sp)
    800044f0:	0080                	addi	s0,sp,64
    800044f2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800044f4:	0001c517          	auipc	a0,0x1c
    800044f8:	79450513          	addi	a0,a0,1940 # 80020c88 <ftable>
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	6da080e7          	jalr	1754(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004504:	40dc                	lw	a5,4(s1)
    80004506:	06f05163          	blez	a5,80004568 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000450a:	37fd                	addiw	a5,a5,-1
    8000450c:	0007871b          	sext.w	a4,a5
    80004510:	c0dc                	sw	a5,4(s1)
    80004512:	06e04363          	bgtz	a4,80004578 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004516:	0004a903          	lw	s2,0(s1)
    8000451a:	0094ca83          	lbu	s5,9(s1)
    8000451e:	0104ba03          	ld	s4,16(s1)
    80004522:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004526:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000452a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000452e:	0001c517          	auipc	a0,0x1c
    80004532:	75a50513          	addi	a0,a0,1882 # 80020c88 <ftable>
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	754080e7          	jalr	1876(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    8000453e:	4785                	li	a5,1
    80004540:	04f90d63          	beq	s2,a5,8000459a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004544:	3979                	addiw	s2,s2,-2
    80004546:	4785                	li	a5,1
    80004548:	0527e063          	bltu	a5,s2,80004588 <fileclose+0xa8>
    begin_op();
    8000454c:	00000097          	auipc	ra,0x0
    80004550:	acc080e7          	jalr	-1332(ra) # 80004018 <begin_op>
    iput(ff.ip);
    80004554:	854e                	mv	a0,s3
    80004556:	fffff097          	auipc	ra,0xfffff
    8000455a:	2b0080e7          	jalr	688(ra) # 80003806 <iput>
    end_op();
    8000455e:	00000097          	auipc	ra,0x0
    80004562:	b38080e7          	jalr	-1224(ra) # 80004096 <end_op>
    80004566:	a00d                	j	80004588 <fileclose+0xa8>
    panic("fileclose");
    80004568:	00004517          	auipc	a0,0x4
    8000456c:	14850513          	addi	a0,a0,328 # 800086b0 <syscalls+0x248>
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	fd0080e7          	jalr	-48(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004578:	0001c517          	auipc	a0,0x1c
    8000457c:	71050513          	addi	a0,a0,1808 # 80020c88 <ftable>
    80004580:	ffffc097          	auipc	ra,0xffffc
    80004584:	70a080e7          	jalr	1802(ra) # 80000c8a <release>
  }
}
    80004588:	70e2                	ld	ra,56(sp)
    8000458a:	7442                	ld	s0,48(sp)
    8000458c:	74a2                	ld	s1,40(sp)
    8000458e:	7902                	ld	s2,32(sp)
    80004590:	69e2                	ld	s3,24(sp)
    80004592:	6a42                	ld	s4,16(sp)
    80004594:	6aa2                	ld	s5,8(sp)
    80004596:	6121                	addi	sp,sp,64
    80004598:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000459a:	85d6                	mv	a1,s5
    8000459c:	8552                	mv	a0,s4
    8000459e:	00000097          	auipc	ra,0x0
    800045a2:	34c080e7          	jalr	844(ra) # 800048ea <pipeclose>
    800045a6:	b7cd                	j	80004588 <fileclose+0xa8>

00000000800045a8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045a8:	715d                	addi	sp,sp,-80
    800045aa:	e486                	sd	ra,72(sp)
    800045ac:	e0a2                	sd	s0,64(sp)
    800045ae:	fc26                	sd	s1,56(sp)
    800045b0:	f84a                	sd	s2,48(sp)
    800045b2:	f44e                	sd	s3,40(sp)
    800045b4:	0880                	addi	s0,sp,80
    800045b6:	84aa                	mv	s1,a0
    800045b8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800045ba:	ffffd097          	auipc	ra,0xffffd
    800045be:	412080e7          	jalr	1042(ra) # 800019cc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800045c2:	409c                	lw	a5,0(s1)
    800045c4:	37f9                	addiw	a5,a5,-2
    800045c6:	4705                	li	a4,1
    800045c8:	04f76763          	bltu	a4,a5,80004616 <filestat+0x6e>
    800045cc:	892a                	mv	s2,a0
    ilock(f->ip);
    800045ce:	6c88                	ld	a0,24(s1)
    800045d0:	fffff097          	auipc	ra,0xfffff
    800045d4:	07c080e7          	jalr	124(ra) # 8000364c <ilock>
    stati(f->ip, &st);
    800045d8:	fb840593          	addi	a1,s0,-72
    800045dc:	6c88                	ld	a0,24(s1)
    800045de:	fffff097          	auipc	ra,0xfffff
    800045e2:	2f8080e7          	jalr	760(ra) # 800038d6 <stati>
    iunlock(f->ip);
    800045e6:	6c88                	ld	a0,24(s1)
    800045e8:	fffff097          	auipc	ra,0xfffff
    800045ec:	126080e7          	jalr	294(ra) # 8000370e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800045f0:	46e1                	li	a3,24
    800045f2:	fb840613          	addi	a2,s0,-72
    800045f6:	85ce                	mv	a1,s3
    800045f8:	05093503          	ld	a0,80(s2)
    800045fc:	ffffd097          	auipc	ra,0xffffd
    80004600:	090080e7          	jalr	144(ra) # 8000168c <copyout>
    80004604:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004608:	60a6                	ld	ra,72(sp)
    8000460a:	6406                	ld	s0,64(sp)
    8000460c:	74e2                	ld	s1,56(sp)
    8000460e:	7942                	ld	s2,48(sp)
    80004610:	79a2                	ld	s3,40(sp)
    80004612:	6161                	addi	sp,sp,80
    80004614:	8082                	ret
  return -1;
    80004616:	557d                	li	a0,-1
    80004618:	bfc5                	j	80004608 <filestat+0x60>

000000008000461a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000461a:	7179                	addi	sp,sp,-48
    8000461c:	f406                	sd	ra,40(sp)
    8000461e:	f022                	sd	s0,32(sp)
    80004620:	ec26                	sd	s1,24(sp)
    80004622:	e84a                	sd	s2,16(sp)
    80004624:	e44e                	sd	s3,8(sp)
    80004626:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004628:	00854783          	lbu	a5,8(a0)
    8000462c:	c3d5                	beqz	a5,800046d0 <fileread+0xb6>
    8000462e:	84aa                	mv	s1,a0
    80004630:	89ae                	mv	s3,a1
    80004632:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004634:	411c                	lw	a5,0(a0)
    80004636:	4705                	li	a4,1
    80004638:	04e78963          	beq	a5,a4,8000468a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000463c:	470d                	li	a4,3
    8000463e:	04e78d63          	beq	a5,a4,80004698 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004642:	4709                	li	a4,2
    80004644:	06e79e63          	bne	a5,a4,800046c0 <fileread+0xa6>
    ilock(f->ip);
    80004648:	6d08                	ld	a0,24(a0)
    8000464a:	fffff097          	auipc	ra,0xfffff
    8000464e:	002080e7          	jalr	2(ra) # 8000364c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004652:	874a                	mv	a4,s2
    80004654:	5094                	lw	a3,32(s1)
    80004656:	864e                	mv	a2,s3
    80004658:	4585                	li	a1,1
    8000465a:	6c88                	ld	a0,24(s1)
    8000465c:	fffff097          	auipc	ra,0xfffff
    80004660:	2a4080e7          	jalr	676(ra) # 80003900 <readi>
    80004664:	892a                	mv	s2,a0
    80004666:	00a05563          	blez	a0,80004670 <fileread+0x56>
      f->off += r;
    8000466a:	509c                	lw	a5,32(s1)
    8000466c:	9fa9                	addw	a5,a5,a0
    8000466e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004670:	6c88                	ld	a0,24(s1)
    80004672:	fffff097          	auipc	ra,0xfffff
    80004676:	09c080e7          	jalr	156(ra) # 8000370e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000467a:	854a                	mv	a0,s2
    8000467c:	70a2                	ld	ra,40(sp)
    8000467e:	7402                	ld	s0,32(sp)
    80004680:	64e2                	ld	s1,24(sp)
    80004682:	6942                	ld	s2,16(sp)
    80004684:	69a2                	ld	s3,8(sp)
    80004686:	6145                	addi	sp,sp,48
    80004688:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000468a:	6908                	ld	a0,16(a0)
    8000468c:	00000097          	auipc	ra,0x0
    80004690:	3c6080e7          	jalr	966(ra) # 80004a52 <piperead>
    80004694:	892a                	mv	s2,a0
    80004696:	b7d5                	j	8000467a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004698:	02451783          	lh	a5,36(a0)
    8000469c:	03079693          	slli	a3,a5,0x30
    800046a0:	92c1                	srli	a3,a3,0x30
    800046a2:	4725                	li	a4,9
    800046a4:	02d76863          	bltu	a4,a3,800046d4 <fileread+0xba>
    800046a8:	0792                	slli	a5,a5,0x4
    800046aa:	0001c717          	auipc	a4,0x1c
    800046ae:	53e70713          	addi	a4,a4,1342 # 80020be8 <devsw>
    800046b2:	97ba                	add	a5,a5,a4
    800046b4:	639c                	ld	a5,0(a5)
    800046b6:	c38d                	beqz	a5,800046d8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046b8:	4505                	li	a0,1
    800046ba:	9782                	jalr	a5
    800046bc:	892a                	mv	s2,a0
    800046be:	bf75                	j	8000467a <fileread+0x60>
    panic("fileread");
    800046c0:	00004517          	auipc	a0,0x4
    800046c4:	00050513          	mv	a0,a0
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	e78080e7          	jalr	-392(ra) # 80000540 <panic>
    return -1;
    800046d0:	597d                	li	s2,-1
    800046d2:	b765                	j	8000467a <fileread+0x60>
      return -1;
    800046d4:	597d                	li	s2,-1
    800046d6:	b755                	j	8000467a <fileread+0x60>
    800046d8:	597d                	li	s2,-1
    800046da:	b745                	j	8000467a <fileread+0x60>

00000000800046dc <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800046dc:	715d                	addi	sp,sp,-80
    800046de:	e486                	sd	ra,72(sp)
    800046e0:	e0a2                	sd	s0,64(sp)
    800046e2:	fc26                	sd	s1,56(sp)
    800046e4:	f84a                	sd	s2,48(sp)
    800046e6:	f44e                	sd	s3,40(sp)
    800046e8:	f052                	sd	s4,32(sp)
    800046ea:	ec56                	sd	s5,24(sp)
    800046ec:	e85a                	sd	s6,16(sp)
    800046ee:	e45e                	sd	s7,8(sp)
    800046f0:	e062                	sd	s8,0(sp)
    800046f2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800046f4:	00954783          	lbu	a5,9(a0) # 800086c9 <syscalls+0x261>
    800046f8:	10078663          	beqz	a5,80004804 <filewrite+0x128>
    800046fc:	892a                	mv	s2,a0
    800046fe:	8b2e                	mv	s6,a1
    80004700:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004702:	411c                	lw	a5,0(a0)
    80004704:	4705                	li	a4,1
    80004706:	02e78263          	beq	a5,a4,8000472a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000470a:	470d                	li	a4,3
    8000470c:	02e78663          	beq	a5,a4,80004738 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004710:	4709                	li	a4,2
    80004712:	0ee79163          	bne	a5,a4,800047f4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004716:	0ac05d63          	blez	a2,800047d0 <filewrite+0xf4>
    int i = 0;
    8000471a:	4981                	li	s3,0
    8000471c:	6b85                	lui	s7,0x1
    8000471e:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004722:	6c05                	lui	s8,0x1
    80004724:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004728:	a861                	j	800047c0 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000472a:	6908                	ld	a0,16(a0)
    8000472c:	00000097          	auipc	ra,0x0
    80004730:	22e080e7          	jalr	558(ra) # 8000495a <pipewrite>
    80004734:	8a2a                	mv	s4,a0
    80004736:	a045                	j	800047d6 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004738:	02451783          	lh	a5,36(a0)
    8000473c:	03079693          	slli	a3,a5,0x30
    80004740:	92c1                	srli	a3,a3,0x30
    80004742:	4725                	li	a4,9
    80004744:	0cd76263          	bltu	a4,a3,80004808 <filewrite+0x12c>
    80004748:	0792                	slli	a5,a5,0x4
    8000474a:	0001c717          	auipc	a4,0x1c
    8000474e:	49e70713          	addi	a4,a4,1182 # 80020be8 <devsw>
    80004752:	97ba                	add	a5,a5,a4
    80004754:	679c                	ld	a5,8(a5)
    80004756:	cbdd                	beqz	a5,8000480c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004758:	4505                	li	a0,1
    8000475a:	9782                	jalr	a5
    8000475c:	8a2a                	mv	s4,a0
    8000475e:	a8a5                	j	800047d6 <filewrite+0xfa>
    80004760:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004764:	00000097          	auipc	ra,0x0
    80004768:	8b4080e7          	jalr	-1868(ra) # 80004018 <begin_op>
      ilock(f->ip);
    8000476c:	01893503          	ld	a0,24(s2)
    80004770:	fffff097          	auipc	ra,0xfffff
    80004774:	edc080e7          	jalr	-292(ra) # 8000364c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004778:	8756                	mv	a4,s5
    8000477a:	02092683          	lw	a3,32(s2)
    8000477e:	01698633          	add	a2,s3,s6
    80004782:	4585                	li	a1,1
    80004784:	01893503          	ld	a0,24(s2)
    80004788:	fffff097          	auipc	ra,0xfffff
    8000478c:	270080e7          	jalr	624(ra) # 800039f8 <writei>
    80004790:	84aa                	mv	s1,a0
    80004792:	00a05763          	blez	a0,800047a0 <filewrite+0xc4>
        f->off += r;
    80004796:	02092783          	lw	a5,32(s2)
    8000479a:	9fa9                	addw	a5,a5,a0
    8000479c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047a0:	01893503          	ld	a0,24(s2)
    800047a4:	fffff097          	auipc	ra,0xfffff
    800047a8:	f6a080e7          	jalr	-150(ra) # 8000370e <iunlock>
      end_op();
    800047ac:	00000097          	auipc	ra,0x0
    800047b0:	8ea080e7          	jalr	-1814(ra) # 80004096 <end_op>

      if(r != n1){
    800047b4:	009a9f63          	bne	s5,s1,800047d2 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800047b8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047bc:	0149db63          	bge	s3,s4,800047d2 <filewrite+0xf6>
      int n1 = n - i;
    800047c0:	413a04bb          	subw	s1,s4,s3
    800047c4:	0004879b          	sext.w	a5,s1
    800047c8:	f8fbdce3          	bge	s7,a5,80004760 <filewrite+0x84>
    800047cc:	84e2                	mv	s1,s8
    800047ce:	bf49                	j	80004760 <filewrite+0x84>
    int i = 0;
    800047d0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800047d2:	013a1f63          	bne	s4,s3,800047f0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800047d6:	8552                	mv	a0,s4
    800047d8:	60a6                	ld	ra,72(sp)
    800047da:	6406                	ld	s0,64(sp)
    800047dc:	74e2                	ld	s1,56(sp)
    800047de:	7942                	ld	s2,48(sp)
    800047e0:	79a2                	ld	s3,40(sp)
    800047e2:	7a02                	ld	s4,32(sp)
    800047e4:	6ae2                	ld	s5,24(sp)
    800047e6:	6b42                	ld	s6,16(sp)
    800047e8:	6ba2                	ld	s7,8(sp)
    800047ea:	6c02                	ld	s8,0(sp)
    800047ec:	6161                	addi	sp,sp,80
    800047ee:	8082                	ret
    ret = (i == n ? n : -1);
    800047f0:	5a7d                	li	s4,-1
    800047f2:	b7d5                	j	800047d6 <filewrite+0xfa>
    panic("filewrite");
    800047f4:	00004517          	auipc	a0,0x4
    800047f8:	edc50513          	addi	a0,a0,-292 # 800086d0 <syscalls+0x268>
    800047fc:	ffffc097          	auipc	ra,0xffffc
    80004800:	d44080e7          	jalr	-700(ra) # 80000540 <panic>
    return -1;
    80004804:	5a7d                	li	s4,-1
    80004806:	bfc1                	j	800047d6 <filewrite+0xfa>
      return -1;
    80004808:	5a7d                	li	s4,-1
    8000480a:	b7f1                	j	800047d6 <filewrite+0xfa>
    8000480c:	5a7d                	li	s4,-1
    8000480e:	b7e1                	j	800047d6 <filewrite+0xfa>

0000000080004810 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004810:	7179                	addi	sp,sp,-48
    80004812:	f406                	sd	ra,40(sp)
    80004814:	f022                	sd	s0,32(sp)
    80004816:	ec26                	sd	s1,24(sp)
    80004818:	e84a                	sd	s2,16(sp)
    8000481a:	e44e                	sd	s3,8(sp)
    8000481c:	e052                	sd	s4,0(sp)
    8000481e:	1800                	addi	s0,sp,48
    80004820:	84aa                	mv	s1,a0
    80004822:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004824:	0005b023          	sd	zero,0(a1)
    80004828:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000482c:	00000097          	auipc	ra,0x0
    80004830:	bf8080e7          	jalr	-1032(ra) # 80004424 <filealloc>
    80004834:	e088                	sd	a0,0(s1)
    80004836:	c551                	beqz	a0,800048c2 <pipealloc+0xb2>
    80004838:	00000097          	auipc	ra,0x0
    8000483c:	bec080e7          	jalr	-1044(ra) # 80004424 <filealloc>
    80004840:	00aa3023          	sd	a0,0(s4)
    80004844:	c92d                	beqz	a0,800048b6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	2a0080e7          	jalr	672(ra) # 80000ae6 <kalloc>
    8000484e:	892a                	mv	s2,a0
    80004850:	c125                	beqz	a0,800048b0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004852:	4985                	li	s3,1
    80004854:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004858:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000485c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004860:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004864:	00004597          	auipc	a1,0x4
    80004868:	e7c58593          	addi	a1,a1,-388 # 800086e0 <syscalls+0x278>
    8000486c:	ffffc097          	auipc	ra,0xffffc
    80004870:	2da080e7          	jalr	730(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004874:	609c                	ld	a5,0(s1)
    80004876:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000487a:	609c                	ld	a5,0(s1)
    8000487c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004880:	609c                	ld	a5,0(s1)
    80004882:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004886:	609c                	ld	a5,0(s1)
    80004888:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000488c:	000a3783          	ld	a5,0(s4)
    80004890:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004894:	000a3783          	ld	a5,0(s4)
    80004898:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000489c:	000a3783          	ld	a5,0(s4)
    800048a0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800048a4:	000a3783          	ld	a5,0(s4)
    800048a8:	0127b823          	sd	s2,16(a5)
  return 0;
    800048ac:	4501                	li	a0,0
    800048ae:	a025                	j	800048d6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800048b0:	6088                	ld	a0,0(s1)
    800048b2:	e501                	bnez	a0,800048ba <pipealloc+0xaa>
    800048b4:	a039                	j	800048c2 <pipealloc+0xb2>
    800048b6:	6088                	ld	a0,0(s1)
    800048b8:	c51d                	beqz	a0,800048e6 <pipealloc+0xd6>
    fileclose(*f0);
    800048ba:	00000097          	auipc	ra,0x0
    800048be:	c26080e7          	jalr	-986(ra) # 800044e0 <fileclose>
  if(*f1)
    800048c2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800048c6:	557d                	li	a0,-1
  if(*f1)
    800048c8:	c799                	beqz	a5,800048d6 <pipealloc+0xc6>
    fileclose(*f1);
    800048ca:	853e                	mv	a0,a5
    800048cc:	00000097          	auipc	ra,0x0
    800048d0:	c14080e7          	jalr	-1004(ra) # 800044e0 <fileclose>
  return -1;
    800048d4:	557d                	li	a0,-1
}
    800048d6:	70a2                	ld	ra,40(sp)
    800048d8:	7402                	ld	s0,32(sp)
    800048da:	64e2                	ld	s1,24(sp)
    800048dc:	6942                	ld	s2,16(sp)
    800048de:	69a2                	ld	s3,8(sp)
    800048e0:	6a02                	ld	s4,0(sp)
    800048e2:	6145                	addi	sp,sp,48
    800048e4:	8082                	ret
  return -1;
    800048e6:	557d                	li	a0,-1
    800048e8:	b7fd                	j	800048d6 <pipealloc+0xc6>

00000000800048ea <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800048ea:	1101                	addi	sp,sp,-32
    800048ec:	ec06                	sd	ra,24(sp)
    800048ee:	e822                	sd	s0,16(sp)
    800048f0:	e426                	sd	s1,8(sp)
    800048f2:	e04a                	sd	s2,0(sp)
    800048f4:	1000                	addi	s0,sp,32
    800048f6:	84aa                	mv	s1,a0
    800048f8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	2dc080e7          	jalr	732(ra) # 80000bd6 <acquire>
  if(writable){
    80004902:	02090d63          	beqz	s2,8000493c <pipeclose+0x52>
    pi->writeopen = 0;
    80004906:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000490a:	21848513          	addi	a0,s1,536
    8000490e:	ffffd097          	auipc	ra,0xffffd
    80004912:	7ca080e7          	jalr	1994(ra) # 800020d8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004916:	2204b783          	ld	a5,544(s1)
    8000491a:	eb95                	bnez	a5,8000494e <pipeclose+0x64>
    release(&pi->lock);
    8000491c:	8526                	mv	a0,s1
    8000491e:	ffffc097          	auipc	ra,0xffffc
    80004922:	36c080e7          	jalr	876(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004926:	8526                	mv	a0,s1
    80004928:	ffffc097          	auipc	ra,0xffffc
    8000492c:	0c0080e7          	jalr	192(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004930:	60e2                	ld	ra,24(sp)
    80004932:	6442                	ld	s0,16(sp)
    80004934:	64a2                	ld	s1,8(sp)
    80004936:	6902                	ld	s2,0(sp)
    80004938:	6105                	addi	sp,sp,32
    8000493a:	8082                	ret
    pi->readopen = 0;
    8000493c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004940:	21c48513          	addi	a0,s1,540
    80004944:	ffffd097          	auipc	ra,0xffffd
    80004948:	794080e7          	jalr	1940(ra) # 800020d8 <wakeup>
    8000494c:	b7e9                	j	80004916 <pipeclose+0x2c>
    release(&pi->lock);
    8000494e:	8526                	mv	a0,s1
    80004950:	ffffc097          	auipc	ra,0xffffc
    80004954:	33a080e7          	jalr	826(ra) # 80000c8a <release>
}
    80004958:	bfe1                	j	80004930 <pipeclose+0x46>

000000008000495a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000495a:	711d                	addi	sp,sp,-96
    8000495c:	ec86                	sd	ra,88(sp)
    8000495e:	e8a2                	sd	s0,80(sp)
    80004960:	e4a6                	sd	s1,72(sp)
    80004962:	e0ca                	sd	s2,64(sp)
    80004964:	fc4e                	sd	s3,56(sp)
    80004966:	f852                	sd	s4,48(sp)
    80004968:	f456                	sd	s5,40(sp)
    8000496a:	f05a                	sd	s6,32(sp)
    8000496c:	ec5e                	sd	s7,24(sp)
    8000496e:	e862                	sd	s8,16(sp)
    80004970:	1080                	addi	s0,sp,96
    80004972:	84aa                	mv	s1,a0
    80004974:	8aae                	mv	s5,a1
    80004976:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004978:	ffffd097          	auipc	ra,0xffffd
    8000497c:	054080e7          	jalr	84(ra) # 800019cc <myproc>
    80004980:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004982:	8526                	mv	a0,s1
    80004984:	ffffc097          	auipc	ra,0xffffc
    80004988:	252080e7          	jalr	594(ra) # 80000bd6 <acquire>
  while(i < n){
    8000498c:	0b405663          	blez	s4,80004a38 <pipewrite+0xde>
  int i = 0;
    80004990:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004992:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004994:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004998:	21c48b93          	addi	s7,s1,540
    8000499c:	a089                	j	800049de <pipewrite+0x84>
      release(&pi->lock);
    8000499e:	8526                	mv	a0,s1
    800049a0:	ffffc097          	auipc	ra,0xffffc
    800049a4:	2ea080e7          	jalr	746(ra) # 80000c8a <release>
      return -1;
    800049a8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800049aa:	854a                	mv	a0,s2
    800049ac:	60e6                	ld	ra,88(sp)
    800049ae:	6446                	ld	s0,80(sp)
    800049b0:	64a6                	ld	s1,72(sp)
    800049b2:	6906                	ld	s2,64(sp)
    800049b4:	79e2                	ld	s3,56(sp)
    800049b6:	7a42                	ld	s4,48(sp)
    800049b8:	7aa2                	ld	s5,40(sp)
    800049ba:	7b02                	ld	s6,32(sp)
    800049bc:	6be2                	ld	s7,24(sp)
    800049be:	6c42                	ld	s8,16(sp)
    800049c0:	6125                	addi	sp,sp,96
    800049c2:	8082                	ret
      wakeup(&pi->nread);
    800049c4:	8562                	mv	a0,s8
    800049c6:	ffffd097          	auipc	ra,0xffffd
    800049ca:	712080e7          	jalr	1810(ra) # 800020d8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800049ce:	85a6                	mv	a1,s1
    800049d0:	855e                	mv	a0,s7
    800049d2:	ffffd097          	auipc	ra,0xffffd
    800049d6:	6a2080e7          	jalr	1698(ra) # 80002074 <sleep>
  while(i < n){
    800049da:	07495063          	bge	s2,s4,80004a3a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800049de:	2204a783          	lw	a5,544(s1)
    800049e2:	dfd5                	beqz	a5,8000499e <pipewrite+0x44>
    800049e4:	854e                	mv	a0,s3
    800049e6:	ffffe097          	auipc	ra,0xffffe
    800049ea:	936080e7          	jalr	-1738(ra) # 8000231c <killed>
    800049ee:	f945                	bnez	a0,8000499e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800049f0:	2184a783          	lw	a5,536(s1)
    800049f4:	21c4a703          	lw	a4,540(s1)
    800049f8:	2007879b          	addiw	a5,a5,512
    800049fc:	fcf704e3          	beq	a4,a5,800049c4 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a00:	4685                	li	a3,1
    80004a02:	01590633          	add	a2,s2,s5
    80004a06:	faf40593          	addi	a1,s0,-81
    80004a0a:	0509b503          	ld	a0,80(s3)
    80004a0e:	ffffd097          	auipc	ra,0xffffd
    80004a12:	d0a080e7          	jalr	-758(ra) # 80001718 <copyin>
    80004a16:	03650263          	beq	a0,s6,80004a3a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a1a:	21c4a783          	lw	a5,540(s1)
    80004a1e:	0017871b          	addiw	a4,a5,1
    80004a22:	20e4ae23          	sw	a4,540(s1)
    80004a26:	1ff7f793          	andi	a5,a5,511
    80004a2a:	97a6                	add	a5,a5,s1
    80004a2c:	faf44703          	lbu	a4,-81(s0)
    80004a30:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a34:	2905                	addiw	s2,s2,1
    80004a36:	b755                	j	800049da <pipewrite+0x80>
  int i = 0;
    80004a38:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004a3a:	21848513          	addi	a0,s1,536
    80004a3e:	ffffd097          	auipc	ra,0xffffd
    80004a42:	69a080e7          	jalr	1690(ra) # 800020d8 <wakeup>
  release(&pi->lock);
    80004a46:	8526                	mv	a0,s1
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	242080e7          	jalr	578(ra) # 80000c8a <release>
  return i;
    80004a50:	bfa9                	j	800049aa <pipewrite+0x50>

0000000080004a52 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a52:	715d                	addi	sp,sp,-80
    80004a54:	e486                	sd	ra,72(sp)
    80004a56:	e0a2                	sd	s0,64(sp)
    80004a58:	fc26                	sd	s1,56(sp)
    80004a5a:	f84a                	sd	s2,48(sp)
    80004a5c:	f44e                	sd	s3,40(sp)
    80004a5e:	f052                	sd	s4,32(sp)
    80004a60:	ec56                	sd	s5,24(sp)
    80004a62:	e85a                	sd	s6,16(sp)
    80004a64:	0880                	addi	s0,sp,80
    80004a66:	84aa                	mv	s1,a0
    80004a68:	892e                	mv	s2,a1
    80004a6a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a6c:	ffffd097          	auipc	ra,0xffffd
    80004a70:	f60080e7          	jalr	-160(ra) # 800019cc <myproc>
    80004a74:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a76:	8526                	mv	a0,s1
    80004a78:	ffffc097          	auipc	ra,0xffffc
    80004a7c:	15e080e7          	jalr	350(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a80:	2184a703          	lw	a4,536(s1)
    80004a84:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a88:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a8c:	02f71763          	bne	a4,a5,80004aba <piperead+0x68>
    80004a90:	2244a783          	lw	a5,548(s1)
    80004a94:	c39d                	beqz	a5,80004aba <piperead+0x68>
    if(killed(pr)){
    80004a96:	8552                	mv	a0,s4
    80004a98:	ffffe097          	auipc	ra,0xffffe
    80004a9c:	884080e7          	jalr	-1916(ra) # 8000231c <killed>
    80004aa0:	e949                	bnez	a0,80004b32 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aa2:	85a6                	mv	a1,s1
    80004aa4:	854e                	mv	a0,s3
    80004aa6:	ffffd097          	auipc	ra,0xffffd
    80004aaa:	5ce080e7          	jalr	1486(ra) # 80002074 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004aae:	2184a703          	lw	a4,536(s1)
    80004ab2:	21c4a783          	lw	a5,540(s1)
    80004ab6:	fcf70de3          	beq	a4,a5,80004a90 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004aba:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004abc:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004abe:	05505463          	blez	s5,80004b06 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004ac2:	2184a783          	lw	a5,536(s1)
    80004ac6:	21c4a703          	lw	a4,540(s1)
    80004aca:	02f70e63          	beq	a4,a5,80004b06 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ace:	0017871b          	addiw	a4,a5,1
    80004ad2:	20e4ac23          	sw	a4,536(s1)
    80004ad6:	1ff7f793          	andi	a5,a5,511
    80004ada:	97a6                	add	a5,a5,s1
    80004adc:	0187c783          	lbu	a5,24(a5)
    80004ae0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ae4:	4685                	li	a3,1
    80004ae6:	fbf40613          	addi	a2,s0,-65
    80004aea:	85ca                	mv	a1,s2
    80004aec:	050a3503          	ld	a0,80(s4)
    80004af0:	ffffd097          	auipc	ra,0xffffd
    80004af4:	b9c080e7          	jalr	-1124(ra) # 8000168c <copyout>
    80004af8:	01650763          	beq	a0,s6,80004b06 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004afc:	2985                	addiw	s3,s3,1
    80004afe:	0905                	addi	s2,s2,1
    80004b00:	fd3a91e3          	bne	s5,s3,80004ac2 <piperead+0x70>
    80004b04:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b06:	21c48513          	addi	a0,s1,540
    80004b0a:	ffffd097          	auipc	ra,0xffffd
    80004b0e:	5ce080e7          	jalr	1486(ra) # 800020d8 <wakeup>
  release(&pi->lock);
    80004b12:	8526                	mv	a0,s1
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	176080e7          	jalr	374(ra) # 80000c8a <release>
  return i;
}
    80004b1c:	854e                	mv	a0,s3
    80004b1e:	60a6                	ld	ra,72(sp)
    80004b20:	6406                	ld	s0,64(sp)
    80004b22:	74e2                	ld	s1,56(sp)
    80004b24:	7942                	ld	s2,48(sp)
    80004b26:	79a2                	ld	s3,40(sp)
    80004b28:	7a02                	ld	s4,32(sp)
    80004b2a:	6ae2                	ld	s5,24(sp)
    80004b2c:	6b42                	ld	s6,16(sp)
    80004b2e:	6161                	addi	sp,sp,80
    80004b30:	8082                	ret
      release(&pi->lock);
    80004b32:	8526                	mv	a0,s1
    80004b34:	ffffc097          	auipc	ra,0xffffc
    80004b38:	156080e7          	jalr	342(ra) # 80000c8a <release>
      return -1;
    80004b3c:	59fd                	li	s3,-1
    80004b3e:	bff9                	j	80004b1c <piperead+0xca>

0000000080004b40 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004b40:	1141                	addi	sp,sp,-16
    80004b42:	e422                	sd	s0,8(sp)
    80004b44:	0800                	addi	s0,sp,16
    80004b46:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004b48:	8905                	andi	a0,a0,1
    80004b4a:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004b4c:	8b89                	andi	a5,a5,2
    80004b4e:	c399                	beqz	a5,80004b54 <flags2perm+0x14>
      perm |= PTE_W;
    80004b50:	00456513          	ori	a0,a0,4
    return perm;
}
    80004b54:	6422                	ld	s0,8(sp)
    80004b56:	0141                	addi	sp,sp,16
    80004b58:	8082                	ret

0000000080004b5a <exec>:

int
exec(char *path, char **argv)
{
    80004b5a:	de010113          	addi	sp,sp,-544
    80004b5e:	20113c23          	sd	ra,536(sp)
    80004b62:	20813823          	sd	s0,528(sp)
    80004b66:	20913423          	sd	s1,520(sp)
    80004b6a:	21213023          	sd	s2,512(sp)
    80004b6e:	ffce                	sd	s3,504(sp)
    80004b70:	fbd2                	sd	s4,496(sp)
    80004b72:	f7d6                	sd	s5,488(sp)
    80004b74:	f3da                	sd	s6,480(sp)
    80004b76:	efde                	sd	s7,472(sp)
    80004b78:	ebe2                	sd	s8,464(sp)
    80004b7a:	e7e6                	sd	s9,456(sp)
    80004b7c:	e3ea                	sd	s10,448(sp)
    80004b7e:	ff6e                	sd	s11,440(sp)
    80004b80:	1400                	addi	s0,sp,544
    80004b82:	892a                	mv	s2,a0
    80004b84:	dea43423          	sd	a0,-536(s0)
    80004b88:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b8c:	ffffd097          	auipc	ra,0xffffd
    80004b90:	e40080e7          	jalr	-448(ra) # 800019cc <myproc>
    80004b94:	84aa                	mv	s1,a0

  begin_op();
    80004b96:	fffff097          	auipc	ra,0xfffff
    80004b9a:	482080e7          	jalr	1154(ra) # 80004018 <begin_op>

  if((ip = namei(path)) == 0){
    80004b9e:	854a                	mv	a0,s2
    80004ba0:	fffff097          	auipc	ra,0xfffff
    80004ba4:	258080e7          	jalr	600(ra) # 80003df8 <namei>
    80004ba8:	c93d                	beqz	a0,80004c1e <exec+0xc4>
    80004baa:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004bac:	fffff097          	auipc	ra,0xfffff
    80004bb0:	aa0080e7          	jalr	-1376(ra) # 8000364c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004bb4:	04000713          	li	a4,64
    80004bb8:	4681                	li	a3,0
    80004bba:	e5040613          	addi	a2,s0,-432
    80004bbe:	4581                	li	a1,0
    80004bc0:	8556                	mv	a0,s5
    80004bc2:	fffff097          	auipc	ra,0xfffff
    80004bc6:	d3e080e7          	jalr	-706(ra) # 80003900 <readi>
    80004bca:	04000793          	li	a5,64
    80004bce:	00f51a63          	bne	a0,a5,80004be2 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004bd2:	e5042703          	lw	a4,-432(s0)
    80004bd6:	464c47b7          	lui	a5,0x464c4
    80004bda:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004bde:	04f70663          	beq	a4,a5,80004c2a <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004be2:	8556                	mv	a0,s5
    80004be4:	fffff097          	auipc	ra,0xfffff
    80004be8:	cca080e7          	jalr	-822(ra) # 800038ae <iunlockput>
    end_op();
    80004bec:	fffff097          	auipc	ra,0xfffff
    80004bf0:	4aa080e7          	jalr	1194(ra) # 80004096 <end_op>
  }
  return -1;
    80004bf4:	557d                	li	a0,-1
}
    80004bf6:	21813083          	ld	ra,536(sp)
    80004bfa:	21013403          	ld	s0,528(sp)
    80004bfe:	20813483          	ld	s1,520(sp)
    80004c02:	20013903          	ld	s2,512(sp)
    80004c06:	79fe                	ld	s3,504(sp)
    80004c08:	7a5e                	ld	s4,496(sp)
    80004c0a:	7abe                	ld	s5,488(sp)
    80004c0c:	7b1e                	ld	s6,480(sp)
    80004c0e:	6bfe                	ld	s7,472(sp)
    80004c10:	6c5e                	ld	s8,464(sp)
    80004c12:	6cbe                	ld	s9,456(sp)
    80004c14:	6d1e                	ld	s10,448(sp)
    80004c16:	7dfa                	ld	s11,440(sp)
    80004c18:	22010113          	addi	sp,sp,544
    80004c1c:	8082                	ret
    end_op();
    80004c1e:	fffff097          	auipc	ra,0xfffff
    80004c22:	478080e7          	jalr	1144(ra) # 80004096 <end_op>
    return -1;
    80004c26:	557d                	li	a0,-1
    80004c28:	b7f9                	j	80004bf6 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c2a:	8526                	mv	a0,s1
    80004c2c:	ffffd097          	auipc	ra,0xffffd
    80004c30:	e64080e7          	jalr	-412(ra) # 80001a90 <proc_pagetable>
    80004c34:	8b2a                	mv	s6,a0
    80004c36:	d555                	beqz	a0,80004be2 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c38:	e7042783          	lw	a5,-400(s0)
    80004c3c:	e8845703          	lhu	a4,-376(s0)
    80004c40:	c735                	beqz	a4,80004cac <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c42:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c44:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004c48:	6a05                	lui	s4,0x1
    80004c4a:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004c4e:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004c52:	6d85                	lui	s11,0x1
    80004c54:	7d7d                	lui	s10,0xfffff
    80004c56:	a4a9                	j	80004ea0 <exec+0x346>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004c58:	00004517          	auipc	a0,0x4
    80004c5c:	a9050513          	addi	a0,a0,-1392 # 800086e8 <syscalls+0x280>
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	8e0080e7          	jalr	-1824(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c68:	874a                	mv	a4,s2
    80004c6a:	009c86bb          	addw	a3,s9,s1
    80004c6e:	4581                	li	a1,0
    80004c70:	8556                	mv	a0,s5
    80004c72:	fffff097          	auipc	ra,0xfffff
    80004c76:	c8e080e7          	jalr	-882(ra) # 80003900 <readi>
    80004c7a:	2501                	sext.w	a0,a0
    80004c7c:	1aa91f63          	bne	s2,a0,80004e3a <exec+0x2e0>
  for(i = 0; i < sz; i += PGSIZE){
    80004c80:	009d84bb          	addw	s1,s11,s1
    80004c84:	013d09bb          	addw	s3,s10,s3
    80004c88:	1f74fc63          	bgeu	s1,s7,80004e80 <exec+0x326>
    pa = walkaddr(pagetable, va + i);
    80004c8c:	02049593          	slli	a1,s1,0x20
    80004c90:	9181                	srli	a1,a1,0x20
    80004c92:	95e2                	add	a1,a1,s8
    80004c94:	855a                	mv	a0,s6
    80004c96:	ffffc097          	auipc	ra,0xffffc
    80004c9a:	3e6080e7          	jalr	998(ra) # 8000107c <walkaddr>
    80004c9e:	862a                	mv	a2,a0
    if(pa == 0)
    80004ca0:	dd45                	beqz	a0,80004c58 <exec+0xfe>
      n = PGSIZE;
    80004ca2:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004ca4:	fd49f2e3          	bgeu	s3,s4,80004c68 <exec+0x10e>
      n = sz - i;
    80004ca8:	894e                	mv	s2,s3
    80004caa:	bf7d                	j	80004c68 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cac:	4901                	li	s2,0
  iunlockput(ip);
    80004cae:	8556                	mv	a0,s5
    80004cb0:	fffff097          	auipc	ra,0xfffff
    80004cb4:	bfe080e7          	jalr	-1026(ra) # 800038ae <iunlockput>
  end_op();
    80004cb8:	fffff097          	auipc	ra,0xfffff
    80004cbc:	3de080e7          	jalr	990(ra) # 80004096 <end_op>
  p = myproc();
    80004cc0:	ffffd097          	auipc	ra,0xffffd
    80004cc4:	d0c080e7          	jalr	-756(ra) # 800019cc <myproc>
    80004cc8:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004cca:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004cce:	6785                	lui	a5,0x1
    80004cd0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004cd2:	97ca                	add	a5,a5,s2
    80004cd4:	777d                	lui	a4,0xfffff
    80004cd6:	8ff9                	and	a5,a5,a4
    80004cd8:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004cdc:	4691                	li	a3,4
    80004cde:	6609                	lui	a2,0x2
    80004ce0:	963e                	add	a2,a2,a5
    80004ce2:	85be                	mv	a1,a5
    80004ce4:	855a                	mv	a0,s6
    80004ce6:	ffffc097          	auipc	ra,0xffffc
    80004cea:	74a080e7          	jalr	1866(ra) # 80001430 <uvmalloc>
    80004cee:	8c2a                	mv	s8,a0
  ip = 0;
    80004cf0:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004cf2:	14050463          	beqz	a0,80004e3a <exec+0x2e0>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004cf6:	75f9                	lui	a1,0xffffe
    80004cf8:	95aa                	add	a1,a1,a0
    80004cfa:	855a                	mv	a0,s6
    80004cfc:	ffffd097          	auipc	ra,0xffffd
    80004d00:	95e080e7          	jalr	-1698(ra) # 8000165a <uvmclear>
  stackbase = sp - PGSIZE;
    80004d04:	7afd                	lui	s5,0xfffff
    80004d06:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d08:	df043783          	ld	a5,-528(s0)
    80004d0c:	6388                	ld	a0,0(a5)
    80004d0e:	c925                	beqz	a0,80004d7e <exec+0x224>
    80004d10:	e9040993          	addi	s3,s0,-368
    80004d14:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004d18:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d1a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d1c:	ffffc097          	auipc	ra,0xffffc
    80004d20:	132080e7          	jalr	306(ra) # 80000e4e <strlen>
    80004d24:	0015079b          	addiw	a5,a0,1
    80004d28:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d2c:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004d30:	13596c63          	bltu	s2,s5,80004e68 <exec+0x30e>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d34:	df043d83          	ld	s11,-528(s0)
    80004d38:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004d3c:	8552                	mv	a0,s4
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	110080e7          	jalr	272(ra) # 80000e4e <strlen>
    80004d46:	0015069b          	addiw	a3,a0,1
    80004d4a:	8652                	mv	a2,s4
    80004d4c:	85ca                	mv	a1,s2
    80004d4e:	855a                	mv	a0,s6
    80004d50:	ffffd097          	auipc	ra,0xffffd
    80004d54:	93c080e7          	jalr	-1732(ra) # 8000168c <copyout>
    80004d58:	10054c63          	bltz	a0,80004e70 <exec+0x316>
    ustack[argc] = sp;
    80004d5c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d60:	0485                	addi	s1,s1,1
    80004d62:	008d8793          	addi	a5,s11,8
    80004d66:	def43823          	sd	a5,-528(s0)
    80004d6a:	008db503          	ld	a0,8(s11)
    80004d6e:	c911                	beqz	a0,80004d82 <exec+0x228>
    if(argc >= MAXARG)
    80004d70:	09a1                	addi	s3,s3,8
    80004d72:	fb3c95e3          	bne	s9,s3,80004d1c <exec+0x1c2>
  sz = sz1;
    80004d76:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004d7a:	4a81                	li	s5,0
    80004d7c:	a87d                	j	80004e3a <exec+0x2e0>
  sp = sz;
    80004d7e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d80:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d82:	00349793          	slli	a5,s1,0x3
    80004d86:	f9078793          	addi	a5,a5,-112
    80004d8a:	97a2                	add	a5,a5,s0
    80004d8c:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004d90:	00148693          	addi	a3,s1,1
    80004d94:	068e                	slli	a3,a3,0x3
    80004d96:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d9a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d9e:	01597663          	bgeu	s2,s5,80004daa <exec+0x250>
  sz = sz1;
    80004da2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004da6:	4a81                	li	s5,0
    80004da8:	a849                	j	80004e3a <exec+0x2e0>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004daa:	e9040613          	addi	a2,s0,-368
    80004dae:	85ca                	mv	a1,s2
    80004db0:	855a                	mv	a0,s6
    80004db2:	ffffd097          	auipc	ra,0xffffd
    80004db6:	8da080e7          	jalr	-1830(ra) # 8000168c <copyout>
    80004dba:	0a054f63          	bltz	a0,80004e78 <exec+0x31e>
  p->trapframe->a1 = sp;
    80004dbe:	058bb783          	ld	a5,88(s7)
    80004dc2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004dc6:	de843783          	ld	a5,-536(s0)
    80004dca:	0007c703          	lbu	a4,0(a5)
    80004dce:	cf11                	beqz	a4,80004dea <exec+0x290>
    80004dd0:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004dd2:	02f00693          	li	a3,47
    80004dd6:	a039                	j	80004de4 <exec+0x28a>
      last = s+1;
    80004dd8:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004ddc:	0785                	addi	a5,a5,1
    80004dde:	fff7c703          	lbu	a4,-1(a5)
    80004de2:	c701                	beqz	a4,80004dea <exec+0x290>
    if(*s == '/')
    80004de4:	fed71ce3          	bne	a4,a3,80004ddc <exec+0x282>
    80004de8:	bfc5                	j	80004dd8 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004dea:	4641                	li	a2,16
    80004dec:	de843583          	ld	a1,-536(s0)
    80004df0:	158b8513          	addi	a0,s7,344
    80004df4:	ffffc097          	auipc	ra,0xffffc
    80004df8:	028080e7          	jalr	40(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004dfc:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e00:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e04:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e08:	058bb783          	ld	a5,88(s7)
    80004e0c:	e6843703          	ld	a4,-408(s0)
    80004e10:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e12:	058bb783          	ld	a5,88(s7)
    80004e16:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e1a:	85ea                	mv	a1,s10
    80004e1c:	ffffd097          	auipc	ra,0xffffd
    80004e20:	d10080e7          	jalr	-752(ra) # 80001b2c <proc_freepagetable>
  vmprint(p->pagetable);
    80004e24:	050bb503          	ld	a0,80(s7)
    80004e28:	ffffc097          	auipc	ra,0xffffc
    80004e2c:	166080e7          	jalr	358(ra) # 80000f8e <vmprint>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e30:	0004851b          	sext.w	a0,s1
    80004e34:	b3c9                	j	80004bf6 <exec+0x9c>
    80004e36:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004e3a:	df843583          	ld	a1,-520(s0)
    80004e3e:	855a                	mv	a0,s6
    80004e40:	ffffd097          	auipc	ra,0xffffd
    80004e44:	cec080e7          	jalr	-788(ra) # 80001b2c <proc_freepagetable>
  if(ip){
    80004e48:	d80a9de3          	bnez	s5,80004be2 <exec+0x88>
  return -1;
    80004e4c:	557d                	li	a0,-1
    80004e4e:	b365                	j	80004bf6 <exec+0x9c>
    80004e50:	df243c23          	sd	s2,-520(s0)
    80004e54:	b7dd                	j	80004e3a <exec+0x2e0>
    80004e56:	df243c23          	sd	s2,-520(s0)
    80004e5a:	b7c5                	j	80004e3a <exec+0x2e0>
    80004e5c:	df243c23          	sd	s2,-520(s0)
    80004e60:	bfe9                	j	80004e3a <exec+0x2e0>
    80004e62:	df243c23          	sd	s2,-520(s0)
    80004e66:	bfd1                	j	80004e3a <exec+0x2e0>
  sz = sz1;
    80004e68:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e6c:	4a81                	li	s5,0
    80004e6e:	b7f1                	j	80004e3a <exec+0x2e0>
  sz = sz1;
    80004e70:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e74:	4a81                	li	s5,0
    80004e76:	b7d1                	j	80004e3a <exec+0x2e0>
  sz = sz1;
    80004e78:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e7c:	4a81                	li	s5,0
    80004e7e:	bf75                	j	80004e3a <exec+0x2e0>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004e80:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e84:	e0843783          	ld	a5,-504(s0)
    80004e88:	0017869b          	addiw	a3,a5,1
    80004e8c:	e0d43423          	sd	a3,-504(s0)
    80004e90:	e0043783          	ld	a5,-512(s0)
    80004e94:	0387879b          	addiw	a5,a5,56
    80004e98:	e8845703          	lhu	a4,-376(s0)
    80004e9c:	e0e6d9e3          	bge	a3,a4,80004cae <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ea0:	2781                	sext.w	a5,a5
    80004ea2:	e0f43023          	sd	a5,-512(s0)
    80004ea6:	03800713          	li	a4,56
    80004eaa:	86be                	mv	a3,a5
    80004eac:	e1840613          	addi	a2,s0,-488
    80004eb0:	4581                	li	a1,0
    80004eb2:	8556                	mv	a0,s5
    80004eb4:	fffff097          	auipc	ra,0xfffff
    80004eb8:	a4c080e7          	jalr	-1460(ra) # 80003900 <readi>
    80004ebc:	03800793          	li	a5,56
    80004ec0:	f6f51be3          	bne	a0,a5,80004e36 <exec+0x2dc>
    if(ph.type != ELF_PROG_LOAD)
    80004ec4:	e1842783          	lw	a5,-488(s0)
    80004ec8:	4705                	li	a4,1
    80004eca:	fae79de3          	bne	a5,a4,80004e84 <exec+0x32a>
    if(ph.memsz < ph.filesz)
    80004ece:	e4043483          	ld	s1,-448(s0)
    80004ed2:	e3843783          	ld	a5,-456(s0)
    80004ed6:	f6f4ede3          	bltu	s1,a5,80004e50 <exec+0x2f6>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004eda:	e2843783          	ld	a5,-472(s0)
    80004ede:	94be                	add	s1,s1,a5
    80004ee0:	f6f4ebe3          	bltu	s1,a5,80004e56 <exec+0x2fc>
    if(ph.vaddr % PGSIZE != 0)
    80004ee4:	de043703          	ld	a4,-544(s0)
    80004ee8:	8ff9                	and	a5,a5,a4
    80004eea:	fbad                	bnez	a5,80004e5c <exec+0x302>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004eec:	e1c42503          	lw	a0,-484(s0)
    80004ef0:	00000097          	auipc	ra,0x0
    80004ef4:	c50080e7          	jalr	-944(ra) # 80004b40 <flags2perm>
    80004ef8:	86aa                	mv	a3,a0
    80004efa:	8626                	mv	a2,s1
    80004efc:	85ca                	mv	a1,s2
    80004efe:	855a                	mv	a0,s6
    80004f00:	ffffc097          	auipc	ra,0xffffc
    80004f04:	530080e7          	jalr	1328(ra) # 80001430 <uvmalloc>
    80004f08:	dea43c23          	sd	a0,-520(s0)
    80004f0c:	d939                	beqz	a0,80004e62 <exec+0x308>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f0e:	e2843c03          	ld	s8,-472(s0)
    80004f12:	e2042c83          	lw	s9,-480(s0)
    80004f16:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f1a:	f60b83e3          	beqz	s7,80004e80 <exec+0x326>
    80004f1e:	89de                	mv	s3,s7
    80004f20:	4481                	li	s1,0
    80004f22:	b3ad                	j	80004c8c <exec+0x132>

0000000080004f24 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f24:	7179                	addi	sp,sp,-48
    80004f26:	f406                	sd	ra,40(sp)
    80004f28:	f022                	sd	s0,32(sp)
    80004f2a:	ec26                	sd	s1,24(sp)
    80004f2c:	e84a                	sd	s2,16(sp)
    80004f2e:	1800                	addi	s0,sp,48
    80004f30:	892e                	mv	s2,a1
    80004f32:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004f34:	fdc40593          	addi	a1,s0,-36
    80004f38:	ffffe097          	auipc	ra,0xffffe
    80004f3c:	baa080e7          	jalr	-1110(ra) # 80002ae2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f40:	fdc42703          	lw	a4,-36(s0)
    80004f44:	47bd                	li	a5,15
    80004f46:	02e7eb63          	bltu	a5,a4,80004f7c <argfd+0x58>
    80004f4a:	ffffd097          	auipc	ra,0xffffd
    80004f4e:	a82080e7          	jalr	-1406(ra) # 800019cc <myproc>
    80004f52:	fdc42703          	lw	a4,-36(s0)
    80004f56:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd29a>
    80004f5a:	078e                	slli	a5,a5,0x3
    80004f5c:	953e                	add	a0,a0,a5
    80004f5e:	611c                	ld	a5,0(a0)
    80004f60:	c385                	beqz	a5,80004f80 <argfd+0x5c>
    return -1;
  if(pfd)
    80004f62:	00090463          	beqz	s2,80004f6a <argfd+0x46>
    *pfd = fd;
    80004f66:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004f6a:	4501                	li	a0,0
  if(pf)
    80004f6c:	c091                	beqz	s1,80004f70 <argfd+0x4c>
    *pf = f;
    80004f6e:	e09c                	sd	a5,0(s1)
}
    80004f70:	70a2                	ld	ra,40(sp)
    80004f72:	7402                	ld	s0,32(sp)
    80004f74:	64e2                	ld	s1,24(sp)
    80004f76:	6942                	ld	s2,16(sp)
    80004f78:	6145                	addi	sp,sp,48
    80004f7a:	8082                	ret
    return -1;
    80004f7c:	557d                	li	a0,-1
    80004f7e:	bfcd                	j	80004f70 <argfd+0x4c>
    80004f80:	557d                	li	a0,-1
    80004f82:	b7fd                	j	80004f70 <argfd+0x4c>

0000000080004f84 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f84:	1101                	addi	sp,sp,-32
    80004f86:	ec06                	sd	ra,24(sp)
    80004f88:	e822                	sd	s0,16(sp)
    80004f8a:	e426                	sd	s1,8(sp)
    80004f8c:	1000                	addi	s0,sp,32
    80004f8e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f90:	ffffd097          	auipc	ra,0xffffd
    80004f94:	a3c080e7          	jalr	-1476(ra) # 800019cc <myproc>
    80004f98:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f9a:	0d050793          	addi	a5,a0,208
    80004f9e:	4501                	li	a0,0
    80004fa0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004fa2:	6398                	ld	a4,0(a5)
    80004fa4:	cb19                	beqz	a4,80004fba <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004fa6:	2505                	addiw	a0,a0,1
    80004fa8:	07a1                	addi	a5,a5,8
    80004faa:	fed51ce3          	bne	a0,a3,80004fa2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004fae:	557d                	li	a0,-1
}
    80004fb0:	60e2                	ld	ra,24(sp)
    80004fb2:	6442                	ld	s0,16(sp)
    80004fb4:	64a2                	ld	s1,8(sp)
    80004fb6:	6105                	addi	sp,sp,32
    80004fb8:	8082                	ret
      p->ofile[fd] = f;
    80004fba:	01a50793          	addi	a5,a0,26
    80004fbe:	078e                	slli	a5,a5,0x3
    80004fc0:	963e                	add	a2,a2,a5
    80004fc2:	e204                	sd	s1,0(a2)
      return fd;
    80004fc4:	b7f5                	j	80004fb0 <fdalloc+0x2c>

0000000080004fc6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004fc6:	715d                	addi	sp,sp,-80
    80004fc8:	e486                	sd	ra,72(sp)
    80004fca:	e0a2                	sd	s0,64(sp)
    80004fcc:	fc26                	sd	s1,56(sp)
    80004fce:	f84a                	sd	s2,48(sp)
    80004fd0:	f44e                	sd	s3,40(sp)
    80004fd2:	f052                	sd	s4,32(sp)
    80004fd4:	ec56                	sd	s5,24(sp)
    80004fd6:	e85a                	sd	s6,16(sp)
    80004fd8:	0880                	addi	s0,sp,80
    80004fda:	8b2e                	mv	s6,a1
    80004fdc:	89b2                	mv	s3,a2
    80004fde:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004fe0:	fb040593          	addi	a1,s0,-80
    80004fe4:	fffff097          	auipc	ra,0xfffff
    80004fe8:	e32080e7          	jalr	-462(ra) # 80003e16 <nameiparent>
    80004fec:	84aa                	mv	s1,a0
    80004fee:	14050f63          	beqz	a0,8000514c <create+0x186>
    return 0;

  ilock(dp);
    80004ff2:	ffffe097          	auipc	ra,0xffffe
    80004ff6:	65a080e7          	jalr	1626(ra) # 8000364c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004ffa:	4601                	li	a2,0
    80004ffc:	fb040593          	addi	a1,s0,-80
    80005000:	8526                	mv	a0,s1
    80005002:	fffff097          	auipc	ra,0xfffff
    80005006:	b2e080e7          	jalr	-1234(ra) # 80003b30 <dirlookup>
    8000500a:	8aaa                	mv	s5,a0
    8000500c:	c931                	beqz	a0,80005060 <create+0x9a>
    iunlockput(dp);
    8000500e:	8526                	mv	a0,s1
    80005010:	fffff097          	auipc	ra,0xfffff
    80005014:	89e080e7          	jalr	-1890(ra) # 800038ae <iunlockput>
    ilock(ip);
    80005018:	8556                	mv	a0,s5
    8000501a:	ffffe097          	auipc	ra,0xffffe
    8000501e:	632080e7          	jalr	1586(ra) # 8000364c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005022:	000b059b          	sext.w	a1,s6
    80005026:	4789                	li	a5,2
    80005028:	02f59563          	bne	a1,a5,80005052 <create+0x8c>
    8000502c:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd2c4>
    80005030:	37f9                	addiw	a5,a5,-2
    80005032:	17c2                	slli	a5,a5,0x30
    80005034:	93c1                	srli	a5,a5,0x30
    80005036:	4705                	li	a4,1
    80005038:	00f76d63          	bltu	a4,a5,80005052 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000503c:	8556                	mv	a0,s5
    8000503e:	60a6                	ld	ra,72(sp)
    80005040:	6406                	ld	s0,64(sp)
    80005042:	74e2                	ld	s1,56(sp)
    80005044:	7942                	ld	s2,48(sp)
    80005046:	79a2                	ld	s3,40(sp)
    80005048:	7a02                	ld	s4,32(sp)
    8000504a:	6ae2                	ld	s5,24(sp)
    8000504c:	6b42                	ld	s6,16(sp)
    8000504e:	6161                	addi	sp,sp,80
    80005050:	8082                	ret
    iunlockput(ip);
    80005052:	8556                	mv	a0,s5
    80005054:	fffff097          	auipc	ra,0xfffff
    80005058:	85a080e7          	jalr	-1958(ra) # 800038ae <iunlockput>
    return 0;
    8000505c:	4a81                	li	s5,0
    8000505e:	bff9                	j	8000503c <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005060:	85da                	mv	a1,s6
    80005062:	4088                	lw	a0,0(s1)
    80005064:	ffffe097          	auipc	ra,0xffffe
    80005068:	44a080e7          	jalr	1098(ra) # 800034ae <ialloc>
    8000506c:	8a2a                	mv	s4,a0
    8000506e:	c539                	beqz	a0,800050bc <create+0xf6>
  ilock(ip);
    80005070:	ffffe097          	auipc	ra,0xffffe
    80005074:	5dc080e7          	jalr	1500(ra) # 8000364c <ilock>
  ip->major = major;
    80005078:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000507c:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005080:	4905                	li	s2,1
    80005082:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005086:	8552                	mv	a0,s4
    80005088:	ffffe097          	auipc	ra,0xffffe
    8000508c:	4f8080e7          	jalr	1272(ra) # 80003580 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005090:	000b059b          	sext.w	a1,s6
    80005094:	03258b63          	beq	a1,s2,800050ca <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005098:	004a2603          	lw	a2,4(s4)
    8000509c:	fb040593          	addi	a1,s0,-80
    800050a0:	8526                	mv	a0,s1
    800050a2:	fffff097          	auipc	ra,0xfffff
    800050a6:	ca4080e7          	jalr	-860(ra) # 80003d46 <dirlink>
    800050aa:	06054f63          	bltz	a0,80005128 <create+0x162>
  iunlockput(dp);
    800050ae:	8526                	mv	a0,s1
    800050b0:	ffffe097          	auipc	ra,0xffffe
    800050b4:	7fe080e7          	jalr	2046(ra) # 800038ae <iunlockput>
  return ip;
    800050b8:	8ad2                	mv	s5,s4
    800050ba:	b749                	j	8000503c <create+0x76>
    iunlockput(dp);
    800050bc:	8526                	mv	a0,s1
    800050be:	ffffe097          	auipc	ra,0xffffe
    800050c2:	7f0080e7          	jalr	2032(ra) # 800038ae <iunlockput>
    return 0;
    800050c6:	8ad2                	mv	s5,s4
    800050c8:	bf95                	j	8000503c <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800050ca:	004a2603          	lw	a2,4(s4)
    800050ce:	00003597          	auipc	a1,0x3
    800050d2:	63a58593          	addi	a1,a1,1594 # 80008708 <syscalls+0x2a0>
    800050d6:	8552                	mv	a0,s4
    800050d8:	fffff097          	auipc	ra,0xfffff
    800050dc:	c6e080e7          	jalr	-914(ra) # 80003d46 <dirlink>
    800050e0:	04054463          	bltz	a0,80005128 <create+0x162>
    800050e4:	40d0                	lw	a2,4(s1)
    800050e6:	00003597          	auipc	a1,0x3
    800050ea:	62a58593          	addi	a1,a1,1578 # 80008710 <syscalls+0x2a8>
    800050ee:	8552                	mv	a0,s4
    800050f0:	fffff097          	auipc	ra,0xfffff
    800050f4:	c56080e7          	jalr	-938(ra) # 80003d46 <dirlink>
    800050f8:	02054863          	bltz	a0,80005128 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800050fc:	004a2603          	lw	a2,4(s4)
    80005100:	fb040593          	addi	a1,s0,-80
    80005104:	8526                	mv	a0,s1
    80005106:	fffff097          	auipc	ra,0xfffff
    8000510a:	c40080e7          	jalr	-960(ra) # 80003d46 <dirlink>
    8000510e:	00054d63          	bltz	a0,80005128 <create+0x162>
    dp->nlink++;  // for ".."
    80005112:	04a4d783          	lhu	a5,74(s1)
    80005116:	2785                	addiw	a5,a5,1
    80005118:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000511c:	8526                	mv	a0,s1
    8000511e:	ffffe097          	auipc	ra,0xffffe
    80005122:	462080e7          	jalr	1122(ra) # 80003580 <iupdate>
    80005126:	b761                	j	800050ae <create+0xe8>
  ip->nlink = 0;
    80005128:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000512c:	8552                	mv	a0,s4
    8000512e:	ffffe097          	auipc	ra,0xffffe
    80005132:	452080e7          	jalr	1106(ra) # 80003580 <iupdate>
  iunlockput(ip);
    80005136:	8552                	mv	a0,s4
    80005138:	ffffe097          	auipc	ra,0xffffe
    8000513c:	776080e7          	jalr	1910(ra) # 800038ae <iunlockput>
  iunlockput(dp);
    80005140:	8526                	mv	a0,s1
    80005142:	ffffe097          	auipc	ra,0xffffe
    80005146:	76c080e7          	jalr	1900(ra) # 800038ae <iunlockput>
  return 0;
    8000514a:	bdcd                	j	8000503c <create+0x76>
    return 0;
    8000514c:	8aaa                	mv	s5,a0
    8000514e:	b5fd                	j	8000503c <create+0x76>

0000000080005150 <sys_dup>:
{
    80005150:	7179                	addi	sp,sp,-48
    80005152:	f406                	sd	ra,40(sp)
    80005154:	f022                	sd	s0,32(sp)
    80005156:	ec26                	sd	s1,24(sp)
    80005158:	e84a                	sd	s2,16(sp)
    8000515a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000515c:	fd840613          	addi	a2,s0,-40
    80005160:	4581                	li	a1,0
    80005162:	4501                	li	a0,0
    80005164:	00000097          	auipc	ra,0x0
    80005168:	dc0080e7          	jalr	-576(ra) # 80004f24 <argfd>
    return -1;
    8000516c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000516e:	02054363          	bltz	a0,80005194 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005172:	fd843903          	ld	s2,-40(s0)
    80005176:	854a                	mv	a0,s2
    80005178:	00000097          	auipc	ra,0x0
    8000517c:	e0c080e7          	jalr	-500(ra) # 80004f84 <fdalloc>
    80005180:	84aa                	mv	s1,a0
    return -1;
    80005182:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005184:	00054863          	bltz	a0,80005194 <sys_dup+0x44>
  filedup(f);
    80005188:	854a                	mv	a0,s2
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	304080e7          	jalr	772(ra) # 8000448e <filedup>
  return fd;
    80005192:	87a6                	mv	a5,s1
}
    80005194:	853e                	mv	a0,a5
    80005196:	70a2                	ld	ra,40(sp)
    80005198:	7402                	ld	s0,32(sp)
    8000519a:	64e2                	ld	s1,24(sp)
    8000519c:	6942                	ld	s2,16(sp)
    8000519e:	6145                	addi	sp,sp,48
    800051a0:	8082                	ret

00000000800051a2 <sys_read>:
{
    800051a2:	7179                	addi	sp,sp,-48
    800051a4:	f406                	sd	ra,40(sp)
    800051a6:	f022                	sd	s0,32(sp)
    800051a8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800051aa:	fd840593          	addi	a1,s0,-40
    800051ae:	4505                	li	a0,1
    800051b0:	ffffe097          	auipc	ra,0xffffe
    800051b4:	952080e7          	jalr	-1710(ra) # 80002b02 <argaddr>
  argint(2, &n);
    800051b8:	fe440593          	addi	a1,s0,-28
    800051bc:	4509                	li	a0,2
    800051be:	ffffe097          	auipc	ra,0xffffe
    800051c2:	924080e7          	jalr	-1756(ra) # 80002ae2 <argint>
  if(argfd(0, 0, &f) < 0)
    800051c6:	fe840613          	addi	a2,s0,-24
    800051ca:	4581                	li	a1,0
    800051cc:	4501                	li	a0,0
    800051ce:	00000097          	auipc	ra,0x0
    800051d2:	d56080e7          	jalr	-682(ra) # 80004f24 <argfd>
    800051d6:	87aa                	mv	a5,a0
    return -1;
    800051d8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800051da:	0007cc63          	bltz	a5,800051f2 <sys_read+0x50>
  return fileread(f, p, n);
    800051de:	fe442603          	lw	a2,-28(s0)
    800051e2:	fd843583          	ld	a1,-40(s0)
    800051e6:	fe843503          	ld	a0,-24(s0)
    800051ea:	fffff097          	auipc	ra,0xfffff
    800051ee:	430080e7          	jalr	1072(ra) # 8000461a <fileread>
}
    800051f2:	70a2                	ld	ra,40(sp)
    800051f4:	7402                	ld	s0,32(sp)
    800051f6:	6145                	addi	sp,sp,48
    800051f8:	8082                	ret

00000000800051fa <sys_write>:
{
    800051fa:	7179                	addi	sp,sp,-48
    800051fc:	f406                	sd	ra,40(sp)
    800051fe:	f022                	sd	s0,32(sp)
    80005200:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005202:	fd840593          	addi	a1,s0,-40
    80005206:	4505                	li	a0,1
    80005208:	ffffe097          	auipc	ra,0xffffe
    8000520c:	8fa080e7          	jalr	-1798(ra) # 80002b02 <argaddr>
  argint(2, &n);
    80005210:	fe440593          	addi	a1,s0,-28
    80005214:	4509                	li	a0,2
    80005216:	ffffe097          	auipc	ra,0xffffe
    8000521a:	8cc080e7          	jalr	-1844(ra) # 80002ae2 <argint>
  if(argfd(0, 0, &f) < 0)
    8000521e:	fe840613          	addi	a2,s0,-24
    80005222:	4581                	li	a1,0
    80005224:	4501                	li	a0,0
    80005226:	00000097          	auipc	ra,0x0
    8000522a:	cfe080e7          	jalr	-770(ra) # 80004f24 <argfd>
    8000522e:	87aa                	mv	a5,a0
    return -1;
    80005230:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005232:	0007cc63          	bltz	a5,8000524a <sys_write+0x50>
  return filewrite(f, p, n);
    80005236:	fe442603          	lw	a2,-28(s0)
    8000523a:	fd843583          	ld	a1,-40(s0)
    8000523e:	fe843503          	ld	a0,-24(s0)
    80005242:	fffff097          	auipc	ra,0xfffff
    80005246:	49a080e7          	jalr	1178(ra) # 800046dc <filewrite>
}
    8000524a:	70a2                	ld	ra,40(sp)
    8000524c:	7402                	ld	s0,32(sp)
    8000524e:	6145                	addi	sp,sp,48
    80005250:	8082                	ret

0000000080005252 <sys_close>:
{
    80005252:	1101                	addi	sp,sp,-32
    80005254:	ec06                	sd	ra,24(sp)
    80005256:	e822                	sd	s0,16(sp)
    80005258:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000525a:	fe040613          	addi	a2,s0,-32
    8000525e:	fec40593          	addi	a1,s0,-20
    80005262:	4501                	li	a0,0
    80005264:	00000097          	auipc	ra,0x0
    80005268:	cc0080e7          	jalr	-832(ra) # 80004f24 <argfd>
    return -1;
    8000526c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000526e:	02054463          	bltz	a0,80005296 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005272:	ffffc097          	auipc	ra,0xffffc
    80005276:	75a080e7          	jalr	1882(ra) # 800019cc <myproc>
    8000527a:	fec42783          	lw	a5,-20(s0)
    8000527e:	07e9                	addi	a5,a5,26
    80005280:	078e                	slli	a5,a5,0x3
    80005282:	953e                	add	a0,a0,a5
    80005284:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005288:	fe043503          	ld	a0,-32(s0)
    8000528c:	fffff097          	auipc	ra,0xfffff
    80005290:	254080e7          	jalr	596(ra) # 800044e0 <fileclose>
  return 0;
    80005294:	4781                	li	a5,0
}
    80005296:	853e                	mv	a0,a5
    80005298:	60e2                	ld	ra,24(sp)
    8000529a:	6442                	ld	s0,16(sp)
    8000529c:	6105                	addi	sp,sp,32
    8000529e:	8082                	ret

00000000800052a0 <sys_fstat>:
{
    800052a0:	1101                	addi	sp,sp,-32
    800052a2:	ec06                	sd	ra,24(sp)
    800052a4:	e822                	sd	s0,16(sp)
    800052a6:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800052a8:	fe040593          	addi	a1,s0,-32
    800052ac:	4505                	li	a0,1
    800052ae:	ffffe097          	auipc	ra,0xffffe
    800052b2:	854080e7          	jalr	-1964(ra) # 80002b02 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800052b6:	fe840613          	addi	a2,s0,-24
    800052ba:	4581                	li	a1,0
    800052bc:	4501                	li	a0,0
    800052be:	00000097          	auipc	ra,0x0
    800052c2:	c66080e7          	jalr	-922(ra) # 80004f24 <argfd>
    800052c6:	87aa                	mv	a5,a0
    return -1;
    800052c8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052ca:	0007ca63          	bltz	a5,800052de <sys_fstat+0x3e>
  return filestat(f, st);
    800052ce:	fe043583          	ld	a1,-32(s0)
    800052d2:	fe843503          	ld	a0,-24(s0)
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	2d2080e7          	jalr	722(ra) # 800045a8 <filestat>
}
    800052de:	60e2                	ld	ra,24(sp)
    800052e0:	6442                	ld	s0,16(sp)
    800052e2:	6105                	addi	sp,sp,32
    800052e4:	8082                	ret

00000000800052e6 <sys_link>:
{
    800052e6:	7169                	addi	sp,sp,-304
    800052e8:	f606                	sd	ra,296(sp)
    800052ea:	f222                	sd	s0,288(sp)
    800052ec:	ee26                	sd	s1,280(sp)
    800052ee:	ea4a                	sd	s2,272(sp)
    800052f0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052f2:	08000613          	li	a2,128
    800052f6:	ed040593          	addi	a1,s0,-304
    800052fa:	4501                	li	a0,0
    800052fc:	ffffe097          	auipc	ra,0xffffe
    80005300:	826080e7          	jalr	-2010(ra) # 80002b22 <argstr>
    return -1;
    80005304:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005306:	10054e63          	bltz	a0,80005422 <sys_link+0x13c>
    8000530a:	08000613          	li	a2,128
    8000530e:	f5040593          	addi	a1,s0,-176
    80005312:	4505                	li	a0,1
    80005314:	ffffe097          	auipc	ra,0xffffe
    80005318:	80e080e7          	jalr	-2034(ra) # 80002b22 <argstr>
    return -1;
    8000531c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000531e:	10054263          	bltz	a0,80005422 <sys_link+0x13c>
  begin_op();
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	cf6080e7          	jalr	-778(ra) # 80004018 <begin_op>
  if((ip = namei(old)) == 0){
    8000532a:	ed040513          	addi	a0,s0,-304
    8000532e:	fffff097          	auipc	ra,0xfffff
    80005332:	aca080e7          	jalr	-1334(ra) # 80003df8 <namei>
    80005336:	84aa                	mv	s1,a0
    80005338:	c551                	beqz	a0,800053c4 <sys_link+0xde>
  ilock(ip);
    8000533a:	ffffe097          	auipc	ra,0xffffe
    8000533e:	312080e7          	jalr	786(ra) # 8000364c <ilock>
  if(ip->type == T_DIR){
    80005342:	04449703          	lh	a4,68(s1)
    80005346:	4785                	li	a5,1
    80005348:	08f70463          	beq	a4,a5,800053d0 <sys_link+0xea>
  ip->nlink++;
    8000534c:	04a4d783          	lhu	a5,74(s1)
    80005350:	2785                	addiw	a5,a5,1
    80005352:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005356:	8526                	mv	a0,s1
    80005358:	ffffe097          	auipc	ra,0xffffe
    8000535c:	228080e7          	jalr	552(ra) # 80003580 <iupdate>
  iunlock(ip);
    80005360:	8526                	mv	a0,s1
    80005362:	ffffe097          	auipc	ra,0xffffe
    80005366:	3ac080e7          	jalr	940(ra) # 8000370e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000536a:	fd040593          	addi	a1,s0,-48
    8000536e:	f5040513          	addi	a0,s0,-176
    80005372:	fffff097          	auipc	ra,0xfffff
    80005376:	aa4080e7          	jalr	-1372(ra) # 80003e16 <nameiparent>
    8000537a:	892a                	mv	s2,a0
    8000537c:	c935                	beqz	a0,800053f0 <sys_link+0x10a>
  ilock(dp);
    8000537e:	ffffe097          	auipc	ra,0xffffe
    80005382:	2ce080e7          	jalr	718(ra) # 8000364c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005386:	00092703          	lw	a4,0(s2)
    8000538a:	409c                	lw	a5,0(s1)
    8000538c:	04f71d63          	bne	a4,a5,800053e6 <sys_link+0x100>
    80005390:	40d0                	lw	a2,4(s1)
    80005392:	fd040593          	addi	a1,s0,-48
    80005396:	854a                	mv	a0,s2
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	9ae080e7          	jalr	-1618(ra) # 80003d46 <dirlink>
    800053a0:	04054363          	bltz	a0,800053e6 <sys_link+0x100>
  iunlockput(dp);
    800053a4:	854a                	mv	a0,s2
    800053a6:	ffffe097          	auipc	ra,0xffffe
    800053aa:	508080e7          	jalr	1288(ra) # 800038ae <iunlockput>
  iput(ip);
    800053ae:	8526                	mv	a0,s1
    800053b0:	ffffe097          	auipc	ra,0xffffe
    800053b4:	456080e7          	jalr	1110(ra) # 80003806 <iput>
  end_op();
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	cde080e7          	jalr	-802(ra) # 80004096 <end_op>
  return 0;
    800053c0:	4781                	li	a5,0
    800053c2:	a085                	j	80005422 <sys_link+0x13c>
    end_op();
    800053c4:	fffff097          	auipc	ra,0xfffff
    800053c8:	cd2080e7          	jalr	-814(ra) # 80004096 <end_op>
    return -1;
    800053cc:	57fd                	li	a5,-1
    800053ce:	a891                	j	80005422 <sys_link+0x13c>
    iunlockput(ip);
    800053d0:	8526                	mv	a0,s1
    800053d2:	ffffe097          	auipc	ra,0xffffe
    800053d6:	4dc080e7          	jalr	1244(ra) # 800038ae <iunlockput>
    end_op();
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	cbc080e7          	jalr	-836(ra) # 80004096 <end_op>
    return -1;
    800053e2:	57fd                	li	a5,-1
    800053e4:	a83d                	j	80005422 <sys_link+0x13c>
    iunlockput(dp);
    800053e6:	854a                	mv	a0,s2
    800053e8:	ffffe097          	auipc	ra,0xffffe
    800053ec:	4c6080e7          	jalr	1222(ra) # 800038ae <iunlockput>
  ilock(ip);
    800053f0:	8526                	mv	a0,s1
    800053f2:	ffffe097          	auipc	ra,0xffffe
    800053f6:	25a080e7          	jalr	602(ra) # 8000364c <ilock>
  ip->nlink--;
    800053fa:	04a4d783          	lhu	a5,74(s1)
    800053fe:	37fd                	addiw	a5,a5,-1
    80005400:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005404:	8526                	mv	a0,s1
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	17a080e7          	jalr	378(ra) # 80003580 <iupdate>
  iunlockput(ip);
    8000540e:	8526                	mv	a0,s1
    80005410:	ffffe097          	auipc	ra,0xffffe
    80005414:	49e080e7          	jalr	1182(ra) # 800038ae <iunlockput>
  end_op();
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	c7e080e7          	jalr	-898(ra) # 80004096 <end_op>
  return -1;
    80005420:	57fd                	li	a5,-1
}
    80005422:	853e                	mv	a0,a5
    80005424:	70b2                	ld	ra,296(sp)
    80005426:	7412                	ld	s0,288(sp)
    80005428:	64f2                	ld	s1,280(sp)
    8000542a:	6952                	ld	s2,272(sp)
    8000542c:	6155                	addi	sp,sp,304
    8000542e:	8082                	ret

0000000080005430 <sys_unlink>:
{
    80005430:	7151                	addi	sp,sp,-240
    80005432:	f586                	sd	ra,232(sp)
    80005434:	f1a2                	sd	s0,224(sp)
    80005436:	eda6                	sd	s1,216(sp)
    80005438:	e9ca                	sd	s2,208(sp)
    8000543a:	e5ce                	sd	s3,200(sp)
    8000543c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000543e:	08000613          	li	a2,128
    80005442:	f3040593          	addi	a1,s0,-208
    80005446:	4501                	li	a0,0
    80005448:	ffffd097          	auipc	ra,0xffffd
    8000544c:	6da080e7          	jalr	1754(ra) # 80002b22 <argstr>
    80005450:	18054163          	bltz	a0,800055d2 <sys_unlink+0x1a2>
  begin_op();
    80005454:	fffff097          	auipc	ra,0xfffff
    80005458:	bc4080e7          	jalr	-1084(ra) # 80004018 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000545c:	fb040593          	addi	a1,s0,-80
    80005460:	f3040513          	addi	a0,s0,-208
    80005464:	fffff097          	auipc	ra,0xfffff
    80005468:	9b2080e7          	jalr	-1614(ra) # 80003e16 <nameiparent>
    8000546c:	84aa                	mv	s1,a0
    8000546e:	c979                	beqz	a0,80005544 <sys_unlink+0x114>
  ilock(dp);
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	1dc080e7          	jalr	476(ra) # 8000364c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005478:	00003597          	auipc	a1,0x3
    8000547c:	29058593          	addi	a1,a1,656 # 80008708 <syscalls+0x2a0>
    80005480:	fb040513          	addi	a0,s0,-80
    80005484:	ffffe097          	auipc	ra,0xffffe
    80005488:	692080e7          	jalr	1682(ra) # 80003b16 <namecmp>
    8000548c:	14050a63          	beqz	a0,800055e0 <sys_unlink+0x1b0>
    80005490:	00003597          	auipc	a1,0x3
    80005494:	28058593          	addi	a1,a1,640 # 80008710 <syscalls+0x2a8>
    80005498:	fb040513          	addi	a0,s0,-80
    8000549c:	ffffe097          	auipc	ra,0xffffe
    800054a0:	67a080e7          	jalr	1658(ra) # 80003b16 <namecmp>
    800054a4:	12050e63          	beqz	a0,800055e0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054a8:	f2c40613          	addi	a2,s0,-212
    800054ac:	fb040593          	addi	a1,s0,-80
    800054b0:	8526                	mv	a0,s1
    800054b2:	ffffe097          	auipc	ra,0xffffe
    800054b6:	67e080e7          	jalr	1662(ra) # 80003b30 <dirlookup>
    800054ba:	892a                	mv	s2,a0
    800054bc:	12050263          	beqz	a0,800055e0 <sys_unlink+0x1b0>
  ilock(ip);
    800054c0:	ffffe097          	auipc	ra,0xffffe
    800054c4:	18c080e7          	jalr	396(ra) # 8000364c <ilock>
  if(ip->nlink < 1)
    800054c8:	04a91783          	lh	a5,74(s2)
    800054cc:	08f05263          	blez	a5,80005550 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800054d0:	04491703          	lh	a4,68(s2)
    800054d4:	4785                	li	a5,1
    800054d6:	08f70563          	beq	a4,a5,80005560 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800054da:	4641                	li	a2,16
    800054dc:	4581                	li	a1,0
    800054de:	fc040513          	addi	a0,s0,-64
    800054e2:	ffffb097          	auipc	ra,0xffffb
    800054e6:	7f0080e7          	jalr	2032(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054ea:	4741                	li	a4,16
    800054ec:	f2c42683          	lw	a3,-212(s0)
    800054f0:	fc040613          	addi	a2,s0,-64
    800054f4:	4581                	li	a1,0
    800054f6:	8526                	mv	a0,s1
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	500080e7          	jalr	1280(ra) # 800039f8 <writei>
    80005500:	47c1                	li	a5,16
    80005502:	0af51563          	bne	a0,a5,800055ac <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005506:	04491703          	lh	a4,68(s2)
    8000550a:	4785                	li	a5,1
    8000550c:	0af70863          	beq	a4,a5,800055bc <sys_unlink+0x18c>
  iunlockput(dp);
    80005510:	8526                	mv	a0,s1
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	39c080e7          	jalr	924(ra) # 800038ae <iunlockput>
  ip->nlink--;
    8000551a:	04a95783          	lhu	a5,74(s2)
    8000551e:	37fd                	addiw	a5,a5,-1
    80005520:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005524:	854a                	mv	a0,s2
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	05a080e7          	jalr	90(ra) # 80003580 <iupdate>
  iunlockput(ip);
    8000552e:	854a                	mv	a0,s2
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	37e080e7          	jalr	894(ra) # 800038ae <iunlockput>
  end_op();
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	b5e080e7          	jalr	-1186(ra) # 80004096 <end_op>
  return 0;
    80005540:	4501                	li	a0,0
    80005542:	a84d                	j	800055f4 <sys_unlink+0x1c4>
    end_op();
    80005544:	fffff097          	auipc	ra,0xfffff
    80005548:	b52080e7          	jalr	-1198(ra) # 80004096 <end_op>
    return -1;
    8000554c:	557d                	li	a0,-1
    8000554e:	a05d                	j	800055f4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005550:	00003517          	auipc	a0,0x3
    80005554:	1c850513          	addi	a0,a0,456 # 80008718 <syscalls+0x2b0>
    80005558:	ffffb097          	auipc	ra,0xffffb
    8000555c:	fe8080e7          	jalr	-24(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005560:	04c92703          	lw	a4,76(s2)
    80005564:	02000793          	li	a5,32
    80005568:	f6e7f9e3          	bgeu	a5,a4,800054da <sys_unlink+0xaa>
    8000556c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005570:	4741                	li	a4,16
    80005572:	86ce                	mv	a3,s3
    80005574:	f1840613          	addi	a2,s0,-232
    80005578:	4581                	li	a1,0
    8000557a:	854a                	mv	a0,s2
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	384080e7          	jalr	900(ra) # 80003900 <readi>
    80005584:	47c1                	li	a5,16
    80005586:	00f51b63          	bne	a0,a5,8000559c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000558a:	f1845783          	lhu	a5,-232(s0)
    8000558e:	e7a1                	bnez	a5,800055d6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005590:	29c1                	addiw	s3,s3,16
    80005592:	04c92783          	lw	a5,76(s2)
    80005596:	fcf9ede3          	bltu	s3,a5,80005570 <sys_unlink+0x140>
    8000559a:	b781                	j	800054da <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000559c:	00003517          	auipc	a0,0x3
    800055a0:	19450513          	addi	a0,a0,404 # 80008730 <syscalls+0x2c8>
    800055a4:	ffffb097          	auipc	ra,0xffffb
    800055a8:	f9c080e7          	jalr	-100(ra) # 80000540 <panic>
    panic("unlink: writei");
    800055ac:	00003517          	auipc	a0,0x3
    800055b0:	19c50513          	addi	a0,a0,412 # 80008748 <syscalls+0x2e0>
    800055b4:	ffffb097          	auipc	ra,0xffffb
    800055b8:	f8c080e7          	jalr	-116(ra) # 80000540 <panic>
    dp->nlink--;
    800055bc:	04a4d783          	lhu	a5,74(s1)
    800055c0:	37fd                	addiw	a5,a5,-1
    800055c2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055c6:	8526                	mv	a0,s1
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	fb8080e7          	jalr	-72(ra) # 80003580 <iupdate>
    800055d0:	b781                	j	80005510 <sys_unlink+0xe0>
    return -1;
    800055d2:	557d                	li	a0,-1
    800055d4:	a005                	j	800055f4 <sys_unlink+0x1c4>
    iunlockput(ip);
    800055d6:	854a                	mv	a0,s2
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	2d6080e7          	jalr	726(ra) # 800038ae <iunlockput>
  iunlockput(dp);
    800055e0:	8526                	mv	a0,s1
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	2cc080e7          	jalr	716(ra) # 800038ae <iunlockput>
  end_op();
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	aac080e7          	jalr	-1364(ra) # 80004096 <end_op>
  return -1;
    800055f2:	557d                	li	a0,-1
}
    800055f4:	70ae                	ld	ra,232(sp)
    800055f6:	740e                	ld	s0,224(sp)
    800055f8:	64ee                	ld	s1,216(sp)
    800055fa:	694e                	ld	s2,208(sp)
    800055fc:	69ae                	ld	s3,200(sp)
    800055fe:	616d                	addi	sp,sp,240
    80005600:	8082                	ret

0000000080005602 <sys_open>:

uint64
sys_open(void)
{
    80005602:	7131                	addi	sp,sp,-192
    80005604:	fd06                	sd	ra,184(sp)
    80005606:	f922                	sd	s0,176(sp)
    80005608:	f526                	sd	s1,168(sp)
    8000560a:	f14a                	sd	s2,160(sp)
    8000560c:	ed4e                	sd	s3,152(sp)
    8000560e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005610:	f4c40593          	addi	a1,s0,-180
    80005614:	4505                	li	a0,1
    80005616:	ffffd097          	auipc	ra,0xffffd
    8000561a:	4cc080e7          	jalr	1228(ra) # 80002ae2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000561e:	08000613          	li	a2,128
    80005622:	f5040593          	addi	a1,s0,-176
    80005626:	4501                	li	a0,0
    80005628:	ffffd097          	auipc	ra,0xffffd
    8000562c:	4fa080e7          	jalr	1274(ra) # 80002b22 <argstr>
    80005630:	87aa                	mv	a5,a0
    return -1;
    80005632:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005634:	0a07c963          	bltz	a5,800056e6 <sys_open+0xe4>

  begin_op();
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	9e0080e7          	jalr	-1568(ra) # 80004018 <begin_op>

  if(omode & O_CREATE){
    80005640:	f4c42783          	lw	a5,-180(s0)
    80005644:	2007f793          	andi	a5,a5,512
    80005648:	cfc5                	beqz	a5,80005700 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000564a:	4681                	li	a3,0
    8000564c:	4601                	li	a2,0
    8000564e:	4589                	li	a1,2
    80005650:	f5040513          	addi	a0,s0,-176
    80005654:	00000097          	auipc	ra,0x0
    80005658:	972080e7          	jalr	-1678(ra) # 80004fc6 <create>
    8000565c:	84aa                	mv	s1,a0
    if(ip == 0){
    8000565e:	c959                	beqz	a0,800056f4 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005660:	04449703          	lh	a4,68(s1)
    80005664:	478d                	li	a5,3
    80005666:	00f71763          	bne	a4,a5,80005674 <sys_open+0x72>
    8000566a:	0464d703          	lhu	a4,70(s1)
    8000566e:	47a5                	li	a5,9
    80005670:	0ce7ed63          	bltu	a5,a4,8000574a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	db0080e7          	jalr	-592(ra) # 80004424 <filealloc>
    8000567c:	89aa                	mv	s3,a0
    8000567e:	10050363          	beqz	a0,80005784 <sys_open+0x182>
    80005682:	00000097          	auipc	ra,0x0
    80005686:	902080e7          	jalr	-1790(ra) # 80004f84 <fdalloc>
    8000568a:	892a                	mv	s2,a0
    8000568c:	0e054763          	bltz	a0,8000577a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005690:	04449703          	lh	a4,68(s1)
    80005694:	478d                	li	a5,3
    80005696:	0cf70563          	beq	a4,a5,80005760 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000569a:	4789                	li	a5,2
    8000569c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056a0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056a4:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056a8:	f4c42783          	lw	a5,-180(s0)
    800056ac:	0017c713          	xori	a4,a5,1
    800056b0:	8b05                	andi	a4,a4,1
    800056b2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800056b6:	0037f713          	andi	a4,a5,3
    800056ba:	00e03733          	snez	a4,a4
    800056be:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800056c2:	4007f793          	andi	a5,a5,1024
    800056c6:	c791                	beqz	a5,800056d2 <sys_open+0xd0>
    800056c8:	04449703          	lh	a4,68(s1)
    800056cc:	4789                	li	a5,2
    800056ce:	0af70063          	beq	a4,a5,8000576e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800056d2:	8526                	mv	a0,s1
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	03a080e7          	jalr	58(ra) # 8000370e <iunlock>
  end_op();
    800056dc:	fffff097          	auipc	ra,0xfffff
    800056e0:	9ba080e7          	jalr	-1606(ra) # 80004096 <end_op>

  return fd;
    800056e4:	854a                	mv	a0,s2
}
    800056e6:	70ea                	ld	ra,184(sp)
    800056e8:	744a                	ld	s0,176(sp)
    800056ea:	74aa                	ld	s1,168(sp)
    800056ec:	790a                	ld	s2,160(sp)
    800056ee:	69ea                	ld	s3,152(sp)
    800056f0:	6129                	addi	sp,sp,192
    800056f2:	8082                	ret
      end_op();
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	9a2080e7          	jalr	-1630(ra) # 80004096 <end_op>
      return -1;
    800056fc:	557d                	li	a0,-1
    800056fe:	b7e5                	j	800056e6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005700:	f5040513          	addi	a0,s0,-176
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	6f4080e7          	jalr	1780(ra) # 80003df8 <namei>
    8000570c:	84aa                	mv	s1,a0
    8000570e:	c905                	beqz	a0,8000573e <sys_open+0x13c>
    ilock(ip);
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	f3c080e7          	jalr	-196(ra) # 8000364c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005718:	04449703          	lh	a4,68(s1)
    8000571c:	4785                	li	a5,1
    8000571e:	f4f711e3          	bne	a4,a5,80005660 <sys_open+0x5e>
    80005722:	f4c42783          	lw	a5,-180(s0)
    80005726:	d7b9                	beqz	a5,80005674 <sys_open+0x72>
      iunlockput(ip);
    80005728:	8526                	mv	a0,s1
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	184080e7          	jalr	388(ra) # 800038ae <iunlockput>
      end_op();
    80005732:	fffff097          	auipc	ra,0xfffff
    80005736:	964080e7          	jalr	-1692(ra) # 80004096 <end_op>
      return -1;
    8000573a:	557d                	li	a0,-1
    8000573c:	b76d                	j	800056e6 <sys_open+0xe4>
      end_op();
    8000573e:	fffff097          	auipc	ra,0xfffff
    80005742:	958080e7          	jalr	-1704(ra) # 80004096 <end_op>
      return -1;
    80005746:	557d                	li	a0,-1
    80005748:	bf79                	j	800056e6 <sys_open+0xe4>
    iunlockput(ip);
    8000574a:	8526                	mv	a0,s1
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	162080e7          	jalr	354(ra) # 800038ae <iunlockput>
    end_op();
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	942080e7          	jalr	-1726(ra) # 80004096 <end_op>
    return -1;
    8000575c:	557d                	li	a0,-1
    8000575e:	b761                	j	800056e6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005760:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005764:	04649783          	lh	a5,70(s1)
    80005768:	02f99223          	sh	a5,36(s3)
    8000576c:	bf25                	j	800056a4 <sys_open+0xa2>
    itrunc(ip);
    8000576e:	8526                	mv	a0,s1
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	fea080e7          	jalr	-22(ra) # 8000375a <itrunc>
    80005778:	bfa9                	j	800056d2 <sys_open+0xd0>
      fileclose(f);
    8000577a:	854e                	mv	a0,s3
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	d64080e7          	jalr	-668(ra) # 800044e0 <fileclose>
    iunlockput(ip);
    80005784:	8526                	mv	a0,s1
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	128080e7          	jalr	296(ra) # 800038ae <iunlockput>
    end_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	908080e7          	jalr	-1784(ra) # 80004096 <end_op>
    return -1;
    80005796:	557d                	li	a0,-1
    80005798:	b7b9                	j	800056e6 <sys_open+0xe4>

000000008000579a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000579a:	7175                	addi	sp,sp,-144
    8000579c:	e506                	sd	ra,136(sp)
    8000579e:	e122                	sd	s0,128(sp)
    800057a0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	876080e7          	jalr	-1930(ra) # 80004018 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057aa:	08000613          	li	a2,128
    800057ae:	f7040593          	addi	a1,s0,-144
    800057b2:	4501                	li	a0,0
    800057b4:	ffffd097          	auipc	ra,0xffffd
    800057b8:	36e080e7          	jalr	878(ra) # 80002b22 <argstr>
    800057bc:	02054963          	bltz	a0,800057ee <sys_mkdir+0x54>
    800057c0:	4681                	li	a3,0
    800057c2:	4601                	li	a2,0
    800057c4:	4585                	li	a1,1
    800057c6:	f7040513          	addi	a0,s0,-144
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	7fc080e7          	jalr	2044(ra) # 80004fc6 <create>
    800057d2:	cd11                	beqz	a0,800057ee <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	0da080e7          	jalr	218(ra) # 800038ae <iunlockput>
  end_op();
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	8ba080e7          	jalr	-1862(ra) # 80004096 <end_op>
  return 0;
    800057e4:	4501                	li	a0,0
}
    800057e6:	60aa                	ld	ra,136(sp)
    800057e8:	640a                	ld	s0,128(sp)
    800057ea:	6149                	addi	sp,sp,144
    800057ec:	8082                	ret
    end_op();
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	8a8080e7          	jalr	-1880(ra) # 80004096 <end_op>
    return -1;
    800057f6:	557d                	li	a0,-1
    800057f8:	b7fd                	j	800057e6 <sys_mkdir+0x4c>

00000000800057fa <sys_mknod>:

uint64
sys_mknod(void)
{
    800057fa:	7135                	addi	sp,sp,-160
    800057fc:	ed06                	sd	ra,152(sp)
    800057fe:	e922                	sd	s0,144(sp)
    80005800:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	816080e7          	jalr	-2026(ra) # 80004018 <begin_op>
  argint(1, &major);
    8000580a:	f6c40593          	addi	a1,s0,-148
    8000580e:	4505                	li	a0,1
    80005810:	ffffd097          	auipc	ra,0xffffd
    80005814:	2d2080e7          	jalr	722(ra) # 80002ae2 <argint>
  argint(2, &minor);
    80005818:	f6840593          	addi	a1,s0,-152
    8000581c:	4509                	li	a0,2
    8000581e:	ffffd097          	auipc	ra,0xffffd
    80005822:	2c4080e7          	jalr	708(ra) # 80002ae2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005826:	08000613          	li	a2,128
    8000582a:	f7040593          	addi	a1,s0,-144
    8000582e:	4501                	li	a0,0
    80005830:	ffffd097          	auipc	ra,0xffffd
    80005834:	2f2080e7          	jalr	754(ra) # 80002b22 <argstr>
    80005838:	02054b63          	bltz	a0,8000586e <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000583c:	f6841683          	lh	a3,-152(s0)
    80005840:	f6c41603          	lh	a2,-148(s0)
    80005844:	458d                	li	a1,3
    80005846:	f7040513          	addi	a0,s0,-144
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	77c080e7          	jalr	1916(ra) # 80004fc6 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005852:	cd11                	beqz	a0,8000586e <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	05a080e7          	jalr	90(ra) # 800038ae <iunlockput>
  end_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	83a080e7          	jalr	-1990(ra) # 80004096 <end_op>
  return 0;
    80005864:	4501                	li	a0,0
}
    80005866:	60ea                	ld	ra,152(sp)
    80005868:	644a                	ld	s0,144(sp)
    8000586a:	610d                	addi	sp,sp,160
    8000586c:	8082                	ret
    end_op();
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	828080e7          	jalr	-2008(ra) # 80004096 <end_op>
    return -1;
    80005876:	557d                	li	a0,-1
    80005878:	b7fd                	j	80005866 <sys_mknod+0x6c>

000000008000587a <sys_chdir>:

uint64
sys_chdir(void)
{
    8000587a:	7135                	addi	sp,sp,-160
    8000587c:	ed06                	sd	ra,152(sp)
    8000587e:	e922                	sd	s0,144(sp)
    80005880:	e526                	sd	s1,136(sp)
    80005882:	e14a                	sd	s2,128(sp)
    80005884:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005886:	ffffc097          	auipc	ra,0xffffc
    8000588a:	146080e7          	jalr	326(ra) # 800019cc <myproc>
    8000588e:	892a                	mv	s2,a0
  
  begin_op();
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	788080e7          	jalr	1928(ra) # 80004018 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005898:	08000613          	li	a2,128
    8000589c:	f6040593          	addi	a1,s0,-160
    800058a0:	4501                	li	a0,0
    800058a2:	ffffd097          	auipc	ra,0xffffd
    800058a6:	280080e7          	jalr	640(ra) # 80002b22 <argstr>
    800058aa:	04054b63          	bltz	a0,80005900 <sys_chdir+0x86>
    800058ae:	f6040513          	addi	a0,s0,-160
    800058b2:	ffffe097          	auipc	ra,0xffffe
    800058b6:	546080e7          	jalr	1350(ra) # 80003df8 <namei>
    800058ba:	84aa                	mv	s1,a0
    800058bc:	c131                	beqz	a0,80005900 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	d8e080e7          	jalr	-626(ra) # 8000364c <ilock>
  if(ip->type != T_DIR){
    800058c6:	04449703          	lh	a4,68(s1)
    800058ca:	4785                	li	a5,1
    800058cc:	04f71063          	bne	a4,a5,8000590c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800058d0:	8526                	mv	a0,s1
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	e3c080e7          	jalr	-452(ra) # 8000370e <iunlock>
  iput(p->cwd);
    800058da:	15093503          	ld	a0,336(s2)
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	f28080e7          	jalr	-216(ra) # 80003806 <iput>
  end_op();
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	7b0080e7          	jalr	1968(ra) # 80004096 <end_op>
  p->cwd = ip;
    800058ee:	14993823          	sd	s1,336(s2)
  return 0;
    800058f2:	4501                	li	a0,0
}
    800058f4:	60ea                	ld	ra,152(sp)
    800058f6:	644a                	ld	s0,144(sp)
    800058f8:	64aa                	ld	s1,136(sp)
    800058fa:	690a                	ld	s2,128(sp)
    800058fc:	610d                	addi	sp,sp,160
    800058fe:	8082                	ret
    end_op();
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	796080e7          	jalr	1942(ra) # 80004096 <end_op>
    return -1;
    80005908:	557d                	li	a0,-1
    8000590a:	b7ed                	j	800058f4 <sys_chdir+0x7a>
    iunlockput(ip);
    8000590c:	8526                	mv	a0,s1
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	fa0080e7          	jalr	-96(ra) # 800038ae <iunlockput>
    end_op();
    80005916:	ffffe097          	auipc	ra,0xffffe
    8000591a:	780080e7          	jalr	1920(ra) # 80004096 <end_op>
    return -1;
    8000591e:	557d                	li	a0,-1
    80005920:	bfd1                	j	800058f4 <sys_chdir+0x7a>

0000000080005922 <sys_exec>:

uint64
sys_exec(void)
{
    80005922:	7145                	addi	sp,sp,-464
    80005924:	e786                	sd	ra,456(sp)
    80005926:	e3a2                	sd	s0,448(sp)
    80005928:	ff26                	sd	s1,440(sp)
    8000592a:	fb4a                	sd	s2,432(sp)
    8000592c:	f74e                	sd	s3,424(sp)
    8000592e:	f352                	sd	s4,416(sp)
    80005930:	ef56                	sd	s5,408(sp)
    80005932:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005934:	e3840593          	addi	a1,s0,-456
    80005938:	4505                	li	a0,1
    8000593a:	ffffd097          	auipc	ra,0xffffd
    8000593e:	1c8080e7          	jalr	456(ra) # 80002b02 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005942:	08000613          	li	a2,128
    80005946:	f4040593          	addi	a1,s0,-192
    8000594a:	4501                	li	a0,0
    8000594c:	ffffd097          	auipc	ra,0xffffd
    80005950:	1d6080e7          	jalr	470(ra) # 80002b22 <argstr>
    80005954:	87aa                	mv	a5,a0
    return -1;
    80005956:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005958:	0c07c363          	bltz	a5,80005a1e <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    8000595c:	10000613          	li	a2,256
    80005960:	4581                	li	a1,0
    80005962:	e4040513          	addi	a0,s0,-448
    80005966:	ffffb097          	auipc	ra,0xffffb
    8000596a:	36c080e7          	jalr	876(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000596e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005972:	89a6                	mv	s3,s1
    80005974:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005976:	02000a13          	li	s4,32
    8000597a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000597e:	00391513          	slli	a0,s2,0x3
    80005982:	e3040593          	addi	a1,s0,-464
    80005986:	e3843783          	ld	a5,-456(s0)
    8000598a:	953e                	add	a0,a0,a5
    8000598c:	ffffd097          	auipc	ra,0xffffd
    80005990:	0b8080e7          	jalr	184(ra) # 80002a44 <fetchaddr>
    80005994:	02054a63          	bltz	a0,800059c8 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005998:	e3043783          	ld	a5,-464(s0)
    8000599c:	c3b9                	beqz	a5,800059e2 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000599e:	ffffb097          	auipc	ra,0xffffb
    800059a2:	148080e7          	jalr	328(ra) # 80000ae6 <kalloc>
    800059a6:	85aa                	mv	a1,a0
    800059a8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800059ac:	cd11                	beqz	a0,800059c8 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059ae:	6605                	lui	a2,0x1
    800059b0:	e3043503          	ld	a0,-464(s0)
    800059b4:	ffffd097          	auipc	ra,0xffffd
    800059b8:	0e2080e7          	jalr	226(ra) # 80002a96 <fetchstr>
    800059bc:	00054663          	bltz	a0,800059c8 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800059c0:	0905                	addi	s2,s2,1
    800059c2:	09a1                	addi	s3,s3,8
    800059c4:	fb491be3          	bne	s2,s4,8000597a <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059c8:	f4040913          	addi	s2,s0,-192
    800059cc:	6088                	ld	a0,0(s1)
    800059ce:	c539                	beqz	a0,80005a1c <sys_exec+0xfa>
    kfree(argv[i]);
    800059d0:	ffffb097          	auipc	ra,0xffffb
    800059d4:	018080e7          	jalr	24(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059d8:	04a1                	addi	s1,s1,8
    800059da:	ff2499e3          	bne	s1,s2,800059cc <sys_exec+0xaa>
  return -1;
    800059de:	557d                	li	a0,-1
    800059e0:	a83d                	j	80005a1e <sys_exec+0xfc>
      argv[i] = 0;
    800059e2:	0a8e                	slli	s5,s5,0x3
    800059e4:	fc0a8793          	addi	a5,s5,-64
    800059e8:	00878ab3          	add	s5,a5,s0
    800059ec:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800059f0:	e4040593          	addi	a1,s0,-448
    800059f4:	f4040513          	addi	a0,s0,-192
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	162080e7          	jalr	354(ra) # 80004b5a <exec>
    80005a00:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a02:	f4040993          	addi	s3,s0,-192
    80005a06:	6088                	ld	a0,0(s1)
    80005a08:	c901                	beqz	a0,80005a18 <sys_exec+0xf6>
    kfree(argv[i]);
    80005a0a:	ffffb097          	auipc	ra,0xffffb
    80005a0e:	fde080e7          	jalr	-34(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a12:	04a1                	addi	s1,s1,8
    80005a14:	ff3499e3          	bne	s1,s3,80005a06 <sys_exec+0xe4>
  return ret;
    80005a18:	854a                	mv	a0,s2
    80005a1a:	a011                	j	80005a1e <sys_exec+0xfc>
  return -1;
    80005a1c:	557d                	li	a0,-1
}
    80005a1e:	60be                	ld	ra,456(sp)
    80005a20:	641e                	ld	s0,448(sp)
    80005a22:	74fa                	ld	s1,440(sp)
    80005a24:	795a                	ld	s2,432(sp)
    80005a26:	79ba                	ld	s3,424(sp)
    80005a28:	7a1a                	ld	s4,416(sp)
    80005a2a:	6afa                	ld	s5,408(sp)
    80005a2c:	6179                	addi	sp,sp,464
    80005a2e:	8082                	ret

0000000080005a30 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a30:	7139                	addi	sp,sp,-64
    80005a32:	fc06                	sd	ra,56(sp)
    80005a34:	f822                	sd	s0,48(sp)
    80005a36:	f426                	sd	s1,40(sp)
    80005a38:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a3a:	ffffc097          	auipc	ra,0xffffc
    80005a3e:	f92080e7          	jalr	-110(ra) # 800019cc <myproc>
    80005a42:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005a44:	fd840593          	addi	a1,s0,-40
    80005a48:	4501                	li	a0,0
    80005a4a:	ffffd097          	auipc	ra,0xffffd
    80005a4e:	0b8080e7          	jalr	184(ra) # 80002b02 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005a52:	fc840593          	addi	a1,s0,-56
    80005a56:	fd040513          	addi	a0,s0,-48
    80005a5a:	fffff097          	auipc	ra,0xfffff
    80005a5e:	db6080e7          	jalr	-586(ra) # 80004810 <pipealloc>
    return -1;
    80005a62:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005a64:	0c054463          	bltz	a0,80005b2c <sys_pipe+0xfc>
  fd0 = -1;
    80005a68:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a6c:	fd043503          	ld	a0,-48(s0)
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	514080e7          	jalr	1300(ra) # 80004f84 <fdalloc>
    80005a78:	fca42223          	sw	a0,-60(s0)
    80005a7c:	08054b63          	bltz	a0,80005b12 <sys_pipe+0xe2>
    80005a80:	fc843503          	ld	a0,-56(s0)
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	500080e7          	jalr	1280(ra) # 80004f84 <fdalloc>
    80005a8c:	fca42023          	sw	a0,-64(s0)
    80005a90:	06054863          	bltz	a0,80005b00 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a94:	4691                	li	a3,4
    80005a96:	fc440613          	addi	a2,s0,-60
    80005a9a:	fd843583          	ld	a1,-40(s0)
    80005a9e:	68a8                	ld	a0,80(s1)
    80005aa0:	ffffc097          	auipc	ra,0xffffc
    80005aa4:	bec080e7          	jalr	-1044(ra) # 8000168c <copyout>
    80005aa8:	02054063          	bltz	a0,80005ac8 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005aac:	4691                	li	a3,4
    80005aae:	fc040613          	addi	a2,s0,-64
    80005ab2:	fd843583          	ld	a1,-40(s0)
    80005ab6:	0591                	addi	a1,a1,4
    80005ab8:	68a8                	ld	a0,80(s1)
    80005aba:	ffffc097          	auipc	ra,0xffffc
    80005abe:	bd2080e7          	jalr	-1070(ra) # 8000168c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ac2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ac4:	06055463          	bgez	a0,80005b2c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005ac8:	fc442783          	lw	a5,-60(s0)
    80005acc:	07e9                	addi	a5,a5,26
    80005ace:	078e                	slli	a5,a5,0x3
    80005ad0:	97a6                	add	a5,a5,s1
    80005ad2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ad6:	fc042783          	lw	a5,-64(s0)
    80005ada:	07e9                	addi	a5,a5,26
    80005adc:	078e                	slli	a5,a5,0x3
    80005ade:	94be                	add	s1,s1,a5
    80005ae0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005ae4:	fd043503          	ld	a0,-48(s0)
    80005ae8:	fffff097          	auipc	ra,0xfffff
    80005aec:	9f8080e7          	jalr	-1544(ra) # 800044e0 <fileclose>
    fileclose(wf);
    80005af0:	fc843503          	ld	a0,-56(s0)
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	9ec080e7          	jalr	-1556(ra) # 800044e0 <fileclose>
    return -1;
    80005afc:	57fd                	li	a5,-1
    80005afe:	a03d                	j	80005b2c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005b00:	fc442783          	lw	a5,-60(s0)
    80005b04:	0007c763          	bltz	a5,80005b12 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005b08:	07e9                	addi	a5,a5,26
    80005b0a:	078e                	slli	a5,a5,0x3
    80005b0c:	97a6                	add	a5,a5,s1
    80005b0e:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005b12:	fd043503          	ld	a0,-48(s0)
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	9ca080e7          	jalr	-1590(ra) # 800044e0 <fileclose>
    fileclose(wf);
    80005b1e:	fc843503          	ld	a0,-56(s0)
    80005b22:	fffff097          	auipc	ra,0xfffff
    80005b26:	9be080e7          	jalr	-1602(ra) # 800044e0 <fileclose>
    return -1;
    80005b2a:	57fd                	li	a5,-1
}
    80005b2c:	853e                	mv	a0,a5
    80005b2e:	70e2                	ld	ra,56(sp)
    80005b30:	7442                	ld	s0,48(sp)
    80005b32:	74a2                	ld	s1,40(sp)
    80005b34:	6121                	addi	sp,sp,64
    80005b36:	8082                	ret
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
    80005b80:	d91fc0ef          	jal	ra,80002910 <kerneltrap>
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
    80005c1c:	d88080e7          	jalr	-632(ra) # 800019a0 <cpuid>
  
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
    80005c54:	d50080e7          	jalr	-688(ra) # 800019a0 <cpuid>
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
    80005c7c:	d28080e7          	jalr	-728(ra) # 800019a0 <cpuid>
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
    80005ca8:	f9c78793          	addi	a5,a5,-100 # 80021c40 <disk>
    80005cac:	97aa                	add	a5,a5,a0
    80005cae:	0187c783          	lbu	a5,24(a5)
    80005cb2:	ebb9                	bnez	a5,80005d08 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005cb4:	00451693          	slli	a3,a0,0x4
    80005cb8:	0001c797          	auipc	a5,0x1c
    80005cbc:	f8878793          	addi	a5,a5,-120 # 80021c40 <disk>
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
    80005ce4:	f7850513          	addi	a0,a0,-136 # 80021c58 <disk+0x18>
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	3f0080e7          	jalr	1008(ra) # 800020d8 <wakeup>
}
    80005cf0:	60a2                	ld	ra,8(sp)
    80005cf2:	6402                	ld	s0,0(sp)
    80005cf4:	0141                	addi	sp,sp,16
    80005cf6:	8082                	ret
    panic("free_desc 1");
    80005cf8:	00003517          	auipc	a0,0x3
    80005cfc:	a6050513          	addi	a0,a0,-1440 # 80008758 <syscalls+0x2f0>
    80005d00:	ffffb097          	auipc	ra,0xffffb
    80005d04:	840080e7          	jalr	-1984(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005d08:	00003517          	auipc	a0,0x3
    80005d0c:	a6050513          	addi	a0,a0,-1440 # 80008768 <syscalls+0x300>
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
    80005d28:	a5458593          	addi	a1,a1,-1452 # 80008778 <syscalls+0x310>
    80005d2c:	0001c517          	auipc	a0,0x1c
    80005d30:	03c50513          	addi	a0,a0,60 # 80021d68 <disk+0x128>
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
    80005d94:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc9df>
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
    80005dda:	e6a48493          	addi	s1,s1,-406 # 80021c40 <disk>
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
    80005dfe:	e4e73703          	ld	a4,-434(a4) # 80021c48 <disk+0x8>
    80005e02:	cb65                	beqz	a4,80005ef2 <virtio_disk_init+0x1da>
    80005e04:	c7fd                	beqz	a5,80005ef2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005e06:	6605                	lui	a2,0x1
    80005e08:	4581                	li	a1,0
    80005e0a:	ffffb097          	auipc	ra,0xffffb
    80005e0e:	ec8080e7          	jalr	-312(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005e12:	0001c497          	auipc	s1,0x1c
    80005e16:	e2e48493          	addi	s1,s1,-466 # 80021c40 <disk>
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
    80005ea6:	8e650513          	addi	a0,a0,-1818 # 80008788 <syscalls+0x320>
    80005eaa:	ffffa097          	auipc	ra,0xffffa
    80005eae:	696080e7          	jalr	1686(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005eb2:	00003517          	auipc	a0,0x3
    80005eb6:	8f650513          	addi	a0,a0,-1802 # 800087a8 <syscalls+0x340>
    80005eba:	ffffa097          	auipc	ra,0xffffa
    80005ebe:	686080e7          	jalr	1670(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005ec2:	00003517          	auipc	a0,0x3
    80005ec6:	90650513          	addi	a0,a0,-1786 # 800087c8 <syscalls+0x360>
    80005eca:	ffffa097          	auipc	ra,0xffffa
    80005ece:	676080e7          	jalr	1654(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80005ed2:	00003517          	auipc	a0,0x3
    80005ed6:	91650513          	addi	a0,a0,-1770 # 800087e8 <syscalls+0x380>
    80005eda:	ffffa097          	auipc	ra,0xffffa
    80005ede:	666080e7          	jalr	1638(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80005ee2:	00003517          	auipc	a0,0x3
    80005ee6:	92650513          	addi	a0,a0,-1754 # 80008808 <syscalls+0x3a0>
    80005eea:	ffffa097          	auipc	ra,0xffffa
    80005eee:	656080e7          	jalr	1622(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80005ef2:	00003517          	auipc	a0,0x3
    80005ef6:	93650513          	addi	a0,a0,-1738 # 80008828 <syscalls+0x3c0>
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
    80005f36:	e3650513          	addi	a0,a0,-458 # 80021d68 <disk+0x128>
    80005f3a:	ffffb097          	auipc	ra,0xffffb
    80005f3e:	c9c080e7          	jalr	-868(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80005f42:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f44:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f46:	0001cb97          	auipc	s7,0x1c
    80005f4a:	cfab8b93          	addi	s7,s7,-774 # 80021c40 <disk>
  for(int i = 0; i < 3; i++){
    80005f4e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f50:	0001cc97          	auipc	s9,0x1c
    80005f54:	e18c8c93          	addi	s9,s9,-488 # 80021d68 <disk+0x128>
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
    80005f76:	cce70713          	addi	a4,a4,-818 # 80021c40 <disk>
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
    80005fae:	cae50513          	addi	a0,a0,-850 # 80021c58 <disk+0x18>
    80005fb2:	ffffc097          	auipc	ra,0xffffc
    80005fb6:	0c2080e7          	jalr	194(ra) # 80002074 <sleep>
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
    80005fd2:	c7278793          	addi	a5,a5,-910 # 80021c40 <disk>
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
    800060a8:	cc490913          	addi	s2,s2,-828 # 80021d68 <disk+0x128>
  while(b->disk == 1) {
    800060ac:	4485                	li	s1,1
    800060ae:	00b79c63          	bne	a5,a1,800060c6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800060b2:	85ca                	mv	a1,s2
    800060b4:	8556                	mv	a0,s5
    800060b6:	ffffc097          	auipc	ra,0xffffc
    800060ba:	fbe080e7          	jalr	-66(ra) # 80002074 <sleep>
  while(b->disk == 1) {
    800060be:	004aa783          	lw	a5,4(s5)
    800060c2:	fe9788e3          	beq	a5,s1,800060b2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800060c6:	f8042903          	lw	s2,-128(s0)
    800060ca:	00290713          	addi	a4,s2,2
    800060ce:	0712                	slli	a4,a4,0x4
    800060d0:	0001c797          	auipc	a5,0x1c
    800060d4:	b7078793          	addi	a5,a5,-1168 # 80021c40 <disk>
    800060d8:	97ba                	add	a5,a5,a4
    800060da:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800060de:	0001c997          	auipc	s3,0x1c
    800060e2:	b6298993          	addi	s3,s3,-1182 # 80021c40 <disk>
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
    8000610a:	c6250513          	addi	a0,a0,-926 # 80021d68 <disk+0x128>
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
    80006142:	b0248493          	addi	s1,s1,-1278 # 80021c40 <disk>
    80006146:	0001c517          	auipc	a0,0x1c
    8000614a:	c2250513          	addi	a0,a0,-990 # 80021d68 <disk+0x128>
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
    800061a2:	f3a080e7          	jalr	-198(ra) # 800020d8 <wakeup>

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
    800061c2:	baa50513          	addi	a0,a0,-1110 # 80021d68 <disk+0x128>
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
    800061dc:	66850513          	addi	a0,a0,1640 # 80008840 <syscalls+0x3d8>
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
