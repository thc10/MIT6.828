
obj/user/hello:     file format elf32-i386


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
  80002c:	e8 2e 00 00 00       	call   80005f <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:
// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 18             	sub    $0x18,%esp
	cprintf("hello, world\n");
  800039:	c7 04 24 68 0e 80 00 	movl   $0x800e68,(%esp)
  800040:	e8 1c 01 00 00       	call   800161 <cprintf>
	cprintf("i am environment %08x\n", thisenv->env_id);
  800045:	a1 04 20 80 00       	mov    0x802004,%eax
  80004a:	8b 40 48             	mov    0x48(%eax),%eax
  80004d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800051:	c7 04 24 76 0e 80 00 	movl   $0x800e76,(%esp)
  800058:	e8 04 01 00 00       	call   800161 <cprintf>
}
  80005d:	c9                   	leave  
  80005e:	c3                   	ret    

0080005f <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80005f:	55                   	push   %ebp
  800060:	89 e5                	mov    %esp,%ebp
  800062:	56                   	push   %esi
  800063:	53                   	push   %ebx
  800064:	83 ec 10             	sub    $0x10,%esp
  800067:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80006a:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  80006d:	e8 f3 0a 00 00       	call   800b65 <sys_getenvid>
  800072:	25 ff 03 00 00       	and    $0x3ff,%eax
  800077:	8d 04 40             	lea    (%eax,%eax,2),%eax
  80007a:	c1 e0 05             	shl    $0x5,%eax
  80007d:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800082:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800087:	85 db                	test   %ebx,%ebx
  800089:	7e 07                	jle    800092 <libmain+0x33>
		binaryname = argv[0];
  80008b:	8b 06                	mov    (%esi),%eax
  80008d:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800092:	89 74 24 04          	mov    %esi,0x4(%esp)
  800096:	89 1c 24             	mov    %ebx,(%esp)
  800099:	e8 95 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80009e:	e8 07 00 00 00       	call   8000aa <exit>
}
  8000a3:	83 c4 10             	add    $0x10,%esp
  8000a6:	5b                   	pop    %ebx
  8000a7:	5e                   	pop    %esi
  8000a8:	5d                   	pop    %ebp
  8000a9:	c3                   	ret    

008000aa <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000aa:	55                   	push   %ebp
  8000ab:	89 e5                	mov    %esp,%ebp
  8000ad:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000b0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000b7:	e8 57 0a 00 00       	call   800b13 <sys_env_destroy>
}
  8000bc:	c9                   	leave  
  8000bd:	c3                   	ret    

008000be <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000be:	55                   	push   %ebp
  8000bf:	89 e5                	mov    %esp,%ebp
  8000c1:	53                   	push   %ebx
  8000c2:	83 ec 14             	sub    $0x14,%esp
  8000c5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000c8:	8b 13                	mov    (%ebx),%edx
  8000ca:	8d 42 01             	lea    0x1(%edx),%eax
  8000cd:	89 03                	mov    %eax,(%ebx)
  8000cf:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000d2:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000d6:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000db:	75 19                	jne    8000f6 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8000dd:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8000e4:	00 
  8000e5:	8d 43 08             	lea    0x8(%ebx),%eax
  8000e8:	89 04 24             	mov    %eax,(%esp)
  8000eb:	e8 e6 09 00 00       	call   800ad6 <sys_cputs>
		b->idx = 0;
  8000f0:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8000f6:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000fa:	83 c4 14             	add    $0x14,%esp
  8000fd:	5b                   	pop    %ebx
  8000fe:	5d                   	pop    %ebp
  8000ff:	c3                   	ret    

00800100 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800100:	55                   	push   %ebp
  800101:	89 e5                	mov    %esp,%ebp
  800103:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800109:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800110:	00 00 00 
	b.cnt = 0;
  800113:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80011a:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80011d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800120:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800124:	8b 45 08             	mov    0x8(%ebp),%eax
  800127:	89 44 24 08          	mov    %eax,0x8(%esp)
  80012b:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800131:	89 44 24 04          	mov    %eax,0x4(%esp)
  800135:	c7 04 24 be 00 80 00 	movl   $0x8000be,(%esp)
  80013c:	e8 ad 01 00 00       	call   8002ee <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800141:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800147:	89 44 24 04          	mov    %eax,0x4(%esp)
  80014b:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800151:	89 04 24             	mov    %eax,(%esp)
  800154:	e8 7d 09 00 00       	call   800ad6 <sys_cputs>

	return b.cnt;
}
  800159:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80015f:	c9                   	leave  
  800160:	c3                   	ret    

00800161 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800161:	55                   	push   %ebp
  800162:	89 e5                	mov    %esp,%ebp
  800164:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800167:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80016a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80016e:	8b 45 08             	mov    0x8(%ebp),%eax
  800171:	89 04 24             	mov    %eax,(%esp)
  800174:	e8 87 ff ff ff       	call   800100 <vcprintf>
	va_end(ap);

	return cnt;
}
  800179:	c9                   	leave  
  80017a:	c3                   	ret    
  80017b:	66 90                	xchg   %ax,%ax
  80017d:	66 90                	xchg   %ax,%ax
  80017f:	90                   	nop

00800180 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800180:	55                   	push   %ebp
  800181:	89 e5                	mov    %esp,%ebp
  800183:	57                   	push   %edi
  800184:	56                   	push   %esi
  800185:	53                   	push   %ebx
  800186:	83 ec 3c             	sub    $0x3c,%esp
  800189:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80018c:	89 d7                	mov    %edx,%edi
  80018e:	8b 45 08             	mov    0x8(%ebp),%eax
  800191:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800194:	8b 45 0c             	mov    0xc(%ebp),%eax
  800197:	89 c3                	mov    %eax,%ebx
  800199:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80019c:	8b 45 10             	mov    0x10(%ebp),%eax
  80019f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8001a2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8001a7:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8001aa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8001ad:	39 d9                	cmp    %ebx,%ecx
  8001af:	72 05                	jb     8001b6 <printnum+0x36>
  8001b1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8001b4:	77 69                	ja     80021f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001b6:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8001b9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8001bd:	83 ee 01             	sub    $0x1,%esi
  8001c0:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001c4:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001c8:	8b 44 24 08          	mov    0x8(%esp),%eax
  8001cc:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8001d0:	89 c3                	mov    %eax,%ebx
  8001d2:	89 d6                	mov    %edx,%esi
  8001d4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8001d7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8001da:	89 54 24 08          	mov    %edx,0x8(%esp)
  8001de:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8001e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8001e5:	89 04 24             	mov    %eax,(%esp)
  8001e8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8001eb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001ef:	e8 ec 09 00 00       	call   800be0 <__udivdi3>
  8001f4:	89 d9                	mov    %ebx,%ecx
  8001f6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8001fa:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001fe:	89 04 24             	mov    %eax,(%esp)
  800201:	89 54 24 04          	mov    %edx,0x4(%esp)
  800205:	89 fa                	mov    %edi,%edx
  800207:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80020a:	e8 71 ff ff ff       	call   800180 <printnum>
  80020f:	eb 1b                	jmp    80022c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800211:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800215:	8b 45 18             	mov    0x18(%ebp),%eax
  800218:	89 04 24             	mov    %eax,(%esp)
  80021b:	ff d3                	call   *%ebx
  80021d:	eb 03                	jmp    800222 <printnum+0xa2>
  80021f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800222:	83 ee 01             	sub    $0x1,%esi
  800225:	85 f6                	test   %esi,%esi
  800227:	7f e8                	jg     800211 <printnum+0x91>
  800229:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80022c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800230:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800234:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800237:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80023a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80023e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800242:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800245:	89 04 24             	mov    %eax,(%esp)
  800248:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80024b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80024f:	e8 bc 0a 00 00       	call   800d10 <__umoddi3>
  800254:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800258:	0f be 80 97 0e 80 00 	movsbl 0x800e97(%eax),%eax
  80025f:	89 04 24             	mov    %eax,(%esp)
  800262:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800265:	ff d0                	call   *%eax
}
  800267:	83 c4 3c             	add    $0x3c,%esp
  80026a:	5b                   	pop    %ebx
  80026b:	5e                   	pop    %esi
  80026c:	5f                   	pop    %edi
  80026d:	5d                   	pop    %ebp
  80026e:	c3                   	ret    

0080026f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80026f:	55                   	push   %ebp
  800270:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800272:	83 fa 01             	cmp    $0x1,%edx
  800275:	7e 0e                	jle    800285 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800277:	8b 10                	mov    (%eax),%edx
  800279:	8d 4a 08             	lea    0x8(%edx),%ecx
  80027c:	89 08                	mov    %ecx,(%eax)
  80027e:	8b 02                	mov    (%edx),%eax
  800280:	8b 52 04             	mov    0x4(%edx),%edx
  800283:	eb 22                	jmp    8002a7 <getuint+0x38>
	else if (lflag)
  800285:	85 d2                	test   %edx,%edx
  800287:	74 10                	je     800299 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800289:	8b 10                	mov    (%eax),%edx
  80028b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80028e:	89 08                	mov    %ecx,(%eax)
  800290:	8b 02                	mov    (%edx),%eax
  800292:	ba 00 00 00 00       	mov    $0x0,%edx
  800297:	eb 0e                	jmp    8002a7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800299:	8b 10                	mov    (%eax),%edx
  80029b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80029e:	89 08                	mov    %ecx,(%eax)
  8002a0:	8b 02                	mov    (%edx),%eax
  8002a2:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8002a7:	5d                   	pop    %ebp
  8002a8:	c3                   	ret    

008002a9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002a9:	55                   	push   %ebp
  8002aa:	89 e5                	mov    %esp,%ebp
  8002ac:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002af:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002b3:	8b 10                	mov    (%eax),%edx
  8002b5:	3b 50 04             	cmp    0x4(%eax),%edx
  8002b8:	73 0a                	jae    8002c4 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002ba:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002bd:	89 08                	mov    %ecx,(%eax)
  8002bf:	8b 45 08             	mov    0x8(%ebp),%eax
  8002c2:	88 02                	mov    %al,(%edx)
}
  8002c4:	5d                   	pop    %ebp
  8002c5:	c3                   	ret    

008002c6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002c6:	55                   	push   %ebp
  8002c7:	89 e5                	mov    %esp,%ebp
  8002c9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8002cc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002d3:	8b 45 10             	mov    0x10(%ebp),%eax
  8002d6:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002da:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002dd:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002e1:	8b 45 08             	mov    0x8(%ebp),%eax
  8002e4:	89 04 24             	mov    %eax,(%esp)
  8002e7:	e8 02 00 00 00       	call   8002ee <vprintfmt>
	va_end(ap);
}
  8002ec:	c9                   	leave  
  8002ed:	c3                   	ret    

008002ee <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002ee:	55                   	push   %ebp
  8002ef:	89 e5                	mov    %esp,%ebp
  8002f1:	57                   	push   %edi
  8002f2:	56                   	push   %esi
  8002f3:	53                   	push   %ebx
  8002f4:	83 ec 3c             	sub    $0x3c,%esp
  8002f7:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8002fa:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002fd:	eb 14                	jmp    800313 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002ff:	85 c0                	test   %eax,%eax
  800301:	0f 84 b3 03 00 00    	je     8006ba <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
  800307:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80030b:	89 04 24             	mov    %eax,(%esp)
  80030e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800311:	89 f3                	mov    %esi,%ebx
  800313:	8d 73 01             	lea    0x1(%ebx),%esi
  800316:	0f b6 03             	movzbl (%ebx),%eax
  800319:	83 f8 25             	cmp    $0x25,%eax
  80031c:	75 e1                	jne    8002ff <vprintfmt+0x11>
  80031e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800322:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  800329:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  800330:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800337:	ba 00 00 00 00       	mov    $0x0,%edx
  80033c:	eb 1d                	jmp    80035b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80033e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  800340:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800344:	eb 15                	jmp    80035b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800346:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800348:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80034c:	eb 0d                	jmp    80035b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  80034e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800351:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800354:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80035b:	8d 5e 01             	lea    0x1(%esi),%ebx
  80035e:	0f b6 0e             	movzbl (%esi),%ecx
  800361:	0f b6 c1             	movzbl %cl,%eax
  800364:	83 e9 23             	sub    $0x23,%ecx
  800367:	80 f9 55             	cmp    $0x55,%cl
  80036a:	0f 87 2a 03 00 00    	ja     80069a <vprintfmt+0x3ac>
  800370:	0f b6 c9             	movzbl %cl,%ecx
  800373:	ff 24 8d 24 0f 80 00 	jmp    *0x800f24(,%ecx,4)
  80037a:	89 de                	mov    %ebx,%esi
  80037c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800381:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  800384:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  800388:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  80038b:	8d 58 d0             	lea    -0x30(%eax),%ebx
  80038e:	83 fb 09             	cmp    $0x9,%ebx
  800391:	77 36                	ja     8003c9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800393:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800396:	eb e9                	jmp    800381 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800398:	8b 45 14             	mov    0x14(%ebp),%eax
  80039b:	8d 48 04             	lea    0x4(%eax),%ecx
  80039e:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003a1:	8b 00                	mov    (%eax),%eax
  8003a3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003a8:	eb 22                	jmp    8003cc <vprintfmt+0xde>
  8003aa:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8003ad:	85 c9                	test   %ecx,%ecx
  8003af:	b8 00 00 00 00       	mov    $0x0,%eax
  8003b4:	0f 49 c1             	cmovns %ecx,%eax
  8003b7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ba:	89 de                	mov    %ebx,%esi
  8003bc:	eb 9d                	jmp    80035b <vprintfmt+0x6d>
  8003be:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003c0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  8003c7:	eb 92                	jmp    80035b <vprintfmt+0x6d>
  8003c9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  8003cc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8003d0:	79 89                	jns    80035b <vprintfmt+0x6d>
  8003d2:	e9 77 ff ff ff       	jmp    80034e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003d7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003da:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003dc:	e9 7a ff ff ff       	jmp    80035b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003e1:	8b 45 14             	mov    0x14(%ebp),%eax
  8003e4:	8d 50 04             	lea    0x4(%eax),%edx
  8003e7:	89 55 14             	mov    %edx,0x14(%ebp)
  8003ea:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003ee:	8b 00                	mov    (%eax),%eax
  8003f0:	89 04 24             	mov    %eax,(%esp)
  8003f3:	ff 55 08             	call   *0x8(%ebp)
			break;
  8003f6:	e9 18 ff ff ff       	jmp    800313 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003fb:	8b 45 14             	mov    0x14(%ebp),%eax
  8003fe:	8d 50 04             	lea    0x4(%eax),%edx
  800401:	89 55 14             	mov    %edx,0x14(%ebp)
  800404:	8b 00                	mov    (%eax),%eax
  800406:	99                   	cltd   
  800407:	31 d0                	xor    %edx,%eax
  800409:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80040b:	83 f8 06             	cmp    $0x6,%eax
  80040e:	7f 0b                	jg     80041b <vprintfmt+0x12d>
  800410:	8b 14 85 7c 10 80 00 	mov    0x80107c(,%eax,4),%edx
  800417:	85 d2                	test   %edx,%edx
  800419:	75 20                	jne    80043b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  80041b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80041f:	c7 44 24 08 af 0e 80 	movl   $0x800eaf,0x8(%esp)
  800426:	00 
  800427:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80042b:	8b 45 08             	mov    0x8(%ebp),%eax
  80042e:	89 04 24             	mov    %eax,(%esp)
  800431:	e8 90 fe ff ff       	call   8002c6 <printfmt>
  800436:	e9 d8 fe ff ff       	jmp    800313 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  80043b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80043f:	c7 44 24 08 b8 0e 80 	movl   $0x800eb8,0x8(%esp)
  800446:	00 
  800447:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80044b:	8b 45 08             	mov    0x8(%ebp),%eax
  80044e:	89 04 24             	mov    %eax,(%esp)
  800451:	e8 70 fe ff ff       	call   8002c6 <printfmt>
  800456:	e9 b8 fe ff ff       	jmp    800313 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80045b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  80045e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800461:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800464:	8b 45 14             	mov    0x14(%ebp),%eax
  800467:	8d 50 04             	lea    0x4(%eax),%edx
  80046a:	89 55 14             	mov    %edx,0x14(%ebp)
  80046d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  80046f:	85 f6                	test   %esi,%esi
  800471:	b8 a8 0e 80 00       	mov    $0x800ea8,%eax
  800476:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  800479:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  80047d:	0f 84 97 00 00 00    	je     80051a <vprintfmt+0x22c>
  800483:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800487:	0f 8e 9b 00 00 00    	jle    800528 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  80048d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800491:	89 34 24             	mov    %esi,(%esp)
  800494:	e8 cf 02 00 00       	call   800768 <strnlen>
  800499:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80049c:	29 c2                	sub    %eax,%edx
  80049e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  8004a1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  8004a5:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8004a8:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8004ab:	8b 75 08             	mov    0x8(%ebp),%esi
  8004ae:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8004b1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004b3:	eb 0f                	jmp    8004c4 <vprintfmt+0x1d6>
					putch(padc, putdat);
  8004b5:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004b9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8004bc:	89 04 24             	mov    %eax,(%esp)
  8004bf:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004c1:	83 eb 01             	sub    $0x1,%ebx
  8004c4:	85 db                	test   %ebx,%ebx
  8004c6:	7f ed                	jg     8004b5 <vprintfmt+0x1c7>
  8004c8:	8b 75 d8             	mov    -0x28(%ebp),%esi
  8004cb:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8004ce:	85 d2                	test   %edx,%edx
  8004d0:	b8 00 00 00 00       	mov    $0x0,%eax
  8004d5:	0f 49 c2             	cmovns %edx,%eax
  8004d8:	29 c2                	sub    %eax,%edx
  8004da:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8004dd:	89 d7                	mov    %edx,%edi
  8004df:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8004e2:	eb 50                	jmp    800534 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004e4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004e8:	74 1e                	je     800508 <vprintfmt+0x21a>
  8004ea:	0f be d2             	movsbl %dl,%edx
  8004ed:	83 ea 20             	sub    $0x20,%edx
  8004f0:	83 fa 5e             	cmp    $0x5e,%edx
  8004f3:	76 13                	jbe    800508 <vprintfmt+0x21a>
					putch('?', putdat);
  8004f5:	8b 45 0c             	mov    0xc(%ebp),%eax
  8004f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8004fc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800503:	ff 55 08             	call   *0x8(%ebp)
  800506:	eb 0d                	jmp    800515 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  800508:	8b 55 0c             	mov    0xc(%ebp),%edx
  80050b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80050f:	89 04 24             	mov    %eax,(%esp)
  800512:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800515:	83 ef 01             	sub    $0x1,%edi
  800518:	eb 1a                	jmp    800534 <vprintfmt+0x246>
  80051a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80051d:	8b 7d dc             	mov    -0x24(%ebp),%edi
  800520:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800523:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800526:	eb 0c                	jmp    800534 <vprintfmt+0x246>
  800528:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80052b:	8b 7d dc             	mov    -0x24(%ebp),%edi
  80052e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800531:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800534:	83 c6 01             	add    $0x1,%esi
  800537:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  80053b:	0f be c2             	movsbl %dl,%eax
  80053e:	85 c0                	test   %eax,%eax
  800540:	74 27                	je     800569 <vprintfmt+0x27b>
  800542:	85 db                	test   %ebx,%ebx
  800544:	78 9e                	js     8004e4 <vprintfmt+0x1f6>
  800546:	83 eb 01             	sub    $0x1,%ebx
  800549:	79 99                	jns    8004e4 <vprintfmt+0x1f6>
  80054b:	89 f8                	mov    %edi,%eax
  80054d:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800550:	8b 75 08             	mov    0x8(%ebp),%esi
  800553:	89 c3                	mov    %eax,%ebx
  800555:	eb 1a                	jmp    800571 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800557:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80055b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800562:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800564:	83 eb 01             	sub    $0x1,%ebx
  800567:	eb 08                	jmp    800571 <vprintfmt+0x283>
  800569:	89 fb                	mov    %edi,%ebx
  80056b:	8b 75 08             	mov    0x8(%ebp),%esi
  80056e:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800571:	85 db                	test   %ebx,%ebx
  800573:	7f e2                	jg     800557 <vprintfmt+0x269>
  800575:	89 75 08             	mov    %esi,0x8(%ebp)
  800578:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80057b:	e9 93 fd ff ff       	jmp    800313 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800580:	83 fa 01             	cmp    $0x1,%edx
  800583:	7e 16                	jle    80059b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
  800585:	8b 45 14             	mov    0x14(%ebp),%eax
  800588:	8d 50 08             	lea    0x8(%eax),%edx
  80058b:	89 55 14             	mov    %edx,0x14(%ebp)
  80058e:	8b 50 04             	mov    0x4(%eax),%edx
  800591:	8b 00                	mov    (%eax),%eax
  800593:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800596:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800599:	eb 32                	jmp    8005cd <vprintfmt+0x2df>
	else if (lflag)
  80059b:	85 d2                	test   %edx,%edx
  80059d:	74 18                	je     8005b7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
  80059f:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a2:	8d 50 04             	lea    0x4(%eax),%edx
  8005a5:	89 55 14             	mov    %edx,0x14(%ebp)
  8005a8:	8b 30                	mov    (%eax),%esi
  8005aa:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8005ad:	89 f0                	mov    %esi,%eax
  8005af:	c1 f8 1f             	sar    $0x1f,%eax
  8005b2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8005b5:	eb 16                	jmp    8005cd <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
  8005b7:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ba:	8d 50 04             	lea    0x4(%eax),%edx
  8005bd:	89 55 14             	mov    %edx,0x14(%ebp)
  8005c0:	8b 30                	mov    (%eax),%esi
  8005c2:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8005c5:	89 f0                	mov    %esi,%eax
  8005c7:	c1 f8 1f             	sar    $0x1f,%eax
  8005ca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005d0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005d3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005d8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8005dc:	0f 89 80 00 00 00    	jns    800662 <vprintfmt+0x374>
				putch('-', putdat);
  8005e2:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005e6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8005ed:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8005f0:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005f3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8005f6:	f7 d8                	neg    %eax
  8005f8:	83 d2 00             	adc    $0x0,%edx
  8005fb:	f7 da                	neg    %edx
			}
			base = 10;
  8005fd:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800602:	eb 5e                	jmp    800662 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800604:	8d 45 14             	lea    0x14(%ebp),%eax
  800607:	e8 63 fc ff ff       	call   80026f <getuint>
			base = 10;
  80060c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800611:	eb 4f                	jmp    800662 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800613:	8d 45 14             	lea    0x14(%ebp),%eax
  800616:	e8 54 fc ff ff       	call   80026f <getuint>
			base = 8;
  80061b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800620:	eb 40                	jmp    800662 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
  800622:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800626:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80062d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800630:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800634:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80063b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80063e:	8b 45 14             	mov    0x14(%ebp),%eax
  800641:	8d 50 04             	lea    0x4(%eax),%edx
  800644:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800647:	8b 00                	mov    (%eax),%eax
  800649:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80064e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800653:	eb 0d                	jmp    800662 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800655:	8d 45 14             	lea    0x14(%ebp),%eax
  800658:	e8 12 fc ff ff       	call   80026f <getuint>
			base = 16;
  80065d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800662:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  800666:	89 74 24 10          	mov    %esi,0x10(%esp)
  80066a:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80066d:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800671:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800675:	89 04 24             	mov    %eax,(%esp)
  800678:	89 54 24 04          	mov    %edx,0x4(%esp)
  80067c:	89 fa                	mov    %edi,%edx
  80067e:	8b 45 08             	mov    0x8(%ebp),%eax
  800681:	e8 fa fa ff ff       	call   800180 <printnum>
			break;
  800686:	e9 88 fc ff ff       	jmp    800313 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80068b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80068f:	89 04 24             	mov    %eax,(%esp)
  800692:	ff 55 08             	call   *0x8(%ebp)
			break;
  800695:	e9 79 fc ff ff       	jmp    800313 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80069a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80069e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8006a5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006a8:	89 f3                	mov    %esi,%ebx
  8006aa:	eb 03                	jmp    8006af <vprintfmt+0x3c1>
  8006ac:	83 eb 01             	sub    $0x1,%ebx
  8006af:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  8006b3:	75 f7                	jne    8006ac <vprintfmt+0x3be>
  8006b5:	e9 59 fc ff ff       	jmp    800313 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  8006ba:	83 c4 3c             	add    $0x3c,%esp
  8006bd:	5b                   	pop    %ebx
  8006be:	5e                   	pop    %esi
  8006bf:	5f                   	pop    %edi
  8006c0:	5d                   	pop    %ebp
  8006c1:	c3                   	ret    

008006c2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006c2:	55                   	push   %ebp
  8006c3:	89 e5                	mov    %esp,%ebp
  8006c5:	83 ec 28             	sub    $0x28,%esp
  8006c8:	8b 45 08             	mov    0x8(%ebp),%eax
  8006cb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006ce:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006d1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006d5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006d8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006df:	85 c0                	test   %eax,%eax
  8006e1:	74 30                	je     800713 <vsnprintf+0x51>
  8006e3:	85 d2                	test   %edx,%edx
  8006e5:	7e 2c                	jle    800713 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006e7:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ea:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8006ee:	8b 45 10             	mov    0x10(%ebp),%eax
  8006f1:	89 44 24 08          	mov    %eax,0x8(%esp)
  8006f5:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8006fc:	c7 04 24 a9 02 80 00 	movl   $0x8002a9,(%esp)
  800703:	e8 e6 fb ff ff       	call   8002ee <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800708:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80070b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80070e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800711:	eb 05                	jmp    800718 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800713:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800718:	c9                   	leave  
  800719:	c3                   	ret    

0080071a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80071a:	55                   	push   %ebp
  80071b:	89 e5                	mov    %esp,%ebp
  80071d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800720:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800723:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800727:	8b 45 10             	mov    0x10(%ebp),%eax
  80072a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80072e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800731:	89 44 24 04          	mov    %eax,0x4(%esp)
  800735:	8b 45 08             	mov    0x8(%ebp),%eax
  800738:	89 04 24             	mov    %eax,(%esp)
  80073b:	e8 82 ff ff ff       	call   8006c2 <vsnprintf>
	va_end(ap);

	return rc;
}
  800740:	c9                   	leave  
  800741:	c3                   	ret    
  800742:	66 90                	xchg   %ax,%ax
  800744:	66 90                	xchg   %ax,%ax
  800746:	66 90                	xchg   %ax,%ax
  800748:	66 90                	xchg   %ax,%ax
  80074a:	66 90                	xchg   %ax,%ax
  80074c:	66 90                	xchg   %ax,%ax
  80074e:	66 90                	xchg   %ax,%ax

00800750 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800750:	55                   	push   %ebp
  800751:	89 e5                	mov    %esp,%ebp
  800753:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800756:	b8 00 00 00 00       	mov    $0x0,%eax
  80075b:	eb 03                	jmp    800760 <strlen+0x10>
		n++;
  80075d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800760:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800764:	75 f7                	jne    80075d <strlen+0xd>
		n++;
	return n;
}
  800766:	5d                   	pop    %ebp
  800767:	c3                   	ret    

00800768 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800768:	55                   	push   %ebp
  800769:	89 e5                	mov    %esp,%ebp
  80076b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80076e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800771:	b8 00 00 00 00       	mov    $0x0,%eax
  800776:	eb 03                	jmp    80077b <strnlen+0x13>
		n++;
  800778:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80077b:	39 d0                	cmp    %edx,%eax
  80077d:	74 06                	je     800785 <strnlen+0x1d>
  80077f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800783:	75 f3                	jne    800778 <strnlen+0x10>
		n++;
	return n;
}
  800785:	5d                   	pop    %ebp
  800786:	c3                   	ret    

00800787 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800787:	55                   	push   %ebp
  800788:	89 e5                	mov    %esp,%ebp
  80078a:	53                   	push   %ebx
  80078b:	8b 45 08             	mov    0x8(%ebp),%eax
  80078e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800791:	89 c2                	mov    %eax,%edx
  800793:	83 c2 01             	add    $0x1,%edx
  800796:	83 c1 01             	add    $0x1,%ecx
  800799:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80079d:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007a0:	84 db                	test   %bl,%bl
  8007a2:	75 ef                	jne    800793 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007a4:	5b                   	pop    %ebx
  8007a5:	5d                   	pop    %ebp
  8007a6:	c3                   	ret    

008007a7 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007a7:	55                   	push   %ebp
  8007a8:	89 e5                	mov    %esp,%ebp
  8007aa:	53                   	push   %ebx
  8007ab:	83 ec 08             	sub    $0x8,%esp
  8007ae:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007b1:	89 1c 24             	mov    %ebx,(%esp)
  8007b4:	e8 97 ff ff ff       	call   800750 <strlen>
	strcpy(dst + len, src);
  8007b9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007bc:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007c0:	01 d8                	add    %ebx,%eax
  8007c2:	89 04 24             	mov    %eax,(%esp)
  8007c5:	e8 bd ff ff ff       	call   800787 <strcpy>
	return dst;
}
  8007ca:	89 d8                	mov    %ebx,%eax
  8007cc:	83 c4 08             	add    $0x8,%esp
  8007cf:	5b                   	pop    %ebx
  8007d0:	5d                   	pop    %ebp
  8007d1:	c3                   	ret    

008007d2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007d2:	55                   	push   %ebp
  8007d3:	89 e5                	mov    %esp,%ebp
  8007d5:	56                   	push   %esi
  8007d6:	53                   	push   %ebx
  8007d7:	8b 75 08             	mov    0x8(%ebp),%esi
  8007da:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007dd:	89 f3                	mov    %esi,%ebx
  8007df:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007e2:	89 f2                	mov    %esi,%edx
  8007e4:	eb 0f                	jmp    8007f5 <strncpy+0x23>
		*dst++ = *src;
  8007e6:	83 c2 01             	add    $0x1,%edx
  8007e9:	0f b6 01             	movzbl (%ecx),%eax
  8007ec:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007ef:	80 39 01             	cmpb   $0x1,(%ecx)
  8007f2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007f5:	39 da                	cmp    %ebx,%edx
  8007f7:	75 ed                	jne    8007e6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007f9:	89 f0                	mov    %esi,%eax
  8007fb:	5b                   	pop    %ebx
  8007fc:	5e                   	pop    %esi
  8007fd:	5d                   	pop    %ebp
  8007fe:	c3                   	ret    

008007ff <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007ff:	55                   	push   %ebp
  800800:	89 e5                	mov    %esp,%ebp
  800802:	56                   	push   %esi
  800803:	53                   	push   %ebx
  800804:	8b 75 08             	mov    0x8(%ebp),%esi
  800807:	8b 55 0c             	mov    0xc(%ebp),%edx
  80080a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80080d:	89 f0                	mov    %esi,%eax
  80080f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800813:	85 c9                	test   %ecx,%ecx
  800815:	75 0b                	jne    800822 <strlcpy+0x23>
  800817:	eb 1d                	jmp    800836 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800819:	83 c0 01             	add    $0x1,%eax
  80081c:	83 c2 01             	add    $0x1,%edx
  80081f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800822:	39 d8                	cmp    %ebx,%eax
  800824:	74 0b                	je     800831 <strlcpy+0x32>
  800826:	0f b6 0a             	movzbl (%edx),%ecx
  800829:	84 c9                	test   %cl,%cl
  80082b:	75 ec                	jne    800819 <strlcpy+0x1a>
  80082d:	89 c2                	mov    %eax,%edx
  80082f:	eb 02                	jmp    800833 <strlcpy+0x34>
  800831:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800833:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800836:	29 f0                	sub    %esi,%eax
}
  800838:	5b                   	pop    %ebx
  800839:	5e                   	pop    %esi
  80083a:	5d                   	pop    %ebp
  80083b:	c3                   	ret    

0080083c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80083c:	55                   	push   %ebp
  80083d:	89 e5                	mov    %esp,%ebp
  80083f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800842:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800845:	eb 06                	jmp    80084d <strcmp+0x11>
		p++, q++;
  800847:	83 c1 01             	add    $0x1,%ecx
  80084a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80084d:	0f b6 01             	movzbl (%ecx),%eax
  800850:	84 c0                	test   %al,%al
  800852:	74 04                	je     800858 <strcmp+0x1c>
  800854:	3a 02                	cmp    (%edx),%al
  800856:	74 ef                	je     800847 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800858:	0f b6 c0             	movzbl %al,%eax
  80085b:	0f b6 12             	movzbl (%edx),%edx
  80085e:	29 d0                	sub    %edx,%eax
}
  800860:	5d                   	pop    %ebp
  800861:	c3                   	ret    

00800862 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800862:	55                   	push   %ebp
  800863:	89 e5                	mov    %esp,%ebp
  800865:	53                   	push   %ebx
  800866:	8b 45 08             	mov    0x8(%ebp),%eax
  800869:	8b 55 0c             	mov    0xc(%ebp),%edx
  80086c:	89 c3                	mov    %eax,%ebx
  80086e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800871:	eb 06                	jmp    800879 <strncmp+0x17>
		n--, p++, q++;
  800873:	83 c0 01             	add    $0x1,%eax
  800876:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800879:	39 d8                	cmp    %ebx,%eax
  80087b:	74 15                	je     800892 <strncmp+0x30>
  80087d:	0f b6 08             	movzbl (%eax),%ecx
  800880:	84 c9                	test   %cl,%cl
  800882:	74 04                	je     800888 <strncmp+0x26>
  800884:	3a 0a                	cmp    (%edx),%cl
  800886:	74 eb                	je     800873 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800888:	0f b6 00             	movzbl (%eax),%eax
  80088b:	0f b6 12             	movzbl (%edx),%edx
  80088e:	29 d0                	sub    %edx,%eax
  800890:	eb 05                	jmp    800897 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800892:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800897:	5b                   	pop    %ebx
  800898:	5d                   	pop    %ebp
  800899:	c3                   	ret    

0080089a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80089a:	55                   	push   %ebp
  80089b:	89 e5                	mov    %esp,%ebp
  80089d:	8b 45 08             	mov    0x8(%ebp),%eax
  8008a0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008a4:	eb 07                	jmp    8008ad <strchr+0x13>
		if (*s == c)
  8008a6:	38 ca                	cmp    %cl,%dl
  8008a8:	74 0f                	je     8008b9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008aa:	83 c0 01             	add    $0x1,%eax
  8008ad:	0f b6 10             	movzbl (%eax),%edx
  8008b0:	84 d2                	test   %dl,%dl
  8008b2:	75 f2                	jne    8008a6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008b4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008b9:	5d                   	pop    %ebp
  8008ba:	c3                   	ret    

008008bb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008bb:	55                   	push   %ebp
  8008bc:	89 e5                	mov    %esp,%ebp
  8008be:	8b 45 08             	mov    0x8(%ebp),%eax
  8008c1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008c5:	eb 07                	jmp    8008ce <strfind+0x13>
		if (*s == c)
  8008c7:	38 ca                	cmp    %cl,%dl
  8008c9:	74 0a                	je     8008d5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  8008cb:	83 c0 01             	add    $0x1,%eax
  8008ce:	0f b6 10             	movzbl (%eax),%edx
  8008d1:	84 d2                	test   %dl,%dl
  8008d3:	75 f2                	jne    8008c7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  8008d5:	5d                   	pop    %ebp
  8008d6:	c3                   	ret    

008008d7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008d7:	55                   	push   %ebp
  8008d8:	89 e5                	mov    %esp,%ebp
  8008da:	57                   	push   %edi
  8008db:	56                   	push   %esi
  8008dc:	53                   	push   %ebx
  8008dd:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008e0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008e3:	85 c9                	test   %ecx,%ecx
  8008e5:	74 36                	je     80091d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008e7:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008ed:	75 28                	jne    800917 <memset+0x40>
  8008ef:	f6 c1 03             	test   $0x3,%cl
  8008f2:	75 23                	jne    800917 <memset+0x40>
		c &= 0xFF;
  8008f4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008f8:	89 d3                	mov    %edx,%ebx
  8008fa:	c1 e3 08             	shl    $0x8,%ebx
  8008fd:	89 d6                	mov    %edx,%esi
  8008ff:	c1 e6 18             	shl    $0x18,%esi
  800902:	89 d0                	mov    %edx,%eax
  800904:	c1 e0 10             	shl    $0x10,%eax
  800907:	09 f0                	or     %esi,%eax
  800909:	09 c2                	or     %eax,%edx
  80090b:	89 d0                	mov    %edx,%eax
  80090d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  80090f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800912:	fc                   	cld    
  800913:	f3 ab                	rep stos %eax,%es:(%edi)
  800915:	eb 06                	jmp    80091d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800917:	8b 45 0c             	mov    0xc(%ebp),%eax
  80091a:	fc                   	cld    
  80091b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80091d:	89 f8                	mov    %edi,%eax
  80091f:	5b                   	pop    %ebx
  800920:	5e                   	pop    %esi
  800921:	5f                   	pop    %edi
  800922:	5d                   	pop    %ebp
  800923:	c3                   	ret    

00800924 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800924:	55                   	push   %ebp
  800925:	89 e5                	mov    %esp,%ebp
  800927:	57                   	push   %edi
  800928:	56                   	push   %esi
  800929:	8b 45 08             	mov    0x8(%ebp),%eax
  80092c:	8b 75 0c             	mov    0xc(%ebp),%esi
  80092f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800932:	39 c6                	cmp    %eax,%esi
  800934:	73 35                	jae    80096b <memmove+0x47>
  800936:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800939:	39 d0                	cmp    %edx,%eax
  80093b:	73 2e                	jae    80096b <memmove+0x47>
		s += n;
		d += n;
  80093d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800940:	89 d6                	mov    %edx,%esi
  800942:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800944:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80094a:	75 13                	jne    80095f <memmove+0x3b>
  80094c:	f6 c1 03             	test   $0x3,%cl
  80094f:	75 0e                	jne    80095f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800951:	83 ef 04             	sub    $0x4,%edi
  800954:	8d 72 fc             	lea    -0x4(%edx),%esi
  800957:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  80095a:	fd                   	std    
  80095b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80095d:	eb 09                	jmp    800968 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  80095f:	83 ef 01             	sub    $0x1,%edi
  800962:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800965:	fd                   	std    
  800966:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800968:	fc                   	cld    
  800969:	eb 1d                	jmp    800988 <memmove+0x64>
  80096b:	89 f2                	mov    %esi,%edx
  80096d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80096f:	f6 c2 03             	test   $0x3,%dl
  800972:	75 0f                	jne    800983 <memmove+0x5f>
  800974:	f6 c1 03             	test   $0x3,%cl
  800977:	75 0a                	jne    800983 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800979:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  80097c:	89 c7                	mov    %eax,%edi
  80097e:	fc                   	cld    
  80097f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800981:	eb 05                	jmp    800988 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800983:	89 c7                	mov    %eax,%edi
  800985:	fc                   	cld    
  800986:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800988:	5e                   	pop    %esi
  800989:	5f                   	pop    %edi
  80098a:	5d                   	pop    %ebp
  80098b:	c3                   	ret    

0080098c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80098c:	55                   	push   %ebp
  80098d:	89 e5                	mov    %esp,%ebp
  80098f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800992:	8b 45 10             	mov    0x10(%ebp),%eax
  800995:	89 44 24 08          	mov    %eax,0x8(%esp)
  800999:	8b 45 0c             	mov    0xc(%ebp),%eax
  80099c:	89 44 24 04          	mov    %eax,0x4(%esp)
  8009a0:	8b 45 08             	mov    0x8(%ebp),%eax
  8009a3:	89 04 24             	mov    %eax,(%esp)
  8009a6:	e8 79 ff ff ff       	call   800924 <memmove>
}
  8009ab:	c9                   	leave  
  8009ac:	c3                   	ret    

008009ad <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009ad:	55                   	push   %ebp
  8009ae:	89 e5                	mov    %esp,%ebp
  8009b0:	56                   	push   %esi
  8009b1:	53                   	push   %ebx
  8009b2:	8b 55 08             	mov    0x8(%ebp),%edx
  8009b5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8009b8:	89 d6                	mov    %edx,%esi
  8009ba:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009bd:	eb 1a                	jmp    8009d9 <memcmp+0x2c>
		if (*s1 != *s2)
  8009bf:	0f b6 02             	movzbl (%edx),%eax
  8009c2:	0f b6 19             	movzbl (%ecx),%ebx
  8009c5:	38 d8                	cmp    %bl,%al
  8009c7:	74 0a                	je     8009d3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009c9:	0f b6 c0             	movzbl %al,%eax
  8009cc:	0f b6 db             	movzbl %bl,%ebx
  8009cf:	29 d8                	sub    %ebx,%eax
  8009d1:	eb 0f                	jmp    8009e2 <memcmp+0x35>
		s1++, s2++;
  8009d3:	83 c2 01             	add    $0x1,%edx
  8009d6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009d9:	39 f2                	cmp    %esi,%edx
  8009db:	75 e2                	jne    8009bf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009e2:	5b                   	pop    %ebx
  8009e3:	5e                   	pop    %esi
  8009e4:	5d                   	pop    %ebp
  8009e5:	c3                   	ret    

008009e6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009e6:	55                   	push   %ebp
  8009e7:	89 e5                	mov    %esp,%ebp
  8009e9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009ec:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8009ef:	89 c2                	mov    %eax,%edx
  8009f1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  8009f4:	eb 07                	jmp    8009fd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009f6:	38 08                	cmp    %cl,(%eax)
  8009f8:	74 07                	je     800a01 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009fa:	83 c0 01             	add    $0x1,%eax
  8009fd:	39 d0                	cmp    %edx,%eax
  8009ff:	72 f5                	jb     8009f6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a01:	5d                   	pop    %ebp
  800a02:	c3                   	ret    

00800a03 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a03:	55                   	push   %ebp
  800a04:	89 e5                	mov    %esp,%ebp
  800a06:	57                   	push   %edi
  800a07:	56                   	push   %esi
  800a08:	53                   	push   %ebx
  800a09:	8b 55 08             	mov    0x8(%ebp),%edx
  800a0c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a0f:	eb 03                	jmp    800a14 <strtol+0x11>
		s++;
  800a11:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a14:	0f b6 0a             	movzbl (%edx),%ecx
  800a17:	80 f9 09             	cmp    $0x9,%cl
  800a1a:	74 f5                	je     800a11 <strtol+0xe>
  800a1c:	80 f9 20             	cmp    $0x20,%cl
  800a1f:	74 f0                	je     800a11 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a21:	80 f9 2b             	cmp    $0x2b,%cl
  800a24:	75 0a                	jne    800a30 <strtol+0x2d>
		s++;
  800a26:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a29:	bf 00 00 00 00       	mov    $0x0,%edi
  800a2e:	eb 11                	jmp    800a41 <strtol+0x3e>
  800a30:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a35:	80 f9 2d             	cmp    $0x2d,%cl
  800a38:	75 07                	jne    800a41 <strtol+0x3e>
		s++, neg = 1;
  800a3a:	8d 52 01             	lea    0x1(%edx),%edx
  800a3d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a41:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800a46:	75 15                	jne    800a5d <strtol+0x5a>
  800a48:	80 3a 30             	cmpb   $0x30,(%edx)
  800a4b:	75 10                	jne    800a5d <strtol+0x5a>
  800a4d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800a51:	75 0a                	jne    800a5d <strtol+0x5a>
		s += 2, base = 16;
  800a53:	83 c2 02             	add    $0x2,%edx
  800a56:	b8 10 00 00 00       	mov    $0x10,%eax
  800a5b:	eb 10                	jmp    800a6d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800a5d:	85 c0                	test   %eax,%eax
  800a5f:	75 0c                	jne    800a6d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a61:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a63:	80 3a 30             	cmpb   $0x30,(%edx)
  800a66:	75 05                	jne    800a6d <strtol+0x6a>
		s++, base = 8;
  800a68:	83 c2 01             	add    $0x1,%edx
  800a6b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800a6d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800a72:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a75:	0f b6 0a             	movzbl (%edx),%ecx
  800a78:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800a7b:	89 f0                	mov    %esi,%eax
  800a7d:	3c 09                	cmp    $0x9,%al
  800a7f:	77 08                	ja     800a89 <strtol+0x86>
			dig = *s - '0';
  800a81:	0f be c9             	movsbl %cl,%ecx
  800a84:	83 e9 30             	sub    $0x30,%ecx
  800a87:	eb 20                	jmp    800aa9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800a89:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800a8c:	89 f0                	mov    %esi,%eax
  800a8e:	3c 19                	cmp    $0x19,%al
  800a90:	77 08                	ja     800a9a <strtol+0x97>
			dig = *s - 'a' + 10;
  800a92:	0f be c9             	movsbl %cl,%ecx
  800a95:	83 e9 57             	sub    $0x57,%ecx
  800a98:	eb 0f                	jmp    800aa9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800a9a:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800a9d:	89 f0                	mov    %esi,%eax
  800a9f:	3c 19                	cmp    $0x19,%al
  800aa1:	77 16                	ja     800ab9 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800aa3:	0f be c9             	movsbl %cl,%ecx
  800aa6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800aa9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800aac:	7d 0f                	jge    800abd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800aae:	83 c2 01             	add    $0x1,%edx
  800ab1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800ab5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800ab7:	eb bc                	jmp    800a75 <strtol+0x72>
  800ab9:	89 d8                	mov    %ebx,%eax
  800abb:	eb 02                	jmp    800abf <strtol+0xbc>
  800abd:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800abf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ac3:	74 05                	je     800aca <strtol+0xc7>
		*endptr = (char *) s;
  800ac5:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ac8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800aca:	f7 d8                	neg    %eax
  800acc:	85 ff                	test   %edi,%edi
  800ace:	0f 44 c3             	cmove  %ebx,%eax
}
  800ad1:	5b                   	pop    %ebx
  800ad2:	5e                   	pop    %esi
  800ad3:	5f                   	pop    %edi
  800ad4:	5d                   	pop    %ebp
  800ad5:	c3                   	ret    

00800ad6 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800ad6:	55                   	push   %ebp
  800ad7:	89 e5                	mov    %esp,%ebp
  800ad9:	57                   	push   %edi
  800ada:	56                   	push   %esi
  800adb:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800adc:	b8 00 00 00 00       	mov    $0x0,%eax
  800ae1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ae4:	8b 55 08             	mov    0x8(%ebp),%edx
  800ae7:	89 c3                	mov    %eax,%ebx
  800ae9:	89 c7                	mov    %eax,%edi
  800aeb:	89 c6                	mov    %eax,%esi
  800aed:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800aef:	5b                   	pop    %ebx
  800af0:	5e                   	pop    %esi
  800af1:	5f                   	pop    %edi
  800af2:	5d                   	pop    %ebp
  800af3:	c3                   	ret    

00800af4 <sys_cgetc>:

int
sys_cgetc(void)
{
  800af4:	55                   	push   %ebp
  800af5:	89 e5                	mov    %esp,%ebp
  800af7:	57                   	push   %edi
  800af8:	56                   	push   %esi
  800af9:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800afa:	ba 00 00 00 00       	mov    $0x0,%edx
  800aff:	b8 01 00 00 00       	mov    $0x1,%eax
  800b04:	89 d1                	mov    %edx,%ecx
  800b06:	89 d3                	mov    %edx,%ebx
  800b08:	89 d7                	mov    %edx,%edi
  800b0a:	89 d6                	mov    %edx,%esi
  800b0c:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800b0e:	5b                   	pop    %ebx
  800b0f:	5e                   	pop    %esi
  800b10:	5f                   	pop    %edi
  800b11:	5d                   	pop    %ebp
  800b12:	c3                   	ret    

00800b13 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b13:	55                   	push   %ebp
  800b14:	89 e5                	mov    %esp,%ebp
  800b16:	57                   	push   %edi
  800b17:	56                   	push   %esi
  800b18:	53                   	push   %ebx
  800b19:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b1c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b21:	b8 03 00 00 00       	mov    $0x3,%eax
  800b26:	8b 55 08             	mov    0x8(%ebp),%edx
  800b29:	89 cb                	mov    %ecx,%ebx
  800b2b:	89 cf                	mov    %ecx,%edi
  800b2d:	89 ce                	mov    %ecx,%esi
  800b2f:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800b31:	85 c0                	test   %eax,%eax
  800b33:	7e 28                	jle    800b5d <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b35:	89 44 24 10          	mov    %eax,0x10(%esp)
  800b39:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800b40:	00 
  800b41:	c7 44 24 08 98 10 80 	movl   $0x801098,0x8(%esp)
  800b48:	00 
  800b49:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800b50:	00 
  800b51:	c7 04 24 b5 10 80 00 	movl   $0x8010b5,(%esp)
  800b58:	e8 27 00 00 00       	call   800b84 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b5d:	83 c4 2c             	add    $0x2c,%esp
  800b60:	5b                   	pop    %ebx
  800b61:	5e                   	pop    %esi
  800b62:	5f                   	pop    %edi
  800b63:	5d                   	pop    %ebp
  800b64:	c3                   	ret    

00800b65 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b65:	55                   	push   %ebp
  800b66:	89 e5                	mov    %esp,%ebp
  800b68:	57                   	push   %edi
  800b69:	56                   	push   %esi
  800b6a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b6b:	ba 00 00 00 00       	mov    $0x0,%edx
  800b70:	b8 02 00 00 00       	mov    $0x2,%eax
  800b75:	89 d1                	mov    %edx,%ecx
  800b77:	89 d3                	mov    %edx,%ebx
  800b79:	89 d7                	mov    %edx,%edi
  800b7b:	89 d6                	mov    %edx,%esi
  800b7d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b7f:	5b                   	pop    %ebx
  800b80:	5e                   	pop    %esi
  800b81:	5f                   	pop    %edi
  800b82:	5d                   	pop    %ebp
  800b83:	c3                   	ret    

00800b84 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800b84:	55                   	push   %ebp
  800b85:	89 e5                	mov    %esp,%ebp
  800b87:	56                   	push   %esi
  800b88:	53                   	push   %ebx
  800b89:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800b8c:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800b8f:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800b95:	e8 cb ff ff ff       	call   800b65 <sys_getenvid>
  800b9a:	8b 55 0c             	mov    0xc(%ebp),%edx
  800b9d:	89 54 24 10          	mov    %edx,0x10(%esp)
  800ba1:	8b 55 08             	mov    0x8(%ebp),%edx
  800ba4:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800ba8:	89 74 24 08          	mov    %esi,0x8(%esp)
  800bac:	89 44 24 04          	mov    %eax,0x4(%esp)
  800bb0:	c7 04 24 c4 10 80 00 	movl   $0x8010c4,(%esp)
  800bb7:	e8 a5 f5 ff ff       	call   800161 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800bbc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800bc0:	8b 45 10             	mov    0x10(%ebp),%eax
  800bc3:	89 04 24             	mov    %eax,(%esp)
  800bc6:	e8 35 f5 ff ff       	call   800100 <vcprintf>
	cprintf("\n");
  800bcb:	c7 04 24 74 0e 80 00 	movl   $0x800e74,(%esp)
  800bd2:	e8 8a f5 ff ff       	call   800161 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800bd7:	cc                   	int3   
  800bd8:	eb fd                	jmp    800bd7 <_panic+0x53>
  800bda:	66 90                	xchg   %ax,%ax
  800bdc:	66 90                	xchg   %ax,%ax
  800bde:	66 90                	xchg   %ax,%ax

00800be0 <__udivdi3>:
  800be0:	55                   	push   %ebp
  800be1:	57                   	push   %edi
  800be2:	56                   	push   %esi
  800be3:	83 ec 0c             	sub    $0xc,%esp
  800be6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800bea:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800bee:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800bf2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800bf6:	85 c0                	test   %eax,%eax
  800bf8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800bfc:	89 ea                	mov    %ebp,%edx
  800bfe:	89 0c 24             	mov    %ecx,(%esp)
  800c01:	75 2d                	jne    800c30 <__udivdi3+0x50>
  800c03:	39 e9                	cmp    %ebp,%ecx
  800c05:	77 61                	ja     800c68 <__udivdi3+0x88>
  800c07:	85 c9                	test   %ecx,%ecx
  800c09:	89 ce                	mov    %ecx,%esi
  800c0b:	75 0b                	jne    800c18 <__udivdi3+0x38>
  800c0d:	b8 01 00 00 00       	mov    $0x1,%eax
  800c12:	31 d2                	xor    %edx,%edx
  800c14:	f7 f1                	div    %ecx
  800c16:	89 c6                	mov    %eax,%esi
  800c18:	31 d2                	xor    %edx,%edx
  800c1a:	89 e8                	mov    %ebp,%eax
  800c1c:	f7 f6                	div    %esi
  800c1e:	89 c5                	mov    %eax,%ebp
  800c20:	89 f8                	mov    %edi,%eax
  800c22:	f7 f6                	div    %esi
  800c24:	89 ea                	mov    %ebp,%edx
  800c26:	83 c4 0c             	add    $0xc,%esp
  800c29:	5e                   	pop    %esi
  800c2a:	5f                   	pop    %edi
  800c2b:	5d                   	pop    %ebp
  800c2c:	c3                   	ret    
  800c2d:	8d 76 00             	lea    0x0(%esi),%esi
  800c30:	39 e8                	cmp    %ebp,%eax
  800c32:	77 24                	ja     800c58 <__udivdi3+0x78>
  800c34:	0f bd e8             	bsr    %eax,%ebp
  800c37:	83 f5 1f             	xor    $0x1f,%ebp
  800c3a:	75 3c                	jne    800c78 <__udivdi3+0x98>
  800c3c:	8b 74 24 04          	mov    0x4(%esp),%esi
  800c40:	39 34 24             	cmp    %esi,(%esp)
  800c43:	0f 86 9f 00 00 00    	jbe    800ce8 <__udivdi3+0x108>
  800c49:	39 d0                	cmp    %edx,%eax
  800c4b:	0f 82 97 00 00 00    	jb     800ce8 <__udivdi3+0x108>
  800c51:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c58:	31 d2                	xor    %edx,%edx
  800c5a:	31 c0                	xor    %eax,%eax
  800c5c:	83 c4 0c             	add    $0xc,%esp
  800c5f:	5e                   	pop    %esi
  800c60:	5f                   	pop    %edi
  800c61:	5d                   	pop    %ebp
  800c62:	c3                   	ret    
  800c63:	90                   	nop
  800c64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c68:	89 f8                	mov    %edi,%eax
  800c6a:	f7 f1                	div    %ecx
  800c6c:	31 d2                	xor    %edx,%edx
  800c6e:	83 c4 0c             	add    $0xc,%esp
  800c71:	5e                   	pop    %esi
  800c72:	5f                   	pop    %edi
  800c73:	5d                   	pop    %ebp
  800c74:	c3                   	ret    
  800c75:	8d 76 00             	lea    0x0(%esi),%esi
  800c78:	89 e9                	mov    %ebp,%ecx
  800c7a:	8b 3c 24             	mov    (%esp),%edi
  800c7d:	d3 e0                	shl    %cl,%eax
  800c7f:	89 c6                	mov    %eax,%esi
  800c81:	b8 20 00 00 00       	mov    $0x20,%eax
  800c86:	29 e8                	sub    %ebp,%eax
  800c88:	89 c1                	mov    %eax,%ecx
  800c8a:	d3 ef                	shr    %cl,%edi
  800c8c:	89 e9                	mov    %ebp,%ecx
  800c8e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800c92:	8b 3c 24             	mov    (%esp),%edi
  800c95:	09 74 24 08          	or     %esi,0x8(%esp)
  800c99:	89 d6                	mov    %edx,%esi
  800c9b:	d3 e7                	shl    %cl,%edi
  800c9d:	89 c1                	mov    %eax,%ecx
  800c9f:	89 3c 24             	mov    %edi,(%esp)
  800ca2:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800ca6:	d3 ee                	shr    %cl,%esi
  800ca8:	89 e9                	mov    %ebp,%ecx
  800caa:	d3 e2                	shl    %cl,%edx
  800cac:	89 c1                	mov    %eax,%ecx
  800cae:	d3 ef                	shr    %cl,%edi
  800cb0:	09 d7                	or     %edx,%edi
  800cb2:	89 f2                	mov    %esi,%edx
  800cb4:	89 f8                	mov    %edi,%eax
  800cb6:	f7 74 24 08          	divl   0x8(%esp)
  800cba:	89 d6                	mov    %edx,%esi
  800cbc:	89 c7                	mov    %eax,%edi
  800cbe:	f7 24 24             	mull   (%esp)
  800cc1:	39 d6                	cmp    %edx,%esi
  800cc3:	89 14 24             	mov    %edx,(%esp)
  800cc6:	72 30                	jb     800cf8 <__udivdi3+0x118>
  800cc8:	8b 54 24 04          	mov    0x4(%esp),%edx
  800ccc:	89 e9                	mov    %ebp,%ecx
  800cce:	d3 e2                	shl    %cl,%edx
  800cd0:	39 c2                	cmp    %eax,%edx
  800cd2:	73 05                	jae    800cd9 <__udivdi3+0xf9>
  800cd4:	3b 34 24             	cmp    (%esp),%esi
  800cd7:	74 1f                	je     800cf8 <__udivdi3+0x118>
  800cd9:	89 f8                	mov    %edi,%eax
  800cdb:	31 d2                	xor    %edx,%edx
  800cdd:	e9 7a ff ff ff       	jmp    800c5c <__udivdi3+0x7c>
  800ce2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800ce8:	31 d2                	xor    %edx,%edx
  800cea:	b8 01 00 00 00       	mov    $0x1,%eax
  800cef:	e9 68 ff ff ff       	jmp    800c5c <__udivdi3+0x7c>
  800cf4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800cf8:	8d 47 ff             	lea    -0x1(%edi),%eax
  800cfb:	31 d2                	xor    %edx,%edx
  800cfd:	83 c4 0c             	add    $0xc,%esp
  800d00:	5e                   	pop    %esi
  800d01:	5f                   	pop    %edi
  800d02:	5d                   	pop    %ebp
  800d03:	c3                   	ret    
  800d04:	66 90                	xchg   %ax,%ax
  800d06:	66 90                	xchg   %ax,%ax
  800d08:	66 90                	xchg   %ax,%ax
  800d0a:	66 90                	xchg   %ax,%ax
  800d0c:	66 90                	xchg   %ax,%ax
  800d0e:	66 90                	xchg   %ax,%ax

00800d10 <__umoddi3>:
  800d10:	55                   	push   %ebp
  800d11:	57                   	push   %edi
  800d12:	56                   	push   %esi
  800d13:	83 ec 14             	sub    $0x14,%esp
  800d16:	8b 44 24 28          	mov    0x28(%esp),%eax
  800d1a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800d1e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800d22:	89 c7                	mov    %eax,%edi
  800d24:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d28:	8b 44 24 30          	mov    0x30(%esp),%eax
  800d2c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800d30:	89 34 24             	mov    %esi,(%esp)
  800d33:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d37:	85 c0                	test   %eax,%eax
  800d39:	89 c2                	mov    %eax,%edx
  800d3b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800d3f:	75 17                	jne    800d58 <__umoddi3+0x48>
  800d41:	39 fe                	cmp    %edi,%esi
  800d43:	76 4b                	jbe    800d90 <__umoddi3+0x80>
  800d45:	89 c8                	mov    %ecx,%eax
  800d47:	89 fa                	mov    %edi,%edx
  800d49:	f7 f6                	div    %esi
  800d4b:	89 d0                	mov    %edx,%eax
  800d4d:	31 d2                	xor    %edx,%edx
  800d4f:	83 c4 14             	add    $0x14,%esp
  800d52:	5e                   	pop    %esi
  800d53:	5f                   	pop    %edi
  800d54:	5d                   	pop    %ebp
  800d55:	c3                   	ret    
  800d56:	66 90                	xchg   %ax,%ax
  800d58:	39 f8                	cmp    %edi,%eax
  800d5a:	77 54                	ja     800db0 <__umoddi3+0xa0>
  800d5c:	0f bd e8             	bsr    %eax,%ebp
  800d5f:	83 f5 1f             	xor    $0x1f,%ebp
  800d62:	75 5c                	jne    800dc0 <__umoddi3+0xb0>
  800d64:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800d68:	39 3c 24             	cmp    %edi,(%esp)
  800d6b:	0f 87 e7 00 00 00    	ja     800e58 <__umoddi3+0x148>
  800d71:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800d75:	29 f1                	sub    %esi,%ecx
  800d77:	19 c7                	sbb    %eax,%edi
  800d79:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d7d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800d81:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d85:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d89:	83 c4 14             	add    $0x14,%esp
  800d8c:	5e                   	pop    %esi
  800d8d:	5f                   	pop    %edi
  800d8e:	5d                   	pop    %ebp
  800d8f:	c3                   	ret    
  800d90:	85 f6                	test   %esi,%esi
  800d92:	89 f5                	mov    %esi,%ebp
  800d94:	75 0b                	jne    800da1 <__umoddi3+0x91>
  800d96:	b8 01 00 00 00       	mov    $0x1,%eax
  800d9b:	31 d2                	xor    %edx,%edx
  800d9d:	f7 f6                	div    %esi
  800d9f:	89 c5                	mov    %eax,%ebp
  800da1:	8b 44 24 04          	mov    0x4(%esp),%eax
  800da5:	31 d2                	xor    %edx,%edx
  800da7:	f7 f5                	div    %ebp
  800da9:	89 c8                	mov    %ecx,%eax
  800dab:	f7 f5                	div    %ebp
  800dad:	eb 9c                	jmp    800d4b <__umoddi3+0x3b>
  800daf:	90                   	nop
  800db0:	89 c8                	mov    %ecx,%eax
  800db2:	89 fa                	mov    %edi,%edx
  800db4:	83 c4 14             	add    $0x14,%esp
  800db7:	5e                   	pop    %esi
  800db8:	5f                   	pop    %edi
  800db9:	5d                   	pop    %ebp
  800dba:	c3                   	ret    
  800dbb:	90                   	nop
  800dbc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800dc0:	8b 04 24             	mov    (%esp),%eax
  800dc3:	be 20 00 00 00       	mov    $0x20,%esi
  800dc8:	89 e9                	mov    %ebp,%ecx
  800dca:	29 ee                	sub    %ebp,%esi
  800dcc:	d3 e2                	shl    %cl,%edx
  800dce:	89 f1                	mov    %esi,%ecx
  800dd0:	d3 e8                	shr    %cl,%eax
  800dd2:	89 e9                	mov    %ebp,%ecx
  800dd4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800dd8:	8b 04 24             	mov    (%esp),%eax
  800ddb:	09 54 24 04          	or     %edx,0x4(%esp)
  800ddf:	89 fa                	mov    %edi,%edx
  800de1:	d3 e0                	shl    %cl,%eax
  800de3:	89 f1                	mov    %esi,%ecx
  800de5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800de9:	8b 44 24 10          	mov    0x10(%esp),%eax
  800ded:	d3 ea                	shr    %cl,%edx
  800def:	89 e9                	mov    %ebp,%ecx
  800df1:	d3 e7                	shl    %cl,%edi
  800df3:	89 f1                	mov    %esi,%ecx
  800df5:	d3 e8                	shr    %cl,%eax
  800df7:	89 e9                	mov    %ebp,%ecx
  800df9:	09 f8                	or     %edi,%eax
  800dfb:	8b 7c 24 10          	mov    0x10(%esp),%edi
  800dff:	f7 74 24 04          	divl   0x4(%esp)
  800e03:	d3 e7                	shl    %cl,%edi
  800e05:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e09:	89 d7                	mov    %edx,%edi
  800e0b:	f7 64 24 08          	mull   0x8(%esp)
  800e0f:	39 d7                	cmp    %edx,%edi
  800e11:	89 c1                	mov    %eax,%ecx
  800e13:	89 14 24             	mov    %edx,(%esp)
  800e16:	72 2c                	jb     800e44 <__umoddi3+0x134>
  800e18:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  800e1c:	72 22                	jb     800e40 <__umoddi3+0x130>
  800e1e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800e22:	29 c8                	sub    %ecx,%eax
  800e24:	19 d7                	sbb    %edx,%edi
  800e26:	89 e9                	mov    %ebp,%ecx
  800e28:	89 fa                	mov    %edi,%edx
  800e2a:	d3 e8                	shr    %cl,%eax
  800e2c:	89 f1                	mov    %esi,%ecx
  800e2e:	d3 e2                	shl    %cl,%edx
  800e30:	89 e9                	mov    %ebp,%ecx
  800e32:	d3 ef                	shr    %cl,%edi
  800e34:	09 d0                	or     %edx,%eax
  800e36:	89 fa                	mov    %edi,%edx
  800e38:	83 c4 14             	add    $0x14,%esp
  800e3b:	5e                   	pop    %esi
  800e3c:	5f                   	pop    %edi
  800e3d:	5d                   	pop    %ebp
  800e3e:	c3                   	ret    
  800e3f:	90                   	nop
  800e40:	39 d7                	cmp    %edx,%edi
  800e42:	75 da                	jne    800e1e <__umoddi3+0x10e>
  800e44:	8b 14 24             	mov    (%esp),%edx
  800e47:	89 c1                	mov    %eax,%ecx
  800e49:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  800e4d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  800e51:	eb cb                	jmp    800e1e <__umoddi3+0x10e>
  800e53:	90                   	nop
  800e54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e58:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  800e5c:	0f 82 0f ff ff ff    	jb     800d71 <__umoddi3+0x61>
  800e62:	e9 1a ff ff ff       	jmp    800d81 <__umoddi3+0x71>
