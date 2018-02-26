
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 20 19 10 f0 	movl   $0xf0101920,(%esp)
f0100055:	e8 d7 08 00 00       	call   f0100931 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 18 07 00 00       	call   f010079f <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 3c 19 10 f0 	movl   $0xf010193c,(%esp)
f0100092:	e8 9a 08 00 00       	call   f0100931 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 c2 13 00 00       	call   f0101487 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a5 04 00 00       	call   f010056f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 57 19 10 f0 	movl   $0xf0101957,(%esp)
f01000d9:	e8 53 08 00 00       	call   f0100931 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 b3 06 00 00       	call   f01007a9 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 72 19 10 f0 	movl   $0xf0101972,(%esp)
f010012c:	e8 00 08 00 00       	call   f0100931 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 c1 07 00 00       	call   f01008fe <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 ae 19 10 f0 	movl   $0xf01019ae,(%esp)
f0100144:	e8 e8 07 00 00       	call   f0100931 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 54 06 00 00       	call   f01007a9 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 8a 19 10 f0 	movl   $0xf010198a,(%esp)
f0100176:	e8 b6 07 00 00       	call   f0100931 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 74 07 00 00       	call   f01008fe <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 ae 19 10 f0 	movl   $0xf01019ae,(%esp)
f0100191:	e8 9b 07 00 00       	call   f0100931 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 24 25 11 f0    	mov    %ecx,0xf0112524
f01001d9:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 f7 00 00 00    	je     f0100305 <kbd_proc_data+0x105>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010020e:	a8 20                	test   $0x20,%al
f0100210:	0f 85 f5 00 00 00    	jne    f010030b <kbd_proc_data+0x10b>
f0100216:	b2 60                	mov    $0x60,%dl
f0100218:	ec                   	in     (%dx),%al
f0100219:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010021b:	3c e0                	cmp    $0xe0,%al
f010021d:	75 0d                	jne    f010022c <kbd_proc_data+0x2c>
		// E0 escape character
		shift |= E0ESC;
f010021f:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100226:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010022b:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010022c:	55                   	push   %ebp
f010022d:	89 e5                	mov    %esp,%ebp
f010022f:	53                   	push   %ebx
f0100230:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100233:	84 c0                	test   %al,%al
f0100235:	79 37                	jns    f010026e <kbd_proc_data+0x6e>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100237:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010023d:	89 cb                	mov    %ecx,%ebx
f010023f:	83 e3 40             	and    $0x40,%ebx
f0100242:	83 e0 7f             	and    $0x7f,%eax
f0100245:	85 db                	test   %ebx,%ebx
f0100247:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010024a:	0f b6 d2             	movzbl %dl,%edx
f010024d:	0f b6 82 00 1b 10 f0 	movzbl -0xfefe500(%edx),%eax
f0100254:	83 c8 40             	or     $0x40,%eax
f0100257:	0f b6 c0             	movzbl %al,%eax
f010025a:	f7 d0                	not    %eax
f010025c:	21 c1                	and    %eax,%ecx
f010025e:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
		return 0;
f0100264:	b8 00 00 00 00       	mov    $0x0,%eax
f0100269:	e9 a3 00 00 00       	jmp    f0100311 <kbd_proc_data+0x111>
	} else if (shift & E0ESC) {
f010026e:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100274:	f6 c1 40             	test   $0x40,%cl
f0100277:	74 0e                	je     f0100287 <kbd_proc_data+0x87>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100279:	83 c8 80             	or     $0xffffff80,%eax
f010027c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010027e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100281:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100287:	0f b6 d2             	movzbl %dl,%edx
f010028a:	0f b6 82 00 1b 10 f0 	movzbl -0xfefe500(%edx),%eax
f0100291:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f0100297:	0f b6 8a 00 1a 10 f0 	movzbl -0xfefe600(%edx),%ecx
f010029e:	31 c8                	xor    %ecx,%eax
f01002a0:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f01002a5:	89 c1                	mov    %eax,%ecx
f01002a7:	83 e1 03             	and    $0x3,%ecx
f01002aa:	8b 0c 8d e0 19 10 f0 	mov    -0xfefe620(,%ecx,4),%ecx
f01002b1:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002b5:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b8:	a8 08                	test   $0x8,%al
f01002ba:	74 1b                	je     f01002d7 <kbd_proc_data+0xd7>
		if ('a' <= c && c <= 'z')
f01002bc:	89 da                	mov    %ebx,%edx
f01002be:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002c1:	83 f9 19             	cmp    $0x19,%ecx
f01002c4:	77 05                	ja     f01002cb <kbd_proc_data+0xcb>
			c += 'A' - 'a';
f01002c6:	83 eb 20             	sub    $0x20,%ebx
f01002c9:	eb 0c                	jmp    f01002d7 <kbd_proc_data+0xd7>
		else if ('A' <= c && c <= 'Z')
f01002cb:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002ce:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002d1:	83 fa 19             	cmp    $0x19,%edx
f01002d4:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d7:	f7 d0                	not    %eax
f01002d9:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002db:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002dd:	f6 c2 06             	test   $0x6,%dl
f01002e0:	75 2f                	jne    f0100311 <kbd_proc_data+0x111>
f01002e2:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e8:	75 27                	jne    f0100311 <kbd_proc_data+0x111>
		cprintf("Rebooting!\n");
f01002ea:	c7 04 24 a4 19 10 f0 	movl   $0xf01019a4,(%esp)
f01002f1:	e8 3b 06 00 00       	call   f0100931 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002f6:	ba 92 00 00 00       	mov    $0x92,%edx
f01002fb:	b8 03 00 00 00       	mov    $0x3,%eax
f0100300:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100301:	89 d8                	mov    %ebx,%eax
f0100303:	eb 0c                	jmp    f0100311 <kbd_proc_data+0x111>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100305:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010030a:	c3                   	ret    
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010030b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100310:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100311:	83 c4 14             	add    $0x14,%esp
f0100314:	5b                   	pop    %ebx
f0100315:	5d                   	pop    %ebp
f0100316:	c3                   	ret    

f0100317 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100317:	55                   	push   %ebp
f0100318:	89 e5                	mov    %esp,%ebp
f010031a:	57                   	push   %edi
f010031b:	56                   	push   %esi
f010031c:	53                   	push   %ebx
f010031d:	83 ec 1c             	sub    $0x1c,%esp
f0100320:	89 c7                	mov    %eax,%edi
f0100322:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100327:	be fd 03 00 00       	mov    $0x3fd,%esi
f010032c:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100331:	eb 06                	jmp    f0100339 <cons_putc+0x22>
f0100333:	89 ca                	mov    %ecx,%edx
f0100335:	ec                   	in     (%dx),%al
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	89 f2                	mov    %esi,%edx
f010033b:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010033c:	a8 20                	test   $0x20,%al
f010033e:	75 05                	jne    f0100345 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100340:	83 eb 01             	sub    $0x1,%ebx
f0100343:	75 ee                	jne    f0100333 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100345:	89 f8                	mov    %edi,%eax
f0100347:	0f b6 c0             	movzbl %al,%eax
f010034a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100352:	ee                   	out    %al,(%dx)
f0100353:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100358:	be 79 03 00 00       	mov    $0x379,%esi
f010035d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100362:	eb 06                	jmp    f010036a <cons_putc+0x53>
f0100364:	89 ca                	mov    %ecx,%edx
f0100366:	ec                   	in     (%dx),%al
f0100367:	ec                   	in     (%dx),%al
f0100368:	ec                   	in     (%dx),%al
f0100369:	ec                   	in     (%dx),%al
f010036a:	89 f2                	mov    %esi,%edx
f010036c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010036d:	84 c0                	test   %al,%al
f010036f:	78 05                	js     f0100376 <cons_putc+0x5f>
f0100371:	83 eb 01             	sub    $0x1,%ebx
f0100374:	75 ee                	jne    f0100364 <cons_putc+0x4d>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100376:	ba 78 03 00 00       	mov    $0x378,%edx
f010037b:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010037f:	ee                   	out    %al,(%dx)
f0100380:	b2 7a                	mov    $0x7a,%dl
f0100382:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100387:	ee                   	out    %al,(%dx)
f0100388:	b8 08 00 00 00       	mov    $0x8,%eax
f010038d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010038e:	89 fa                	mov    %edi,%edx
f0100390:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100396:	89 f8                	mov    %edi,%eax
f0100398:	80 cc 07             	or     $0x7,%ah
f010039b:	85 d2                	test   %edx,%edx
f010039d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01003a0:	89 f8                	mov    %edi,%eax
f01003a2:	0f b6 c0             	movzbl %al,%eax
f01003a5:	83 f8 09             	cmp    $0x9,%eax
f01003a8:	74 78                	je     f0100422 <cons_putc+0x10b>
f01003aa:	83 f8 09             	cmp    $0x9,%eax
f01003ad:	7f 0a                	jg     f01003b9 <cons_putc+0xa2>
f01003af:	83 f8 08             	cmp    $0x8,%eax
f01003b2:	74 18                	je     f01003cc <cons_putc+0xb5>
f01003b4:	e9 9d 00 00 00       	jmp    f0100456 <cons_putc+0x13f>
f01003b9:	83 f8 0a             	cmp    $0xa,%eax
f01003bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01003c0:	74 3a                	je     f01003fc <cons_putc+0xe5>
f01003c2:	83 f8 0d             	cmp    $0xd,%eax
f01003c5:	74 3d                	je     f0100404 <cons_putc+0xed>
f01003c7:	e9 8a 00 00 00       	jmp    f0100456 <cons_putc+0x13f>
	case '\b':
		if (crt_pos > 0) {
f01003cc:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003d3:	66 85 c0             	test   %ax,%ax
f01003d6:	0f 84 e5 00 00 00    	je     f01004c1 <cons_putc+0x1aa>
			crt_pos--;
f01003dc:	83 e8 01             	sub    $0x1,%eax
f01003df:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003e5:	0f b7 c0             	movzwl %ax,%eax
f01003e8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003ed:	83 cf 20             	or     $0x20,%edi
f01003f0:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003f6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003fa:	eb 78                	jmp    f0100474 <cons_putc+0x15d>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003fc:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f0100403:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100404:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010040b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100411:	c1 e8 16             	shr    $0x16,%eax
f0100414:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100417:	c1 e0 04             	shl    $0x4,%eax
f010041a:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100420:	eb 52                	jmp    f0100474 <cons_putc+0x15d>
		break;
	case '\t':
		cons_putc(' ');
f0100422:	b8 20 00 00 00       	mov    $0x20,%eax
f0100427:	e8 eb fe ff ff       	call   f0100317 <cons_putc>
		cons_putc(' ');
f010042c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100431:	e8 e1 fe ff ff       	call   f0100317 <cons_putc>
		cons_putc(' ');
f0100436:	b8 20 00 00 00       	mov    $0x20,%eax
f010043b:	e8 d7 fe ff ff       	call   f0100317 <cons_putc>
		cons_putc(' ');
f0100440:	b8 20 00 00 00       	mov    $0x20,%eax
f0100445:	e8 cd fe ff ff       	call   f0100317 <cons_putc>
		cons_putc(' ');
f010044a:	b8 20 00 00 00       	mov    $0x20,%eax
f010044f:	e8 c3 fe ff ff       	call   f0100317 <cons_putc>
f0100454:	eb 1e                	jmp    f0100474 <cons_putc+0x15d>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100456:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010045d:	8d 50 01             	lea    0x1(%eax),%edx
f0100460:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100467:	0f b7 c0             	movzwl %ax,%eax
f010046a:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100470:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100474:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010047b:	cf 07 
f010047d:	76 42                	jbe    f01004c1 <cons_putc+0x1aa>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010047f:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100484:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010048b:	00 
f010048c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100492:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100496:	89 04 24             	mov    %eax,(%esp)
f0100499:	e8 36 10 00 00       	call   f01014d4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010049e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004a4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01004a9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004af:	83 c0 01             	add    $0x1,%eax
f01004b2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004b7:	75 f0                	jne    f01004a9 <cons_putc+0x192>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004b9:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004c0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004c1:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004c7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004cc:	89 ca                	mov    %ecx,%edx
f01004ce:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004cf:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004d6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004d9:	89 d8                	mov    %ebx,%eax
f01004db:	66 c1 e8 08          	shr    $0x8,%ax
f01004df:	89 f2                	mov    %esi,%edx
f01004e1:	ee                   	out    %al,(%dx)
f01004e2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004e7:	89 ca                	mov    %ecx,%edx
f01004e9:	ee                   	out    %al,(%dx)
f01004ea:	89 d8                	mov    %ebx,%eax
f01004ec:	89 f2                	mov    %esi,%edx
f01004ee:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004ef:	83 c4 1c             	add    $0x1c,%esp
f01004f2:	5b                   	pop    %ebx
f01004f3:	5e                   	pop    %esi
f01004f4:	5f                   	pop    %edi
f01004f5:	5d                   	pop    %ebp
f01004f6:	c3                   	ret    

f01004f7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004f7:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004fe:	74 11                	je     f0100511 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100500:	55                   	push   %ebp
f0100501:	89 e5                	mov    %esp,%ebp
f0100503:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100506:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f010050b:	e8 ac fc ff ff       	call   f01001bc <cons_intr>
}
f0100510:	c9                   	leave  
f0100511:	f3 c3                	repz ret 

f0100513 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100513:	55                   	push   %ebp
f0100514:	89 e5                	mov    %esp,%ebp
f0100516:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100519:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010051e:	e8 99 fc ff ff       	call   f01001bc <cons_intr>
}
f0100523:	c9                   	leave  
f0100524:	c3                   	ret    

f0100525 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100525:	55                   	push   %ebp
f0100526:	89 e5                	mov    %esp,%ebp
f0100528:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010052b:	e8 c7 ff ff ff       	call   f01004f7 <serial_intr>
	kbd_intr();
f0100530:	e8 de ff ff ff       	call   f0100513 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100535:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010053a:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100540:	74 26                	je     f0100568 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100542:	8d 50 01             	lea    0x1(%eax),%edx
f0100545:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010054b:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100552:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100554:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010055a:	75 11                	jne    f010056d <cons_getc+0x48>
			cons.rpos = 0;
f010055c:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100563:	00 00 00 
f0100566:	eb 05                	jmp    f010056d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100568:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010056d:	c9                   	leave  
f010056e:	c3                   	ret    

f010056f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010056f:	55                   	push   %ebp
f0100570:	89 e5                	mov    %esp,%ebp
f0100572:	57                   	push   %edi
f0100573:	56                   	push   %esi
f0100574:	53                   	push   %ebx
f0100575:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100578:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010057f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100586:	5a a5 
	if (*cp != 0xA55A) {
f0100588:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010058f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100593:	74 11                	je     f01005a6 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100595:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010059c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010059f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01005a4:	eb 16                	jmp    f01005bc <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005a6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005ad:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005b4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005bc:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01005c2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c7:	89 ca                	mov    %ecx,%edx
f01005c9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ca:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cd:	89 da                	mov    %ebx,%edx
f01005cf:	ec                   	in     (%dx),%al
f01005d0:	0f b6 f0             	movzbl %al,%esi
f01005d3:	c1 e6 08             	shl    $0x8,%esi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005db:	89 ca                	mov    %ecx,%edx
f01005dd:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005de:	89 da                	mov    %ebx,%edx
f01005e0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005e1:	89 3d 2c 25 11 f0    	mov    %edi,0xf011252c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005e7:	0f b6 d8             	movzbl %al,%ebx
f01005ea:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005ec:	66 89 35 28 25 11 f0 	mov    %si,0xf0112528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005f3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005fd:	89 f2                	mov    %esi,%edx
f01005ff:	ee                   	out    %al,(%dx)
f0100600:	b2 fb                	mov    $0xfb,%dl
f0100602:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100607:	ee                   	out    %al,(%dx)
f0100608:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010060d:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100612:	89 da                	mov    %ebx,%edx
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 f9                	mov    $0xf9,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 fb                	mov    $0xfb,%dl
f010061f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100624:	ee                   	out    %al,(%dx)
f0100625:	b2 fc                	mov    $0xfc,%dl
f0100627:	b8 00 00 00 00       	mov    $0x0,%eax
f010062c:	ee                   	out    %al,(%dx)
f010062d:	b2 f9                	mov    $0xf9,%dl
f010062f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100634:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100635:	b2 fd                	mov    $0xfd,%dl
f0100637:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100638:	3c ff                	cmp    $0xff,%al
f010063a:	0f 95 c1             	setne  %cl
f010063d:	88 0d 34 25 11 f0    	mov    %cl,0xf0112534
f0100643:	89 f2                	mov    %esi,%edx
f0100645:	ec                   	in     (%dx),%al
f0100646:	89 da                	mov    %ebx,%edx
f0100648:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100649:	84 c9                	test   %cl,%cl
f010064b:	75 0c                	jne    f0100659 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010064d:	c7 04 24 b0 19 10 f0 	movl   $0xf01019b0,(%esp)
f0100654:	e8 d8 02 00 00       	call   f0100931 <cprintf>
}
f0100659:	83 c4 1c             	add    $0x1c,%esp
f010065c:	5b                   	pop    %ebx
f010065d:	5e                   	pop    %esi
f010065e:	5f                   	pop    %edi
f010065f:	5d                   	pop    %ebp
f0100660:	c3                   	ret    

f0100661 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100667:	8b 45 08             	mov    0x8(%ebp),%eax
f010066a:	e8 a8 fc ff ff       	call   f0100317 <cons_putc>
}
f010066f:	c9                   	leave  
f0100670:	c3                   	ret    

f0100671 <getchar>:

int
getchar(void)
{
f0100671:	55                   	push   %ebp
f0100672:	89 e5                	mov    %esp,%ebp
f0100674:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100677:	e8 a9 fe ff ff       	call   f0100525 <cons_getc>
f010067c:	85 c0                	test   %eax,%eax
f010067e:	74 f7                	je     f0100677 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100680:	c9                   	leave  
f0100681:	c3                   	ret    

f0100682 <iscons>:

int
iscons(int fdnum)
{
f0100682:	55                   	push   %ebp
f0100683:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100685:	b8 01 00 00 00       	mov    $0x1,%eax
f010068a:	5d                   	pop    %ebp
f010068b:	c3                   	ret    
f010068c:	66 90                	xchg   %ax,%ax
f010068e:	66 90                	xchg   %ax,%ax

f0100690 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100696:	c7 44 24 08 00 1c 10 	movl   $0xf0101c00,0x8(%esp)
f010069d:	f0 
f010069e:	c7 44 24 04 1e 1c 10 	movl   $0xf0101c1e,0x4(%esp)
f01006a5:	f0 
f01006a6:	c7 04 24 23 1c 10 f0 	movl   $0xf0101c23,(%esp)
f01006ad:	e8 7f 02 00 00       	call   f0100931 <cprintf>
f01006b2:	c7 44 24 08 8c 1c 10 	movl   $0xf0101c8c,0x8(%esp)
f01006b9:	f0 
f01006ba:	c7 44 24 04 2c 1c 10 	movl   $0xf0101c2c,0x4(%esp)
f01006c1:	f0 
f01006c2:	c7 04 24 23 1c 10 f0 	movl   $0xf0101c23,(%esp)
f01006c9:	e8 63 02 00 00       	call   f0100931 <cprintf>
	return 0;
}
f01006ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d3:	c9                   	leave  
f01006d4:	c3                   	ret    

f01006d5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006d5:	55                   	push   %ebp
f01006d6:	89 e5                	mov    %esp,%ebp
f01006d8:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006db:	c7 04 24 35 1c 10 f0 	movl   $0xf0101c35,(%esp)
f01006e2:	e8 4a 02 00 00       	call   f0100931 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006e7:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006ee:	00 
f01006ef:	c7 04 24 b4 1c 10 f0 	movl   $0xf0101cb4,(%esp)
f01006f6:	e8 36 02 00 00       	call   f0100931 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006fb:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100702:	00 
f0100703:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f010070a:	f0 
f010070b:	c7 04 24 dc 1c 10 f0 	movl   $0xf0101cdc,(%esp)
f0100712:	e8 1a 02 00 00       	call   f0100931 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100717:	c7 44 24 08 17 19 10 	movl   $0x101917,0x8(%esp)
f010071e:	00 
f010071f:	c7 44 24 04 17 19 10 	movl   $0xf0101917,0x4(%esp)
f0100726:	f0 
f0100727:	c7 04 24 00 1d 10 f0 	movl   $0xf0101d00,(%esp)
f010072e:	e8 fe 01 00 00       	call   f0100931 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100733:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f010073a:	00 
f010073b:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f0100742:	f0 
f0100743:	c7 04 24 24 1d 10 f0 	movl   $0xf0101d24,(%esp)
f010074a:	e8 e2 01 00 00       	call   f0100931 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010074f:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100756:	00 
f0100757:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010075e:	f0 
f010075f:	c7 04 24 48 1d 10 f0 	movl   $0xf0101d48,(%esp)
f0100766:	e8 c6 01 00 00       	call   f0100931 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010076b:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f0100770:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100775:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010077a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100780:	85 c0                	test   %eax,%eax
f0100782:	0f 48 c2             	cmovs  %edx,%eax
f0100785:	c1 f8 0a             	sar    $0xa,%eax
f0100788:	89 44 24 04          	mov    %eax,0x4(%esp)
f010078c:	c7 04 24 6c 1d 10 f0 	movl   $0xf0101d6c,(%esp)
f0100793:	e8 99 01 00 00       	call   f0100931 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100798:	b8 00 00 00 00       	mov    $0x0,%eax
f010079d:	c9                   	leave  
f010079e:	c3                   	ret    

f010079f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010079f:	55                   	push   %ebp
f01007a0:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f01007a2:	b8 00 00 00 00       	mov    $0x0,%eax
f01007a7:	5d                   	pop    %ebp
f01007a8:	c3                   	ret    

f01007a9 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007a9:	55                   	push   %ebp
f01007aa:	89 e5                	mov    %esp,%ebp
f01007ac:	57                   	push   %edi
f01007ad:	56                   	push   %esi
f01007ae:	53                   	push   %ebx
f01007af:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007b2:	c7 04 24 98 1d 10 f0 	movl   $0xf0101d98,(%esp)
f01007b9:	e8 73 01 00 00       	call   f0100931 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007be:	c7 04 24 bc 1d 10 f0 	movl   $0xf0101dbc,(%esp)
f01007c5:	e8 67 01 00 00       	call   f0100931 <cprintf>


	while (1) {
		buf = readline("K> ");
f01007ca:	c7 04 24 4e 1c 10 f0 	movl   $0xf0101c4e,(%esp)
f01007d1:	e8 5a 0a 00 00       	call   f0101230 <readline>
f01007d6:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007d8:	85 c0                	test   %eax,%eax
f01007da:	74 ee                	je     f01007ca <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007dc:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007e3:	be 00 00 00 00       	mov    $0x0,%esi
f01007e8:	eb 0a                	jmp    f01007f4 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007ea:	c6 03 00             	movb   $0x0,(%ebx)
f01007ed:	89 f7                	mov    %esi,%edi
f01007ef:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007f2:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007f4:	0f b6 03             	movzbl (%ebx),%eax
f01007f7:	84 c0                	test   %al,%al
f01007f9:	74 63                	je     f010085e <monitor+0xb5>
f01007fb:	0f be c0             	movsbl %al,%eax
f01007fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100802:	c7 04 24 52 1c 10 f0 	movl   $0xf0101c52,(%esp)
f0100809:	e8 3c 0c 00 00       	call   f010144a <strchr>
f010080e:	85 c0                	test   %eax,%eax
f0100810:	75 d8                	jne    f01007ea <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100812:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100815:	74 47                	je     f010085e <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100817:	83 fe 0f             	cmp    $0xf,%esi
f010081a:	75 16                	jne    f0100832 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010081c:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100823:	00 
f0100824:	c7 04 24 57 1c 10 f0 	movl   $0xf0101c57,(%esp)
f010082b:	e8 01 01 00 00       	call   f0100931 <cprintf>
f0100830:	eb 98                	jmp    f01007ca <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100832:	8d 7e 01             	lea    0x1(%esi),%edi
f0100835:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100839:	eb 03                	jmp    f010083e <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010083b:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010083e:	0f b6 03             	movzbl (%ebx),%eax
f0100841:	84 c0                	test   %al,%al
f0100843:	74 ad                	je     f01007f2 <monitor+0x49>
f0100845:	0f be c0             	movsbl %al,%eax
f0100848:	89 44 24 04          	mov    %eax,0x4(%esp)
f010084c:	c7 04 24 52 1c 10 f0 	movl   $0xf0101c52,(%esp)
f0100853:	e8 f2 0b 00 00       	call   f010144a <strchr>
f0100858:	85 c0                	test   %eax,%eax
f010085a:	74 df                	je     f010083b <monitor+0x92>
f010085c:	eb 94                	jmp    f01007f2 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f010085e:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100865:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100866:	85 f6                	test   %esi,%esi
f0100868:	0f 84 5c ff ff ff    	je     f01007ca <monitor+0x21>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010086e:	c7 44 24 04 1e 1c 10 	movl   $0xf0101c1e,0x4(%esp)
f0100875:	f0 
f0100876:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100879:	89 04 24             	mov    %eax,(%esp)
f010087c:	e8 6b 0b 00 00       	call   f01013ec <strcmp>
f0100881:	85 c0                	test   %eax,%eax
f0100883:	74 1b                	je     f01008a0 <monitor+0xf7>
f0100885:	c7 44 24 04 2c 1c 10 	movl   $0xf0101c2c,0x4(%esp)
f010088c:	f0 
f010088d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100890:	89 04 24             	mov    %eax,(%esp)
f0100893:	e8 54 0b 00 00       	call   f01013ec <strcmp>
f0100898:	85 c0                	test   %eax,%eax
f010089a:	75 2f                	jne    f01008cb <monitor+0x122>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010089c:	b0 01                	mov    $0x1,%al
f010089e:	eb 05                	jmp    f01008a5 <monitor+0xfc>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008a0:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008a5:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008a8:	01 d0                	add    %edx,%eax
f01008aa:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01008ad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01008b1:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008b4:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008b8:	89 34 24             	mov    %esi,(%esp)
f01008bb:	ff 14 85 ec 1d 10 f0 	call   *-0xfefe214(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008c2:	85 c0                	test   %eax,%eax
f01008c4:	78 1d                	js     f01008e3 <monitor+0x13a>
f01008c6:	e9 ff fe ff ff       	jmp    f01007ca <monitor+0x21>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008cb:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008ce:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d2:	c7 04 24 74 1c 10 f0 	movl   $0xf0101c74,(%esp)
f01008d9:	e8 53 00 00 00       	call   f0100931 <cprintf>
f01008de:	e9 e7 fe ff ff       	jmp    f01007ca <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008e3:	83 c4 5c             	add    $0x5c,%esp
f01008e6:	5b                   	pop    %ebx
f01008e7:	5e                   	pop    %esi
f01008e8:	5f                   	pop    %edi
f01008e9:	5d                   	pop    %ebp
f01008ea:	c3                   	ret    

f01008eb <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008eb:	55                   	push   %ebp
f01008ec:	89 e5                	mov    %esp,%ebp
f01008ee:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01008f1:	8b 45 08             	mov    0x8(%ebp),%eax
f01008f4:	89 04 24             	mov    %eax,(%esp)
f01008f7:	e8 65 fd ff ff       	call   f0100661 <cputchar>
	*cnt++;
}
f01008fc:	c9                   	leave  
f01008fd:	c3                   	ret    

f01008fe <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008fe:	55                   	push   %ebp
f01008ff:	89 e5                	mov    %esp,%ebp
f0100901:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100904:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010090b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010090e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100912:	8b 45 08             	mov    0x8(%ebp),%eax
f0100915:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100919:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010091c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100920:	c7 04 24 eb 08 10 f0 	movl   $0xf01008eb,(%esp)
f0100927:	e8 18 04 00 00       	call   f0100d44 <vprintfmt>
	return cnt;
}
f010092c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010092f:	c9                   	leave  
f0100930:	c3                   	ret    

f0100931 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100931:	55                   	push   %ebp
f0100932:	89 e5                	mov    %esp,%ebp
f0100934:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100937:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010093a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010093e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100941:	89 04 24             	mov    %eax,(%esp)
f0100944:	e8 b5 ff ff ff       	call   f01008fe <vcprintf>
	va_end(ap);

	return cnt;
}
f0100949:	c9                   	leave  
f010094a:	c3                   	ret    

f010094b <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010094b:	55                   	push   %ebp
f010094c:	89 e5                	mov    %esp,%ebp
f010094e:	57                   	push   %edi
f010094f:	56                   	push   %esi
f0100950:	53                   	push   %ebx
f0100951:	83 ec 10             	sub    $0x10,%esp
f0100954:	89 c6                	mov    %eax,%esi
f0100956:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100959:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010095c:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010095f:	8b 1a                	mov    (%edx),%ebx
f0100961:	8b 01                	mov    (%ecx),%eax
f0100963:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100966:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f010096d:	eb 77                	jmp    f01009e6 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f010096f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100972:	01 d8                	add    %ebx,%eax
f0100974:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100979:	99                   	cltd   
f010097a:	f7 f9                	idiv   %ecx
f010097c:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010097e:	eb 01                	jmp    f0100981 <stab_binsearch+0x36>
			m--;
f0100980:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100981:	39 d9                	cmp    %ebx,%ecx
f0100983:	7c 1d                	jl     f01009a2 <stab_binsearch+0x57>
f0100985:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100988:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f010098d:	39 fa                	cmp    %edi,%edx
f010098f:	75 ef                	jne    f0100980 <stab_binsearch+0x35>
f0100991:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100994:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100997:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f010099b:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010099e:	73 18                	jae    f01009b8 <stab_binsearch+0x6d>
f01009a0:	eb 05                	jmp    f01009a7 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009a2:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f01009a5:	eb 3f                	jmp    f01009e6 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01009a7:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01009aa:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f01009ac:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009af:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009b6:	eb 2e                	jmp    f01009e6 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009b8:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009bb:	73 15                	jae    f01009d2 <stab_binsearch+0x87>
			*region_right = m - 1;
f01009bd:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01009c0:	48                   	dec    %eax
f01009c1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009c4:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009c7:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009c9:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009d0:	eb 14                	jmp    f01009e6 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009d2:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01009d5:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f01009d8:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f01009da:	ff 45 0c             	incl   0xc(%ebp)
f01009dd:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009df:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01009e6:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01009e9:	7e 84                	jle    f010096f <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01009eb:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01009ef:	75 0d                	jne    f01009fe <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f01009f1:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01009f4:	8b 00                	mov    (%eax),%eax
f01009f6:	48                   	dec    %eax
f01009f7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01009fa:	89 07                	mov    %eax,(%edi)
f01009fc:	eb 22                	jmp    f0100a20 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009fe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a01:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a03:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a06:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a08:	eb 01                	jmp    f0100a0b <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a0a:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a0b:	39 c1                	cmp    %eax,%ecx
f0100a0d:	7d 0c                	jge    f0100a1b <stab_binsearch+0xd0>
f0100a0f:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100a12:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a17:	39 fa                	cmp    %edi,%edx
f0100a19:	75 ef                	jne    f0100a0a <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a1b:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100a1e:	89 07                	mov    %eax,(%edi)
	}
}
f0100a20:	83 c4 10             	add    $0x10,%esp
f0100a23:	5b                   	pop    %ebx
f0100a24:	5e                   	pop    %esi
f0100a25:	5f                   	pop    %edi
f0100a26:	5d                   	pop    %ebp
f0100a27:	c3                   	ret    

f0100a28 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a28:	55                   	push   %ebp
f0100a29:	89 e5                	mov    %esp,%ebp
f0100a2b:	57                   	push   %edi
f0100a2c:	56                   	push   %esi
f0100a2d:	53                   	push   %ebx
f0100a2e:	83 ec 2c             	sub    $0x2c,%esp
f0100a31:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a34:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a37:	c7 03 fc 1d 10 f0    	movl   $0xf0101dfc,(%ebx)
	info->eip_line = 0;
f0100a3d:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a44:	c7 43 08 fc 1d 10 f0 	movl   $0xf0101dfc,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100a4b:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100a52:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100a55:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a5c:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100a62:	76 12                	jbe    f0100a76 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a64:	b8 6b 71 10 f0       	mov    $0xf010716b,%eax
f0100a69:	3d bd 58 10 f0       	cmp    $0xf01058bd,%eax
f0100a6e:	0f 86 6b 01 00 00    	jbe    f0100bdf <debuginfo_eip+0x1b7>
f0100a74:	eb 1c                	jmp    f0100a92 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a76:	c7 44 24 08 06 1e 10 	movl   $0xf0101e06,0x8(%esp)
f0100a7d:	f0 
f0100a7e:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100a85:	00 
f0100a86:	c7 04 24 13 1e 10 f0 	movl   $0xf0101e13,(%esp)
f0100a8d:	e8 66 f6 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a92:	80 3d 6a 71 10 f0 00 	cmpb   $0x0,0xf010716a
f0100a99:	0f 85 47 01 00 00    	jne    f0100be6 <debuginfo_eip+0x1be>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a9f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100aa6:	b8 bc 58 10 f0       	mov    $0xf01058bc,%eax
f0100aab:	2d 34 20 10 f0       	sub    $0xf0102034,%eax
f0100ab0:	c1 f8 02             	sar    $0x2,%eax
f0100ab3:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100ab9:	83 e8 01             	sub    $0x1,%eax
f0100abc:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100abf:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ac3:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100aca:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100acd:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ad0:	b8 34 20 10 f0       	mov    $0xf0102034,%eax
f0100ad5:	e8 71 fe ff ff       	call   f010094b <stab_binsearch>
	if (lfile == 0)
f0100ada:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100add:	85 c0                	test   %eax,%eax
f0100adf:	0f 84 08 01 00 00    	je     f0100bed <debuginfo_eip+0x1c5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100ae5:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100ae8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100aeb:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100aee:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100af2:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100af9:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100afc:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100aff:	b8 34 20 10 f0       	mov    $0xf0102034,%eax
f0100b04:	e8 42 fe ff ff       	call   f010094b <stab_binsearch>

	if (lfun <= rfun) {
f0100b09:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100b0c:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100b0f:	7f 2e                	jg     f0100b3f <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b11:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b14:	8d 90 34 20 10 f0    	lea    -0xfefdfcc(%eax),%edx
f0100b1a:	8b 80 34 20 10 f0    	mov    -0xfefdfcc(%eax),%eax
f0100b20:	b9 6b 71 10 f0       	mov    $0xf010716b,%ecx
f0100b25:	81 e9 bd 58 10 f0    	sub    $0xf01058bd,%ecx
f0100b2b:	39 c8                	cmp    %ecx,%eax
f0100b2d:	73 08                	jae    f0100b37 <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b2f:	05 bd 58 10 f0       	add    $0xf01058bd,%eax
f0100b34:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b37:	8b 42 08             	mov    0x8(%edx),%eax
f0100b3a:	89 43 10             	mov    %eax,0x10(%ebx)
f0100b3d:	eb 06                	jmp    f0100b45 <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b3f:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b42:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b45:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100b4c:	00 
f0100b4d:	8b 43 08             	mov    0x8(%ebx),%eax
f0100b50:	89 04 24             	mov    %eax,(%esp)
f0100b53:	e8 13 09 00 00       	call   f010146b <strfind>
f0100b58:	2b 43 08             	sub    0x8(%ebx),%eax
f0100b5b:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b5e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b61:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b64:	05 34 20 10 f0       	add    $0xf0102034,%eax
f0100b69:	eb 06                	jmp    f0100b71 <debuginfo_eip+0x149>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b6b:	83 ef 01             	sub    $0x1,%edi
f0100b6e:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b71:	39 cf                	cmp    %ecx,%edi
f0100b73:	7c 33                	jl     f0100ba8 <debuginfo_eip+0x180>
	       && stabs[lline].n_type != N_SOL
f0100b75:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100b79:	80 fa 84             	cmp    $0x84,%dl
f0100b7c:	74 0b                	je     f0100b89 <debuginfo_eip+0x161>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b7e:	80 fa 64             	cmp    $0x64,%dl
f0100b81:	75 e8                	jne    f0100b6b <debuginfo_eip+0x143>
f0100b83:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100b87:	74 e2                	je     f0100b6b <debuginfo_eip+0x143>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b89:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100b8c:	8b 87 34 20 10 f0    	mov    -0xfefdfcc(%edi),%eax
f0100b92:	ba 6b 71 10 f0       	mov    $0xf010716b,%edx
f0100b97:	81 ea bd 58 10 f0    	sub    $0xf01058bd,%edx
f0100b9d:	39 d0                	cmp    %edx,%eax
f0100b9f:	73 07                	jae    f0100ba8 <debuginfo_eip+0x180>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100ba1:	05 bd 58 10 f0       	add    $0xf01058bd,%eax
f0100ba6:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ba8:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100bab:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bae:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bb3:	39 f1                	cmp    %esi,%ecx
f0100bb5:	7d 42                	jge    f0100bf9 <debuginfo_eip+0x1d1>
		for (lline = lfun + 1;
f0100bb7:	8d 51 01             	lea    0x1(%ecx),%edx
f0100bba:	6b c1 0c             	imul   $0xc,%ecx,%eax
f0100bbd:	05 34 20 10 f0       	add    $0xf0102034,%eax
f0100bc2:	eb 07                	jmp    f0100bcb <debuginfo_eip+0x1a3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100bc4:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100bc8:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100bcb:	39 f2                	cmp    %esi,%edx
f0100bcd:	74 25                	je     f0100bf4 <debuginfo_eip+0x1cc>
f0100bcf:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bd2:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100bd6:	74 ec                	je     f0100bc4 <debuginfo_eip+0x19c>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bd8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bdd:	eb 1a                	jmp    f0100bf9 <debuginfo_eip+0x1d1>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100bdf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100be4:	eb 13                	jmp    f0100bf9 <debuginfo_eip+0x1d1>
f0100be6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100beb:	eb 0c                	jmp    f0100bf9 <debuginfo_eip+0x1d1>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100bed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bf2:	eb 05                	jmp    f0100bf9 <debuginfo_eip+0x1d1>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bf4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100bf9:	83 c4 2c             	add    $0x2c,%esp
f0100bfc:	5b                   	pop    %ebx
f0100bfd:	5e                   	pop    %esi
f0100bfe:	5f                   	pop    %edi
f0100bff:	5d                   	pop    %ebp
f0100c00:	c3                   	ret    
f0100c01:	66 90                	xchg   %ax,%ax
f0100c03:	66 90                	xchg   %ax,%ax
f0100c05:	66 90                	xchg   %ax,%ax
f0100c07:	66 90                	xchg   %ax,%ax
f0100c09:	66 90                	xchg   %ax,%ax
f0100c0b:	66 90                	xchg   %ax,%ax
f0100c0d:	66 90                	xchg   %ax,%ax
f0100c0f:	90                   	nop

f0100c10 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c10:	55                   	push   %ebp
f0100c11:	89 e5                	mov    %esp,%ebp
f0100c13:	57                   	push   %edi
f0100c14:	56                   	push   %esi
f0100c15:	53                   	push   %ebx
f0100c16:	83 ec 3c             	sub    $0x3c,%esp
f0100c19:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100c1c:	89 d7                	mov    %edx,%edi
f0100c1e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c21:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100c24:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c27:	89 c3                	mov    %eax,%ebx
f0100c29:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100c2c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100c2f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c32:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100c37:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c3a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100c3d:	39 d9                	cmp    %ebx,%ecx
f0100c3f:	72 05                	jb     f0100c46 <printnum+0x36>
f0100c41:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100c44:	77 69                	ja     f0100caf <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c46:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100c49:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100c4d:	83 ee 01             	sub    $0x1,%esi
f0100c50:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100c54:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100c58:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100c5c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100c60:	89 c3                	mov    %eax,%ebx
f0100c62:	89 d6                	mov    %edx,%esi
f0100c64:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100c67:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100c6a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100c6e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100c72:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c75:	89 04 24             	mov    %eax,(%esp)
f0100c78:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c7b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c7f:	e8 0c 0a 00 00       	call   f0101690 <__udivdi3>
f0100c84:	89 d9                	mov    %ebx,%ecx
f0100c86:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100c8a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100c8e:	89 04 24             	mov    %eax,(%esp)
f0100c91:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c95:	89 fa                	mov    %edi,%edx
f0100c97:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c9a:	e8 71 ff ff ff       	call   f0100c10 <printnum>
f0100c9f:	eb 1b                	jmp    f0100cbc <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100ca1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ca5:	8b 45 18             	mov    0x18(%ebp),%eax
f0100ca8:	89 04 24             	mov    %eax,(%esp)
f0100cab:	ff d3                	call   *%ebx
f0100cad:	eb 03                	jmp    f0100cb2 <printnum+0xa2>
f0100caf:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100cb2:	83 ee 01             	sub    $0x1,%esi
f0100cb5:	85 f6                	test   %esi,%esi
f0100cb7:	7f e8                	jg     f0100ca1 <printnum+0x91>
f0100cb9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100cbc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cc0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100cc4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100cc7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100cca:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cce:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100cd2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cd5:	89 04 24             	mov    %eax,(%esp)
f0100cd8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100cdb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cdf:	e8 dc 0a 00 00       	call   f01017c0 <__umoddi3>
f0100ce4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ce8:	0f be 80 21 1e 10 f0 	movsbl -0xfefe1df(%eax),%eax
f0100cef:	89 04 24             	mov    %eax,(%esp)
f0100cf2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cf5:	ff d0                	call   *%eax
}
f0100cf7:	83 c4 3c             	add    $0x3c,%esp
f0100cfa:	5b                   	pop    %ebx
f0100cfb:	5e                   	pop    %esi
f0100cfc:	5f                   	pop    %edi
f0100cfd:	5d                   	pop    %ebp
f0100cfe:	c3                   	ret    

f0100cff <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100cff:	55                   	push   %ebp
f0100d00:	89 e5                	mov    %esp,%ebp
f0100d02:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d05:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d09:	8b 10                	mov    (%eax),%edx
f0100d0b:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d0e:	73 0a                	jae    f0100d1a <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d10:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d13:	89 08                	mov    %ecx,(%eax)
f0100d15:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d18:	88 02                	mov    %al,(%edx)
}
f0100d1a:	5d                   	pop    %ebp
f0100d1b:	c3                   	ret    

f0100d1c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d1c:	55                   	push   %ebp
f0100d1d:	89 e5                	mov    %esp,%ebp
f0100d1f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d22:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d25:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d29:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d2c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d30:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d33:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d37:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d3a:	89 04 24             	mov    %eax,(%esp)
f0100d3d:	e8 02 00 00 00       	call   f0100d44 <vprintfmt>
	va_end(ap);
}
f0100d42:	c9                   	leave  
f0100d43:	c3                   	ret    

f0100d44 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d44:	55                   	push   %ebp
f0100d45:	89 e5                	mov    %esp,%ebp
f0100d47:	57                   	push   %edi
f0100d48:	56                   	push   %esi
f0100d49:	53                   	push   %ebx
f0100d4a:	83 ec 3c             	sub    $0x3c,%esp
f0100d4d:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d50:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d53:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100d56:	eb 11                	jmp    f0100d69 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100d58:	85 c0                	test   %eax,%eax
f0100d5a:	0f 84 48 04 00 00    	je     f01011a8 <vprintfmt+0x464>
				return;
			putch(ch, putdat);
f0100d60:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100d64:	89 04 24             	mov    %eax,(%esp)
f0100d67:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d69:	83 c7 01             	add    $0x1,%edi
f0100d6c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100d70:	83 f8 25             	cmp    $0x25,%eax
f0100d73:	75 e3                	jne    f0100d58 <vprintfmt+0x14>
f0100d75:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100d79:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100d80:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100d87:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100d8e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d93:	eb 1f                	jmp    f0100db4 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d95:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100d98:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100d9c:	eb 16                	jmp    f0100db4 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d9e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100da1:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100da5:	eb 0d                	jmp    f0100db4 <vprintfmt+0x70>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100da7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100daa:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100dad:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100db4:	8d 47 01             	lea    0x1(%edi),%eax
f0100db7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100dba:	0f b6 17             	movzbl (%edi),%edx
f0100dbd:	0f b6 c2             	movzbl %dl,%eax
f0100dc0:	83 ea 23             	sub    $0x23,%edx
f0100dc3:	80 fa 55             	cmp    $0x55,%dl
f0100dc6:	0f 87 bf 03 00 00    	ja     f010118b <vprintfmt+0x447>
f0100dcc:	0f b6 d2             	movzbl %dl,%edx
f0100dcf:	ff 24 95 b0 1e 10 f0 	jmp    *-0xfefe150(,%edx,4)
f0100dd6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100dd9:	ba 00 00 00 00       	mov    $0x0,%edx
f0100dde:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100de1:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100de4:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100de8:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0100deb:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100dee:	83 f9 09             	cmp    $0x9,%ecx
f0100df1:	77 3c                	ja     f0100e2f <vprintfmt+0xeb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100df3:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100df6:	eb e9                	jmp    f0100de1 <vprintfmt+0x9d>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100df8:	8b 45 14             	mov    0x14(%ebp),%eax
f0100dfb:	8b 00                	mov    (%eax),%eax
f0100dfd:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100e00:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e03:	8d 40 04             	lea    0x4(%eax),%eax
f0100e06:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e09:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e0c:	eb 27                	jmp    f0100e35 <vprintfmt+0xf1>
f0100e0e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100e11:	85 d2                	test   %edx,%edx
f0100e13:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e18:	0f 49 c2             	cmovns %edx,%eax
f0100e1b:	89 45 e0             	mov    %eax,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e1e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e21:	eb 91                	jmp    f0100db4 <vprintfmt+0x70>
f0100e23:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e26:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100e2d:	eb 85                	jmp    f0100db4 <vprintfmt+0x70>
f0100e2f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100e32:	89 55 d0             	mov    %edx,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100e35:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e39:	0f 89 75 ff ff ff    	jns    f0100db4 <vprintfmt+0x70>
f0100e3f:	e9 63 ff ff ff       	jmp    f0100da7 <vprintfmt+0x63>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e44:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e47:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e4a:	e9 65 ff ff ff       	jmp    f0100db4 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e4f:	8b 45 14             	mov    0x14(%ebp),%eax
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e52:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100e56:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e5a:	8b 00                	mov    (%eax),%eax
f0100e5c:	89 04 24             	mov    %eax,(%esp)
f0100e5f:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e61:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100e64:	e9 00 ff ff ff       	jmp    f0100d69 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e69:	8b 45 14             	mov    0x14(%ebp),%eax
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e6c:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100e70:	8b 00                	mov    (%eax),%eax
f0100e72:	99                   	cltd   
f0100e73:	31 d0                	xor    %edx,%eax
f0100e75:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100e77:	83 f8 06             	cmp    $0x6,%eax
f0100e7a:	7f 0b                	jg     f0100e87 <vprintfmt+0x143>
f0100e7c:	8b 14 85 08 20 10 f0 	mov    -0xfefdff8(,%eax,4),%edx
f0100e83:	85 d2                	test   %edx,%edx
f0100e85:	75 20                	jne    f0100ea7 <vprintfmt+0x163>
				printfmt(putch, putdat, "error %d", err);
f0100e87:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e8b:	c7 44 24 08 39 1e 10 	movl   $0xf0101e39,0x8(%esp)
f0100e92:	f0 
f0100e93:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e97:	89 34 24             	mov    %esi,(%esp)
f0100e9a:	e8 7d fe ff ff       	call   f0100d1c <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e9f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100ea2:	e9 c2 fe ff ff       	jmp    f0100d69 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0100ea7:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100eab:	c7 44 24 08 42 1e 10 	movl   $0xf0101e42,0x8(%esp)
f0100eb2:	f0 
f0100eb3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100eb7:	89 34 24             	mov    %esi,(%esp)
f0100eba:	e8 5d fe ff ff       	call   f0100d1c <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ebf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ec2:	e9 a2 fe ff ff       	jmp    f0100d69 <vprintfmt+0x25>
f0100ec7:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eca:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100ecd:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100ed0:	89 4d cc             	mov    %ecx,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100ed3:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100ed7:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100ed9:	85 ff                	test   %edi,%edi
f0100edb:	b8 32 1e 10 f0       	mov    $0xf0101e32,%eax
f0100ee0:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100ee3:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100ee7:	0f 84 92 00 00 00    	je     f0100f7f <vprintfmt+0x23b>
f0100eed:	85 c9                	test   %ecx,%ecx
f0100eef:	0f 8e 98 00 00 00    	jle    f0100f8d <vprintfmt+0x249>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ef5:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100ef9:	89 3c 24             	mov    %edi,(%esp)
f0100efc:	e8 17 04 00 00       	call   f0101318 <strnlen>
f0100f01:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100f04:	29 c1                	sub    %eax,%ecx
f0100f06:	89 4d cc             	mov    %ecx,-0x34(%ebp)
					putch(padc, putdat);
f0100f09:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100f0d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f10:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f13:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f15:	eb 0f                	jmp    f0100f26 <vprintfmt+0x1e2>
					putch(padc, putdat);
f0100f17:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f1b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f1e:	89 04 24             	mov    %eax,(%esp)
f0100f21:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f23:	83 ef 01             	sub    $0x1,%edi
f0100f26:	85 ff                	test   %edi,%edi
f0100f28:	7f ed                	jg     f0100f17 <vprintfmt+0x1d3>
f0100f2a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f2d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100f30:	85 c9                	test   %ecx,%ecx
f0100f32:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f37:	0f 49 c1             	cmovns %ecx,%eax
f0100f3a:	29 c1                	sub    %eax,%ecx
f0100f3c:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f3f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f42:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f45:	89 cb                	mov    %ecx,%ebx
f0100f47:	eb 50                	jmp    f0100f99 <vprintfmt+0x255>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f49:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f4d:	74 1e                	je     f0100f6d <vprintfmt+0x229>
f0100f4f:	0f be d2             	movsbl %dl,%edx
f0100f52:	83 ea 20             	sub    $0x20,%edx
f0100f55:	83 fa 5e             	cmp    $0x5e,%edx
f0100f58:	76 13                	jbe    f0100f6d <vprintfmt+0x229>
					putch('?', putdat);
f0100f5a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f5d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f61:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100f68:	ff 55 08             	call   *0x8(%ebp)
f0100f6b:	eb 0d                	jmp    f0100f7a <vprintfmt+0x236>
				else
					putch(ch, putdat);
f0100f6d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0100f70:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100f74:	89 04 24             	mov    %eax,(%esp)
f0100f77:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f7a:	83 eb 01             	sub    $0x1,%ebx
f0100f7d:	eb 1a                	jmp    f0100f99 <vprintfmt+0x255>
f0100f7f:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f82:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f85:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f88:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f8b:	eb 0c                	jmp    f0100f99 <vprintfmt+0x255>
f0100f8d:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f90:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f93:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f96:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f99:	83 c7 01             	add    $0x1,%edi
f0100f9c:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0100fa0:	0f be c2             	movsbl %dl,%eax
f0100fa3:	85 c0                	test   %eax,%eax
f0100fa5:	74 25                	je     f0100fcc <vprintfmt+0x288>
f0100fa7:	85 f6                	test   %esi,%esi
f0100fa9:	78 9e                	js     f0100f49 <vprintfmt+0x205>
f0100fab:	83 ee 01             	sub    $0x1,%esi
f0100fae:	79 99                	jns    f0100f49 <vprintfmt+0x205>
f0100fb0:	89 df                	mov    %ebx,%edi
f0100fb2:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fb5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fb8:	eb 1a                	jmp    f0100fd4 <vprintfmt+0x290>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100fba:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fbe:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100fc5:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100fc7:	83 ef 01             	sub    $0x1,%edi
f0100fca:	eb 08                	jmp    f0100fd4 <vprintfmt+0x290>
f0100fcc:	89 df                	mov    %ebx,%edi
f0100fce:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fd1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fd4:	85 ff                	test   %edi,%edi
f0100fd6:	7f e2                	jg     f0100fba <vprintfmt+0x276>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fd8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100fdb:	e9 89 fd ff ff       	jmp    f0100d69 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100fe0:	83 f9 01             	cmp    $0x1,%ecx
f0100fe3:	7e 19                	jle    f0100ffe <vprintfmt+0x2ba>
		return va_arg(*ap, long long);
f0100fe5:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fe8:	8b 50 04             	mov    0x4(%eax),%edx
f0100feb:	8b 00                	mov    (%eax),%eax
f0100fed:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100ff0:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100ff3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ff6:	8d 40 08             	lea    0x8(%eax),%eax
f0100ff9:	89 45 14             	mov    %eax,0x14(%ebp)
f0100ffc:	eb 38                	jmp    f0101036 <vprintfmt+0x2f2>
	else if (lflag)
f0100ffe:	85 c9                	test   %ecx,%ecx
f0101000:	74 1b                	je     f010101d <vprintfmt+0x2d9>
		return va_arg(*ap, long);
f0101002:	8b 45 14             	mov    0x14(%ebp),%eax
f0101005:	8b 00                	mov    (%eax),%eax
f0101007:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010100a:	89 c1                	mov    %eax,%ecx
f010100c:	c1 f9 1f             	sar    $0x1f,%ecx
f010100f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101012:	8b 45 14             	mov    0x14(%ebp),%eax
f0101015:	8d 40 04             	lea    0x4(%eax),%eax
f0101018:	89 45 14             	mov    %eax,0x14(%ebp)
f010101b:	eb 19                	jmp    f0101036 <vprintfmt+0x2f2>
	else
		return va_arg(*ap, int);
f010101d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101020:	8b 00                	mov    (%eax),%eax
f0101022:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101025:	89 c1                	mov    %eax,%ecx
f0101027:	c1 f9 1f             	sar    $0x1f,%ecx
f010102a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010102d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101030:	8d 40 04             	lea    0x4(%eax),%eax
f0101033:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101036:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101039:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010103c:	bf 0a 00 00 00       	mov    $0xa,%edi
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101041:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101045:	0f 89 04 01 00 00    	jns    f010114f <vprintfmt+0x40b>
				putch('-', putdat);
f010104b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010104f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101056:	ff d6                	call   *%esi
				num = -(long long) num;
f0101058:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010105b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010105e:	f7 da                	neg    %edx
f0101060:	83 d1 00             	adc    $0x0,%ecx
f0101063:	f7 d9                	neg    %ecx
f0101065:	e9 e5 00 00 00       	jmp    f010114f <vprintfmt+0x40b>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010106a:	83 f9 01             	cmp    $0x1,%ecx
f010106d:	7e 10                	jle    f010107f <vprintfmt+0x33b>
		return va_arg(*ap, unsigned long long);
f010106f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101072:	8b 10                	mov    (%eax),%edx
f0101074:	8b 48 04             	mov    0x4(%eax),%ecx
f0101077:	8d 40 08             	lea    0x8(%eax),%eax
f010107a:	89 45 14             	mov    %eax,0x14(%ebp)
f010107d:	eb 26                	jmp    f01010a5 <vprintfmt+0x361>
	else if (lflag)
f010107f:	85 c9                	test   %ecx,%ecx
f0101081:	74 12                	je     f0101095 <vprintfmt+0x351>
		return va_arg(*ap, unsigned long);
f0101083:	8b 45 14             	mov    0x14(%ebp),%eax
f0101086:	8b 10                	mov    (%eax),%edx
f0101088:	b9 00 00 00 00       	mov    $0x0,%ecx
f010108d:	8d 40 04             	lea    0x4(%eax),%eax
f0101090:	89 45 14             	mov    %eax,0x14(%ebp)
f0101093:	eb 10                	jmp    f01010a5 <vprintfmt+0x361>
	else
		return va_arg(*ap, unsigned int);
f0101095:	8b 45 14             	mov    0x14(%ebp),%eax
f0101098:	8b 10                	mov    (%eax),%edx
f010109a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010109f:	8d 40 04             	lea    0x4(%eax),%eax
f01010a2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01010a5:	bf 0a 00 00 00       	mov    $0xa,%edi
			goto number;
f01010aa:	e9 a0 00 00 00       	jmp    f010114f <vprintfmt+0x40b>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01010af:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010b3:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01010ba:	ff d6                	call   *%esi
			putch('X', putdat);
f01010bc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010c0:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01010c7:	ff d6                	call   *%esi
			putch('X', putdat);
f01010c9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010cd:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01010d4:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010d6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f01010d9:	e9 8b fc ff ff       	jmp    f0100d69 <vprintfmt+0x25>

		// pointer
		case 'p':
			putch('0', putdat);
f01010de:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010e2:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01010e9:	ff d6                	call   *%esi
			putch('x', putdat);
f01010eb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010ef:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01010f6:	ff d6                	call   *%esi
			num = (unsigned long long)
f01010f8:	8b 45 14             	mov    0x14(%ebp),%eax
f01010fb:	8b 10                	mov    (%eax),%edx
f01010fd:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
f0101102:	8d 40 04             	lea    0x4(%eax),%eax
f0101105:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101108:	bf 10 00 00 00       	mov    $0x10,%edi
			goto number;
f010110d:	eb 40                	jmp    f010114f <vprintfmt+0x40b>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010110f:	83 f9 01             	cmp    $0x1,%ecx
f0101112:	7e 10                	jle    f0101124 <vprintfmt+0x3e0>
		return va_arg(*ap, unsigned long long);
f0101114:	8b 45 14             	mov    0x14(%ebp),%eax
f0101117:	8b 10                	mov    (%eax),%edx
f0101119:	8b 48 04             	mov    0x4(%eax),%ecx
f010111c:	8d 40 08             	lea    0x8(%eax),%eax
f010111f:	89 45 14             	mov    %eax,0x14(%ebp)
f0101122:	eb 26                	jmp    f010114a <vprintfmt+0x406>
	else if (lflag)
f0101124:	85 c9                	test   %ecx,%ecx
f0101126:	74 12                	je     f010113a <vprintfmt+0x3f6>
		return va_arg(*ap, unsigned long);
f0101128:	8b 45 14             	mov    0x14(%ebp),%eax
f010112b:	8b 10                	mov    (%eax),%edx
f010112d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101132:	8d 40 04             	lea    0x4(%eax),%eax
f0101135:	89 45 14             	mov    %eax,0x14(%ebp)
f0101138:	eb 10                	jmp    f010114a <vprintfmt+0x406>
	else
		return va_arg(*ap, unsigned int);
f010113a:	8b 45 14             	mov    0x14(%ebp),%eax
f010113d:	8b 10                	mov    (%eax),%edx
f010113f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101144:	8d 40 04             	lea    0x4(%eax),%eax
f0101147:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010114a:	bf 10 00 00 00       	mov    $0x10,%edi
		number:
			printnum(putch, putdat, num, base, width, padc);
f010114f:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101153:	89 44 24 10          	mov    %eax,0x10(%esp)
f0101157:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010115a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010115e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101162:	89 14 24             	mov    %edx,(%esp)
f0101165:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101169:	89 da                	mov    %ebx,%edx
f010116b:	89 f0                	mov    %esi,%eax
f010116d:	e8 9e fa ff ff       	call   f0100c10 <printnum>
			break;
f0101172:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101175:	e9 ef fb ff ff       	jmp    f0100d69 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010117a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010117e:	89 04 24             	mov    %eax,(%esp)
f0101181:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101183:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101186:	e9 de fb ff ff       	jmp    f0100d69 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010118b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010118f:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101196:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101198:	eb 03                	jmp    f010119d <vprintfmt+0x459>
f010119a:	83 ef 01             	sub    $0x1,%edi
f010119d:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01011a1:	75 f7                	jne    f010119a <vprintfmt+0x456>
f01011a3:	e9 c1 fb ff ff       	jmp    f0100d69 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01011a8:	83 c4 3c             	add    $0x3c,%esp
f01011ab:	5b                   	pop    %ebx
f01011ac:	5e                   	pop    %esi
f01011ad:	5f                   	pop    %edi
f01011ae:	5d                   	pop    %ebp
f01011af:	c3                   	ret    

f01011b0 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011b0:	55                   	push   %ebp
f01011b1:	89 e5                	mov    %esp,%ebp
f01011b3:	83 ec 28             	sub    $0x28,%esp
f01011b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01011b9:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011bc:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011bf:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011c3:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011c6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011cd:	85 c0                	test   %eax,%eax
f01011cf:	74 30                	je     f0101201 <vsnprintf+0x51>
f01011d1:	85 d2                	test   %edx,%edx
f01011d3:	7e 2c                	jle    f0101201 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011d5:	8b 45 14             	mov    0x14(%ebp),%eax
f01011d8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011dc:	8b 45 10             	mov    0x10(%ebp),%eax
f01011df:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011e3:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011e6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011ea:	c7 04 24 ff 0c 10 f0 	movl   $0xf0100cff,(%esp)
f01011f1:	e8 4e fb ff ff       	call   f0100d44 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011f6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011f9:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011ff:	eb 05                	jmp    f0101206 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101201:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101206:	c9                   	leave  
f0101207:	c3                   	ret    

f0101208 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101208:	55                   	push   %ebp
f0101209:	89 e5                	mov    %esp,%ebp
f010120b:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010120e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101211:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101215:	8b 45 10             	mov    0x10(%ebp),%eax
f0101218:	89 44 24 08          	mov    %eax,0x8(%esp)
f010121c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010121f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101223:	8b 45 08             	mov    0x8(%ebp),%eax
f0101226:	89 04 24             	mov    %eax,(%esp)
f0101229:	e8 82 ff ff ff       	call   f01011b0 <vsnprintf>
	va_end(ap);

	return rc;
}
f010122e:	c9                   	leave  
f010122f:	c3                   	ret    

f0101230 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101230:	55                   	push   %ebp
f0101231:	89 e5                	mov    %esp,%ebp
f0101233:	57                   	push   %edi
f0101234:	56                   	push   %esi
f0101235:	53                   	push   %ebx
f0101236:	83 ec 1c             	sub    $0x1c,%esp
f0101239:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010123c:	85 c0                	test   %eax,%eax
f010123e:	74 10                	je     f0101250 <readline+0x20>
		cprintf("%s", prompt);
f0101240:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101244:	c7 04 24 42 1e 10 f0 	movl   $0xf0101e42,(%esp)
f010124b:	e8 e1 f6 ff ff       	call   f0100931 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101250:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101257:	e8 26 f4 ff ff       	call   f0100682 <iscons>
f010125c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010125e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101263:	e8 09 f4 ff ff       	call   f0100671 <getchar>
f0101268:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010126a:	85 c0                	test   %eax,%eax
f010126c:	79 17                	jns    f0101285 <readline+0x55>
			cprintf("read error: %e\n", c);
f010126e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101272:	c7 04 24 24 20 10 f0 	movl   $0xf0102024,(%esp)
f0101279:	e8 b3 f6 ff ff       	call   f0100931 <cprintf>
			return NULL;
f010127e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101283:	eb 6d                	jmp    f01012f2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101285:	83 f8 7f             	cmp    $0x7f,%eax
f0101288:	74 05                	je     f010128f <readline+0x5f>
f010128a:	83 f8 08             	cmp    $0x8,%eax
f010128d:	75 19                	jne    f01012a8 <readline+0x78>
f010128f:	85 f6                	test   %esi,%esi
f0101291:	7e 15                	jle    f01012a8 <readline+0x78>
			if (echoing)
f0101293:	85 ff                	test   %edi,%edi
f0101295:	74 0c                	je     f01012a3 <readline+0x73>
				cputchar('\b');
f0101297:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010129e:	e8 be f3 ff ff       	call   f0100661 <cputchar>
			i--;
f01012a3:	83 ee 01             	sub    $0x1,%esi
f01012a6:	eb bb                	jmp    f0101263 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012a8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012ae:	7f 1c                	jg     f01012cc <readline+0x9c>
f01012b0:	83 fb 1f             	cmp    $0x1f,%ebx
f01012b3:	7e 17                	jle    f01012cc <readline+0x9c>
			if (echoing)
f01012b5:	85 ff                	test   %edi,%edi
f01012b7:	74 08                	je     f01012c1 <readline+0x91>
				cputchar(c);
f01012b9:	89 1c 24             	mov    %ebx,(%esp)
f01012bc:	e8 a0 f3 ff ff       	call   f0100661 <cputchar>
			buf[i++] = c;
f01012c1:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01012c7:	8d 76 01             	lea    0x1(%esi),%esi
f01012ca:	eb 97                	jmp    f0101263 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01012cc:	83 fb 0d             	cmp    $0xd,%ebx
f01012cf:	74 05                	je     f01012d6 <readline+0xa6>
f01012d1:	83 fb 0a             	cmp    $0xa,%ebx
f01012d4:	75 8d                	jne    f0101263 <readline+0x33>
			if (echoing)
f01012d6:	85 ff                	test   %edi,%edi
f01012d8:	74 0c                	je     f01012e6 <readline+0xb6>
				cputchar('\n');
f01012da:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01012e1:	e8 7b f3 ff ff       	call   f0100661 <cputchar>
			buf[i] = 0;
f01012e6:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01012ed:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01012f2:	83 c4 1c             	add    $0x1c,%esp
f01012f5:	5b                   	pop    %ebx
f01012f6:	5e                   	pop    %esi
f01012f7:	5f                   	pop    %edi
f01012f8:	5d                   	pop    %ebp
f01012f9:	c3                   	ret    
f01012fa:	66 90                	xchg   %ax,%ax
f01012fc:	66 90                	xchg   %ax,%ax
f01012fe:	66 90                	xchg   %ax,%ax

f0101300 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101300:	55                   	push   %ebp
f0101301:	89 e5                	mov    %esp,%ebp
f0101303:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101306:	b8 00 00 00 00       	mov    $0x0,%eax
f010130b:	eb 03                	jmp    f0101310 <strlen+0x10>
		n++;
f010130d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101310:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101314:	75 f7                	jne    f010130d <strlen+0xd>
		n++;
	return n;
}
f0101316:	5d                   	pop    %ebp
f0101317:	c3                   	ret    

f0101318 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101318:	55                   	push   %ebp
f0101319:	89 e5                	mov    %esp,%ebp
f010131b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010131e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101321:	b8 00 00 00 00       	mov    $0x0,%eax
f0101326:	eb 03                	jmp    f010132b <strnlen+0x13>
		n++;
f0101328:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010132b:	39 d0                	cmp    %edx,%eax
f010132d:	74 06                	je     f0101335 <strnlen+0x1d>
f010132f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101333:	75 f3                	jne    f0101328 <strnlen+0x10>
		n++;
	return n;
}
f0101335:	5d                   	pop    %ebp
f0101336:	c3                   	ret    

f0101337 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101337:	55                   	push   %ebp
f0101338:	89 e5                	mov    %esp,%ebp
f010133a:	53                   	push   %ebx
f010133b:	8b 45 08             	mov    0x8(%ebp),%eax
f010133e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101341:	89 c2                	mov    %eax,%edx
f0101343:	83 c2 01             	add    $0x1,%edx
f0101346:	83 c1 01             	add    $0x1,%ecx
f0101349:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010134d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101350:	84 db                	test   %bl,%bl
f0101352:	75 ef                	jne    f0101343 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101354:	5b                   	pop    %ebx
f0101355:	5d                   	pop    %ebp
f0101356:	c3                   	ret    

f0101357 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101357:	55                   	push   %ebp
f0101358:	89 e5                	mov    %esp,%ebp
f010135a:	53                   	push   %ebx
f010135b:	83 ec 08             	sub    $0x8,%esp
f010135e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101361:	89 1c 24             	mov    %ebx,(%esp)
f0101364:	e8 97 ff ff ff       	call   f0101300 <strlen>
	strcpy(dst + len, src);
f0101369:	8b 55 0c             	mov    0xc(%ebp),%edx
f010136c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101370:	01 d8                	add    %ebx,%eax
f0101372:	89 04 24             	mov    %eax,(%esp)
f0101375:	e8 bd ff ff ff       	call   f0101337 <strcpy>
	return dst;
}
f010137a:	89 d8                	mov    %ebx,%eax
f010137c:	83 c4 08             	add    $0x8,%esp
f010137f:	5b                   	pop    %ebx
f0101380:	5d                   	pop    %ebp
f0101381:	c3                   	ret    

f0101382 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101382:	55                   	push   %ebp
f0101383:	89 e5                	mov    %esp,%ebp
f0101385:	56                   	push   %esi
f0101386:	53                   	push   %ebx
f0101387:	8b 75 08             	mov    0x8(%ebp),%esi
f010138a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010138d:	89 f3                	mov    %esi,%ebx
f010138f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101392:	89 f2                	mov    %esi,%edx
f0101394:	eb 0f                	jmp    f01013a5 <strncpy+0x23>
		*dst++ = *src;
f0101396:	83 c2 01             	add    $0x1,%edx
f0101399:	0f b6 01             	movzbl (%ecx),%eax
f010139c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010139f:	80 39 01             	cmpb   $0x1,(%ecx)
f01013a2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013a5:	39 da                	cmp    %ebx,%edx
f01013a7:	75 ed                	jne    f0101396 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013a9:	89 f0                	mov    %esi,%eax
f01013ab:	5b                   	pop    %ebx
f01013ac:	5e                   	pop    %esi
f01013ad:	5d                   	pop    %ebp
f01013ae:	c3                   	ret    

f01013af <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013af:	55                   	push   %ebp
f01013b0:	89 e5                	mov    %esp,%ebp
f01013b2:	56                   	push   %esi
f01013b3:	53                   	push   %ebx
f01013b4:	8b 75 08             	mov    0x8(%ebp),%esi
f01013b7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013ba:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01013bd:	89 f0                	mov    %esi,%eax
f01013bf:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013c3:	85 c9                	test   %ecx,%ecx
f01013c5:	75 0b                	jne    f01013d2 <strlcpy+0x23>
f01013c7:	eb 1d                	jmp    f01013e6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013c9:	83 c0 01             	add    $0x1,%eax
f01013cc:	83 c2 01             	add    $0x1,%edx
f01013cf:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013d2:	39 d8                	cmp    %ebx,%eax
f01013d4:	74 0b                	je     f01013e1 <strlcpy+0x32>
f01013d6:	0f b6 0a             	movzbl (%edx),%ecx
f01013d9:	84 c9                	test   %cl,%cl
f01013db:	75 ec                	jne    f01013c9 <strlcpy+0x1a>
f01013dd:	89 c2                	mov    %eax,%edx
f01013df:	eb 02                	jmp    f01013e3 <strlcpy+0x34>
f01013e1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01013e3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01013e6:	29 f0                	sub    %esi,%eax
}
f01013e8:	5b                   	pop    %ebx
f01013e9:	5e                   	pop    %esi
f01013ea:	5d                   	pop    %ebp
f01013eb:	c3                   	ret    

f01013ec <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013ec:	55                   	push   %ebp
f01013ed:	89 e5                	mov    %esp,%ebp
f01013ef:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013f2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013f5:	eb 06                	jmp    f01013fd <strcmp+0x11>
		p++, q++;
f01013f7:	83 c1 01             	add    $0x1,%ecx
f01013fa:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013fd:	0f b6 01             	movzbl (%ecx),%eax
f0101400:	84 c0                	test   %al,%al
f0101402:	74 04                	je     f0101408 <strcmp+0x1c>
f0101404:	3a 02                	cmp    (%edx),%al
f0101406:	74 ef                	je     f01013f7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101408:	0f b6 c0             	movzbl %al,%eax
f010140b:	0f b6 12             	movzbl (%edx),%edx
f010140e:	29 d0                	sub    %edx,%eax
}
f0101410:	5d                   	pop    %ebp
f0101411:	c3                   	ret    

f0101412 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101412:	55                   	push   %ebp
f0101413:	89 e5                	mov    %esp,%ebp
f0101415:	53                   	push   %ebx
f0101416:	8b 45 08             	mov    0x8(%ebp),%eax
f0101419:	8b 55 0c             	mov    0xc(%ebp),%edx
f010141c:	89 c3                	mov    %eax,%ebx
f010141e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101421:	eb 06                	jmp    f0101429 <strncmp+0x17>
		n--, p++, q++;
f0101423:	83 c0 01             	add    $0x1,%eax
f0101426:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101429:	39 d8                	cmp    %ebx,%eax
f010142b:	74 15                	je     f0101442 <strncmp+0x30>
f010142d:	0f b6 08             	movzbl (%eax),%ecx
f0101430:	84 c9                	test   %cl,%cl
f0101432:	74 04                	je     f0101438 <strncmp+0x26>
f0101434:	3a 0a                	cmp    (%edx),%cl
f0101436:	74 eb                	je     f0101423 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101438:	0f b6 00             	movzbl (%eax),%eax
f010143b:	0f b6 12             	movzbl (%edx),%edx
f010143e:	29 d0                	sub    %edx,%eax
f0101440:	eb 05                	jmp    f0101447 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101442:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101447:	5b                   	pop    %ebx
f0101448:	5d                   	pop    %ebp
f0101449:	c3                   	ret    

f010144a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010144a:	55                   	push   %ebp
f010144b:	89 e5                	mov    %esp,%ebp
f010144d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101450:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101454:	eb 07                	jmp    f010145d <strchr+0x13>
		if (*s == c)
f0101456:	38 ca                	cmp    %cl,%dl
f0101458:	74 0f                	je     f0101469 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010145a:	83 c0 01             	add    $0x1,%eax
f010145d:	0f b6 10             	movzbl (%eax),%edx
f0101460:	84 d2                	test   %dl,%dl
f0101462:	75 f2                	jne    f0101456 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101464:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101469:	5d                   	pop    %ebp
f010146a:	c3                   	ret    

f010146b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010146b:	55                   	push   %ebp
f010146c:	89 e5                	mov    %esp,%ebp
f010146e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101471:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101475:	eb 07                	jmp    f010147e <strfind+0x13>
		if (*s == c)
f0101477:	38 ca                	cmp    %cl,%dl
f0101479:	74 0a                	je     f0101485 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010147b:	83 c0 01             	add    $0x1,%eax
f010147e:	0f b6 10             	movzbl (%eax),%edx
f0101481:	84 d2                	test   %dl,%dl
f0101483:	75 f2                	jne    f0101477 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101485:	5d                   	pop    %ebp
f0101486:	c3                   	ret    

f0101487 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101487:	55                   	push   %ebp
f0101488:	89 e5                	mov    %esp,%ebp
f010148a:	57                   	push   %edi
f010148b:	56                   	push   %esi
f010148c:	53                   	push   %ebx
f010148d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101490:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101493:	85 c9                	test   %ecx,%ecx
f0101495:	74 36                	je     f01014cd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101497:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010149d:	75 28                	jne    f01014c7 <memset+0x40>
f010149f:	f6 c1 03             	test   $0x3,%cl
f01014a2:	75 23                	jne    f01014c7 <memset+0x40>
		c &= 0xFF;
f01014a4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01014a8:	89 d3                	mov    %edx,%ebx
f01014aa:	c1 e3 08             	shl    $0x8,%ebx
f01014ad:	89 d6                	mov    %edx,%esi
f01014af:	c1 e6 18             	shl    $0x18,%esi
f01014b2:	89 d0                	mov    %edx,%eax
f01014b4:	c1 e0 10             	shl    $0x10,%eax
f01014b7:	09 f0                	or     %esi,%eax
f01014b9:	09 c2                	or     %eax,%edx
f01014bb:	89 d0                	mov    %edx,%eax
f01014bd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01014bf:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01014c2:	fc                   	cld    
f01014c3:	f3 ab                	rep stos %eax,%es:(%edi)
f01014c5:	eb 06                	jmp    f01014cd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014c7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014ca:	fc                   	cld    
f01014cb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014cd:	89 f8                	mov    %edi,%eax
f01014cf:	5b                   	pop    %ebx
f01014d0:	5e                   	pop    %esi
f01014d1:	5f                   	pop    %edi
f01014d2:	5d                   	pop    %ebp
f01014d3:	c3                   	ret    

f01014d4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014d4:	55                   	push   %ebp
f01014d5:	89 e5                	mov    %esp,%ebp
f01014d7:	57                   	push   %edi
f01014d8:	56                   	push   %esi
f01014d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01014dc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014df:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014e2:	39 c6                	cmp    %eax,%esi
f01014e4:	73 35                	jae    f010151b <memmove+0x47>
f01014e6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014e9:	39 d0                	cmp    %edx,%eax
f01014eb:	73 2e                	jae    f010151b <memmove+0x47>
		s += n;
		d += n;
f01014ed:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01014f0:	89 d6                	mov    %edx,%esi
f01014f2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014f4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01014fa:	75 13                	jne    f010150f <memmove+0x3b>
f01014fc:	f6 c1 03             	test   $0x3,%cl
f01014ff:	75 0e                	jne    f010150f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101501:	83 ef 04             	sub    $0x4,%edi
f0101504:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101507:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010150a:	fd                   	std    
f010150b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010150d:	eb 09                	jmp    f0101518 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010150f:	83 ef 01             	sub    $0x1,%edi
f0101512:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101515:	fd                   	std    
f0101516:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101518:	fc                   	cld    
f0101519:	eb 1d                	jmp    f0101538 <memmove+0x64>
f010151b:	89 f2                	mov    %esi,%edx
f010151d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010151f:	f6 c2 03             	test   $0x3,%dl
f0101522:	75 0f                	jne    f0101533 <memmove+0x5f>
f0101524:	f6 c1 03             	test   $0x3,%cl
f0101527:	75 0a                	jne    f0101533 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101529:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010152c:	89 c7                	mov    %eax,%edi
f010152e:	fc                   	cld    
f010152f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101531:	eb 05                	jmp    f0101538 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101533:	89 c7                	mov    %eax,%edi
f0101535:	fc                   	cld    
f0101536:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101538:	5e                   	pop    %esi
f0101539:	5f                   	pop    %edi
f010153a:	5d                   	pop    %ebp
f010153b:	c3                   	ret    

f010153c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010153c:	55                   	push   %ebp
f010153d:	89 e5                	mov    %esp,%ebp
f010153f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101542:	8b 45 10             	mov    0x10(%ebp),%eax
f0101545:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101549:	8b 45 0c             	mov    0xc(%ebp),%eax
f010154c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101550:	8b 45 08             	mov    0x8(%ebp),%eax
f0101553:	89 04 24             	mov    %eax,(%esp)
f0101556:	e8 79 ff ff ff       	call   f01014d4 <memmove>
}
f010155b:	c9                   	leave  
f010155c:	c3                   	ret    

f010155d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010155d:	55                   	push   %ebp
f010155e:	89 e5                	mov    %esp,%ebp
f0101560:	56                   	push   %esi
f0101561:	53                   	push   %ebx
f0101562:	8b 55 08             	mov    0x8(%ebp),%edx
f0101565:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101568:	89 d6                	mov    %edx,%esi
f010156a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010156d:	eb 1a                	jmp    f0101589 <memcmp+0x2c>
		if (*s1 != *s2)
f010156f:	0f b6 02             	movzbl (%edx),%eax
f0101572:	0f b6 19             	movzbl (%ecx),%ebx
f0101575:	38 d8                	cmp    %bl,%al
f0101577:	74 0a                	je     f0101583 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101579:	0f b6 c0             	movzbl %al,%eax
f010157c:	0f b6 db             	movzbl %bl,%ebx
f010157f:	29 d8                	sub    %ebx,%eax
f0101581:	eb 0f                	jmp    f0101592 <memcmp+0x35>
		s1++, s2++;
f0101583:	83 c2 01             	add    $0x1,%edx
f0101586:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101589:	39 f2                	cmp    %esi,%edx
f010158b:	75 e2                	jne    f010156f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010158d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101592:	5b                   	pop    %ebx
f0101593:	5e                   	pop    %esi
f0101594:	5d                   	pop    %ebp
f0101595:	c3                   	ret    

f0101596 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101596:	55                   	push   %ebp
f0101597:	89 e5                	mov    %esp,%ebp
f0101599:	8b 45 08             	mov    0x8(%ebp),%eax
f010159c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010159f:	89 c2                	mov    %eax,%edx
f01015a1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01015a4:	eb 07                	jmp    f01015ad <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01015a6:	38 08                	cmp    %cl,(%eax)
f01015a8:	74 07                	je     f01015b1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015aa:	83 c0 01             	add    $0x1,%eax
f01015ad:	39 d0                	cmp    %edx,%eax
f01015af:	72 f5                	jb     f01015a6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01015b1:	5d                   	pop    %ebp
f01015b2:	c3                   	ret    

f01015b3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01015b3:	55                   	push   %ebp
f01015b4:	89 e5                	mov    %esp,%ebp
f01015b6:	57                   	push   %edi
f01015b7:	56                   	push   %esi
f01015b8:	53                   	push   %ebx
f01015b9:	8b 55 08             	mov    0x8(%ebp),%edx
f01015bc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015bf:	eb 03                	jmp    f01015c4 <strtol+0x11>
		s++;
f01015c1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015c4:	0f b6 0a             	movzbl (%edx),%ecx
f01015c7:	80 f9 09             	cmp    $0x9,%cl
f01015ca:	74 f5                	je     f01015c1 <strtol+0xe>
f01015cc:	80 f9 20             	cmp    $0x20,%cl
f01015cf:	74 f0                	je     f01015c1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01015d1:	80 f9 2b             	cmp    $0x2b,%cl
f01015d4:	75 0a                	jne    f01015e0 <strtol+0x2d>
		s++;
f01015d6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015d9:	bf 00 00 00 00       	mov    $0x0,%edi
f01015de:	eb 11                	jmp    f01015f1 <strtol+0x3e>
f01015e0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015e5:	80 f9 2d             	cmp    $0x2d,%cl
f01015e8:	75 07                	jne    f01015f1 <strtol+0x3e>
		s++, neg = 1;
f01015ea:	8d 52 01             	lea    0x1(%edx),%edx
f01015ed:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015f1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f01015f6:	75 15                	jne    f010160d <strtol+0x5a>
f01015f8:	80 3a 30             	cmpb   $0x30,(%edx)
f01015fb:	75 10                	jne    f010160d <strtol+0x5a>
f01015fd:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101601:	75 0a                	jne    f010160d <strtol+0x5a>
		s += 2, base = 16;
f0101603:	83 c2 02             	add    $0x2,%edx
f0101606:	b8 10 00 00 00       	mov    $0x10,%eax
f010160b:	eb 10                	jmp    f010161d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010160d:	85 c0                	test   %eax,%eax
f010160f:	75 0c                	jne    f010161d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101611:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101613:	80 3a 30             	cmpb   $0x30,(%edx)
f0101616:	75 05                	jne    f010161d <strtol+0x6a>
		s++, base = 8;
f0101618:	83 c2 01             	add    $0x1,%edx
f010161b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010161d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101622:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101625:	0f b6 0a             	movzbl (%edx),%ecx
f0101628:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010162b:	89 f0                	mov    %esi,%eax
f010162d:	3c 09                	cmp    $0x9,%al
f010162f:	77 08                	ja     f0101639 <strtol+0x86>
			dig = *s - '0';
f0101631:	0f be c9             	movsbl %cl,%ecx
f0101634:	83 e9 30             	sub    $0x30,%ecx
f0101637:	eb 20                	jmp    f0101659 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0101639:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010163c:	89 f0                	mov    %esi,%eax
f010163e:	3c 19                	cmp    $0x19,%al
f0101640:	77 08                	ja     f010164a <strtol+0x97>
			dig = *s - 'a' + 10;
f0101642:	0f be c9             	movsbl %cl,%ecx
f0101645:	83 e9 57             	sub    $0x57,%ecx
f0101648:	eb 0f                	jmp    f0101659 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010164a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010164d:	89 f0                	mov    %esi,%eax
f010164f:	3c 19                	cmp    $0x19,%al
f0101651:	77 16                	ja     f0101669 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0101653:	0f be c9             	movsbl %cl,%ecx
f0101656:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101659:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010165c:	7d 0f                	jge    f010166d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010165e:	83 c2 01             	add    $0x1,%edx
f0101661:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101665:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101667:	eb bc                	jmp    f0101625 <strtol+0x72>
f0101669:	89 d8                	mov    %ebx,%eax
f010166b:	eb 02                	jmp    f010166f <strtol+0xbc>
f010166d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010166f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101673:	74 05                	je     f010167a <strtol+0xc7>
		*endptr = (char *) s;
f0101675:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101678:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010167a:	f7 d8                	neg    %eax
f010167c:	85 ff                	test   %edi,%edi
f010167e:	0f 44 c3             	cmove  %ebx,%eax
}
f0101681:	5b                   	pop    %ebx
f0101682:	5e                   	pop    %esi
f0101683:	5f                   	pop    %edi
f0101684:	5d                   	pop    %ebp
f0101685:	c3                   	ret    
f0101686:	66 90                	xchg   %ax,%ax
f0101688:	66 90                	xchg   %ax,%ax
f010168a:	66 90                	xchg   %ax,%ax
f010168c:	66 90                	xchg   %ax,%ax
f010168e:	66 90                	xchg   %ax,%ax

f0101690 <__udivdi3>:
f0101690:	55                   	push   %ebp
f0101691:	57                   	push   %edi
f0101692:	56                   	push   %esi
f0101693:	83 ec 0c             	sub    $0xc,%esp
f0101696:	8b 44 24 28          	mov    0x28(%esp),%eax
f010169a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010169e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01016a2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01016a6:	85 c0                	test   %eax,%eax
f01016a8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01016ac:	89 ea                	mov    %ebp,%edx
f01016ae:	89 0c 24             	mov    %ecx,(%esp)
f01016b1:	75 2d                	jne    f01016e0 <__udivdi3+0x50>
f01016b3:	39 e9                	cmp    %ebp,%ecx
f01016b5:	77 61                	ja     f0101718 <__udivdi3+0x88>
f01016b7:	85 c9                	test   %ecx,%ecx
f01016b9:	89 ce                	mov    %ecx,%esi
f01016bb:	75 0b                	jne    f01016c8 <__udivdi3+0x38>
f01016bd:	b8 01 00 00 00       	mov    $0x1,%eax
f01016c2:	31 d2                	xor    %edx,%edx
f01016c4:	f7 f1                	div    %ecx
f01016c6:	89 c6                	mov    %eax,%esi
f01016c8:	31 d2                	xor    %edx,%edx
f01016ca:	89 e8                	mov    %ebp,%eax
f01016cc:	f7 f6                	div    %esi
f01016ce:	89 c5                	mov    %eax,%ebp
f01016d0:	89 f8                	mov    %edi,%eax
f01016d2:	f7 f6                	div    %esi
f01016d4:	89 ea                	mov    %ebp,%edx
f01016d6:	83 c4 0c             	add    $0xc,%esp
f01016d9:	5e                   	pop    %esi
f01016da:	5f                   	pop    %edi
f01016db:	5d                   	pop    %ebp
f01016dc:	c3                   	ret    
f01016dd:	8d 76 00             	lea    0x0(%esi),%esi
f01016e0:	39 e8                	cmp    %ebp,%eax
f01016e2:	77 24                	ja     f0101708 <__udivdi3+0x78>
f01016e4:	0f bd e8             	bsr    %eax,%ebp
f01016e7:	83 f5 1f             	xor    $0x1f,%ebp
f01016ea:	75 3c                	jne    f0101728 <__udivdi3+0x98>
f01016ec:	8b 74 24 04          	mov    0x4(%esp),%esi
f01016f0:	39 34 24             	cmp    %esi,(%esp)
f01016f3:	0f 86 9f 00 00 00    	jbe    f0101798 <__udivdi3+0x108>
f01016f9:	39 d0                	cmp    %edx,%eax
f01016fb:	0f 82 97 00 00 00    	jb     f0101798 <__udivdi3+0x108>
f0101701:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101708:	31 d2                	xor    %edx,%edx
f010170a:	31 c0                	xor    %eax,%eax
f010170c:	83 c4 0c             	add    $0xc,%esp
f010170f:	5e                   	pop    %esi
f0101710:	5f                   	pop    %edi
f0101711:	5d                   	pop    %ebp
f0101712:	c3                   	ret    
f0101713:	90                   	nop
f0101714:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101718:	89 f8                	mov    %edi,%eax
f010171a:	f7 f1                	div    %ecx
f010171c:	31 d2                	xor    %edx,%edx
f010171e:	83 c4 0c             	add    $0xc,%esp
f0101721:	5e                   	pop    %esi
f0101722:	5f                   	pop    %edi
f0101723:	5d                   	pop    %ebp
f0101724:	c3                   	ret    
f0101725:	8d 76 00             	lea    0x0(%esi),%esi
f0101728:	89 e9                	mov    %ebp,%ecx
f010172a:	8b 3c 24             	mov    (%esp),%edi
f010172d:	d3 e0                	shl    %cl,%eax
f010172f:	89 c6                	mov    %eax,%esi
f0101731:	b8 20 00 00 00       	mov    $0x20,%eax
f0101736:	29 e8                	sub    %ebp,%eax
f0101738:	89 c1                	mov    %eax,%ecx
f010173a:	d3 ef                	shr    %cl,%edi
f010173c:	89 e9                	mov    %ebp,%ecx
f010173e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101742:	8b 3c 24             	mov    (%esp),%edi
f0101745:	09 74 24 08          	or     %esi,0x8(%esp)
f0101749:	89 d6                	mov    %edx,%esi
f010174b:	d3 e7                	shl    %cl,%edi
f010174d:	89 c1                	mov    %eax,%ecx
f010174f:	89 3c 24             	mov    %edi,(%esp)
f0101752:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101756:	d3 ee                	shr    %cl,%esi
f0101758:	89 e9                	mov    %ebp,%ecx
f010175a:	d3 e2                	shl    %cl,%edx
f010175c:	89 c1                	mov    %eax,%ecx
f010175e:	d3 ef                	shr    %cl,%edi
f0101760:	09 d7                	or     %edx,%edi
f0101762:	89 f2                	mov    %esi,%edx
f0101764:	89 f8                	mov    %edi,%eax
f0101766:	f7 74 24 08          	divl   0x8(%esp)
f010176a:	89 d6                	mov    %edx,%esi
f010176c:	89 c7                	mov    %eax,%edi
f010176e:	f7 24 24             	mull   (%esp)
f0101771:	39 d6                	cmp    %edx,%esi
f0101773:	89 14 24             	mov    %edx,(%esp)
f0101776:	72 30                	jb     f01017a8 <__udivdi3+0x118>
f0101778:	8b 54 24 04          	mov    0x4(%esp),%edx
f010177c:	89 e9                	mov    %ebp,%ecx
f010177e:	d3 e2                	shl    %cl,%edx
f0101780:	39 c2                	cmp    %eax,%edx
f0101782:	73 05                	jae    f0101789 <__udivdi3+0xf9>
f0101784:	3b 34 24             	cmp    (%esp),%esi
f0101787:	74 1f                	je     f01017a8 <__udivdi3+0x118>
f0101789:	89 f8                	mov    %edi,%eax
f010178b:	31 d2                	xor    %edx,%edx
f010178d:	e9 7a ff ff ff       	jmp    f010170c <__udivdi3+0x7c>
f0101792:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101798:	31 d2                	xor    %edx,%edx
f010179a:	b8 01 00 00 00       	mov    $0x1,%eax
f010179f:	e9 68 ff ff ff       	jmp    f010170c <__udivdi3+0x7c>
f01017a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017a8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01017ab:	31 d2                	xor    %edx,%edx
f01017ad:	83 c4 0c             	add    $0xc,%esp
f01017b0:	5e                   	pop    %esi
f01017b1:	5f                   	pop    %edi
f01017b2:	5d                   	pop    %ebp
f01017b3:	c3                   	ret    
f01017b4:	66 90                	xchg   %ax,%ax
f01017b6:	66 90                	xchg   %ax,%ax
f01017b8:	66 90                	xchg   %ax,%ax
f01017ba:	66 90                	xchg   %ax,%ax
f01017bc:	66 90                	xchg   %ax,%ax
f01017be:	66 90                	xchg   %ax,%ax

f01017c0 <__umoddi3>:
f01017c0:	55                   	push   %ebp
f01017c1:	57                   	push   %edi
f01017c2:	56                   	push   %esi
f01017c3:	83 ec 14             	sub    $0x14,%esp
f01017c6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01017ca:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01017ce:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f01017d2:	89 c7                	mov    %eax,%edi
f01017d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01017d8:	8b 44 24 30          	mov    0x30(%esp),%eax
f01017dc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01017e0:	89 34 24             	mov    %esi,(%esp)
f01017e3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017e7:	85 c0                	test   %eax,%eax
f01017e9:	89 c2                	mov    %eax,%edx
f01017eb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01017ef:	75 17                	jne    f0101808 <__umoddi3+0x48>
f01017f1:	39 fe                	cmp    %edi,%esi
f01017f3:	76 4b                	jbe    f0101840 <__umoddi3+0x80>
f01017f5:	89 c8                	mov    %ecx,%eax
f01017f7:	89 fa                	mov    %edi,%edx
f01017f9:	f7 f6                	div    %esi
f01017fb:	89 d0                	mov    %edx,%eax
f01017fd:	31 d2                	xor    %edx,%edx
f01017ff:	83 c4 14             	add    $0x14,%esp
f0101802:	5e                   	pop    %esi
f0101803:	5f                   	pop    %edi
f0101804:	5d                   	pop    %ebp
f0101805:	c3                   	ret    
f0101806:	66 90                	xchg   %ax,%ax
f0101808:	39 f8                	cmp    %edi,%eax
f010180a:	77 54                	ja     f0101860 <__umoddi3+0xa0>
f010180c:	0f bd e8             	bsr    %eax,%ebp
f010180f:	83 f5 1f             	xor    $0x1f,%ebp
f0101812:	75 5c                	jne    f0101870 <__umoddi3+0xb0>
f0101814:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101818:	39 3c 24             	cmp    %edi,(%esp)
f010181b:	0f 87 e7 00 00 00    	ja     f0101908 <__umoddi3+0x148>
f0101821:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101825:	29 f1                	sub    %esi,%ecx
f0101827:	19 c7                	sbb    %eax,%edi
f0101829:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010182d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101831:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101835:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101839:	83 c4 14             	add    $0x14,%esp
f010183c:	5e                   	pop    %esi
f010183d:	5f                   	pop    %edi
f010183e:	5d                   	pop    %ebp
f010183f:	c3                   	ret    
f0101840:	85 f6                	test   %esi,%esi
f0101842:	89 f5                	mov    %esi,%ebp
f0101844:	75 0b                	jne    f0101851 <__umoddi3+0x91>
f0101846:	b8 01 00 00 00       	mov    $0x1,%eax
f010184b:	31 d2                	xor    %edx,%edx
f010184d:	f7 f6                	div    %esi
f010184f:	89 c5                	mov    %eax,%ebp
f0101851:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101855:	31 d2                	xor    %edx,%edx
f0101857:	f7 f5                	div    %ebp
f0101859:	89 c8                	mov    %ecx,%eax
f010185b:	f7 f5                	div    %ebp
f010185d:	eb 9c                	jmp    f01017fb <__umoddi3+0x3b>
f010185f:	90                   	nop
f0101860:	89 c8                	mov    %ecx,%eax
f0101862:	89 fa                	mov    %edi,%edx
f0101864:	83 c4 14             	add    $0x14,%esp
f0101867:	5e                   	pop    %esi
f0101868:	5f                   	pop    %edi
f0101869:	5d                   	pop    %ebp
f010186a:	c3                   	ret    
f010186b:	90                   	nop
f010186c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101870:	8b 04 24             	mov    (%esp),%eax
f0101873:	be 20 00 00 00       	mov    $0x20,%esi
f0101878:	89 e9                	mov    %ebp,%ecx
f010187a:	29 ee                	sub    %ebp,%esi
f010187c:	d3 e2                	shl    %cl,%edx
f010187e:	89 f1                	mov    %esi,%ecx
f0101880:	d3 e8                	shr    %cl,%eax
f0101882:	89 e9                	mov    %ebp,%ecx
f0101884:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101888:	8b 04 24             	mov    (%esp),%eax
f010188b:	09 54 24 04          	or     %edx,0x4(%esp)
f010188f:	89 fa                	mov    %edi,%edx
f0101891:	d3 e0                	shl    %cl,%eax
f0101893:	89 f1                	mov    %esi,%ecx
f0101895:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101899:	8b 44 24 10          	mov    0x10(%esp),%eax
f010189d:	d3 ea                	shr    %cl,%edx
f010189f:	89 e9                	mov    %ebp,%ecx
f01018a1:	d3 e7                	shl    %cl,%edi
f01018a3:	89 f1                	mov    %esi,%ecx
f01018a5:	d3 e8                	shr    %cl,%eax
f01018a7:	89 e9                	mov    %ebp,%ecx
f01018a9:	09 f8                	or     %edi,%eax
f01018ab:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01018af:	f7 74 24 04          	divl   0x4(%esp)
f01018b3:	d3 e7                	shl    %cl,%edi
f01018b5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018b9:	89 d7                	mov    %edx,%edi
f01018bb:	f7 64 24 08          	mull   0x8(%esp)
f01018bf:	39 d7                	cmp    %edx,%edi
f01018c1:	89 c1                	mov    %eax,%ecx
f01018c3:	89 14 24             	mov    %edx,(%esp)
f01018c6:	72 2c                	jb     f01018f4 <__umoddi3+0x134>
f01018c8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f01018cc:	72 22                	jb     f01018f0 <__umoddi3+0x130>
f01018ce:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01018d2:	29 c8                	sub    %ecx,%eax
f01018d4:	19 d7                	sbb    %edx,%edi
f01018d6:	89 e9                	mov    %ebp,%ecx
f01018d8:	89 fa                	mov    %edi,%edx
f01018da:	d3 e8                	shr    %cl,%eax
f01018dc:	89 f1                	mov    %esi,%ecx
f01018de:	d3 e2                	shl    %cl,%edx
f01018e0:	89 e9                	mov    %ebp,%ecx
f01018e2:	d3 ef                	shr    %cl,%edi
f01018e4:	09 d0                	or     %edx,%eax
f01018e6:	89 fa                	mov    %edi,%edx
f01018e8:	83 c4 14             	add    $0x14,%esp
f01018eb:	5e                   	pop    %esi
f01018ec:	5f                   	pop    %edi
f01018ed:	5d                   	pop    %ebp
f01018ee:	c3                   	ret    
f01018ef:	90                   	nop
f01018f0:	39 d7                	cmp    %edx,%edi
f01018f2:	75 da                	jne    f01018ce <__umoddi3+0x10e>
f01018f4:	8b 14 24             	mov    (%esp),%edx
f01018f7:	89 c1                	mov    %eax,%ecx
f01018f9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f01018fd:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101901:	eb cb                	jmp    f01018ce <__umoddi3+0x10e>
f0101903:	90                   	nop
f0101904:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101908:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010190c:	0f 82 0f ff ff ff    	jb     f0101821 <__umoddi3+0x61>
f0101912:	e9 1a ff ff ff       	jmp    f0101831 <__umoddi3+0x71>
