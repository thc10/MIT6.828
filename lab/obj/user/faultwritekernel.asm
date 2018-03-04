
obj/user/faultwritekernel:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 11 00 00 00       	call   800042 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	*(unsigned*)0xf0100000 = 0;
  800036:	c7 05 00 00 10 f0 00 	movl   $0x0,0xf0100000
  80003d:	00 00 00 
}
  800040:	5d                   	pop    %ebp
  800041:	c3                   	ret    

00800042 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800042:	55                   	push   %ebp
  800043:	89 e5                	mov    %esp,%ebp
  800045:	83 ec 18             	sub    $0x18,%esp
  800048:	8b 45 08             	mov    0x8(%ebp),%eax
  80004b:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80004e:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800055:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800058:	85 c0                	test   %eax,%eax
  80005a:	7e 08                	jle    800064 <libmain+0x22>
		binaryname = argv[0];
  80005c:	8b 0a                	mov    (%edx),%ecx
  80005e:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800064:	89 54 24 04          	mov    %edx,0x4(%esp)
  800068:	89 04 24             	mov    %eax,(%esp)
  80006b:	e8 c3 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800070:	e8 02 00 00 00       	call   800077 <exit>
}
  800075:	c9                   	leave  
  800076:	c3                   	ret    

00800077 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800077:	55                   	push   %ebp
  800078:	89 e5                	mov    %esp,%ebp
  80007a:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80007d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800084:	e8 3f 00 00 00       	call   8000c8 <sys_env_destroy>
}
  800089:	c9                   	leave  
  80008a:	c3                   	ret    

0080008b <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  80008b:	55                   	push   %ebp
  80008c:	89 e5                	mov    %esp,%ebp
  80008e:	57                   	push   %edi
  80008f:	56                   	push   %esi
  800090:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800091:	b8 00 00 00 00       	mov    $0x0,%eax
  800096:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800099:	8b 55 08             	mov    0x8(%ebp),%edx
  80009c:	89 c3                	mov    %eax,%ebx
  80009e:	89 c7                	mov    %eax,%edi
  8000a0:	89 c6                	mov    %eax,%esi
  8000a2:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000a4:	5b                   	pop    %ebx
  8000a5:	5e                   	pop    %esi
  8000a6:	5f                   	pop    %edi
  8000a7:	5d                   	pop    %ebp
  8000a8:	c3                   	ret    

008000a9 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000a9:	55                   	push   %ebp
  8000aa:	89 e5                	mov    %esp,%ebp
  8000ac:	57                   	push   %edi
  8000ad:	56                   	push   %esi
  8000ae:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000af:	ba 00 00 00 00       	mov    $0x0,%edx
  8000b4:	b8 01 00 00 00       	mov    $0x1,%eax
  8000b9:	89 d1                	mov    %edx,%ecx
  8000bb:	89 d3                	mov    %edx,%ebx
  8000bd:	89 d7                	mov    %edx,%edi
  8000bf:	89 d6                	mov    %edx,%esi
  8000c1:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000c3:	5b                   	pop    %ebx
  8000c4:	5e                   	pop    %esi
  8000c5:	5f                   	pop    %edi
  8000c6:	5d                   	pop    %ebp
  8000c7:	c3                   	ret    

008000c8 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000c8:	55                   	push   %ebp
  8000c9:	89 e5                	mov    %esp,%ebp
  8000cb:	57                   	push   %edi
  8000cc:	56                   	push   %esi
  8000cd:	53                   	push   %ebx
  8000ce:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000d1:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000d6:	b8 03 00 00 00       	mov    $0x3,%eax
  8000db:	8b 55 08             	mov    0x8(%ebp),%edx
  8000de:	89 cb                	mov    %ecx,%ebx
  8000e0:	89 cf                	mov    %ecx,%edi
  8000e2:	89 ce                	mov    %ecx,%esi
  8000e4:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  8000e6:	85 c0                	test   %eax,%eax
  8000e8:	7e 28                	jle    800112 <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000ea:	89 44 24 10          	mov    %eax,0x10(%esp)
  8000ee:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  8000f5:	00 
  8000f6:	c7 44 24 08 42 0e 80 	movl   $0x800e42,0x8(%esp)
  8000fd:	00 
  8000fe:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800105:	00 
  800106:	c7 04 24 5f 0e 80 00 	movl   $0x800e5f,(%esp)
  80010d:	e8 27 00 00 00       	call   800139 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800112:	83 c4 2c             	add    $0x2c,%esp
  800115:	5b                   	pop    %ebx
  800116:	5e                   	pop    %esi
  800117:	5f                   	pop    %edi
  800118:	5d                   	pop    %ebp
  800119:	c3                   	ret    

0080011a <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80011a:	55                   	push   %ebp
  80011b:	89 e5                	mov    %esp,%ebp
  80011d:	57                   	push   %edi
  80011e:	56                   	push   %esi
  80011f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800120:	ba 00 00 00 00       	mov    $0x0,%edx
  800125:	b8 02 00 00 00       	mov    $0x2,%eax
  80012a:	89 d1                	mov    %edx,%ecx
  80012c:	89 d3                	mov    %edx,%ebx
  80012e:	89 d7                	mov    %edx,%edi
  800130:	89 d6                	mov    %edx,%esi
  800132:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800134:	5b                   	pop    %ebx
  800135:	5e                   	pop    %esi
  800136:	5f                   	pop    %edi
  800137:	5d                   	pop    %ebp
  800138:	c3                   	ret    

00800139 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800139:	55                   	push   %ebp
  80013a:	89 e5                	mov    %esp,%ebp
  80013c:	56                   	push   %esi
  80013d:	53                   	push   %ebx
  80013e:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800141:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800144:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80014a:	e8 cb ff ff ff       	call   80011a <sys_getenvid>
  80014f:	8b 55 0c             	mov    0xc(%ebp),%edx
  800152:	89 54 24 10          	mov    %edx,0x10(%esp)
  800156:	8b 55 08             	mov    0x8(%ebp),%edx
  800159:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80015d:	89 74 24 08          	mov    %esi,0x8(%esp)
  800161:	89 44 24 04          	mov    %eax,0x4(%esp)
  800165:	c7 04 24 70 0e 80 00 	movl   $0x800e70,(%esp)
  80016c:	e8 c1 00 00 00       	call   800232 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800171:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800175:	8b 45 10             	mov    0x10(%ebp),%eax
  800178:	89 04 24             	mov    %eax,(%esp)
  80017b:	e8 51 00 00 00       	call   8001d1 <vcprintf>
	cprintf("\n");
  800180:	c7 04 24 94 0e 80 00 	movl   $0x800e94,(%esp)
  800187:	e8 a6 00 00 00       	call   800232 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80018c:	cc                   	int3   
  80018d:	eb fd                	jmp    80018c <_panic+0x53>

0080018f <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80018f:	55                   	push   %ebp
  800190:	89 e5                	mov    %esp,%ebp
  800192:	53                   	push   %ebx
  800193:	83 ec 14             	sub    $0x14,%esp
  800196:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800199:	8b 13                	mov    (%ebx),%edx
  80019b:	8d 42 01             	lea    0x1(%edx),%eax
  80019e:	89 03                	mov    %eax,(%ebx)
  8001a0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001a3:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001a7:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001ac:	75 19                	jne    8001c7 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8001ae:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8001b5:	00 
  8001b6:	8d 43 08             	lea    0x8(%ebx),%eax
  8001b9:	89 04 24             	mov    %eax,(%esp)
  8001bc:	e8 ca fe ff ff       	call   80008b <sys_cputs>
		b->idx = 0;
  8001c1:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8001c7:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001cb:	83 c4 14             	add    $0x14,%esp
  8001ce:	5b                   	pop    %ebx
  8001cf:	5d                   	pop    %ebp
  8001d0:	c3                   	ret    

008001d1 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001d1:	55                   	push   %ebp
  8001d2:	89 e5                	mov    %esp,%ebp
  8001d4:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  8001da:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001e1:	00 00 00 
	b.cnt = 0;
  8001e4:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001eb:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001ee:	8b 45 0c             	mov    0xc(%ebp),%eax
  8001f1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8001f5:	8b 45 08             	mov    0x8(%ebp),%eax
  8001f8:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001fc:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800202:	89 44 24 04          	mov    %eax,0x4(%esp)
  800206:	c7 04 24 8f 01 80 00 	movl   $0x80018f,(%esp)
  80020d:	e8 ac 01 00 00       	call   8003be <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800212:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800218:	89 44 24 04          	mov    %eax,0x4(%esp)
  80021c:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800222:	89 04 24             	mov    %eax,(%esp)
  800225:	e8 61 fe ff ff       	call   80008b <sys_cputs>

	return b.cnt;
}
  80022a:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800230:	c9                   	leave  
  800231:	c3                   	ret    

00800232 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800232:	55                   	push   %ebp
  800233:	89 e5                	mov    %esp,%ebp
  800235:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800238:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80023b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80023f:	8b 45 08             	mov    0x8(%ebp),%eax
  800242:	89 04 24             	mov    %eax,(%esp)
  800245:	e8 87 ff ff ff       	call   8001d1 <vcprintf>
	va_end(ap);

	return cnt;
}
  80024a:	c9                   	leave  
  80024b:	c3                   	ret    
  80024c:	66 90                	xchg   %ax,%ax
  80024e:	66 90                	xchg   %ax,%ax

00800250 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800250:	55                   	push   %ebp
  800251:	89 e5                	mov    %esp,%ebp
  800253:	57                   	push   %edi
  800254:	56                   	push   %esi
  800255:	53                   	push   %ebx
  800256:	83 ec 3c             	sub    $0x3c,%esp
  800259:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80025c:	89 d7                	mov    %edx,%edi
  80025e:	8b 45 08             	mov    0x8(%ebp),%eax
  800261:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800264:	8b 45 0c             	mov    0xc(%ebp),%eax
  800267:	89 c3                	mov    %eax,%ebx
  800269:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80026c:	8b 45 10             	mov    0x10(%ebp),%eax
  80026f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800272:	b9 00 00 00 00       	mov    $0x0,%ecx
  800277:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80027a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80027d:	39 d9                	cmp    %ebx,%ecx
  80027f:	72 05                	jb     800286 <printnum+0x36>
  800281:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  800284:	77 69                	ja     8002ef <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800286:	8b 4d 18             	mov    0x18(%ebp),%ecx
  800289:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80028d:	83 ee 01             	sub    $0x1,%esi
  800290:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800294:	89 44 24 08          	mov    %eax,0x8(%esp)
  800298:	8b 44 24 08          	mov    0x8(%esp),%eax
  80029c:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8002a0:	89 c3                	mov    %eax,%ebx
  8002a2:	89 d6                	mov    %edx,%esi
  8002a4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8002a7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8002aa:	89 54 24 08          	mov    %edx,0x8(%esp)
  8002ae:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8002b2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002b5:	89 04 24             	mov    %eax,(%esp)
  8002b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8002bb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002bf:	e8 ec 08 00 00       	call   800bb0 <__udivdi3>
  8002c4:	89 d9                	mov    %ebx,%ecx
  8002c6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8002ca:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8002ce:	89 04 24             	mov    %eax,(%esp)
  8002d1:	89 54 24 04          	mov    %edx,0x4(%esp)
  8002d5:	89 fa                	mov    %edi,%edx
  8002d7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8002da:	e8 71 ff ff ff       	call   800250 <printnum>
  8002df:	eb 1b                	jmp    8002fc <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002e1:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002e5:	8b 45 18             	mov    0x18(%ebp),%eax
  8002e8:	89 04 24             	mov    %eax,(%esp)
  8002eb:	ff d3                	call   *%ebx
  8002ed:	eb 03                	jmp    8002f2 <printnum+0xa2>
  8002ef:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002f2:	83 ee 01             	sub    $0x1,%esi
  8002f5:	85 f6                	test   %esi,%esi
  8002f7:	7f e8                	jg     8002e1 <printnum+0x91>
  8002f9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002fc:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800300:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800304:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800307:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80030a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80030e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800312:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800315:	89 04 24             	mov    %eax,(%esp)
  800318:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80031b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80031f:	e8 bc 09 00 00       	call   800ce0 <__umoddi3>
  800324:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800328:	0f be 80 96 0e 80 00 	movsbl 0x800e96(%eax),%eax
  80032f:	89 04 24             	mov    %eax,(%esp)
  800332:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800335:	ff d0                	call   *%eax
}
  800337:	83 c4 3c             	add    $0x3c,%esp
  80033a:	5b                   	pop    %ebx
  80033b:	5e                   	pop    %esi
  80033c:	5f                   	pop    %edi
  80033d:	5d                   	pop    %ebp
  80033e:	c3                   	ret    

0080033f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80033f:	55                   	push   %ebp
  800340:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800342:	83 fa 01             	cmp    $0x1,%edx
  800345:	7e 0e                	jle    800355 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800347:	8b 10                	mov    (%eax),%edx
  800349:	8d 4a 08             	lea    0x8(%edx),%ecx
  80034c:	89 08                	mov    %ecx,(%eax)
  80034e:	8b 02                	mov    (%edx),%eax
  800350:	8b 52 04             	mov    0x4(%edx),%edx
  800353:	eb 22                	jmp    800377 <getuint+0x38>
	else if (lflag)
  800355:	85 d2                	test   %edx,%edx
  800357:	74 10                	je     800369 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800359:	8b 10                	mov    (%eax),%edx
  80035b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80035e:	89 08                	mov    %ecx,(%eax)
  800360:	8b 02                	mov    (%edx),%eax
  800362:	ba 00 00 00 00       	mov    $0x0,%edx
  800367:	eb 0e                	jmp    800377 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800369:	8b 10                	mov    (%eax),%edx
  80036b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80036e:	89 08                	mov    %ecx,(%eax)
  800370:	8b 02                	mov    (%edx),%eax
  800372:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800377:	5d                   	pop    %ebp
  800378:	c3                   	ret    

00800379 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800379:	55                   	push   %ebp
  80037a:	89 e5                	mov    %esp,%ebp
  80037c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80037f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800383:	8b 10                	mov    (%eax),%edx
  800385:	3b 50 04             	cmp    0x4(%eax),%edx
  800388:	73 0a                	jae    800394 <sprintputch+0x1b>
		*b->buf++ = ch;
  80038a:	8d 4a 01             	lea    0x1(%edx),%ecx
  80038d:	89 08                	mov    %ecx,(%eax)
  80038f:	8b 45 08             	mov    0x8(%ebp),%eax
  800392:	88 02                	mov    %al,(%edx)
}
  800394:	5d                   	pop    %ebp
  800395:	c3                   	ret    

00800396 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800396:	55                   	push   %ebp
  800397:	89 e5                	mov    %esp,%ebp
  800399:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  80039c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80039f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003a3:	8b 45 10             	mov    0x10(%ebp),%eax
  8003a6:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003aa:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003ad:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003b1:	8b 45 08             	mov    0x8(%ebp),%eax
  8003b4:	89 04 24             	mov    %eax,(%esp)
  8003b7:	e8 02 00 00 00       	call   8003be <vprintfmt>
	va_end(ap);
}
  8003bc:	c9                   	leave  
  8003bd:	c3                   	ret    

008003be <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8003be:	55                   	push   %ebp
  8003bf:	89 e5                	mov    %esp,%ebp
  8003c1:	57                   	push   %edi
  8003c2:	56                   	push   %esi
  8003c3:	53                   	push   %ebx
  8003c4:	83 ec 3c             	sub    $0x3c,%esp
  8003c7:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8003ca:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8003cd:	eb 14                	jmp    8003e3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8003cf:	85 c0                	test   %eax,%eax
  8003d1:	0f 84 b3 03 00 00    	je     80078a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
  8003d7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003db:	89 04 24             	mov    %eax,(%esp)
  8003de:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8003e1:	89 f3                	mov    %esi,%ebx
  8003e3:	8d 73 01             	lea    0x1(%ebx),%esi
  8003e6:	0f b6 03             	movzbl (%ebx),%eax
  8003e9:	83 f8 25             	cmp    $0x25,%eax
  8003ec:	75 e1                	jne    8003cf <vprintfmt+0x11>
  8003ee:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  8003f2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  8003f9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  800400:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800407:	ba 00 00 00 00       	mov    $0x0,%edx
  80040c:	eb 1d                	jmp    80042b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80040e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  800410:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800414:	eb 15                	jmp    80042b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800416:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800418:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80041c:	eb 0d                	jmp    80042b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  80041e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800421:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800424:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80042b:	8d 5e 01             	lea    0x1(%esi),%ebx
  80042e:	0f b6 0e             	movzbl (%esi),%ecx
  800431:	0f b6 c1             	movzbl %cl,%eax
  800434:	83 e9 23             	sub    $0x23,%ecx
  800437:	80 f9 55             	cmp    $0x55,%cl
  80043a:	0f 87 2a 03 00 00    	ja     80076a <vprintfmt+0x3ac>
  800440:	0f b6 c9             	movzbl %cl,%ecx
  800443:	ff 24 8d 24 0f 80 00 	jmp    *0x800f24(,%ecx,4)
  80044a:	89 de                	mov    %ebx,%esi
  80044c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800451:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  800454:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  800458:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  80045b:	8d 58 d0             	lea    -0x30(%eax),%ebx
  80045e:	83 fb 09             	cmp    $0x9,%ebx
  800461:	77 36                	ja     800499 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800463:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800466:	eb e9                	jmp    800451 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800468:	8b 45 14             	mov    0x14(%ebp),%eax
  80046b:	8d 48 04             	lea    0x4(%eax),%ecx
  80046e:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800471:	8b 00                	mov    (%eax),%eax
  800473:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800476:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800478:	eb 22                	jmp    80049c <vprintfmt+0xde>
  80047a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80047d:	85 c9                	test   %ecx,%ecx
  80047f:	b8 00 00 00 00       	mov    $0x0,%eax
  800484:	0f 49 c1             	cmovns %ecx,%eax
  800487:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80048a:	89 de                	mov    %ebx,%esi
  80048c:	eb 9d                	jmp    80042b <vprintfmt+0x6d>
  80048e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800490:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  800497:	eb 92                	jmp    80042b <vprintfmt+0x6d>
  800499:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  80049c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8004a0:	79 89                	jns    80042b <vprintfmt+0x6d>
  8004a2:	e9 77 ff ff ff       	jmp    80041e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8004a7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004aa:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8004ac:	e9 7a ff ff ff       	jmp    80042b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8004b1:	8b 45 14             	mov    0x14(%ebp),%eax
  8004b4:	8d 50 04             	lea    0x4(%eax),%edx
  8004b7:	89 55 14             	mov    %edx,0x14(%ebp)
  8004ba:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004be:	8b 00                	mov    (%eax),%eax
  8004c0:	89 04 24             	mov    %eax,(%esp)
  8004c3:	ff 55 08             	call   *0x8(%ebp)
			break;
  8004c6:	e9 18 ff ff ff       	jmp    8003e3 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004cb:	8b 45 14             	mov    0x14(%ebp),%eax
  8004ce:	8d 50 04             	lea    0x4(%eax),%edx
  8004d1:	89 55 14             	mov    %edx,0x14(%ebp)
  8004d4:	8b 00                	mov    (%eax),%eax
  8004d6:	99                   	cltd   
  8004d7:	31 d0                	xor    %edx,%eax
  8004d9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004db:	83 f8 06             	cmp    $0x6,%eax
  8004de:	7f 0b                	jg     8004eb <vprintfmt+0x12d>
  8004e0:	8b 14 85 7c 10 80 00 	mov    0x80107c(,%eax,4),%edx
  8004e7:	85 d2                	test   %edx,%edx
  8004e9:	75 20                	jne    80050b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  8004eb:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8004ef:	c7 44 24 08 ae 0e 80 	movl   $0x800eae,0x8(%esp)
  8004f6:	00 
  8004f7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004fb:	8b 45 08             	mov    0x8(%ebp),%eax
  8004fe:	89 04 24             	mov    %eax,(%esp)
  800501:	e8 90 fe ff ff       	call   800396 <printfmt>
  800506:	e9 d8 fe ff ff       	jmp    8003e3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  80050b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80050f:	c7 44 24 08 b7 0e 80 	movl   $0x800eb7,0x8(%esp)
  800516:	00 
  800517:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80051b:	8b 45 08             	mov    0x8(%ebp),%eax
  80051e:	89 04 24             	mov    %eax,(%esp)
  800521:	e8 70 fe ff ff       	call   800396 <printfmt>
  800526:	e9 b8 fe ff ff       	jmp    8003e3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80052b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  80052e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800531:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800534:	8b 45 14             	mov    0x14(%ebp),%eax
  800537:	8d 50 04             	lea    0x4(%eax),%edx
  80053a:	89 55 14             	mov    %edx,0x14(%ebp)
  80053d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  80053f:	85 f6                	test   %esi,%esi
  800541:	b8 a7 0e 80 00       	mov    $0x800ea7,%eax
  800546:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  800549:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  80054d:	0f 84 97 00 00 00    	je     8005ea <vprintfmt+0x22c>
  800553:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800557:	0f 8e 9b 00 00 00    	jle    8005f8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  80055d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800561:	89 34 24             	mov    %esi,(%esp)
  800564:	e8 cf 02 00 00       	call   800838 <strnlen>
  800569:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80056c:	29 c2                	sub    %eax,%edx
  80056e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  800571:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  800575:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800578:	89 75 d8             	mov    %esi,-0x28(%ebp)
  80057b:	8b 75 08             	mov    0x8(%ebp),%esi
  80057e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800581:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800583:	eb 0f                	jmp    800594 <vprintfmt+0x1d6>
					putch(padc, putdat);
  800585:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800589:	8b 45 dc             	mov    -0x24(%ebp),%eax
  80058c:	89 04 24             	mov    %eax,(%esp)
  80058f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800591:	83 eb 01             	sub    $0x1,%ebx
  800594:	85 db                	test   %ebx,%ebx
  800596:	7f ed                	jg     800585 <vprintfmt+0x1c7>
  800598:	8b 75 d8             	mov    -0x28(%ebp),%esi
  80059b:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80059e:	85 d2                	test   %edx,%edx
  8005a0:	b8 00 00 00 00       	mov    $0x0,%eax
  8005a5:	0f 49 c2             	cmovns %edx,%eax
  8005a8:	29 c2                	sub    %eax,%edx
  8005aa:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8005ad:	89 d7                	mov    %edx,%edi
  8005af:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8005b2:	eb 50                	jmp    800604 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8005b4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8005b8:	74 1e                	je     8005d8 <vprintfmt+0x21a>
  8005ba:	0f be d2             	movsbl %dl,%edx
  8005bd:	83 ea 20             	sub    $0x20,%edx
  8005c0:	83 fa 5e             	cmp    $0x5e,%edx
  8005c3:	76 13                	jbe    8005d8 <vprintfmt+0x21a>
					putch('?', putdat);
  8005c5:	8b 45 0c             	mov    0xc(%ebp),%eax
  8005c8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8005cc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  8005d3:	ff 55 08             	call   *0x8(%ebp)
  8005d6:	eb 0d                	jmp    8005e5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  8005d8:	8b 55 0c             	mov    0xc(%ebp),%edx
  8005db:	89 54 24 04          	mov    %edx,0x4(%esp)
  8005df:	89 04 24             	mov    %eax,(%esp)
  8005e2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005e5:	83 ef 01             	sub    $0x1,%edi
  8005e8:	eb 1a                	jmp    800604 <vprintfmt+0x246>
  8005ea:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8005ed:	8b 7d dc             	mov    -0x24(%ebp),%edi
  8005f0:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8005f3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8005f6:	eb 0c                	jmp    800604 <vprintfmt+0x246>
  8005f8:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8005fb:	8b 7d dc             	mov    -0x24(%ebp),%edi
  8005fe:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800601:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800604:	83 c6 01             	add    $0x1,%esi
  800607:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  80060b:	0f be c2             	movsbl %dl,%eax
  80060e:	85 c0                	test   %eax,%eax
  800610:	74 27                	je     800639 <vprintfmt+0x27b>
  800612:	85 db                	test   %ebx,%ebx
  800614:	78 9e                	js     8005b4 <vprintfmt+0x1f6>
  800616:	83 eb 01             	sub    $0x1,%ebx
  800619:	79 99                	jns    8005b4 <vprintfmt+0x1f6>
  80061b:	89 f8                	mov    %edi,%eax
  80061d:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800620:	8b 75 08             	mov    0x8(%ebp),%esi
  800623:	89 c3                	mov    %eax,%ebx
  800625:	eb 1a                	jmp    800641 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800627:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80062b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800632:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800634:	83 eb 01             	sub    $0x1,%ebx
  800637:	eb 08                	jmp    800641 <vprintfmt+0x283>
  800639:	89 fb                	mov    %edi,%ebx
  80063b:	8b 75 08             	mov    0x8(%ebp),%esi
  80063e:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800641:	85 db                	test   %ebx,%ebx
  800643:	7f e2                	jg     800627 <vprintfmt+0x269>
  800645:	89 75 08             	mov    %esi,0x8(%ebp)
  800648:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80064b:	e9 93 fd ff ff       	jmp    8003e3 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800650:	83 fa 01             	cmp    $0x1,%edx
  800653:	7e 16                	jle    80066b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
  800655:	8b 45 14             	mov    0x14(%ebp),%eax
  800658:	8d 50 08             	lea    0x8(%eax),%edx
  80065b:	89 55 14             	mov    %edx,0x14(%ebp)
  80065e:	8b 50 04             	mov    0x4(%eax),%edx
  800661:	8b 00                	mov    (%eax),%eax
  800663:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800666:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800669:	eb 32                	jmp    80069d <vprintfmt+0x2df>
	else if (lflag)
  80066b:	85 d2                	test   %edx,%edx
  80066d:	74 18                	je     800687 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
  80066f:	8b 45 14             	mov    0x14(%ebp),%eax
  800672:	8d 50 04             	lea    0x4(%eax),%edx
  800675:	89 55 14             	mov    %edx,0x14(%ebp)
  800678:	8b 30                	mov    (%eax),%esi
  80067a:	89 75 e0             	mov    %esi,-0x20(%ebp)
  80067d:	89 f0                	mov    %esi,%eax
  80067f:	c1 f8 1f             	sar    $0x1f,%eax
  800682:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800685:	eb 16                	jmp    80069d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
  800687:	8b 45 14             	mov    0x14(%ebp),%eax
  80068a:	8d 50 04             	lea    0x4(%eax),%edx
  80068d:	89 55 14             	mov    %edx,0x14(%ebp)
  800690:	8b 30                	mov    (%eax),%esi
  800692:	89 75 e0             	mov    %esi,-0x20(%ebp)
  800695:	89 f0                	mov    %esi,%eax
  800697:	c1 f8 1f             	sar    $0x1f,%eax
  80069a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80069d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8006a0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8006a3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8006a8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8006ac:	0f 89 80 00 00 00    	jns    800732 <vprintfmt+0x374>
				putch('-', putdat);
  8006b2:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006b6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8006bd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8006c0:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8006c3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8006c6:	f7 d8                	neg    %eax
  8006c8:	83 d2 00             	adc    $0x0,%edx
  8006cb:	f7 da                	neg    %edx
			}
			base = 10;
  8006cd:	b9 0a 00 00 00       	mov    $0xa,%ecx
  8006d2:	eb 5e                	jmp    800732 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8006d4:	8d 45 14             	lea    0x14(%ebp),%eax
  8006d7:	e8 63 fc ff ff       	call   80033f <getuint>
			base = 10;
  8006dc:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  8006e1:	eb 4f                	jmp    800732 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  8006e3:	8d 45 14             	lea    0x14(%ebp),%eax
  8006e6:	e8 54 fc ff ff       	call   80033f <getuint>
			base = 8;
  8006eb:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8006f0:	eb 40                	jmp    800732 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
  8006f2:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006f6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8006fd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800700:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800704:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80070b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80070e:	8b 45 14             	mov    0x14(%ebp),%eax
  800711:	8d 50 04             	lea    0x4(%eax),%edx
  800714:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800717:	8b 00                	mov    (%eax),%eax
  800719:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80071e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800723:	eb 0d                	jmp    800732 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800725:	8d 45 14             	lea    0x14(%ebp),%eax
  800728:	e8 12 fc ff ff       	call   80033f <getuint>
			base = 16;
  80072d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800732:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  800736:	89 74 24 10          	mov    %esi,0x10(%esp)
  80073a:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80073d:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800741:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800745:	89 04 24             	mov    %eax,(%esp)
  800748:	89 54 24 04          	mov    %edx,0x4(%esp)
  80074c:	89 fa                	mov    %edi,%edx
  80074e:	8b 45 08             	mov    0x8(%ebp),%eax
  800751:	e8 fa fa ff ff       	call   800250 <printnum>
			break;
  800756:	e9 88 fc ff ff       	jmp    8003e3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80075b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80075f:	89 04 24             	mov    %eax,(%esp)
  800762:	ff 55 08             	call   *0x8(%ebp)
			break;
  800765:	e9 79 fc ff ff       	jmp    8003e3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80076a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80076e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800775:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  800778:	89 f3                	mov    %esi,%ebx
  80077a:	eb 03                	jmp    80077f <vprintfmt+0x3c1>
  80077c:	83 eb 01             	sub    $0x1,%ebx
  80077f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  800783:	75 f7                	jne    80077c <vprintfmt+0x3be>
  800785:	e9 59 fc ff ff       	jmp    8003e3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  80078a:	83 c4 3c             	add    $0x3c,%esp
  80078d:	5b                   	pop    %ebx
  80078e:	5e                   	pop    %esi
  80078f:	5f                   	pop    %edi
  800790:	5d                   	pop    %ebp
  800791:	c3                   	ret    

00800792 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800792:	55                   	push   %ebp
  800793:	89 e5                	mov    %esp,%ebp
  800795:	83 ec 28             	sub    $0x28,%esp
  800798:	8b 45 08             	mov    0x8(%ebp),%eax
  80079b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80079e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8007a1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8007a5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8007a8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007af:	85 c0                	test   %eax,%eax
  8007b1:	74 30                	je     8007e3 <vsnprintf+0x51>
  8007b3:	85 d2                	test   %edx,%edx
  8007b5:	7e 2c                	jle    8007e3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007b7:	8b 45 14             	mov    0x14(%ebp),%eax
  8007ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007be:	8b 45 10             	mov    0x10(%ebp),%eax
  8007c1:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007c5:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007c8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8007cc:	c7 04 24 79 03 80 00 	movl   $0x800379,(%esp)
  8007d3:	e8 e6 fb ff ff       	call   8003be <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007db:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007de:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007e1:	eb 05                	jmp    8007e8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007e3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007e8:	c9                   	leave  
  8007e9:	c3                   	ret    

008007ea <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007ea:	55                   	push   %ebp
  8007eb:	89 e5                	mov    %esp,%ebp
  8007ed:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007f0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007f3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007f7:	8b 45 10             	mov    0x10(%ebp),%eax
  8007fa:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007fe:	8b 45 0c             	mov    0xc(%ebp),%eax
  800801:	89 44 24 04          	mov    %eax,0x4(%esp)
  800805:	8b 45 08             	mov    0x8(%ebp),%eax
  800808:	89 04 24             	mov    %eax,(%esp)
  80080b:	e8 82 ff ff ff       	call   800792 <vsnprintf>
	va_end(ap);

	return rc;
}
  800810:	c9                   	leave  
  800811:	c3                   	ret    
  800812:	66 90                	xchg   %ax,%ax
  800814:	66 90                	xchg   %ax,%ax
  800816:	66 90                	xchg   %ax,%ax
  800818:	66 90                	xchg   %ax,%ax
  80081a:	66 90                	xchg   %ax,%ax
  80081c:	66 90                	xchg   %ax,%ax
  80081e:	66 90                	xchg   %ax,%ax

00800820 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800820:	55                   	push   %ebp
  800821:	89 e5                	mov    %esp,%ebp
  800823:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800826:	b8 00 00 00 00       	mov    $0x0,%eax
  80082b:	eb 03                	jmp    800830 <strlen+0x10>
		n++;
  80082d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800830:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800834:	75 f7                	jne    80082d <strlen+0xd>
		n++;
	return n;
}
  800836:	5d                   	pop    %ebp
  800837:	c3                   	ret    

00800838 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800838:	55                   	push   %ebp
  800839:	89 e5                	mov    %esp,%ebp
  80083b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80083e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800841:	b8 00 00 00 00       	mov    $0x0,%eax
  800846:	eb 03                	jmp    80084b <strnlen+0x13>
		n++;
  800848:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80084b:	39 d0                	cmp    %edx,%eax
  80084d:	74 06                	je     800855 <strnlen+0x1d>
  80084f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800853:	75 f3                	jne    800848 <strnlen+0x10>
		n++;
	return n;
}
  800855:	5d                   	pop    %ebp
  800856:	c3                   	ret    

00800857 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800857:	55                   	push   %ebp
  800858:	89 e5                	mov    %esp,%ebp
  80085a:	53                   	push   %ebx
  80085b:	8b 45 08             	mov    0x8(%ebp),%eax
  80085e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800861:	89 c2                	mov    %eax,%edx
  800863:	83 c2 01             	add    $0x1,%edx
  800866:	83 c1 01             	add    $0x1,%ecx
  800869:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80086d:	88 5a ff             	mov    %bl,-0x1(%edx)
  800870:	84 db                	test   %bl,%bl
  800872:	75 ef                	jne    800863 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800874:	5b                   	pop    %ebx
  800875:	5d                   	pop    %ebp
  800876:	c3                   	ret    

00800877 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800877:	55                   	push   %ebp
  800878:	89 e5                	mov    %esp,%ebp
  80087a:	53                   	push   %ebx
  80087b:	83 ec 08             	sub    $0x8,%esp
  80087e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800881:	89 1c 24             	mov    %ebx,(%esp)
  800884:	e8 97 ff ff ff       	call   800820 <strlen>
	strcpy(dst + len, src);
  800889:	8b 55 0c             	mov    0xc(%ebp),%edx
  80088c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800890:	01 d8                	add    %ebx,%eax
  800892:	89 04 24             	mov    %eax,(%esp)
  800895:	e8 bd ff ff ff       	call   800857 <strcpy>
	return dst;
}
  80089a:	89 d8                	mov    %ebx,%eax
  80089c:	83 c4 08             	add    $0x8,%esp
  80089f:	5b                   	pop    %ebx
  8008a0:	5d                   	pop    %ebp
  8008a1:	c3                   	ret    

008008a2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8008a2:	55                   	push   %ebp
  8008a3:	89 e5                	mov    %esp,%ebp
  8008a5:	56                   	push   %esi
  8008a6:	53                   	push   %ebx
  8008a7:	8b 75 08             	mov    0x8(%ebp),%esi
  8008aa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008ad:	89 f3                	mov    %esi,%ebx
  8008af:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008b2:	89 f2                	mov    %esi,%edx
  8008b4:	eb 0f                	jmp    8008c5 <strncpy+0x23>
		*dst++ = *src;
  8008b6:	83 c2 01             	add    $0x1,%edx
  8008b9:	0f b6 01             	movzbl (%ecx),%eax
  8008bc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8008bf:	80 39 01             	cmpb   $0x1,(%ecx)
  8008c2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008c5:	39 da                	cmp    %ebx,%edx
  8008c7:	75 ed                	jne    8008b6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8008c9:	89 f0                	mov    %esi,%eax
  8008cb:	5b                   	pop    %ebx
  8008cc:	5e                   	pop    %esi
  8008cd:	5d                   	pop    %ebp
  8008ce:	c3                   	ret    

008008cf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8008cf:	55                   	push   %ebp
  8008d0:	89 e5                	mov    %esp,%ebp
  8008d2:	56                   	push   %esi
  8008d3:	53                   	push   %ebx
  8008d4:	8b 75 08             	mov    0x8(%ebp),%esi
  8008d7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008da:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8008dd:	89 f0                	mov    %esi,%eax
  8008df:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008e3:	85 c9                	test   %ecx,%ecx
  8008e5:	75 0b                	jne    8008f2 <strlcpy+0x23>
  8008e7:	eb 1d                	jmp    800906 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008e9:	83 c0 01             	add    $0x1,%eax
  8008ec:	83 c2 01             	add    $0x1,%edx
  8008ef:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008f2:	39 d8                	cmp    %ebx,%eax
  8008f4:	74 0b                	je     800901 <strlcpy+0x32>
  8008f6:	0f b6 0a             	movzbl (%edx),%ecx
  8008f9:	84 c9                	test   %cl,%cl
  8008fb:	75 ec                	jne    8008e9 <strlcpy+0x1a>
  8008fd:	89 c2                	mov    %eax,%edx
  8008ff:	eb 02                	jmp    800903 <strlcpy+0x34>
  800901:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800903:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800906:	29 f0                	sub    %esi,%eax
}
  800908:	5b                   	pop    %ebx
  800909:	5e                   	pop    %esi
  80090a:	5d                   	pop    %ebp
  80090b:	c3                   	ret    

0080090c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80090c:	55                   	push   %ebp
  80090d:	89 e5                	mov    %esp,%ebp
  80090f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800912:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800915:	eb 06                	jmp    80091d <strcmp+0x11>
		p++, q++;
  800917:	83 c1 01             	add    $0x1,%ecx
  80091a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80091d:	0f b6 01             	movzbl (%ecx),%eax
  800920:	84 c0                	test   %al,%al
  800922:	74 04                	je     800928 <strcmp+0x1c>
  800924:	3a 02                	cmp    (%edx),%al
  800926:	74 ef                	je     800917 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800928:	0f b6 c0             	movzbl %al,%eax
  80092b:	0f b6 12             	movzbl (%edx),%edx
  80092e:	29 d0                	sub    %edx,%eax
}
  800930:	5d                   	pop    %ebp
  800931:	c3                   	ret    

00800932 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800932:	55                   	push   %ebp
  800933:	89 e5                	mov    %esp,%ebp
  800935:	53                   	push   %ebx
  800936:	8b 45 08             	mov    0x8(%ebp),%eax
  800939:	8b 55 0c             	mov    0xc(%ebp),%edx
  80093c:	89 c3                	mov    %eax,%ebx
  80093e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800941:	eb 06                	jmp    800949 <strncmp+0x17>
		n--, p++, q++;
  800943:	83 c0 01             	add    $0x1,%eax
  800946:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800949:	39 d8                	cmp    %ebx,%eax
  80094b:	74 15                	je     800962 <strncmp+0x30>
  80094d:	0f b6 08             	movzbl (%eax),%ecx
  800950:	84 c9                	test   %cl,%cl
  800952:	74 04                	je     800958 <strncmp+0x26>
  800954:	3a 0a                	cmp    (%edx),%cl
  800956:	74 eb                	je     800943 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800958:	0f b6 00             	movzbl (%eax),%eax
  80095b:	0f b6 12             	movzbl (%edx),%edx
  80095e:	29 d0                	sub    %edx,%eax
  800960:	eb 05                	jmp    800967 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800962:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800967:	5b                   	pop    %ebx
  800968:	5d                   	pop    %ebp
  800969:	c3                   	ret    

0080096a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80096a:	55                   	push   %ebp
  80096b:	89 e5                	mov    %esp,%ebp
  80096d:	8b 45 08             	mov    0x8(%ebp),%eax
  800970:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800974:	eb 07                	jmp    80097d <strchr+0x13>
		if (*s == c)
  800976:	38 ca                	cmp    %cl,%dl
  800978:	74 0f                	je     800989 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80097a:	83 c0 01             	add    $0x1,%eax
  80097d:	0f b6 10             	movzbl (%eax),%edx
  800980:	84 d2                	test   %dl,%dl
  800982:	75 f2                	jne    800976 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800984:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800989:	5d                   	pop    %ebp
  80098a:	c3                   	ret    

0080098b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80098b:	55                   	push   %ebp
  80098c:	89 e5                	mov    %esp,%ebp
  80098e:	8b 45 08             	mov    0x8(%ebp),%eax
  800991:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800995:	eb 07                	jmp    80099e <strfind+0x13>
		if (*s == c)
  800997:	38 ca                	cmp    %cl,%dl
  800999:	74 0a                	je     8009a5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  80099b:	83 c0 01             	add    $0x1,%eax
  80099e:	0f b6 10             	movzbl (%eax),%edx
  8009a1:	84 d2                	test   %dl,%dl
  8009a3:	75 f2                	jne    800997 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  8009a5:	5d                   	pop    %ebp
  8009a6:	c3                   	ret    

008009a7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8009a7:	55                   	push   %ebp
  8009a8:	89 e5                	mov    %esp,%ebp
  8009aa:	57                   	push   %edi
  8009ab:	56                   	push   %esi
  8009ac:	53                   	push   %ebx
  8009ad:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009b0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8009b3:	85 c9                	test   %ecx,%ecx
  8009b5:	74 36                	je     8009ed <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8009b7:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8009bd:	75 28                	jne    8009e7 <memset+0x40>
  8009bf:	f6 c1 03             	test   $0x3,%cl
  8009c2:	75 23                	jne    8009e7 <memset+0x40>
		c &= 0xFF;
  8009c4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8009c8:	89 d3                	mov    %edx,%ebx
  8009ca:	c1 e3 08             	shl    $0x8,%ebx
  8009cd:	89 d6                	mov    %edx,%esi
  8009cf:	c1 e6 18             	shl    $0x18,%esi
  8009d2:	89 d0                	mov    %edx,%eax
  8009d4:	c1 e0 10             	shl    $0x10,%eax
  8009d7:	09 f0                	or     %esi,%eax
  8009d9:	09 c2                	or     %eax,%edx
  8009db:	89 d0                	mov    %edx,%eax
  8009dd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  8009df:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  8009e2:	fc                   	cld    
  8009e3:	f3 ab                	rep stos %eax,%es:(%edi)
  8009e5:	eb 06                	jmp    8009ed <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009e7:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009ea:	fc                   	cld    
  8009eb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009ed:	89 f8                	mov    %edi,%eax
  8009ef:	5b                   	pop    %ebx
  8009f0:	5e                   	pop    %esi
  8009f1:	5f                   	pop    %edi
  8009f2:	5d                   	pop    %ebp
  8009f3:	c3                   	ret    

008009f4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009f4:	55                   	push   %ebp
  8009f5:	89 e5                	mov    %esp,%ebp
  8009f7:	57                   	push   %edi
  8009f8:	56                   	push   %esi
  8009f9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009fc:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009ff:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a02:	39 c6                	cmp    %eax,%esi
  800a04:	73 35                	jae    800a3b <memmove+0x47>
  800a06:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a09:	39 d0                	cmp    %edx,%eax
  800a0b:	73 2e                	jae    800a3b <memmove+0x47>
		s += n;
		d += n;
  800a0d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800a10:	89 d6                	mov    %edx,%esi
  800a12:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a14:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a1a:	75 13                	jne    800a2f <memmove+0x3b>
  800a1c:	f6 c1 03             	test   $0x3,%cl
  800a1f:	75 0e                	jne    800a2f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a21:	83 ef 04             	sub    $0x4,%edi
  800a24:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a27:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800a2a:	fd                   	std    
  800a2b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a2d:	eb 09                	jmp    800a38 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a2f:	83 ef 01             	sub    $0x1,%edi
  800a32:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a35:	fd                   	std    
  800a36:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a38:	fc                   	cld    
  800a39:	eb 1d                	jmp    800a58 <memmove+0x64>
  800a3b:	89 f2                	mov    %esi,%edx
  800a3d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a3f:	f6 c2 03             	test   $0x3,%dl
  800a42:	75 0f                	jne    800a53 <memmove+0x5f>
  800a44:	f6 c1 03             	test   $0x3,%cl
  800a47:	75 0a                	jne    800a53 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a49:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800a4c:	89 c7                	mov    %eax,%edi
  800a4e:	fc                   	cld    
  800a4f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a51:	eb 05                	jmp    800a58 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a53:	89 c7                	mov    %eax,%edi
  800a55:	fc                   	cld    
  800a56:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a58:	5e                   	pop    %esi
  800a59:	5f                   	pop    %edi
  800a5a:	5d                   	pop    %ebp
  800a5b:	c3                   	ret    

00800a5c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a5c:	55                   	push   %ebp
  800a5d:	89 e5                	mov    %esp,%ebp
  800a5f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800a62:	8b 45 10             	mov    0x10(%ebp),%eax
  800a65:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a69:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a6c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a70:	8b 45 08             	mov    0x8(%ebp),%eax
  800a73:	89 04 24             	mov    %eax,(%esp)
  800a76:	e8 79 ff ff ff       	call   8009f4 <memmove>
}
  800a7b:	c9                   	leave  
  800a7c:	c3                   	ret    

00800a7d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a7d:	55                   	push   %ebp
  800a7e:	89 e5                	mov    %esp,%ebp
  800a80:	56                   	push   %esi
  800a81:	53                   	push   %ebx
  800a82:	8b 55 08             	mov    0x8(%ebp),%edx
  800a85:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a88:	89 d6                	mov    %edx,%esi
  800a8a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a8d:	eb 1a                	jmp    800aa9 <memcmp+0x2c>
		if (*s1 != *s2)
  800a8f:	0f b6 02             	movzbl (%edx),%eax
  800a92:	0f b6 19             	movzbl (%ecx),%ebx
  800a95:	38 d8                	cmp    %bl,%al
  800a97:	74 0a                	je     800aa3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a99:	0f b6 c0             	movzbl %al,%eax
  800a9c:	0f b6 db             	movzbl %bl,%ebx
  800a9f:	29 d8                	sub    %ebx,%eax
  800aa1:	eb 0f                	jmp    800ab2 <memcmp+0x35>
		s1++, s2++;
  800aa3:	83 c2 01             	add    $0x1,%edx
  800aa6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800aa9:	39 f2                	cmp    %esi,%edx
  800aab:	75 e2                	jne    800a8f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800aad:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800ab2:	5b                   	pop    %ebx
  800ab3:	5e                   	pop    %esi
  800ab4:	5d                   	pop    %ebp
  800ab5:	c3                   	ret    

00800ab6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800ab6:	55                   	push   %ebp
  800ab7:	89 e5                	mov    %esp,%ebp
  800ab9:	8b 45 08             	mov    0x8(%ebp),%eax
  800abc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800abf:	89 c2                	mov    %eax,%edx
  800ac1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800ac4:	eb 07                	jmp    800acd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800ac6:	38 08                	cmp    %cl,(%eax)
  800ac8:	74 07                	je     800ad1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800aca:	83 c0 01             	add    $0x1,%eax
  800acd:	39 d0                	cmp    %edx,%eax
  800acf:	72 f5                	jb     800ac6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800ad1:	5d                   	pop    %ebp
  800ad2:	c3                   	ret    

00800ad3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800ad3:	55                   	push   %ebp
  800ad4:	89 e5                	mov    %esp,%ebp
  800ad6:	57                   	push   %edi
  800ad7:	56                   	push   %esi
  800ad8:	53                   	push   %ebx
  800ad9:	8b 55 08             	mov    0x8(%ebp),%edx
  800adc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800adf:	eb 03                	jmp    800ae4 <strtol+0x11>
		s++;
  800ae1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800ae4:	0f b6 0a             	movzbl (%edx),%ecx
  800ae7:	80 f9 09             	cmp    $0x9,%cl
  800aea:	74 f5                	je     800ae1 <strtol+0xe>
  800aec:	80 f9 20             	cmp    $0x20,%cl
  800aef:	74 f0                	je     800ae1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800af1:	80 f9 2b             	cmp    $0x2b,%cl
  800af4:	75 0a                	jne    800b00 <strtol+0x2d>
		s++;
  800af6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800af9:	bf 00 00 00 00       	mov    $0x0,%edi
  800afe:	eb 11                	jmp    800b11 <strtol+0x3e>
  800b00:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b05:	80 f9 2d             	cmp    $0x2d,%cl
  800b08:	75 07                	jne    800b11 <strtol+0x3e>
		s++, neg = 1;
  800b0a:	8d 52 01             	lea    0x1(%edx),%edx
  800b0d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b11:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800b16:	75 15                	jne    800b2d <strtol+0x5a>
  800b18:	80 3a 30             	cmpb   $0x30,(%edx)
  800b1b:	75 10                	jne    800b2d <strtol+0x5a>
  800b1d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b21:	75 0a                	jne    800b2d <strtol+0x5a>
		s += 2, base = 16;
  800b23:	83 c2 02             	add    $0x2,%edx
  800b26:	b8 10 00 00 00       	mov    $0x10,%eax
  800b2b:	eb 10                	jmp    800b3d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800b2d:	85 c0                	test   %eax,%eax
  800b2f:	75 0c                	jne    800b3d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b31:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b33:	80 3a 30             	cmpb   $0x30,(%edx)
  800b36:	75 05                	jne    800b3d <strtol+0x6a>
		s++, base = 8;
  800b38:	83 c2 01             	add    $0x1,%edx
  800b3b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800b3d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800b42:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b45:	0f b6 0a             	movzbl (%edx),%ecx
  800b48:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800b4b:	89 f0                	mov    %esi,%eax
  800b4d:	3c 09                	cmp    $0x9,%al
  800b4f:	77 08                	ja     800b59 <strtol+0x86>
			dig = *s - '0';
  800b51:	0f be c9             	movsbl %cl,%ecx
  800b54:	83 e9 30             	sub    $0x30,%ecx
  800b57:	eb 20                	jmp    800b79 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800b59:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800b5c:	89 f0                	mov    %esi,%eax
  800b5e:	3c 19                	cmp    $0x19,%al
  800b60:	77 08                	ja     800b6a <strtol+0x97>
			dig = *s - 'a' + 10;
  800b62:	0f be c9             	movsbl %cl,%ecx
  800b65:	83 e9 57             	sub    $0x57,%ecx
  800b68:	eb 0f                	jmp    800b79 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800b6a:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800b6d:	89 f0                	mov    %esi,%eax
  800b6f:	3c 19                	cmp    $0x19,%al
  800b71:	77 16                	ja     800b89 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800b73:	0f be c9             	movsbl %cl,%ecx
  800b76:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800b79:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800b7c:	7d 0f                	jge    800b8d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800b7e:	83 c2 01             	add    $0x1,%edx
  800b81:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800b85:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800b87:	eb bc                	jmp    800b45 <strtol+0x72>
  800b89:	89 d8                	mov    %ebx,%eax
  800b8b:	eb 02                	jmp    800b8f <strtol+0xbc>
  800b8d:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800b8f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b93:	74 05                	je     800b9a <strtol+0xc7>
		*endptr = (char *) s;
  800b95:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b98:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800b9a:	f7 d8                	neg    %eax
  800b9c:	85 ff                	test   %edi,%edi
  800b9e:	0f 44 c3             	cmove  %ebx,%eax
}
  800ba1:	5b                   	pop    %ebx
  800ba2:	5e                   	pop    %esi
  800ba3:	5f                   	pop    %edi
  800ba4:	5d                   	pop    %ebp
  800ba5:	c3                   	ret    
  800ba6:	66 90                	xchg   %ax,%ax
  800ba8:	66 90                	xchg   %ax,%ax
  800baa:	66 90                	xchg   %ax,%ax
  800bac:	66 90                	xchg   %ax,%ax
  800bae:	66 90                	xchg   %ax,%ax

00800bb0 <__udivdi3>:
  800bb0:	55                   	push   %ebp
  800bb1:	57                   	push   %edi
  800bb2:	56                   	push   %esi
  800bb3:	83 ec 0c             	sub    $0xc,%esp
  800bb6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800bba:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800bbe:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800bc2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800bc6:	85 c0                	test   %eax,%eax
  800bc8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800bcc:	89 ea                	mov    %ebp,%edx
  800bce:	89 0c 24             	mov    %ecx,(%esp)
  800bd1:	75 2d                	jne    800c00 <__udivdi3+0x50>
  800bd3:	39 e9                	cmp    %ebp,%ecx
  800bd5:	77 61                	ja     800c38 <__udivdi3+0x88>
  800bd7:	85 c9                	test   %ecx,%ecx
  800bd9:	89 ce                	mov    %ecx,%esi
  800bdb:	75 0b                	jne    800be8 <__udivdi3+0x38>
  800bdd:	b8 01 00 00 00       	mov    $0x1,%eax
  800be2:	31 d2                	xor    %edx,%edx
  800be4:	f7 f1                	div    %ecx
  800be6:	89 c6                	mov    %eax,%esi
  800be8:	31 d2                	xor    %edx,%edx
  800bea:	89 e8                	mov    %ebp,%eax
  800bec:	f7 f6                	div    %esi
  800bee:	89 c5                	mov    %eax,%ebp
  800bf0:	89 f8                	mov    %edi,%eax
  800bf2:	f7 f6                	div    %esi
  800bf4:	89 ea                	mov    %ebp,%edx
  800bf6:	83 c4 0c             	add    $0xc,%esp
  800bf9:	5e                   	pop    %esi
  800bfa:	5f                   	pop    %edi
  800bfb:	5d                   	pop    %ebp
  800bfc:	c3                   	ret    
  800bfd:	8d 76 00             	lea    0x0(%esi),%esi
  800c00:	39 e8                	cmp    %ebp,%eax
  800c02:	77 24                	ja     800c28 <__udivdi3+0x78>
  800c04:	0f bd e8             	bsr    %eax,%ebp
  800c07:	83 f5 1f             	xor    $0x1f,%ebp
  800c0a:	75 3c                	jne    800c48 <__udivdi3+0x98>
  800c0c:	8b 74 24 04          	mov    0x4(%esp),%esi
  800c10:	39 34 24             	cmp    %esi,(%esp)
  800c13:	0f 86 9f 00 00 00    	jbe    800cb8 <__udivdi3+0x108>
  800c19:	39 d0                	cmp    %edx,%eax
  800c1b:	0f 82 97 00 00 00    	jb     800cb8 <__udivdi3+0x108>
  800c21:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c28:	31 d2                	xor    %edx,%edx
  800c2a:	31 c0                	xor    %eax,%eax
  800c2c:	83 c4 0c             	add    $0xc,%esp
  800c2f:	5e                   	pop    %esi
  800c30:	5f                   	pop    %edi
  800c31:	5d                   	pop    %ebp
  800c32:	c3                   	ret    
  800c33:	90                   	nop
  800c34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c38:	89 f8                	mov    %edi,%eax
  800c3a:	f7 f1                	div    %ecx
  800c3c:	31 d2                	xor    %edx,%edx
  800c3e:	83 c4 0c             	add    $0xc,%esp
  800c41:	5e                   	pop    %esi
  800c42:	5f                   	pop    %edi
  800c43:	5d                   	pop    %ebp
  800c44:	c3                   	ret    
  800c45:	8d 76 00             	lea    0x0(%esi),%esi
  800c48:	89 e9                	mov    %ebp,%ecx
  800c4a:	8b 3c 24             	mov    (%esp),%edi
  800c4d:	d3 e0                	shl    %cl,%eax
  800c4f:	89 c6                	mov    %eax,%esi
  800c51:	b8 20 00 00 00       	mov    $0x20,%eax
  800c56:	29 e8                	sub    %ebp,%eax
  800c58:	89 c1                	mov    %eax,%ecx
  800c5a:	d3 ef                	shr    %cl,%edi
  800c5c:	89 e9                	mov    %ebp,%ecx
  800c5e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800c62:	8b 3c 24             	mov    (%esp),%edi
  800c65:	09 74 24 08          	or     %esi,0x8(%esp)
  800c69:	89 d6                	mov    %edx,%esi
  800c6b:	d3 e7                	shl    %cl,%edi
  800c6d:	89 c1                	mov    %eax,%ecx
  800c6f:	89 3c 24             	mov    %edi,(%esp)
  800c72:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800c76:	d3 ee                	shr    %cl,%esi
  800c78:	89 e9                	mov    %ebp,%ecx
  800c7a:	d3 e2                	shl    %cl,%edx
  800c7c:	89 c1                	mov    %eax,%ecx
  800c7e:	d3 ef                	shr    %cl,%edi
  800c80:	09 d7                	or     %edx,%edi
  800c82:	89 f2                	mov    %esi,%edx
  800c84:	89 f8                	mov    %edi,%eax
  800c86:	f7 74 24 08          	divl   0x8(%esp)
  800c8a:	89 d6                	mov    %edx,%esi
  800c8c:	89 c7                	mov    %eax,%edi
  800c8e:	f7 24 24             	mull   (%esp)
  800c91:	39 d6                	cmp    %edx,%esi
  800c93:	89 14 24             	mov    %edx,(%esp)
  800c96:	72 30                	jb     800cc8 <__udivdi3+0x118>
  800c98:	8b 54 24 04          	mov    0x4(%esp),%edx
  800c9c:	89 e9                	mov    %ebp,%ecx
  800c9e:	d3 e2                	shl    %cl,%edx
  800ca0:	39 c2                	cmp    %eax,%edx
  800ca2:	73 05                	jae    800ca9 <__udivdi3+0xf9>
  800ca4:	3b 34 24             	cmp    (%esp),%esi
  800ca7:	74 1f                	je     800cc8 <__udivdi3+0x118>
  800ca9:	89 f8                	mov    %edi,%eax
  800cab:	31 d2                	xor    %edx,%edx
  800cad:	e9 7a ff ff ff       	jmp    800c2c <__udivdi3+0x7c>
  800cb2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800cb8:	31 d2                	xor    %edx,%edx
  800cba:	b8 01 00 00 00       	mov    $0x1,%eax
  800cbf:	e9 68 ff ff ff       	jmp    800c2c <__udivdi3+0x7c>
  800cc4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800cc8:	8d 47 ff             	lea    -0x1(%edi),%eax
  800ccb:	31 d2                	xor    %edx,%edx
  800ccd:	83 c4 0c             	add    $0xc,%esp
  800cd0:	5e                   	pop    %esi
  800cd1:	5f                   	pop    %edi
  800cd2:	5d                   	pop    %ebp
  800cd3:	c3                   	ret    
  800cd4:	66 90                	xchg   %ax,%ax
  800cd6:	66 90                	xchg   %ax,%ax
  800cd8:	66 90                	xchg   %ax,%ax
  800cda:	66 90                	xchg   %ax,%ax
  800cdc:	66 90                	xchg   %ax,%ax
  800cde:	66 90                	xchg   %ax,%ax

00800ce0 <__umoddi3>:
  800ce0:	55                   	push   %ebp
  800ce1:	57                   	push   %edi
  800ce2:	56                   	push   %esi
  800ce3:	83 ec 14             	sub    $0x14,%esp
  800ce6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800cea:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800cee:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800cf2:	89 c7                	mov    %eax,%edi
  800cf4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800cf8:	8b 44 24 30          	mov    0x30(%esp),%eax
  800cfc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800d00:	89 34 24             	mov    %esi,(%esp)
  800d03:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d07:	85 c0                	test   %eax,%eax
  800d09:	89 c2                	mov    %eax,%edx
  800d0b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800d0f:	75 17                	jne    800d28 <__umoddi3+0x48>
  800d11:	39 fe                	cmp    %edi,%esi
  800d13:	76 4b                	jbe    800d60 <__umoddi3+0x80>
  800d15:	89 c8                	mov    %ecx,%eax
  800d17:	89 fa                	mov    %edi,%edx
  800d19:	f7 f6                	div    %esi
  800d1b:	89 d0                	mov    %edx,%eax
  800d1d:	31 d2                	xor    %edx,%edx
  800d1f:	83 c4 14             	add    $0x14,%esp
  800d22:	5e                   	pop    %esi
  800d23:	5f                   	pop    %edi
  800d24:	5d                   	pop    %ebp
  800d25:	c3                   	ret    
  800d26:	66 90                	xchg   %ax,%ax
  800d28:	39 f8                	cmp    %edi,%eax
  800d2a:	77 54                	ja     800d80 <__umoddi3+0xa0>
  800d2c:	0f bd e8             	bsr    %eax,%ebp
  800d2f:	83 f5 1f             	xor    $0x1f,%ebp
  800d32:	75 5c                	jne    800d90 <__umoddi3+0xb0>
  800d34:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800d38:	39 3c 24             	cmp    %edi,(%esp)
  800d3b:	0f 87 e7 00 00 00    	ja     800e28 <__umoddi3+0x148>
  800d41:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800d45:	29 f1                	sub    %esi,%ecx
  800d47:	19 c7                	sbb    %eax,%edi
  800d49:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d4d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800d51:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d55:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d59:	83 c4 14             	add    $0x14,%esp
  800d5c:	5e                   	pop    %esi
  800d5d:	5f                   	pop    %edi
  800d5e:	5d                   	pop    %ebp
  800d5f:	c3                   	ret    
  800d60:	85 f6                	test   %esi,%esi
  800d62:	89 f5                	mov    %esi,%ebp
  800d64:	75 0b                	jne    800d71 <__umoddi3+0x91>
  800d66:	b8 01 00 00 00       	mov    $0x1,%eax
  800d6b:	31 d2                	xor    %edx,%edx
  800d6d:	f7 f6                	div    %esi
  800d6f:	89 c5                	mov    %eax,%ebp
  800d71:	8b 44 24 04          	mov    0x4(%esp),%eax
  800d75:	31 d2                	xor    %edx,%edx
  800d77:	f7 f5                	div    %ebp
  800d79:	89 c8                	mov    %ecx,%eax
  800d7b:	f7 f5                	div    %ebp
  800d7d:	eb 9c                	jmp    800d1b <__umoddi3+0x3b>
  800d7f:	90                   	nop
  800d80:	89 c8                	mov    %ecx,%eax
  800d82:	89 fa                	mov    %edi,%edx
  800d84:	83 c4 14             	add    $0x14,%esp
  800d87:	5e                   	pop    %esi
  800d88:	5f                   	pop    %edi
  800d89:	5d                   	pop    %ebp
  800d8a:	c3                   	ret    
  800d8b:	90                   	nop
  800d8c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d90:	8b 04 24             	mov    (%esp),%eax
  800d93:	be 20 00 00 00       	mov    $0x20,%esi
  800d98:	89 e9                	mov    %ebp,%ecx
  800d9a:	29 ee                	sub    %ebp,%esi
  800d9c:	d3 e2                	shl    %cl,%edx
  800d9e:	89 f1                	mov    %esi,%ecx
  800da0:	d3 e8                	shr    %cl,%eax
  800da2:	89 e9                	mov    %ebp,%ecx
  800da4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800da8:	8b 04 24             	mov    (%esp),%eax
  800dab:	09 54 24 04          	or     %edx,0x4(%esp)
  800daf:	89 fa                	mov    %edi,%edx
  800db1:	d3 e0                	shl    %cl,%eax
  800db3:	89 f1                	mov    %esi,%ecx
  800db5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800db9:	8b 44 24 10          	mov    0x10(%esp),%eax
  800dbd:	d3 ea                	shr    %cl,%edx
  800dbf:	89 e9                	mov    %ebp,%ecx
  800dc1:	d3 e7                	shl    %cl,%edi
  800dc3:	89 f1                	mov    %esi,%ecx
  800dc5:	d3 e8                	shr    %cl,%eax
  800dc7:	89 e9                	mov    %ebp,%ecx
  800dc9:	09 f8                	or     %edi,%eax
  800dcb:	8b 7c 24 10          	mov    0x10(%esp),%edi
  800dcf:	f7 74 24 04          	divl   0x4(%esp)
  800dd3:	d3 e7                	shl    %cl,%edi
  800dd5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800dd9:	89 d7                	mov    %edx,%edi
  800ddb:	f7 64 24 08          	mull   0x8(%esp)
  800ddf:	39 d7                	cmp    %edx,%edi
  800de1:	89 c1                	mov    %eax,%ecx
  800de3:	89 14 24             	mov    %edx,(%esp)
  800de6:	72 2c                	jb     800e14 <__umoddi3+0x134>
  800de8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  800dec:	72 22                	jb     800e10 <__umoddi3+0x130>
  800dee:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800df2:	29 c8                	sub    %ecx,%eax
  800df4:	19 d7                	sbb    %edx,%edi
  800df6:	89 e9                	mov    %ebp,%ecx
  800df8:	89 fa                	mov    %edi,%edx
  800dfa:	d3 e8                	shr    %cl,%eax
  800dfc:	89 f1                	mov    %esi,%ecx
  800dfe:	d3 e2                	shl    %cl,%edx
  800e00:	89 e9                	mov    %ebp,%ecx
  800e02:	d3 ef                	shr    %cl,%edi
  800e04:	09 d0                	or     %edx,%eax
  800e06:	89 fa                	mov    %edi,%edx
  800e08:	83 c4 14             	add    $0x14,%esp
  800e0b:	5e                   	pop    %esi
  800e0c:	5f                   	pop    %edi
  800e0d:	5d                   	pop    %ebp
  800e0e:	c3                   	ret    
  800e0f:	90                   	nop
  800e10:	39 d7                	cmp    %edx,%edi
  800e12:	75 da                	jne    800dee <__umoddi3+0x10e>
  800e14:	8b 14 24             	mov    (%esp),%edx
  800e17:	89 c1                	mov    %eax,%ecx
  800e19:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  800e1d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  800e21:	eb cb                	jmp    800dee <__umoddi3+0x10e>
  800e23:	90                   	nop
  800e24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e28:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  800e2c:	0f 82 0f ff ff ff    	jb     800d41 <__umoddi3+0x61>
  800e32:	e9 1a ff ff ff       	jmp    800d51 <__umoddi3+0x71>
