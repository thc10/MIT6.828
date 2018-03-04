
obj/user/faultread:     file format elf32-i386


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
  80002c:	e8 1f 00 00 00       	call   800050 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 18             	sub    $0x18,%esp
	cprintf("I read %08x from location 0!\n", *(unsigned*)0);
  800039:	a1 00 00 00 00       	mov    0x0,%eax
  80003e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800042:	c7 04 24 48 0e 80 00 	movl   $0x800e48,(%esp)
  800049:	e8 ee 00 00 00       	call   80013c <cprintf>
}
  80004e:	c9                   	leave  
  80004f:	c3                   	ret    

00800050 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800050:	55                   	push   %ebp
  800051:	89 e5                	mov    %esp,%ebp
  800053:	83 ec 18             	sub    $0x18,%esp
  800056:	8b 45 08             	mov    0x8(%ebp),%eax
  800059:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80005c:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800063:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800066:	85 c0                	test   %eax,%eax
  800068:	7e 08                	jle    800072 <libmain+0x22>
		binaryname = argv[0];
  80006a:	8b 0a                	mov    (%edx),%ecx
  80006c:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800072:	89 54 24 04          	mov    %edx,0x4(%esp)
  800076:	89 04 24             	mov    %eax,(%esp)
  800079:	e8 b5 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80007e:	e8 02 00 00 00       	call   800085 <exit>
}
  800083:	c9                   	leave  
  800084:	c3                   	ret    

00800085 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800085:	55                   	push   %ebp
  800086:	89 e5                	mov    %esp,%ebp
  800088:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80008b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800092:	e8 5c 0a 00 00       	call   800af3 <sys_env_destroy>
}
  800097:	c9                   	leave  
  800098:	c3                   	ret    

00800099 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800099:	55                   	push   %ebp
  80009a:	89 e5                	mov    %esp,%ebp
  80009c:	53                   	push   %ebx
  80009d:	83 ec 14             	sub    $0x14,%esp
  8000a0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000a3:	8b 13                	mov    (%ebx),%edx
  8000a5:	8d 42 01             	lea    0x1(%edx),%eax
  8000a8:	89 03                	mov    %eax,(%ebx)
  8000aa:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000ad:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000b1:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000b6:	75 19                	jne    8000d1 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8000b8:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8000bf:	00 
  8000c0:	8d 43 08             	lea    0x8(%ebx),%eax
  8000c3:	89 04 24             	mov    %eax,(%esp)
  8000c6:	e8 eb 09 00 00       	call   800ab6 <sys_cputs>
		b->idx = 0;
  8000cb:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8000d1:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000d5:	83 c4 14             	add    $0x14,%esp
  8000d8:	5b                   	pop    %ebx
  8000d9:	5d                   	pop    %ebp
  8000da:	c3                   	ret    

008000db <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000db:	55                   	push   %ebp
  8000dc:	89 e5                	mov    %esp,%ebp
  8000de:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  8000e4:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000eb:	00 00 00 
	b.cnt = 0;
  8000ee:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8000f5:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8000f8:	8b 45 0c             	mov    0xc(%ebp),%eax
  8000fb:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8000ff:	8b 45 08             	mov    0x8(%ebp),%eax
  800102:	89 44 24 08          	mov    %eax,0x8(%esp)
  800106:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80010c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800110:	c7 04 24 99 00 80 00 	movl   $0x800099,(%esp)
  800117:	e8 b2 01 00 00       	call   8002ce <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80011c:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800122:	89 44 24 04          	mov    %eax,0x4(%esp)
  800126:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80012c:	89 04 24             	mov    %eax,(%esp)
  80012f:	e8 82 09 00 00       	call   800ab6 <sys_cputs>

	return b.cnt;
}
  800134:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80013a:	c9                   	leave  
  80013b:	c3                   	ret    

0080013c <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80013c:	55                   	push   %ebp
  80013d:	89 e5                	mov    %esp,%ebp
  80013f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800142:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800145:	89 44 24 04          	mov    %eax,0x4(%esp)
  800149:	8b 45 08             	mov    0x8(%ebp),%eax
  80014c:	89 04 24             	mov    %eax,(%esp)
  80014f:	e8 87 ff ff ff       	call   8000db <vcprintf>
	va_end(ap);

	return cnt;
}
  800154:	c9                   	leave  
  800155:	c3                   	ret    
  800156:	66 90                	xchg   %ax,%ax
  800158:	66 90                	xchg   %ax,%ax
  80015a:	66 90                	xchg   %ax,%ax
  80015c:	66 90                	xchg   %ax,%ax
  80015e:	66 90                	xchg   %ax,%ax

00800160 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800160:	55                   	push   %ebp
  800161:	89 e5                	mov    %esp,%ebp
  800163:	57                   	push   %edi
  800164:	56                   	push   %esi
  800165:	53                   	push   %ebx
  800166:	83 ec 3c             	sub    $0x3c,%esp
  800169:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80016c:	89 d7                	mov    %edx,%edi
  80016e:	8b 45 08             	mov    0x8(%ebp),%eax
  800171:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800174:	8b 45 0c             	mov    0xc(%ebp),%eax
  800177:	89 c3                	mov    %eax,%ebx
  800179:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80017c:	8b 45 10             	mov    0x10(%ebp),%eax
  80017f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800182:	b9 00 00 00 00       	mov    $0x0,%ecx
  800187:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80018a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80018d:	39 d9                	cmp    %ebx,%ecx
  80018f:	72 05                	jb     800196 <printnum+0x36>
  800191:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  800194:	77 69                	ja     8001ff <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800196:	8b 4d 18             	mov    0x18(%ebp),%ecx
  800199:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80019d:	83 ee 01             	sub    $0x1,%esi
  8001a0:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001a4:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001a8:	8b 44 24 08          	mov    0x8(%esp),%eax
  8001ac:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8001b0:	89 c3                	mov    %eax,%ebx
  8001b2:	89 d6                	mov    %edx,%esi
  8001b4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8001b7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8001ba:	89 54 24 08          	mov    %edx,0x8(%esp)
  8001be:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8001c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8001c5:	89 04 24             	mov    %eax,(%esp)
  8001c8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8001cb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001cf:	e8 ec 09 00 00       	call   800bc0 <__udivdi3>
  8001d4:	89 d9                	mov    %ebx,%ecx
  8001d6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8001da:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001de:	89 04 24             	mov    %eax,(%esp)
  8001e1:	89 54 24 04          	mov    %edx,0x4(%esp)
  8001e5:	89 fa                	mov    %edi,%edx
  8001e7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8001ea:	e8 71 ff ff ff       	call   800160 <printnum>
  8001ef:	eb 1b                	jmp    80020c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001f1:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8001f5:	8b 45 18             	mov    0x18(%ebp),%eax
  8001f8:	89 04 24             	mov    %eax,(%esp)
  8001fb:	ff d3                	call   *%ebx
  8001fd:	eb 03                	jmp    800202 <printnum+0xa2>
  8001ff:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800202:	83 ee 01             	sub    $0x1,%esi
  800205:	85 f6                	test   %esi,%esi
  800207:	7f e8                	jg     8001f1 <printnum+0x91>
  800209:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80020c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800210:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800214:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800217:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80021a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80021e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800222:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800225:	89 04 24             	mov    %eax,(%esp)
  800228:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80022b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80022f:	e8 bc 0a 00 00       	call   800cf0 <__umoddi3>
  800234:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800238:	0f be 80 70 0e 80 00 	movsbl 0x800e70(%eax),%eax
  80023f:	89 04 24             	mov    %eax,(%esp)
  800242:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800245:	ff d0                	call   *%eax
}
  800247:	83 c4 3c             	add    $0x3c,%esp
  80024a:	5b                   	pop    %ebx
  80024b:	5e                   	pop    %esi
  80024c:	5f                   	pop    %edi
  80024d:	5d                   	pop    %ebp
  80024e:	c3                   	ret    

0080024f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80024f:	55                   	push   %ebp
  800250:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800252:	83 fa 01             	cmp    $0x1,%edx
  800255:	7e 0e                	jle    800265 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800257:	8b 10                	mov    (%eax),%edx
  800259:	8d 4a 08             	lea    0x8(%edx),%ecx
  80025c:	89 08                	mov    %ecx,(%eax)
  80025e:	8b 02                	mov    (%edx),%eax
  800260:	8b 52 04             	mov    0x4(%edx),%edx
  800263:	eb 22                	jmp    800287 <getuint+0x38>
	else if (lflag)
  800265:	85 d2                	test   %edx,%edx
  800267:	74 10                	je     800279 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800269:	8b 10                	mov    (%eax),%edx
  80026b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80026e:	89 08                	mov    %ecx,(%eax)
  800270:	8b 02                	mov    (%edx),%eax
  800272:	ba 00 00 00 00       	mov    $0x0,%edx
  800277:	eb 0e                	jmp    800287 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800279:	8b 10                	mov    (%eax),%edx
  80027b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80027e:	89 08                	mov    %ecx,(%eax)
  800280:	8b 02                	mov    (%edx),%eax
  800282:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800287:	5d                   	pop    %ebp
  800288:	c3                   	ret    

00800289 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800289:	55                   	push   %ebp
  80028a:	89 e5                	mov    %esp,%ebp
  80028c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80028f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800293:	8b 10                	mov    (%eax),%edx
  800295:	3b 50 04             	cmp    0x4(%eax),%edx
  800298:	73 0a                	jae    8002a4 <sprintputch+0x1b>
		*b->buf++ = ch;
  80029a:	8d 4a 01             	lea    0x1(%edx),%ecx
  80029d:	89 08                	mov    %ecx,(%eax)
  80029f:	8b 45 08             	mov    0x8(%ebp),%eax
  8002a2:	88 02                	mov    %al,(%edx)
}
  8002a4:	5d                   	pop    %ebp
  8002a5:	c3                   	ret    

008002a6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002a6:	55                   	push   %ebp
  8002a7:	89 e5                	mov    %esp,%ebp
  8002a9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8002ac:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002af:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002b3:	8b 45 10             	mov    0x10(%ebp),%eax
  8002b6:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002ba:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002bd:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002c1:	8b 45 08             	mov    0x8(%ebp),%eax
  8002c4:	89 04 24             	mov    %eax,(%esp)
  8002c7:	e8 02 00 00 00       	call   8002ce <vprintfmt>
	va_end(ap);
}
  8002cc:	c9                   	leave  
  8002cd:	c3                   	ret    

008002ce <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002ce:	55                   	push   %ebp
  8002cf:	89 e5                	mov    %esp,%ebp
  8002d1:	57                   	push   %edi
  8002d2:	56                   	push   %esi
  8002d3:	53                   	push   %ebx
  8002d4:	83 ec 3c             	sub    $0x3c,%esp
  8002d7:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8002da:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002dd:	eb 14                	jmp    8002f3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002df:	85 c0                	test   %eax,%eax
  8002e1:	0f 84 b3 03 00 00    	je     80069a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
  8002e7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002eb:	89 04 24             	mov    %eax,(%esp)
  8002ee:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8002f1:	89 f3                	mov    %esi,%ebx
  8002f3:	8d 73 01             	lea    0x1(%ebx),%esi
  8002f6:	0f b6 03             	movzbl (%ebx),%eax
  8002f9:	83 f8 25             	cmp    $0x25,%eax
  8002fc:	75 e1                	jne    8002df <vprintfmt+0x11>
  8002fe:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800302:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  800309:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  800310:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800317:	ba 00 00 00 00       	mov    $0x0,%edx
  80031c:	eb 1d                	jmp    80033b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80031e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  800320:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800324:	eb 15                	jmp    80033b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800326:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800328:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80032c:	eb 0d                	jmp    80033b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  80032e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800331:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800334:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80033b:	8d 5e 01             	lea    0x1(%esi),%ebx
  80033e:	0f b6 0e             	movzbl (%esi),%ecx
  800341:	0f b6 c1             	movzbl %cl,%eax
  800344:	83 e9 23             	sub    $0x23,%ecx
  800347:	80 f9 55             	cmp    $0x55,%cl
  80034a:	0f 87 2a 03 00 00    	ja     80067a <vprintfmt+0x3ac>
  800350:	0f b6 c9             	movzbl %cl,%ecx
  800353:	ff 24 8d 00 0f 80 00 	jmp    *0x800f00(,%ecx,4)
  80035a:	89 de                	mov    %ebx,%esi
  80035c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800361:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  800364:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  800368:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  80036b:	8d 58 d0             	lea    -0x30(%eax),%ebx
  80036e:	83 fb 09             	cmp    $0x9,%ebx
  800371:	77 36                	ja     8003a9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800373:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800376:	eb e9                	jmp    800361 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800378:	8b 45 14             	mov    0x14(%ebp),%eax
  80037b:	8d 48 04             	lea    0x4(%eax),%ecx
  80037e:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800381:	8b 00                	mov    (%eax),%eax
  800383:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800386:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800388:	eb 22                	jmp    8003ac <vprintfmt+0xde>
  80038a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80038d:	85 c9                	test   %ecx,%ecx
  80038f:	b8 00 00 00 00       	mov    $0x0,%eax
  800394:	0f 49 c1             	cmovns %ecx,%eax
  800397:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80039a:	89 de                	mov    %ebx,%esi
  80039c:	eb 9d                	jmp    80033b <vprintfmt+0x6d>
  80039e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003a0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  8003a7:	eb 92                	jmp    80033b <vprintfmt+0x6d>
  8003a9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  8003ac:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8003b0:	79 89                	jns    80033b <vprintfmt+0x6d>
  8003b2:	e9 77 ff ff ff       	jmp    80032e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003b7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ba:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003bc:	e9 7a ff ff ff       	jmp    80033b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003c1:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c4:	8d 50 04             	lea    0x4(%eax),%edx
  8003c7:	89 55 14             	mov    %edx,0x14(%ebp)
  8003ca:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003ce:	8b 00                	mov    (%eax),%eax
  8003d0:	89 04 24             	mov    %eax,(%esp)
  8003d3:	ff 55 08             	call   *0x8(%ebp)
			break;
  8003d6:	e9 18 ff ff ff       	jmp    8002f3 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003db:	8b 45 14             	mov    0x14(%ebp),%eax
  8003de:	8d 50 04             	lea    0x4(%eax),%edx
  8003e1:	89 55 14             	mov    %edx,0x14(%ebp)
  8003e4:	8b 00                	mov    (%eax),%eax
  8003e6:	99                   	cltd   
  8003e7:	31 d0                	xor    %edx,%eax
  8003e9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003eb:	83 f8 06             	cmp    $0x6,%eax
  8003ee:	7f 0b                	jg     8003fb <vprintfmt+0x12d>
  8003f0:	8b 14 85 58 10 80 00 	mov    0x801058(,%eax,4),%edx
  8003f7:	85 d2                	test   %edx,%edx
  8003f9:	75 20                	jne    80041b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  8003fb:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003ff:	c7 44 24 08 88 0e 80 	movl   $0x800e88,0x8(%esp)
  800406:	00 
  800407:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80040b:	8b 45 08             	mov    0x8(%ebp),%eax
  80040e:	89 04 24             	mov    %eax,(%esp)
  800411:	e8 90 fe ff ff       	call   8002a6 <printfmt>
  800416:	e9 d8 fe ff ff       	jmp    8002f3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  80041b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80041f:	c7 44 24 08 91 0e 80 	movl   $0x800e91,0x8(%esp)
  800426:	00 
  800427:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80042b:	8b 45 08             	mov    0x8(%ebp),%eax
  80042e:	89 04 24             	mov    %eax,(%esp)
  800431:	e8 70 fe ff ff       	call   8002a6 <printfmt>
  800436:	e9 b8 fe ff ff       	jmp    8002f3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80043b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  80043e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800441:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800444:	8b 45 14             	mov    0x14(%ebp),%eax
  800447:	8d 50 04             	lea    0x4(%eax),%edx
  80044a:	89 55 14             	mov    %edx,0x14(%ebp)
  80044d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  80044f:	85 f6                	test   %esi,%esi
  800451:	b8 81 0e 80 00       	mov    $0x800e81,%eax
  800456:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  800459:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  80045d:	0f 84 97 00 00 00    	je     8004fa <vprintfmt+0x22c>
  800463:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800467:	0f 8e 9b 00 00 00    	jle    800508 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  80046d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800471:	89 34 24             	mov    %esi,(%esp)
  800474:	e8 cf 02 00 00       	call   800748 <strnlen>
  800479:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80047c:	29 c2                	sub    %eax,%edx
  80047e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  800481:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  800485:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800488:	89 75 d8             	mov    %esi,-0x28(%ebp)
  80048b:	8b 75 08             	mov    0x8(%ebp),%esi
  80048e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800491:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800493:	eb 0f                	jmp    8004a4 <vprintfmt+0x1d6>
					putch(padc, putdat);
  800495:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800499:	8b 45 dc             	mov    -0x24(%ebp),%eax
  80049c:	89 04 24             	mov    %eax,(%esp)
  80049f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004a1:	83 eb 01             	sub    $0x1,%ebx
  8004a4:	85 db                	test   %ebx,%ebx
  8004a6:	7f ed                	jg     800495 <vprintfmt+0x1c7>
  8004a8:	8b 75 d8             	mov    -0x28(%ebp),%esi
  8004ab:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8004ae:	85 d2                	test   %edx,%edx
  8004b0:	b8 00 00 00 00       	mov    $0x0,%eax
  8004b5:	0f 49 c2             	cmovns %edx,%eax
  8004b8:	29 c2                	sub    %eax,%edx
  8004ba:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8004bd:	89 d7                	mov    %edx,%edi
  8004bf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8004c2:	eb 50                	jmp    800514 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004c4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004c8:	74 1e                	je     8004e8 <vprintfmt+0x21a>
  8004ca:	0f be d2             	movsbl %dl,%edx
  8004cd:	83 ea 20             	sub    $0x20,%edx
  8004d0:	83 fa 5e             	cmp    $0x5e,%edx
  8004d3:	76 13                	jbe    8004e8 <vprintfmt+0x21a>
					putch('?', putdat);
  8004d5:	8b 45 0c             	mov    0xc(%ebp),%eax
  8004d8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8004dc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  8004e3:	ff 55 08             	call   *0x8(%ebp)
  8004e6:	eb 0d                	jmp    8004f5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  8004e8:	8b 55 0c             	mov    0xc(%ebp),%edx
  8004eb:	89 54 24 04          	mov    %edx,0x4(%esp)
  8004ef:	89 04 24             	mov    %eax,(%esp)
  8004f2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004f5:	83 ef 01             	sub    $0x1,%edi
  8004f8:	eb 1a                	jmp    800514 <vprintfmt+0x246>
  8004fa:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8004fd:	8b 7d dc             	mov    -0x24(%ebp),%edi
  800500:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800503:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800506:	eb 0c                	jmp    800514 <vprintfmt+0x246>
  800508:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80050b:	8b 7d dc             	mov    -0x24(%ebp),%edi
  80050e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800511:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800514:	83 c6 01             	add    $0x1,%esi
  800517:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  80051b:	0f be c2             	movsbl %dl,%eax
  80051e:	85 c0                	test   %eax,%eax
  800520:	74 27                	je     800549 <vprintfmt+0x27b>
  800522:	85 db                	test   %ebx,%ebx
  800524:	78 9e                	js     8004c4 <vprintfmt+0x1f6>
  800526:	83 eb 01             	sub    $0x1,%ebx
  800529:	79 99                	jns    8004c4 <vprintfmt+0x1f6>
  80052b:	89 f8                	mov    %edi,%eax
  80052d:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800530:	8b 75 08             	mov    0x8(%ebp),%esi
  800533:	89 c3                	mov    %eax,%ebx
  800535:	eb 1a                	jmp    800551 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800537:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80053b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800542:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800544:	83 eb 01             	sub    $0x1,%ebx
  800547:	eb 08                	jmp    800551 <vprintfmt+0x283>
  800549:	89 fb                	mov    %edi,%ebx
  80054b:	8b 75 08             	mov    0x8(%ebp),%esi
  80054e:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800551:	85 db                	test   %ebx,%ebx
  800553:	7f e2                	jg     800537 <vprintfmt+0x269>
  800555:	89 75 08             	mov    %esi,0x8(%ebp)
  800558:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80055b:	e9 93 fd ff ff       	jmp    8002f3 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800560:	83 fa 01             	cmp    $0x1,%edx
  800563:	7e 16                	jle    80057b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
  800565:	8b 45 14             	mov    0x14(%ebp),%eax
  800568:	8d 50 08             	lea    0x8(%eax),%edx
  80056b:	89 55 14             	mov    %edx,0x14(%ebp)
  80056e:	8b 50 04             	mov    0x4(%eax),%edx
  800571:	8b 00                	mov    (%eax),%eax
  800573:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800576:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800579:	eb 32                	jmp    8005ad <vprintfmt+0x2df>
	else if (lflag)
  80057b:	85 d2                	test   %edx,%edx
  80057d:	74 18                	je     800597 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
  80057f:	8b 45 14             	mov    0x14(%ebp),%eax
  800582:	8d 50 04             	lea    0x4(%eax),%edx
  800585:	89 55 14             	mov    %edx,0x14(%ebp)
  800588:	8b 30                	mov    (%eax),%esi
  80058a:	89 75 e0             	mov    %esi,-0x20(%ebp)
  80058d:	89 f0                	mov    %esi,%eax
  80058f:	c1 f8 1f             	sar    $0x1f,%eax
  800592:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800595:	eb 16                	jmp    8005ad <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
  800597:	8b 45 14             	mov    0x14(%ebp),%eax
  80059a:	8d 50 04             	lea    0x4(%eax),%edx
  80059d:	89 55 14             	mov    %edx,0x14(%ebp)
  8005a0:	8b 30                	mov    (%eax),%esi
  8005a2:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8005a5:	89 f0                	mov    %esi,%eax
  8005a7:	c1 f8 1f             	sar    $0x1f,%eax
  8005aa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005ad:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005b0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005b3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005b8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8005bc:	0f 89 80 00 00 00    	jns    800642 <vprintfmt+0x374>
				putch('-', putdat);
  8005c2:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005c6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8005cd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8005d0:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005d3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8005d6:	f7 d8                	neg    %eax
  8005d8:	83 d2 00             	adc    $0x0,%edx
  8005db:	f7 da                	neg    %edx
			}
			base = 10;
  8005dd:	b9 0a 00 00 00       	mov    $0xa,%ecx
  8005e2:	eb 5e                	jmp    800642 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8005e4:	8d 45 14             	lea    0x14(%ebp),%eax
  8005e7:	e8 63 fc ff ff       	call   80024f <getuint>
			base = 10;
  8005ec:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  8005f1:	eb 4f                	jmp    800642 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  8005f3:	8d 45 14             	lea    0x14(%ebp),%eax
  8005f6:	e8 54 fc ff ff       	call   80024f <getuint>
			base = 8;
  8005fb:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800600:	eb 40                	jmp    800642 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
  800602:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800606:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80060d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800610:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800614:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80061b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80061e:	8b 45 14             	mov    0x14(%ebp),%eax
  800621:	8d 50 04             	lea    0x4(%eax),%edx
  800624:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800627:	8b 00                	mov    (%eax),%eax
  800629:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80062e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800633:	eb 0d                	jmp    800642 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800635:	8d 45 14             	lea    0x14(%ebp),%eax
  800638:	e8 12 fc ff ff       	call   80024f <getuint>
			base = 16;
  80063d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800642:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  800646:	89 74 24 10          	mov    %esi,0x10(%esp)
  80064a:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80064d:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800651:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800655:	89 04 24             	mov    %eax,(%esp)
  800658:	89 54 24 04          	mov    %edx,0x4(%esp)
  80065c:	89 fa                	mov    %edi,%edx
  80065e:	8b 45 08             	mov    0x8(%ebp),%eax
  800661:	e8 fa fa ff ff       	call   800160 <printnum>
			break;
  800666:	e9 88 fc ff ff       	jmp    8002f3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80066b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80066f:	89 04 24             	mov    %eax,(%esp)
  800672:	ff 55 08             	call   *0x8(%ebp)
			break;
  800675:	e9 79 fc ff ff       	jmp    8002f3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80067a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80067e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800685:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  800688:	89 f3                	mov    %esi,%ebx
  80068a:	eb 03                	jmp    80068f <vprintfmt+0x3c1>
  80068c:	83 eb 01             	sub    $0x1,%ebx
  80068f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  800693:	75 f7                	jne    80068c <vprintfmt+0x3be>
  800695:	e9 59 fc ff ff       	jmp    8002f3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  80069a:	83 c4 3c             	add    $0x3c,%esp
  80069d:	5b                   	pop    %ebx
  80069e:	5e                   	pop    %esi
  80069f:	5f                   	pop    %edi
  8006a0:	5d                   	pop    %ebp
  8006a1:	c3                   	ret    

008006a2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006a2:	55                   	push   %ebp
  8006a3:	89 e5                	mov    %esp,%ebp
  8006a5:	83 ec 28             	sub    $0x28,%esp
  8006a8:	8b 45 08             	mov    0x8(%ebp),%eax
  8006ab:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006ae:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006b1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006b5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006b8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006bf:	85 c0                	test   %eax,%eax
  8006c1:	74 30                	je     8006f3 <vsnprintf+0x51>
  8006c3:	85 d2                	test   %edx,%edx
  8006c5:	7e 2c                	jle    8006f3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006c7:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ca:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8006ce:	8b 45 10             	mov    0x10(%ebp),%eax
  8006d1:	89 44 24 08          	mov    %eax,0x8(%esp)
  8006d5:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006d8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8006dc:	c7 04 24 89 02 80 00 	movl   $0x800289,(%esp)
  8006e3:	e8 e6 fb ff ff       	call   8002ce <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006e8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8006eb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8006ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8006f1:	eb 05                	jmp    8006f8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8006f3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8006f8:	c9                   	leave  
  8006f9:	c3                   	ret    

008006fa <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8006fa:	55                   	push   %ebp
  8006fb:	89 e5                	mov    %esp,%ebp
  8006fd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800700:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800703:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800707:	8b 45 10             	mov    0x10(%ebp),%eax
  80070a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80070e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800711:	89 44 24 04          	mov    %eax,0x4(%esp)
  800715:	8b 45 08             	mov    0x8(%ebp),%eax
  800718:	89 04 24             	mov    %eax,(%esp)
  80071b:	e8 82 ff ff ff       	call   8006a2 <vsnprintf>
	va_end(ap);

	return rc;
}
  800720:	c9                   	leave  
  800721:	c3                   	ret    
  800722:	66 90                	xchg   %ax,%ax
  800724:	66 90                	xchg   %ax,%ax
  800726:	66 90                	xchg   %ax,%ax
  800728:	66 90                	xchg   %ax,%ax
  80072a:	66 90                	xchg   %ax,%ax
  80072c:	66 90                	xchg   %ax,%ax
  80072e:	66 90                	xchg   %ax,%ax

00800730 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800730:	55                   	push   %ebp
  800731:	89 e5                	mov    %esp,%ebp
  800733:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800736:	b8 00 00 00 00       	mov    $0x0,%eax
  80073b:	eb 03                	jmp    800740 <strlen+0x10>
		n++;
  80073d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800740:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800744:	75 f7                	jne    80073d <strlen+0xd>
		n++;
	return n;
}
  800746:	5d                   	pop    %ebp
  800747:	c3                   	ret    

00800748 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800748:	55                   	push   %ebp
  800749:	89 e5                	mov    %esp,%ebp
  80074b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80074e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800751:	b8 00 00 00 00       	mov    $0x0,%eax
  800756:	eb 03                	jmp    80075b <strnlen+0x13>
		n++;
  800758:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80075b:	39 d0                	cmp    %edx,%eax
  80075d:	74 06                	je     800765 <strnlen+0x1d>
  80075f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800763:	75 f3                	jne    800758 <strnlen+0x10>
		n++;
	return n;
}
  800765:	5d                   	pop    %ebp
  800766:	c3                   	ret    

00800767 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800767:	55                   	push   %ebp
  800768:	89 e5                	mov    %esp,%ebp
  80076a:	53                   	push   %ebx
  80076b:	8b 45 08             	mov    0x8(%ebp),%eax
  80076e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800771:	89 c2                	mov    %eax,%edx
  800773:	83 c2 01             	add    $0x1,%edx
  800776:	83 c1 01             	add    $0x1,%ecx
  800779:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80077d:	88 5a ff             	mov    %bl,-0x1(%edx)
  800780:	84 db                	test   %bl,%bl
  800782:	75 ef                	jne    800773 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800784:	5b                   	pop    %ebx
  800785:	5d                   	pop    %ebp
  800786:	c3                   	ret    

00800787 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800787:	55                   	push   %ebp
  800788:	89 e5                	mov    %esp,%ebp
  80078a:	53                   	push   %ebx
  80078b:	83 ec 08             	sub    $0x8,%esp
  80078e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800791:	89 1c 24             	mov    %ebx,(%esp)
  800794:	e8 97 ff ff ff       	call   800730 <strlen>
	strcpy(dst + len, src);
  800799:	8b 55 0c             	mov    0xc(%ebp),%edx
  80079c:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007a0:	01 d8                	add    %ebx,%eax
  8007a2:	89 04 24             	mov    %eax,(%esp)
  8007a5:	e8 bd ff ff ff       	call   800767 <strcpy>
	return dst;
}
  8007aa:	89 d8                	mov    %ebx,%eax
  8007ac:	83 c4 08             	add    $0x8,%esp
  8007af:	5b                   	pop    %ebx
  8007b0:	5d                   	pop    %ebp
  8007b1:	c3                   	ret    

008007b2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007b2:	55                   	push   %ebp
  8007b3:	89 e5                	mov    %esp,%ebp
  8007b5:	56                   	push   %esi
  8007b6:	53                   	push   %ebx
  8007b7:	8b 75 08             	mov    0x8(%ebp),%esi
  8007ba:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007bd:	89 f3                	mov    %esi,%ebx
  8007bf:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007c2:	89 f2                	mov    %esi,%edx
  8007c4:	eb 0f                	jmp    8007d5 <strncpy+0x23>
		*dst++ = *src;
  8007c6:	83 c2 01             	add    $0x1,%edx
  8007c9:	0f b6 01             	movzbl (%ecx),%eax
  8007cc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007cf:	80 39 01             	cmpb   $0x1,(%ecx)
  8007d2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007d5:	39 da                	cmp    %ebx,%edx
  8007d7:	75 ed                	jne    8007c6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007d9:	89 f0                	mov    %esi,%eax
  8007db:	5b                   	pop    %ebx
  8007dc:	5e                   	pop    %esi
  8007dd:	5d                   	pop    %ebp
  8007de:	c3                   	ret    

008007df <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007df:	55                   	push   %ebp
  8007e0:	89 e5                	mov    %esp,%ebp
  8007e2:	56                   	push   %esi
  8007e3:	53                   	push   %ebx
  8007e4:	8b 75 08             	mov    0x8(%ebp),%esi
  8007e7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007ea:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8007ed:	89 f0                	mov    %esi,%eax
  8007ef:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007f3:	85 c9                	test   %ecx,%ecx
  8007f5:	75 0b                	jne    800802 <strlcpy+0x23>
  8007f7:	eb 1d                	jmp    800816 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007f9:	83 c0 01             	add    $0x1,%eax
  8007fc:	83 c2 01             	add    $0x1,%edx
  8007ff:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800802:	39 d8                	cmp    %ebx,%eax
  800804:	74 0b                	je     800811 <strlcpy+0x32>
  800806:	0f b6 0a             	movzbl (%edx),%ecx
  800809:	84 c9                	test   %cl,%cl
  80080b:	75 ec                	jne    8007f9 <strlcpy+0x1a>
  80080d:	89 c2                	mov    %eax,%edx
  80080f:	eb 02                	jmp    800813 <strlcpy+0x34>
  800811:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800813:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800816:	29 f0                	sub    %esi,%eax
}
  800818:	5b                   	pop    %ebx
  800819:	5e                   	pop    %esi
  80081a:	5d                   	pop    %ebp
  80081b:	c3                   	ret    

0080081c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80081c:	55                   	push   %ebp
  80081d:	89 e5                	mov    %esp,%ebp
  80081f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800822:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800825:	eb 06                	jmp    80082d <strcmp+0x11>
		p++, q++;
  800827:	83 c1 01             	add    $0x1,%ecx
  80082a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80082d:	0f b6 01             	movzbl (%ecx),%eax
  800830:	84 c0                	test   %al,%al
  800832:	74 04                	je     800838 <strcmp+0x1c>
  800834:	3a 02                	cmp    (%edx),%al
  800836:	74 ef                	je     800827 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800838:	0f b6 c0             	movzbl %al,%eax
  80083b:	0f b6 12             	movzbl (%edx),%edx
  80083e:	29 d0                	sub    %edx,%eax
}
  800840:	5d                   	pop    %ebp
  800841:	c3                   	ret    

00800842 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800842:	55                   	push   %ebp
  800843:	89 e5                	mov    %esp,%ebp
  800845:	53                   	push   %ebx
  800846:	8b 45 08             	mov    0x8(%ebp),%eax
  800849:	8b 55 0c             	mov    0xc(%ebp),%edx
  80084c:	89 c3                	mov    %eax,%ebx
  80084e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800851:	eb 06                	jmp    800859 <strncmp+0x17>
		n--, p++, q++;
  800853:	83 c0 01             	add    $0x1,%eax
  800856:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800859:	39 d8                	cmp    %ebx,%eax
  80085b:	74 15                	je     800872 <strncmp+0x30>
  80085d:	0f b6 08             	movzbl (%eax),%ecx
  800860:	84 c9                	test   %cl,%cl
  800862:	74 04                	je     800868 <strncmp+0x26>
  800864:	3a 0a                	cmp    (%edx),%cl
  800866:	74 eb                	je     800853 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800868:	0f b6 00             	movzbl (%eax),%eax
  80086b:	0f b6 12             	movzbl (%edx),%edx
  80086e:	29 d0                	sub    %edx,%eax
  800870:	eb 05                	jmp    800877 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800872:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800877:	5b                   	pop    %ebx
  800878:	5d                   	pop    %ebp
  800879:	c3                   	ret    

0080087a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80087a:	55                   	push   %ebp
  80087b:	89 e5                	mov    %esp,%ebp
  80087d:	8b 45 08             	mov    0x8(%ebp),%eax
  800880:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800884:	eb 07                	jmp    80088d <strchr+0x13>
		if (*s == c)
  800886:	38 ca                	cmp    %cl,%dl
  800888:	74 0f                	je     800899 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80088a:	83 c0 01             	add    $0x1,%eax
  80088d:	0f b6 10             	movzbl (%eax),%edx
  800890:	84 d2                	test   %dl,%dl
  800892:	75 f2                	jne    800886 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800894:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800899:	5d                   	pop    %ebp
  80089a:	c3                   	ret    

0080089b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80089b:	55                   	push   %ebp
  80089c:	89 e5                	mov    %esp,%ebp
  80089e:	8b 45 08             	mov    0x8(%ebp),%eax
  8008a1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008a5:	eb 07                	jmp    8008ae <strfind+0x13>
		if (*s == c)
  8008a7:	38 ca                	cmp    %cl,%dl
  8008a9:	74 0a                	je     8008b5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  8008ab:	83 c0 01             	add    $0x1,%eax
  8008ae:	0f b6 10             	movzbl (%eax),%edx
  8008b1:	84 d2                	test   %dl,%dl
  8008b3:	75 f2                	jne    8008a7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  8008b5:	5d                   	pop    %ebp
  8008b6:	c3                   	ret    

008008b7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008b7:	55                   	push   %ebp
  8008b8:	89 e5                	mov    %esp,%ebp
  8008ba:	57                   	push   %edi
  8008bb:	56                   	push   %esi
  8008bc:	53                   	push   %ebx
  8008bd:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008c0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008c3:	85 c9                	test   %ecx,%ecx
  8008c5:	74 36                	je     8008fd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008c7:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008cd:	75 28                	jne    8008f7 <memset+0x40>
  8008cf:	f6 c1 03             	test   $0x3,%cl
  8008d2:	75 23                	jne    8008f7 <memset+0x40>
		c &= 0xFF;
  8008d4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008d8:	89 d3                	mov    %edx,%ebx
  8008da:	c1 e3 08             	shl    $0x8,%ebx
  8008dd:	89 d6                	mov    %edx,%esi
  8008df:	c1 e6 18             	shl    $0x18,%esi
  8008e2:	89 d0                	mov    %edx,%eax
  8008e4:	c1 e0 10             	shl    $0x10,%eax
  8008e7:	09 f0                	or     %esi,%eax
  8008e9:	09 c2                	or     %eax,%edx
  8008eb:	89 d0                	mov    %edx,%eax
  8008ed:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  8008ef:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  8008f2:	fc                   	cld    
  8008f3:	f3 ab                	rep stos %eax,%es:(%edi)
  8008f5:	eb 06                	jmp    8008fd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008f7:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008fa:	fc                   	cld    
  8008fb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8008fd:	89 f8                	mov    %edi,%eax
  8008ff:	5b                   	pop    %ebx
  800900:	5e                   	pop    %esi
  800901:	5f                   	pop    %edi
  800902:	5d                   	pop    %ebp
  800903:	c3                   	ret    

00800904 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800904:	55                   	push   %ebp
  800905:	89 e5                	mov    %esp,%ebp
  800907:	57                   	push   %edi
  800908:	56                   	push   %esi
  800909:	8b 45 08             	mov    0x8(%ebp),%eax
  80090c:	8b 75 0c             	mov    0xc(%ebp),%esi
  80090f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800912:	39 c6                	cmp    %eax,%esi
  800914:	73 35                	jae    80094b <memmove+0x47>
  800916:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800919:	39 d0                	cmp    %edx,%eax
  80091b:	73 2e                	jae    80094b <memmove+0x47>
		s += n;
		d += n;
  80091d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800920:	89 d6                	mov    %edx,%esi
  800922:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800924:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80092a:	75 13                	jne    80093f <memmove+0x3b>
  80092c:	f6 c1 03             	test   $0x3,%cl
  80092f:	75 0e                	jne    80093f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800931:	83 ef 04             	sub    $0x4,%edi
  800934:	8d 72 fc             	lea    -0x4(%edx),%esi
  800937:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  80093a:	fd                   	std    
  80093b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80093d:	eb 09                	jmp    800948 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  80093f:	83 ef 01             	sub    $0x1,%edi
  800942:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800945:	fd                   	std    
  800946:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800948:	fc                   	cld    
  800949:	eb 1d                	jmp    800968 <memmove+0x64>
  80094b:	89 f2                	mov    %esi,%edx
  80094d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80094f:	f6 c2 03             	test   $0x3,%dl
  800952:	75 0f                	jne    800963 <memmove+0x5f>
  800954:	f6 c1 03             	test   $0x3,%cl
  800957:	75 0a                	jne    800963 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800959:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  80095c:	89 c7                	mov    %eax,%edi
  80095e:	fc                   	cld    
  80095f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800961:	eb 05                	jmp    800968 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800963:	89 c7                	mov    %eax,%edi
  800965:	fc                   	cld    
  800966:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800968:	5e                   	pop    %esi
  800969:	5f                   	pop    %edi
  80096a:	5d                   	pop    %ebp
  80096b:	c3                   	ret    

0080096c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80096c:	55                   	push   %ebp
  80096d:	89 e5                	mov    %esp,%ebp
  80096f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800972:	8b 45 10             	mov    0x10(%ebp),%eax
  800975:	89 44 24 08          	mov    %eax,0x8(%esp)
  800979:	8b 45 0c             	mov    0xc(%ebp),%eax
  80097c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800980:	8b 45 08             	mov    0x8(%ebp),%eax
  800983:	89 04 24             	mov    %eax,(%esp)
  800986:	e8 79 ff ff ff       	call   800904 <memmove>
}
  80098b:	c9                   	leave  
  80098c:	c3                   	ret    

0080098d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80098d:	55                   	push   %ebp
  80098e:	89 e5                	mov    %esp,%ebp
  800990:	56                   	push   %esi
  800991:	53                   	push   %ebx
  800992:	8b 55 08             	mov    0x8(%ebp),%edx
  800995:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800998:	89 d6                	mov    %edx,%esi
  80099a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80099d:	eb 1a                	jmp    8009b9 <memcmp+0x2c>
		if (*s1 != *s2)
  80099f:	0f b6 02             	movzbl (%edx),%eax
  8009a2:	0f b6 19             	movzbl (%ecx),%ebx
  8009a5:	38 d8                	cmp    %bl,%al
  8009a7:	74 0a                	je     8009b3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009a9:	0f b6 c0             	movzbl %al,%eax
  8009ac:	0f b6 db             	movzbl %bl,%ebx
  8009af:	29 d8                	sub    %ebx,%eax
  8009b1:	eb 0f                	jmp    8009c2 <memcmp+0x35>
		s1++, s2++;
  8009b3:	83 c2 01             	add    $0x1,%edx
  8009b6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009b9:	39 f2                	cmp    %esi,%edx
  8009bb:	75 e2                	jne    80099f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009bd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009c2:	5b                   	pop    %ebx
  8009c3:	5e                   	pop    %esi
  8009c4:	5d                   	pop    %ebp
  8009c5:	c3                   	ret    

008009c6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009c6:	55                   	push   %ebp
  8009c7:	89 e5                	mov    %esp,%ebp
  8009c9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009cc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8009cf:	89 c2                	mov    %eax,%edx
  8009d1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  8009d4:	eb 07                	jmp    8009dd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009d6:	38 08                	cmp    %cl,(%eax)
  8009d8:	74 07                	je     8009e1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009da:	83 c0 01             	add    $0x1,%eax
  8009dd:	39 d0                	cmp    %edx,%eax
  8009df:	72 f5                	jb     8009d6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009e1:	5d                   	pop    %ebp
  8009e2:	c3                   	ret    

008009e3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009e3:	55                   	push   %ebp
  8009e4:	89 e5                	mov    %esp,%ebp
  8009e6:	57                   	push   %edi
  8009e7:	56                   	push   %esi
  8009e8:	53                   	push   %ebx
  8009e9:	8b 55 08             	mov    0x8(%ebp),%edx
  8009ec:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009ef:	eb 03                	jmp    8009f4 <strtol+0x11>
		s++;
  8009f1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009f4:	0f b6 0a             	movzbl (%edx),%ecx
  8009f7:	80 f9 09             	cmp    $0x9,%cl
  8009fa:	74 f5                	je     8009f1 <strtol+0xe>
  8009fc:	80 f9 20             	cmp    $0x20,%cl
  8009ff:	74 f0                	je     8009f1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a01:	80 f9 2b             	cmp    $0x2b,%cl
  800a04:	75 0a                	jne    800a10 <strtol+0x2d>
		s++;
  800a06:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a09:	bf 00 00 00 00       	mov    $0x0,%edi
  800a0e:	eb 11                	jmp    800a21 <strtol+0x3e>
  800a10:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a15:	80 f9 2d             	cmp    $0x2d,%cl
  800a18:	75 07                	jne    800a21 <strtol+0x3e>
		s++, neg = 1;
  800a1a:	8d 52 01             	lea    0x1(%edx),%edx
  800a1d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a21:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800a26:	75 15                	jne    800a3d <strtol+0x5a>
  800a28:	80 3a 30             	cmpb   $0x30,(%edx)
  800a2b:	75 10                	jne    800a3d <strtol+0x5a>
  800a2d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800a31:	75 0a                	jne    800a3d <strtol+0x5a>
		s += 2, base = 16;
  800a33:	83 c2 02             	add    $0x2,%edx
  800a36:	b8 10 00 00 00       	mov    $0x10,%eax
  800a3b:	eb 10                	jmp    800a4d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800a3d:	85 c0                	test   %eax,%eax
  800a3f:	75 0c                	jne    800a4d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a41:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a43:	80 3a 30             	cmpb   $0x30,(%edx)
  800a46:	75 05                	jne    800a4d <strtol+0x6a>
		s++, base = 8;
  800a48:	83 c2 01             	add    $0x1,%edx
  800a4b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800a4d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800a52:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a55:	0f b6 0a             	movzbl (%edx),%ecx
  800a58:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800a5b:	89 f0                	mov    %esi,%eax
  800a5d:	3c 09                	cmp    $0x9,%al
  800a5f:	77 08                	ja     800a69 <strtol+0x86>
			dig = *s - '0';
  800a61:	0f be c9             	movsbl %cl,%ecx
  800a64:	83 e9 30             	sub    $0x30,%ecx
  800a67:	eb 20                	jmp    800a89 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800a69:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800a6c:	89 f0                	mov    %esi,%eax
  800a6e:	3c 19                	cmp    $0x19,%al
  800a70:	77 08                	ja     800a7a <strtol+0x97>
			dig = *s - 'a' + 10;
  800a72:	0f be c9             	movsbl %cl,%ecx
  800a75:	83 e9 57             	sub    $0x57,%ecx
  800a78:	eb 0f                	jmp    800a89 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800a7a:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800a7d:	89 f0                	mov    %esi,%eax
  800a7f:	3c 19                	cmp    $0x19,%al
  800a81:	77 16                	ja     800a99 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800a83:	0f be c9             	movsbl %cl,%ecx
  800a86:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800a89:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800a8c:	7d 0f                	jge    800a9d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800a8e:	83 c2 01             	add    $0x1,%edx
  800a91:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800a95:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800a97:	eb bc                	jmp    800a55 <strtol+0x72>
  800a99:	89 d8                	mov    %ebx,%eax
  800a9b:	eb 02                	jmp    800a9f <strtol+0xbc>
  800a9d:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800a9f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800aa3:	74 05                	je     800aaa <strtol+0xc7>
		*endptr = (char *) s;
  800aa5:	8b 75 0c             	mov    0xc(%ebp),%esi
  800aa8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800aaa:	f7 d8                	neg    %eax
  800aac:	85 ff                	test   %edi,%edi
  800aae:	0f 44 c3             	cmove  %ebx,%eax
}
  800ab1:	5b                   	pop    %ebx
  800ab2:	5e                   	pop    %esi
  800ab3:	5f                   	pop    %edi
  800ab4:	5d                   	pop    %ebp
  800ab5:	c3                   	ret    

00800ab6 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800ab6:	55                   	push   %ebp
  800ab7:	89 e5                	mov    %esp,%ebp
  800ab9:	57                   	push   %edi
  800aba:	56                   	push   %esi
  800abb:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800abc:	b8 00 00 00 00       	mov    $0x0,%eax
  800ac1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ac4:	8b 55 08             	mov    0x8(%ebp),%edx
  800ac7:	89 c3                	mov    %eax,%ebx
  800ac9:	89 c7                	mov    %eax,%edi
  800acb:	89 c6                	mov    %eax,%esi
  800acd:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800acf:	5b                   	pop    %ebx
  800ad0:	5e                   	pop    %esi
  800ad1:	5f                   	pop    %edi
  800ad2:	5d                   	pop    %ebp
  800ad3:	c3                   	ret    

00800ad4 <sys_cgetc>:

int
sys_cgetc(void)
{
  800ad4:	55                   	push   %ebp
  800ad5:	89 e5                	mov    %esp,%ebp
  800ad7:	57                   	push   %edi
  800ad8:	56                   	push   %esi
  800ad9:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ada:	ba 00 00 00 00       	mov    $0x0,%edx
  800adf:	b8 01 00 00 00       	mov    $0x1,%eax
  800ae4:	89 d1                	mov    %edx,%ecx
  800ae6:	89 d3                	mov    %edx,%ebx
  800ae8:	89 d7                	mov    %edx,%edi
  800aea:	89 d6                	mov    %edx,%esi
  800aec:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800aee:	5b                   	pop    %ebx
  800aef:	5e                   	pop    %esi
  800af0:	5f                   	pop    %edi
  800af1:	5d                   	pop    %ebp
  800af2:	c3                   	ret    

00800af3 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800af3:	55                   	push   %ebp
  800af4:	89 e5                	mov    %esp,%ebp
  800af6:	57                   	push   %edi
  800af7:	56                   	push   %esi
  800af8:	53                   	push   %ebx
  800af9:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800afc:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b01:	b8 03 00 00 00       	mov    $0x3,%eax
  800b06:	8b 55 08             	mov    0x8(%ebp),%edx
  800b09:	89 cb                	mov    %ecx,%ebx
  800b0b:	89 cf                	mov    %ecx,%edi
  800b0d:	89 ce                	mov    %ecx,%esi
  800b0f:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800b11:	85 c0                	test   %eax,%eax
  800b13:	7e 28                	jle    800b3d <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b15:	89 44 24 10          	mov    %eax,0x10(%esp)
  800b19:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800b20:	00 
  800b21:	c7 44 24 08 74 10 80 	movl   $0x801074,0x8(%esp)
  800b28:	00 
  800b29:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800b30:	00 
  800b31:	c7 04 24 91 10 80 00 	movl   $0x801091,(%esp)
  800b38:	e8 27 00 00 00       	call   800b64 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b3d:	83 c4 2c             	add    $0x2c,%esp
  800b40:	5b                   	pop    %ebx
  800b41:	5e                   	pop    %esi
  800b42:	5f                   	pop    %edi
  800b43:	5d                   	pop    %ebp
  800b44:	c3                   	ret    

00800b45 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b45:	55                   	push   %ebp
  800b46:	89 e5                	mov    %esp,%ebp
  800b48:	57                   	push   %edi
  800b49:	56                   	push   %esi
  800b4a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b4b:	ba 00 00 00 00       	mov    $0x0,%edx
  800b50:	b8 02 00 00 00       	mov    $0x2,%eax
  800b55:	89 d1                	mov    %edx,%ecx
  800b57:	89 d3                	mov    %edx,%ebx
  800b59:	89 d7                	mov    %edx,%edi
  800b5b:	89 d6                	mov    %edx,%esi
  800b5d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b5f:	5b                   	pop    %ebx
  800b60:	5e                   	pop    %esi
  800b61:	5f                   	pop    %edi
  800b62:	5d                   	pop    %ebp
  800b63:	c3                   	ret    

00800b64 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800b64:	55                   	push   %ebp
  800b65:	89 e5                	mov    %esp,%ebp
  800b67:	56                   	push   %esi
  800b68:	53                   	push   %ebx
  800b69:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800b6c:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800b6f:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800b75:	e8 cb ff ff ff       	call   800b45 <sys_getenvid>
  800b7a:	8b 55 0c             	mov    0xc(%ebp),%edx
  800b7d:	89 54 24 10          	mov    %edx,0x10(%esp)
  800b81:	8b 55 08             	mov    0x8(%ebp),%edx
  800b84:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800b88:	89 74 24 08          	mov    %esi,0x8(%esp)
  800b8c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b90:	c7 04 24 a0 10 80 00 	movl   $0x8010a0,(%esp)
  800b97:	e8 a0 f5 ff ff       	call   80013c <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800b9c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800ba0:	8b 45 10             	mov    0x10(%ebp),%eax
  800ba3:	89 04 24             	mov    %eax,(%esp)
  800ba6:	e8 30 f5 ff ff       	call   8000db <vcprintf>
	cprintf("\n");
  800bab:	c7 04 24 64 0e 80 00 	movl   $0x800e64,(%esp)
  800bb2:	e8 85 f5 ff ff       	call   80013c <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800bb7:	cc                   	int3   
  800bb8:	eb fd                	jmp    800bb7 <_panic+0x53>
  800bba:	66 90                	xchg   %ax,%ax
  800bbc:	66 90                	xchg   %ax,%ax
  800bbe:	66 90                	xchg   %ax,%ax

00800bc0 <__udivdi3>:
  800bc0:	55                   	push   %ebp
  800bc1:	57                   	push   %edi
  800bc2:	56                   	push   %esi
  800bc3:	83 ec 0c             	sub    $0xc,%esp
  800bc6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800bca:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800bce:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800bd2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800bd6:	85 c0                	test   %eax,%eax
  800bd8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800bdc:	89 ea                	mov    %ebp,%edx
  800bde:	89 0c 24             	mov    %ecx,(%esp)
  800be1:	75 2d                	jne    800c10 <__udivdi3+0x50>
  800be3:	39 e9                	cmp    %ebp,%ecx
  800be5:	77 61                	ja     800c48 <__udivdi3+0x88>
  800be7:	85 c9                	test   %ecx,%ecx
  800be9:	89 ce                	mov    %ecx,%esi
  800beb:	75 0b                	jne    800bf8 <__udivdi3+0x38>
  800bed:	b8 01 00 00 00       	mov    $0x1,%eax
  800bf2:	31 d2                	xor    %edx,%edx
  800bf4:	f7 f1                	div    %ecx
  800bf6:	89 c6                	mov    %eax,%esi
  800bf8:	31 d2                	xor    %edx,%edx
  800bfa:	89 e8                	mov    %ebp,%eax
  800bfc:	f7 f6                	div    %esi
  800bfe:	89 c5                	mov    %eax,%ebp
  800c00:	89 f8                	mov    %edi,%eax
  800c02:	f7 f6                	div    %esi
  800c04:	89 ea                	mov    %ebp,%edx
  800c06:	83 c4 0c             	add    $0xc,%esp
  800c09:	5e                   	pop    %esi
  800c0a:	5f                   	pop    %edi
  800c0b:	5d                   	pop    %ebp
  800c0c:	c3                   	ret    
  800c0d:	8d 76 00             	lea    0x0(%esi),%esi
  800c10:	39 e8                	cmp    %ebp,%eax
  800c12:	77 24                	ja     800c38 <__udivdi3+0x78>
  800c14:	0f bd e8             	bsr    %eax,%ebp
  800c17:	83 f5 1f             	xor    $0x1f,%ebp
  800c1a:	75 3c                	jne    800c58 <__udivdi3+0x98>
  800c1c:	8b 74 24 04          	mov    0x4(%esp),%esi
  800c20:	39 34 24             	cmp    %esi,(%esp)
  800c23:	0f 86 9f 00 00 00    	jbe    800cc8 <__udivdi3+0x108>
  800c29:	39 d0                	cmp    %edx,%eax
  800c2b:	0f 82 97 00 00 00    	jb     800cc8 <__udivdi3+0x108>
  800c31:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c38:	31 d2                	xor    %edx,%edx
  800c3a:	31 c0                	xor    %eax,%eax
  800c3c:	83 c4 0c             	add    $0xc,%esp
  800c3f:	5e                   	pop    %esi
  800c40:	5f                   	pop    %edi
  800c41:	5d                   	pop    %ebp
  800c42:	c3                   	ret    
  800c43:	90                   	nop
  800c44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c48:	89 f8                	mov    %edi,%eax
  800c4a:	f7 f1                	div    %ecx
  800c4c:	31 d2                	xor    %edx,%edx
  800c4e:	83 c4 0c             	add    $0xc,%esp
  800c51:	5e                   	pop    %esi
  800c52:	5f                   	pop    %edi
  800c53:	5d                   	pop    %ebp
  800c54:	c3                   	ret    
  800c55:	8d 76 00             	lea    0x0(%esi),%esi
  800c58:	89 e9                	mov    %ebp,%ecx
  800c5a:	8b 3c 24             	mov    (%esp),%edi
  800c5d:	d3 e0                	shl    %cl,%eax
  800c5f:	89 c6                	mov    %eax,%esi
  800c61:	b8 20 00 00 00       	mov    $0x20,%eax
  800c66:	29 e8                	sub    %ebp,%eax
  800c68:	89 c1                	mov    %eax,%ecx
  800c6a:	d3 ef                	shr    %cl,%edi
  800c6c:	89 e9                	mov    %ebp,%ecx
  800c6e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800c72:	8b 3c 24             	mov    (%esp),%edi
  800c75:	09 74 24 08          	or     %esi,0x8(%esp)
  800c79:	89 d6                	mov    %edx,%esi
  800c7b:	d3 e7                	shl    %cl,%edi
  800c7d:	89 c1                	mov    %eax,%ecx
  800c7f:	89 3c 24             	mov    %edi,(%esp)
  800c82:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800c86:	d3 ee                	shr    %cl,%esi
  800c88:	89 e9                	mov    %ebp,%ecx
  800c8a:	d3 e2                	shl    %cl,%edx
  800c8c:	89 c1                	mov    %eax,%ecx
  800c8e:	d3 ef                	shr    %cl,%edi
  800c90:	09 d7                	or     %edx,%edi
  800c92:	89 f2                	mov    %esi,%edx
  800c94:	89 f8                	mov    %edi,%eax
  800c96:	f7 74 24 08          	divl   0x8(%esp)
  800c9a:	89 d6                	mov    %edx,%esi
  800c9c:	89 c7                	mov    %eax,%edi
  800c9e:	f7 24 24             	mull   (%esp)
  800ca1:	39 d6                	cmp    %edx,%esi
  800ca3:	89 14 24             	mov    %edx,(%esp)
  800ca6:	72 30                	jb     800cd8 <__udivdi3+0x118>
  800ca8:	8b 54 24 04          	mov    0x4(%esp),%edx
  800cac:	89 e9                	mov    %ebp,%ecx
  800cae:	d3 e2                	shl    %cl,%edx
  800cb0:	39 c2                	cmp    %eax,%edx
  800cb2:	73 05                	jae    800cb9 <__udivdi3+0xf9>
  800cb4:	3b 34 24             	cmp    (%esp),%esi
  800cb7:	74 1f                	je     800cd8 <__udivdi3+0x118>
  800cb9:	89 f8                	mov    %edi,%eax
  800cbb:	31 d2                	xor    %edx,%edx
  800cbd:	e9 7a ff ff ff       	jmp    800c3c <__udivdi3+0x7c>
  800cc2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800cc8:	31 d2                	xor    %edx,%edx
  800cca:	b8 01 00 00 00       	mov    $0x1,%eax
  800ccf:	e9 68 ff ff ff       	jmp    800c3c <__udivdi3+0x7c>
  800cd4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800cd8:	8d 47 ff             	lea    -0x1(%edi),%eax
  800cdb:	31 d2                	xor    %edx,%edx
  800cdd:	83 c4 0c             	add    $0xc,%esp
  800ce0:	5e                   	pop    %esi
  800ce1:	5f                   	pop    %edi
  800ce2:	5d                   	pop    %ebp
  800ce3:	c3                   	ret    
  800ce4:	66 90                	xchg   %ax,%ax
  800ce6:	66 90                	xchg   %ax,%ax
  800ce8:	66 90                	xchg   %ax,%ax
  800cea:	66 90                	xchg   %ax,%ax
  800cec:	66 90                	xchg   %ax,%ax
  800cee:	66 90                	xchg   %ax,%ax

00800cf0 <__umoddi3>:
  800cf0:	55                   	push   %ebp
  800cf1:	57                   	push   %edi
  800cf2:	56                   	push   %esi
  800cf3:	83 ec 14             	sub    $0x14,%esp
  800cf6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800cfa:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800cfe:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800d02:	89 c7                	mov    %eax,%edi
  800d04:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d08:	8b 44 24 30          	mov    0x30(%esp),%eax
  800d0c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800d10:	89 34 24             	mov    %esi,(%esp)
  800d13:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d17:	85 c0                	test   %eax,%eax
  800d19:	89 c2                	mov    %eax,%edx
  800d1b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800d1f:	75 17                	jne    800d38 <__umoddi3+0x48>
  800d21:	39 fe                	cmp    %edi,%esi
  800d23:	76 4b                	jbe    800d70 <__umoddi3+0x80>
  800d25:	89 c8                	mov    %ecx,%eax
  800d27:	89 fa                	mov    %edi,%edx
  800d29:	f7 f6                	div    %esi
  800d2b:	89 d0                	mov    %edx,%eax
  800d2d:	31 d2                	xor    %edx,%edx
  800d2f:	83 c4 14             	add    $0x14,%esp
  800d32:	5e                   	pop    %esi
  800d33:	5f                   	pop    %edi
  800d34:	5d                   	pop    %ebp
  800d35:	c3                   	ret    
  800d36:	66 90                	xchg   %ax,%ax
  800d38:	39 f8                	cmp    %edi,%eax
  800d3a:	77 54                	ja     800d90 <__umoddi3+0xa0>
  800d3c:	0f bd e8             	bsr    %eax,%ebp
  800d3f:	83 f5 1f             	xor    $0x1f,%ebp
  800d42:	75 5c                	jne    800da0 <__umoddi3+0xb0>
  800d44:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800d48:	39 3c 24             	cmp    %edi,(%esp)
  800d4b:	0f 87 e7 00 00 00    	ja     800e38 <__umoddi3+0x148>
  800d51:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800d55:	29 f1                	sub    %esi,%ecx
  800d57:	19 c7                	sbb    %eax,%edi
  800d59:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d5d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800d61:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d65:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d69:	83 c4 14             	add    $0x14,%esp
  800d6c:	5e                   	pop    %esi
  800d6d:	5f                   	pop    %edi
  800d6e:	5d                   	pop    %ebp
  800d6f:	c3                   	ret    
  800d70:	85 f6                	test   %esi,%esi
  800d72:	89 f5                	mov    %esi,%ebp
  800d74:	75 0b                	jne    800d81 <__umoddi3+0x91>
  800d76:	b8 01 00 00 00       	mov    $0x1,%eax
  800d7b:	31 d2                	xor    %edx,%edx
  800d7d:	f7 f6                	div    %esi
  800d7f:	89 c5                	mov    %eax,%ebp
  800d81:	8b 44 24 04          	mov    0x4(%esp),%eax
  800d85:	31 d2                	xor    %edx,%edx
  800d87:	f7 f5                	div    %ebp
  800d89:	89 c8                	mov    %ecx,%eax
  800d8b:	f7 f5                	div    %ebp
  800d8d:	eb 9c                	jmp    800d2b <__umoddi3+0x3b>
  800d8f:	90                   	nop
  800d90:	89 c8                	mov    %ecx,%eax
  800d92:	89 fa                	mov    %edi,%edx
  800d94:	83 c4 14             	add    $0x14,%esp
  800d97:	5e                   	pop    %esi
  800d98:	5f                   	pop    %edi
  800d99:	5d                   	pop    %ebp
  800d9a:	c3                   	ret    
  800d9b:	90                   	nop
  800d9c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800da0:	8b 04 24             	mov    (%esp),%eax
  800da3:	be 20 00 00 00       	mov    $0x20,%esi
  800da8:	89 e9                	mov    %ebp,%ecx
  800daa:	29 ee                	sub    %ebp,%esi
  800dac:	d3 e2                	shl    %cl,%edx
  800dae:	89 f1                	mov    %esi,%ecx
  800db0:	d3 e8                	shr    %cl,%eax
  800db2:	89 e9                	mov    %ebp,%ecx
  800db4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800db8:	8b 04 24             	mov    (%esp),%eax
  800dbb:	09 54 24 04          	or     %edx,0x4(%esp)
  800dbf:	89 fa                	mov    %edi,%edx
  800dc1:	d3 e0                	shl    %cl,%eax
  800dc3:	89 f1                	mov    %esi,%ecx
  800dc5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800dc9:	8b 44 24 10          	mov    0x10(%esp),%eax
  800dcd:	d3 ea                	shr    %cl,%edx
  800dcf:	89 e9                	mov    %ebp,%ecx
  800dd1:	d3 e7                	shl    %cl,%edi
  800dd3:	89 f1                	mov    %esi,%ecx
  800dd5:	d3 e8                	shr    %cl,%eax
  800dd7:	89 e9                	mov    %ebp,%ecx
  800dd9:	09 f8                	or     %edi,%eax
  800ddb:	8b 7c 24 10          	mov    0x10(%esp),%edi
  800ddf:	f7 74 24 04          	divl   0x4(%esp)
  800de3:	d3 e7                	shl    %cl,%edi
  800de5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800de9:	89 d7                	mov    %edx,%edi
  800deb:	f7 64 24 08          	mull   0x8(%esp)
  800def:	39 d7                	cmp    %edx,%edi
  800df1:	89 c1                	mov    %eax,%ecx
  800df3:	89 14 24             	mov    %edx,(%esp)
  800df6:	72 2c                	jb     800e24 <__umoddi3+0x134>
  800df8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  800dfc:	72 22                	jb     800e20 <__umoddi3+0x130>
  800dfe:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800e02:	29 c8                	sub    %ecx,%eax
  800e04:	19 d7                	sbb    %edx,%edi
  800e06:	89 e9                	mov    %ebp,%ecx
  800e08:	89 fa                	mov    %edi,%edx
  800e0a:	d3 e8                	shr    %cl,%eax
  800e0c:	89 f1                	mov    %esi,%ecx
  800e0e:	d3 e2                	shl    %cl,%edx
  800e10:	89 e9                	mov    %ebp,%ecx
  800e12:	d3 ef                	shr    %cl,%edi
  800e14:	09 d0                	or     %edx,%eax
  800e16:	89 fa                	mov    %edi,%edx
  800e18:	83 c4 14             	add    $0x14,%esp
  800e1b:	5e                   	pop    %esi
  800e1c:	5f                   	pop    %edi
  800e1d:	5d                   	pop    %ebp
  800e1e:	c3                   	ret    
  800e1f:	90                   	nop
  800e20:	39 d7                	cmp    %edx,%edi
  800e22:	75 da                	jne    800dfe <__umoddi3+0x10e>
  800e24:	8b 14 24             	mov    (%esp),%edx
  800e27:	89 c1                	mov    %eax,%ecx
  800e29:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  800e2d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  800e31:	eb cb                	jmp    800dfe <__umoddi3+0x10e>
  800e33:	90                   	nop
  800e34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e38:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  800e3c:	0f 82 0f ff ff ff    	jb     800d51 <__umoddi3+0x61>
  800e42:	e9 1a ff ff ff       	jmp    800d61 <__umoddi3+0x71>
