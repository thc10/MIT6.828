
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
f010004e:	c7 04 24 e0 18 10 f0 	movl   $0xf01018e0,(%esp)
f0100055:	e8 f3 08 00 00       	call   f010094d <cprintf>
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
f0100082:	e8 34 07 00 00       	call   f01007bb <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 fc 18 10 f0 	movl   $0xf01018fc,(%esp)
f0100092:	e8 b6 08 00 00       	call   f010094d <cprintf>
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
f01000c0:	e8 82 13 00 00       	call   f0101447 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a5 04 00 00       	call   f010056f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 17 19 10 f0 	movl   $0xf0101917,(%esp)
f01000d9:	e8 6f 08 00 00       	call   f010094d <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 cf 06 00 00       	call   f01007c5 <monitor>
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
f0100125:	c7 04 24 32 19 10 f0 	movl   $0xf0101932,(%esp)
f010012c:	e8 1c 08 00 00       	call   f010094d <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 dd 07 00 00       	call   f010091a <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 6e 19 10 f0 	movl   $0xf010196e,(%esp)
f0100144:	e8 04 08 00 00       	call   f010094d <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 70 06 00 00       	call   f01007c5 <monitor>
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
f010016f:	c7 04 24 4a 19 10 f0 	movl   $0xf010194a,(%esp)
f0100176:	e8 d2 07 00 00       	call   f010094d <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 90 07 00 00       	call   f010091a <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 6e 19 10 f0 	movl   $0xf010196e,(%esp)
f0100191:	e8 b7 07 00 00       	call   f010094d <cprintf>
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
f010024d:	0f b6 82 c0 1a 10 f0 	movzbl -0xfefe540(%edx),%eax
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
f010028a:	0f b6 82 c0 1a 10 f0 	movzbl -0xfefe540(%edx),%eax
f0100291:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f0100297:	0f b6 8a c0 19 10 f0 	movzbl -0xfefe640(%edx),%ecx
f010029e:	31 c8                	xor    %ecx,%eax
f01002a0:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f01002a5:	89 c1                	mov    %eax,%ecx
f01002a7:	83 e1 03             	and    $0x3,%ecx
f01002aa:	8b 0c 8d a0 19 10 f0 	mov    -0xfefe660(,%ecx,4),%ecx
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
f01002ea:	c7 04 24 64 19 10 f0 	movl   $0xf0101964,(%esp)
f01002f1:	e8 57 06 00 00       	call   f010094d <cprintf>
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
f0100499:	e8 f6 0f 00 00       	call   f0101494 <memmove>
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
f010064d:	c7 04 24 70 19 10 f0 	movl   $0xf0101970,(%esp)
f0100654:	e8 f4 02 00 00       	call   f010094d <cprintf>
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
f0100696:	c7 44 24 08 c0 1b 10 	movl   $0xf0101bc0,0x8(%esp)
f010069d:	f0 
f010069e:	c7 44 24 04 de 1b 10 	movl   $0xf0101bde,0x4(%esp)
f01006a5:	f0 
f01006a6:	c7 04 24 e3 1b 10 f0 	movl   $0xf0101be3,(%esp)
f01006ad:	e8 9b 02 00 00       	call   f010094d <cprintf>
f01006b2:	c7 44 24 08 4c 1c 10 	movl   $0xf0101c4c,0x8(%esp)
f01006b9:	f0 
f01006ba:	c7 44 24 04 ec 1b 10 	movl   $0xf0101bec,0x4(%esp)
f01006c1:	f0 
f01006c2:	c7 04 24 e3 1b 10 f0 	movl   $0xf0101be3,(%esp)
f01006c9:	e8 7f 02 00 00       	call   f010094d <cprintf>
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
f01006db:	c7 04 24 f5 1b 10 f0 	movl   $0xf0101bf5,(%esp)
f01006e2:	e8 66 02 00 00       	call   f010094d <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006e7:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006ee:	00 
f01006ef:	c7 04 24 74 1c 10 f0 	movl   $0xf0101c74,(%esp)
f01006f6:	e8 52 02 00 00       	call   f010094d <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006fb:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100702:	00 
f0100703:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f010070a:	f0 
f010070b:	c7 04 24 9c 1c 10 f0 	movl   $0xf0101c9c,(%esp)
f0100712:	e8 36 02 00 00       	call   f010094d <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100717:	c7 44 24 08 d7 18 10 	movl   $0x1018d7,0x8(%esp)
f010071e:	00 
f010071f:	c7 44 24 04 d7 18 10 	movl   $0xf01018d7,0x4(%esp)
f0100726:	f0 
f0100727:	c7 04 24 c0 1c 10 f0 	movl   $0xf0101cc0,(%esp)
f010072e:	e8 1a 02 00 00       	call   f010094d <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100733:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f010073a:	00 
f010073b:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f0100742:	f0 
f0100743:	c7 04 24 e4 1c 10 f0 	movl   $0xf0101ce4,(%esp)
f010074a:	e8 fe 01 00 00       	call   f010094d <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010074f:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100756:	00 
f0100757:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010075e:	f0 
f010075f:	c7 04 24 08 1d 10 f0 	movl   $0xf0101d08,(%esp)
f0100766:	e8 e2 01 00 00       	call   f010094d <cprintf>
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
f010078c:	c7 04 24 2c 1d 10 f0 	movl   $0xf0101d2c,(%esp)
f0100793:	e8 b5 01 00 00       	call   f010094d <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	cprintf("\n here is test of printf o:\n 10 = 0%o\n 50 = 0%o\n", 10, 50);
f0100798:	c7 44 24 08 32 00 00 	movl   $0x32,0x8(%esp)
f010079f:	00 
f01007a0:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
f01007a7:	00 
f01007a8:	c7 04 24 58 1d 10 f0 	movl   $0xf0101d58,(%esp)
f01007af:	e8 99 01 00 00       	call   f010094d <cprintf>
	return 0;
}
f01007b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b9:	c9                   	leave  
f01007ba:	c3                   	ret    

f01007bb <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007bb:	55                   	push   %ebp
f01007bc:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f01007be:	b8 00 00 00 00       	mov    $0x0,%eax
f01007c3:	5d                   	pop    %ebp
f01007c4:	c3                   	ret    

f01007c5 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007c5:	55                   	push   %ebp
f01007c6:	89 e5                	mov    %esp,%ebp
f01007c8:	57                   	push   %edi
f01007c9:	56                   	push   %esi
f01007ca:	53                   	push   %ebx
f01007cb:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007ce:	c7 04 24 8c 1d 10 f0 	movl   $0xf0101d8c,(%esp)
f01007d5:	e8 73 01 00 00       	call   f010094d <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007da:	c7 04 24 b0 1d 10 f0 	movl   $0xf0101db0,(%esp)
f01007e1:	e8 67 01 00 00       	call   f010094d <cprintf>


	while (1) {
		buf = readline("K> ");
f01007e6:	c7 04 24 0e 1c 10 f0 	movl   $0xf0101c0e,(%esp)
f01007ed:	e8 fe 09 00 00       	call   f01011f0 <readline>
f01007f2:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007f4:	85 c0                	test   %eax,%eax
f01007f6:	74 ee                	je     f01007e6 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007f8:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007ff:	be 00 00 00 00       	mov    $0x0,%esi
f0100804:	eb 0a                	jmp    f0100810 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100806:	c6 03 00             	movb   $0x0,(%ebx)
f0100809:	89 f7                	mov    %esi,%edi
f010080b:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010080e:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100810:	0f b6 03             	movzbl (%ebx),%eax
f0100813:	84 c0                	test   %al,%al
f0100815:	74 63                	je     f010087a <monitor+0xb5>
f0100817:	0f be c0             	movsbl %al,%eax
f010081a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010081e:	c7 04 24 12 1c 10 f0 	movl   $0xf0101c12,(%esp)
f0100825:	e8 e0 0b 00 00       	call   f010140a <strchr>
f010082a:	85 c0                	test   %eax,%eax
f010082c:	75 d8                	jne    f0100806 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f010082e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100831:	74 47                	je     f010087a <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100833:	83 fe 0f             	cmp    $0xf,%esi
f0100836:	75 16                	jne    f010084e <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100838:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010083f:	00 
f0100840:	c7 04 24 17 1c 10 f0 	movl   $0xf0101c17,(%esp)
f0100847:	e8 01 01 00 00       	call   f010094d <cprintf>
f010084c:	eb 98                	jmp    f01007e6 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f010084e:	8d 7e 01             	lea    0x1(%esi),%edi
f0100851:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100855:	eb 03                	jmp    f010085a <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100857:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010085a:	0f b6 03             	movzbl (%ebx),%eax
f010085d:	84 c0                	test   %al,%al
f010085f:	74 ad                	je     f010080e <monitor+0x49>
f0100861:	0f be c0             	movsbl %al,%eax
f0100864:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100868:	c7 04 24 12 1c 10 f0 	movl   $0xf0101c12,(%esp)
f010086f:	e8 96 0b 00 00       	call   f010140a <strchr>
f0100874:	85 c0                	test   %eax,%eax
f0100876:	74 df                	je     f0100857 <monitor+0x92>
f0100878:	eb 94                	jmp    f010080e <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f010087a:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100881:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100882:	85 f6                	test   %esi,%esi
f0100884:	0f 84 5c ff ff ff    	je     f01007e6 <monitor+0x21>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010088a:	c7 44 24 04 de 1b 10 	movl   $0xf0101bde,0x4(%esp)
f0100891:	f0 
f0100892:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100895:	89 04 24             	mov    %eax,(%esp)
f0100898:	e8 0f 0b 00 00       	call   f01013ac <strcmp>
f010089d:	85 c0                	test   %eax,%eax
f010089f:	74 1b                	je     f01008bc <monitor+0xf7>
f01008a1:	c7 44 24 04 ec 1b 10 	movl   $0xf0101bec,0x4(%esp)
f01008a8:	f0 
f01008a9:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008ac:	89 04 24             	mov    %eax,(%esp)
f01008af:	e8 f8 0a 00 00       	call   f01013ac <strcmp>
f01008b4:	85 c0                	test   %eax,%eax
f01008b6:	75 2f                	jne    f01008e7 <monitor+0x122>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008b8:	b0 01                	mov    $0x1,%al
f01008ba:	eb 05                	jmp    f01008c1 <monitor+0xfc>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008bc:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008c1:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008c4:	01 d0                	add    %edx,%eax
f01008c6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01008c9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01008cd:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008d0:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008d4:	89 34 24             	mov    %esi,(%esp)
f01008d7:	ff 14 85 e0 1d 10 f0 	call   *-0xfefe220(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008de:	85 c0                	test   %eax,%eax
f01008e0:	78 1d                	js     f01008ff <monitor+0x13a>
f01008e2:	e9 ff fe ff ff       	jmp    f01007e6 <monitor+0x21>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008e7:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008ea:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ee:	c7 04 24 34 1c 10 f0 	movl   $0xf0101c34,(%esp)
f01008f5:	e8 53 00 00 00       	call   f010094d <cprintf>
f01008fa:	e9 e7 fe ff ff       	jmp    f01007e6 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008ff:	83 c4 5c             	add    $0x5c,%esp
f0100902:	5b                   	pop    %ebx
f0100903:	5e                   	pop    %esi
f0100904:	5f                   	pop    %edi
f0100905:	5d                   	pop    %ebp
f0100906:	c3                   	ret    

f0100907 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100907:	55                   	push   %ebp
f0100908:	89 e5                	mov    %esp,%ebp
f010090a:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010090d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100910:	89 04 24             	mov    %eax,(%esp)
f0100913:	e8 49 fd ff ff       	call   f0100661 <cputchar>
	*cnt++;
}
f0100918:	c9                   	leave  
f0100919:	c3                   	ret    

f010091a <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010091a:	55                   	push   %ebp
f010091b:	89 e5                	mov    %esp,%ebp
f010091d:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100920:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100927:	8b 45 0c             	mov    0xc(%ebp),%eax
f010092a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010092e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100931:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100935:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100938:	89 44 24 04          	mov    %eax,0x4(%esp)
f010093c:	c7 04 24 07 09 10 f0 	movl   $0xf0100907,(%esp)
f0100943:	e8 46 04 00 00       	call   f0100d8e <vprintfmt>
	return cnt;
}
f0100948:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010094b:	c9                   	leave  
f010094c:	c3                   	ret    

f010094d <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010094d:	55                   	push   %ebp
f010094e:	89 e5                	mov    %esp,%ebp
f0100950:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100953:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100956:	89 44 24 04          	mov    %eax,0x4(%esp)
f010095a:	8b 45 08             	mov    0x8(%ebp),%eax
f010095d:	89 04 24             	mov    %eax,(%esp)
f0100960:	e8 b5 ff ff ff       	call   f010091a <vcprintf>
	va_end(ap);

	return cnt;
}
f0100965:	c9                   	leave  
f0100966:	c3                   	ret    

f0100967 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100967:	55                   	push   %ebp
f0100968:	89 e5                	mov    %esp,%ebp
f010096a:	57                   	push   %edi
f010096b:	56                   	push   %esi
f010096c:	53                   	push   %ebx
f010096d:	83 ec 10             	sub    $0x10,%esp
f0100970:	89 c6                	mov    %eax,%esi
f0100972:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100975:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100978:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010097b:	8b 1a                	mov    (%edx),%ebx
f010097d:	8b 01                	mov    (%ecx),%eax
f010097f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100982:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100989:	eb 77                	jmp    f0100a02 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f010098b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010098e:	01 d8                	add    %ebx,%eax
f0100990:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100995:	99                   	cltd   
f0100996:	f7 f9                	idiv   %ecx
f0100998:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010099a:	eb 01                	jmp    f010099d <stab_binsearch+0x36>
			m--;
f010099c:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010099d:	39 d9                	cmp    %ebx,%ecx
f010099f:	7c 1d                	jl     f01009be <stab_binsearch+0x57>
f01009a1:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01009a4:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f01009a9:	39 fa                	cmp    %edi,%edx
f01009ab:	75 ef                	jne    f010099c <stab_binsearch+0x35>
f01009ad:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009b0:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01009b3:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f01009b7:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01009ba:	73 18                	jae    f01009d4 <stab_binsearch+0x6d>
f01009bc:	eb 05                	jmp    f01009c3 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009be:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f01009c1:	eb 3f                	jmp    f0100a02 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01009c3:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01009c6:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f01009c8:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009cb:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009d2:	eb 2e                	jmp    f0100a02 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009d4:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009d7:	73 15                	jae    f01009ee <stab_binsearch+0x87>
			*region_right = m - 1;
f01009d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01009dc:	48                   	dec    %eax
f01009dd:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009e0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009e3:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009e5:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009ec:	eb 14                	jmp    f0100a02 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009ee:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01009f1:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f01009f4:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f01009f6:	ff 45 0c             	incl   0xc(%ebp)
f01009f9:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009fb:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a02:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a05:	7e 84                	jle    f010098b <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a07:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a0b:	75 0d                	jne    f0100a1a <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100a0d:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a10:	8b 00                	mov    (%eax),%eax
f0100a12:	48                   	dec    %eax
f0100a13:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100a16:	89 07                	mov    %eax,(%edi)
f0100a18:	eb 22                	jmp    f0100a3c <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a1a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a1d:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a1f:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a22:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a24:	eb 01                	jmp    f0100a27 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a26:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a27:	39 c1                	cmp    %eax,%ecx
f0100a29:	7d 0c                	jge    f0100a37 <stab_binsearch+0xd0>
f0100a2b:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100a2e:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a33:	39 fa                	cmp    %edi,%edx
f0100a35:	75 ef                	jne    f0100a26 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a37:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100a3a:	89 07                	mov    %eax,(%edi)
	}
}
f0100a3c:	83 c4 10             	add    $0x10,%esp
f0100a3f:	5b                   	pop    %ebx
f0100a40:	5e                   	pop    %esi
f0100a41:	5f                   	pop    %edi
f0100a42:	5d                   	pop    %ebp
f0100a43:	c3                   	ret    

f0100a44 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a44:	55                   	push   %ebp
f0100a45:	89 e5                	mov    %esp,%ebp
f0100a47:	57                   	push   %edi
f0100a48:	56                   	push   %esi
f0100a49:	53                   	push   %ebx
f0100a4a:	83 ec 2c             	sub    $0x2c,%esp
f0100a4d:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a50:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a53:	c7 03 f0 1d 10 f0    	movl   $0xf0101df0,(%ebx)
	info->eip_line = 0;
f0100a59:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a60:	c7 43 08 f0 1d 10 f0 	movl   $0xf0101df0,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100a67:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100a6e:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100a71:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a78:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100a7e:	76 12                	jbe    f0100a92 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a80:	b8 51 71 10 f0       	mov    $0xf0107151,%eax
f0100a85:	3d 75 58 10 f0       	cmp    $0xf0105875,%eax
f0100a8a:	0f 86 6b 01 00 00    	jbe    f0100bfb <debuginfo_eip+0x1b7>
f0100a90:	eb 1c                	jmp    f0100aae <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a92:	c7 44 24 08 fa 1d 10 	movl   $0xf0101dfa,0x8(%esp)
f0100a99:	f0 
f0100a9a:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100aa1:	00 
f0100aa2:	c7 04 24 07 1e 10 f0 	movl   $0xf0101e07,(%esp)
f0100aa9:	e8 4a f6 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100aae:	80 3d 50 71 10 f0 00 	cmpb   $0x0,0xf0107150
f0100ab5:	0f 85 47 01 00 00    	jne    f0100c02 <debuginfo_eip+0x1be>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100abb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100ac2:	b8 74 58 10 f0       	mov    $0xf0105874,%eax
f0100ac7:	2d 28 20 10 f0       	sub    $0xf0102028,%eax
f0100acc:	c1 f8 02             	sar    $0x2,%eax
f0100acf:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100ad5:	83 e8 01             	sub    $0x1,%eax
f0100ad8:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100adb:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100adf:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100ae6:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100ae9:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100aec:	b8 28 20 10 f0       	mov    $0xf0102028,%eax
f0100af1:	e8 71 fe ff ff       	call   f0100967 <stab_binsearch>
	if (lfile == 0)
f0100af6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100af9:	85 c0                	test   %eax,%eax
f0100afb:	0f 84 08 01 00 00    	je     f0100c09 <debuginfo_eip+0x1c5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b01:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b04:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b07:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b0a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b0e:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b15:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b18:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b1b:	b8 28 20 10 f0       	mov    $0xf0102028,%eax
f0100b20:	e8 42 fe ff ff       	call   f0100967 <stab_binsearch>

	if (lfun <= rfun) {
f0100b25:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100b28:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100b2b:	7f 2e                	jg     f0100b5b <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b2d:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b30:	8d 90 28 20 10 f0    	lea    -0xfefdfd8(%eax),%edx
f0100b36:	8b 80 28 20 10 f0    	mov    -0xfefdfd8(%eax),%eax
f0100b3c:	b9 51 71 10 f0       	mov    $0xf0107151,%ecx
f0100b41:	81 e9 75 58 10 f0    	sub    $0xf0105875,%ecx
f0100b47:	39 c8                	cmp    %ecx,%eax
f0100b49:	73 08                	jae    f0100b53 <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b4b:	05 75 58 10 f0       	add    $0xf0105875,%eax
f0100b50:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b53:	8b 42 08             	mov    0x8(%edx),%eax
f0100b56:	89 43 10             	mov    %eax,0x10(%ebx)
f0100b59:	eb 06                	jmp    f0100b61 <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b5b:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b5e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b61:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100b68:	00 
f0100b69:	8b 43 08             	mov    0x8(%ebx),%eax
f0100b6c:	89 04 24             	mov    %eax,(%esp)
f0100b6f:	e8 b7 08 00 00       	call   f010142b <strfind>
f0100b74:	2b 43 08             	sub    0x8(%ebx),%eax
f0100b77:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b7a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b7d:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b80:	05 28 20 10 f0       	add    $0xf0102028,%eax
f0100b85:	eb 06                	jmp    f0100b8d <debuginfo_eip+0x149>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b87:	83 ef 01             	sub    $0x1,%edi
f0100b8a:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b8d:	39 cf                	cmp    %ecx,%edi
f0100b8f:	7c 33                	jl     f0100bc4 <debuginfo_eip+0x180>
	       && stabs[lline].n_type != N_SOL
f0100b91:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100b95:	80 fa 84             	cmp    $0x84,%dl
f0100b98:	74 0b                	je     f0100ba5 <debuginfo_eip+0x161>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b9a:	80 fa 64             	cmp    $0x64,%dl
f0100b9d:	75 e8                	jne    f0100b87 <debuginfo_eip+0x143>
f0100b9f:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100ba3:	74 e2                	je     f0100b87 <debuginfo_eip+0x143>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100ba5:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100ba8:	8b 87 28 20 10 f0    	mov    -0xfefdfd8(%edi),%eax
f0100bae:	ba 51 71 10 f0       	mov    $0xf0107151,%edx
f0100bb3:	81 ea 75 58 10 f0    	sub    $0xf0105875,%edx
f0100bb9:	39 d0                	cmp    %edx,%eax
f0100bbb:	73 07                	jae    f0100bc4 <debuginfo_eip+0x180>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100bbd:	05 75 58 10 f0       	add    $0xf0105875,%eax
f0100bc2:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bc4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100bc7:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bca:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bcf:	39 f1                	cmp    %esi,%ecx
f0100bd1:	7d 42                	jge    f0100c15 <debuginfo_eip+0x1d1>
		for (lline = lfun + 1;
f0100bd3:	8d 51 01             	lea    0x1(%ecx),%edx
f0100bd6:	6b c1 0c             	imul   $0xc,%ecx,%eax
f0100bd9:	05 28 20 10 f0       	add    $0xf0102028,%eax
f0100bde:	eb 07                	jmp    f0100be7 <debuginfo_eip+0x1a3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100be0:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100be4:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100be7:	39 f2                	cmp    %esi,%edx
f0100be9:	74 25                	je     f0100c10 <debuginfo_eip+0x1cc>
f0100beb:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bee:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100bf2:	74 ec                	je     f0100be0 <debuginfo_eip+0x19c>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bf4:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bf9:	eb 1a                	jmp    f0100c15 <debuginfo_eip+0x1d1>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100bfb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c00:	eb 13                	jmp    f0100c15 <debuginfo_eip+0x1d1>
f0100c02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c07:	eb 0c                	jmp    f0100c15 <debuginfo_eip+0x1d1>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c0e:	eb 05                	jmp    f0100c15 <debuginfo_eip+0x1d1>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c10:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c15:	83 c4 2c             	add    $0x2c,%esp
f0100c18:	5b                   	pop    %ebx
f0100c19:	5e                   	pop    %esi
f0100c1a:	5f                   	pop    %edi
f0100c1b:	5d                   	pop    %ebp
f0100c1c:	c3                   	ret    
f0100c1d:	66 90                	xchg   %ax,%ax
f0100c1f:	90                   	nop

f0100c20 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c20:	55                   	push   %ebp
f0100c21:	89 e5                	mov    %esp,%ebp
f0100c23:	57                   	push   %edi
f0100c24:	56                   	push   %esi
f0100c25:	53                   	push   %ebx
f0100c26:	83 ec 3c             	sub    $0x3c,%esp
f0100c29:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100c2c:	89 d7                	mov    %edx,%edi
f0100c2e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c31:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100c34:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c37:	89 c3                	mov    %eax,%ebx
f0100c39:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100c3c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100c3f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c42:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100c47:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c4a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100c4d:	39 d9                	cmp    %ebx,%ecx
f0100c4f:	72 05                	jb     f0100c56 <printnum+0x36>
f0100c51:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100c54:	77 69                	ja     f0100cbf <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c56:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100c59:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100c5d:	83 ee 01             	sub    $0x1,%esi
f0100c60:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100c64:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100c68:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100c6c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100c70:	89 c3                	mov    %eax,%ebx
f0100c72:	89 d6                	mov    %edx,%esi
f0100c74:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100c77:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100c7a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100c7e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100c82:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c85:	89 04 24             	mov    %eax,(%esp)
f0100c88:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c8b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c8f:	e8 bc 09 00 00       	call   f0101650 <__udivdi3>
f0100c94:	89 d9                	mov    %ebx,%ecx
f0100c96:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100c9a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100c9e:	89 04 24             	mov    %eax,(%esp)
f0100ca1:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100ca5:	89 fa                	mov    %edi,%edx
f0100ca7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100caa:	e8 71 ff ff ff       	call   f0100c20 <printnum>
f0100caf:	eb 1b                	jmp    f0100ccc <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100cb1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cb5:	8b 45 18             	mov    0x18(%ebp),%eax
f0100cb8:	89 04 24             	mov    %eax,(%esp)
f0100cbb:	ff d3                	call   *%ebx
f0100cbd:	eb 03                	jmp    f0100cc2 <printnum+0xa2>
f0100cbf:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100cc2:	83 ee 01             	sub    $0x1,%esi
f0100cc5:	85 f6                	test   %esi,%esi
f0100cc7:	7f e8                	jg     f0100cb1 <printnum+0x91>
f0100cc9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100ccc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cd0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100cd4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100cd7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100cda:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cde:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100ce2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ce5:	89 04 24             	mov    %eax,(%esp)
f0100ce8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ceb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cef:	e8 8c 0a 00 00       	call   f0101780 <__umoddi3>
f0100cf4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cf8:	0f be 80 15 1e 10 f0 	movsbl -0xfefe1eb(%eax),%eax
f0100cff:	89 04 24             	mov    %eax,(%esp)
f0100d02:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d05:	ff d0                	call   *%eax
}
f0100d07:	83 c4 3c             	add    $0x3c,%esp
f0100d0a:	5b                   	pop    %ebx
f0100d0b:	5e                   	pop    %esi
f0100d0c:	5f                   	pop    %edi
f0100d0d:	5d                   	pop    %ebp
f0100d0e:	c3                   	ret    

f0100d0f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d0f:	55                   	push   %ebp
f0100d10:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d12:	83 fa 01             	cmp    $0x1,%edx
f0100d15:	7e 0e                	jle    f0100d25 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d17:	8b 10                	mov    (%eax),%edx
f0100d19:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d1c:	89 08                	mov    %ecx,(%eax)
f0100d1e:	8b 02                	mov    (%edx),%eax
f0100d20:	8b 52 04             	mov    0x4(%edx),%edx
f0100d23:	eb 22                	jmp    f0100d47 <getuint+0x38>
	else if (lflag)
f0100d25:	85 d2                	test   %edx,%edx
f0100d27:	74 10                	je     f0100d39 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d29:	8b 10                	mov    (%eax),%edx
f0100d2b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d2e:	89 08                	mov    %ecx,(%eax)
f0100d30:	8b 02                	mov    (%edx),%eax
f0100d32:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d37:	eb 0e                	jmp    f0100d47 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d39:	8b 10                	mov    (%eax),%edx
f0100d3b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d3e:	89 08                	mov    %ecx,(%eax)
f0100d40:	8b 02                	mov    (%edx),%eax
f0100d42:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d47:	5d                   	pop    %ebp
f0100d48:	c3                   	ret    

f0100d49 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d49:	55                   	push   %ebp
f0100d4a:	89 e5                	mov    %esp,%ebp
f0100d4c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d4f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d53:	8b 10                	mov    (%eax),%edx
f0100d55:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d58:	73 0a                	jae    f0100d64 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d5a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d5d:	89 08                	mov    %ecx,(%eax)
f0100d5f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d62:	88 02                	mov    %al,(%edx)
}
f0100d64:	5d                   	pop    %ebp
f0100d65:	c3                   	ret    

f0100d66 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d66:	55                   	push   %ebp
f0100d67:	89 e5                	mov    %esp,%ebp
f0100d69:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d6c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d6f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d73:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d76:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d7a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d7d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d81:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d84:	89 04 24             	mov    %eax,(%esp)
f0100d87:	e8 02 00 00 00       	call   f0100d8e <vprintfmt>
	va_end(ap);
}
f0100d8c:	c9                   	leave  
f0100d8d:	c3                   	ret    

f0100d8e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d8e:	55                   	push   %ebp
f0100d8f:	89 e5                	mov    %esp,%ebp
f0100d91:	57                   	push   %edi
f0100d92:	56                   	push   %esi
f0100d93:	53                   	push   %ebx
f0100d94:	83 ec 3c             	sub    $0x3c,%esp
f0100d97:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100d9a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100d9d:	eb 14                	jmp    f0100db3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100d9f:	85 c0                	test   %eax,%eax
f0100da1:	0f 84 b3 03 00 00    	je     f010115a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0100da7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dab:	89 04 24             	mov    %eax,(%esp)
f0100dae:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100db1:	89 f3                	mov    %esi,%ebx
f0100db3:	8d 73 01             	lea    0x1(%ebx),%esi
f0100db6:	0f b6 03             	movzbl (%ebx),%eax
f0100db9:	83 f8 25             	cmp    $0x25,%eax
f0100dbc:	75 e1                	jne    f0100d9f <vprintfmt+0x11>
f0100dbe:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100dc2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100dc9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100dd0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100dd7:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ddc:	eb 1d                	jmp    f0100dfb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dde:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100de0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100de4:	eb 15                	jmp    f0100dfb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100de6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100de8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100dec:	eb 0d                	jmp    f0100dfb <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100dee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100df1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100df4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dfb:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100dfe:	0f b6 0e             	movzbl (%esi),%ecx
f0100e01:	0f b6 c1             	movzbl %cl,%eax
f0100e04:	83 e9 23             	sub    $0x23,%ecx
f0100e07:	80 f9 55             	cmp    $0x55,%cl
f0100e0a:	0f 87 2a 03 00 00    	ja     f010113a <vprintfmt+0x3ac>
f0100e10:	0f b6 c9             	movzbl %cl,%ecx
f0100e13:	ff 24 8d a4 1e 10 f0 	jmp    *-0xfefe15c(,%ecx,4)
f0100e1a:	89 de                	mov    %ebx,%esi
f0100e1c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e21:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100e24:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100e28:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100e2b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100e2e:	83 fb 09             	cmp    $0x9,%ebx
f0100e31:	77 36                	ja     f0100e69 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e33:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e36:	eb e9                	jmp    f0100e21 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e38:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e3b:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e3e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e41:	8b 00                	mov    (%eax),%eax
f0100e43:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e46:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e48:	eb 22                	jmp    f0100e6c <vprintfmt+0xde>
f0100e4a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100e4d:	85 c9                	test   %ecx,%ecx
f0100e4f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e54:	0f 49 c1             	cmovns %ecx,%eax
f0100e57:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e5a:	89 de                	mov    %ebx,%esi
f0100e5c:	eb 9d                	jmp    f0100dfb <vprintfmt+0x6d>
f0100e5e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e60:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0100e67:	eb 92                	jmp    f0100dfb <vprintfmt+0x6d>
f0100e69:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f0100e6c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100e70:	79 89                	jns    f0100dfb <vprintfmt+0x6d>
f0100e72:	e9 77 ff ff ff       	jmp    f0100dee <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e77:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e7a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e7c:	e9 7a ff ff ff       	jmp    f0100dfb <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e81:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e84:	8d 50 04             	lea    0x4(%eax),%edx
f0100e87:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e8a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e8e:	8b 00                	mov    (%eax),%eax
f0100e90:	89 04 24             	mov    %eax,(%esp)
f0100e93:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100e96:	e9 18 ff ff ff       	jmp    f0100db3 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e9b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e9e:	8d 50 04             	lea    0x4(%eax),%edx
f0100ea1:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ea4:	8b 00                	mov    (%eax),%eax
f0100ea6:	99                   	cltd   
f0100ea7:	31 d0                	xor    %edx,%eax
f0100ea9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100eab:	83 f8 06             	cmp    $0x6,%eax
f0100eae:	7f 0b                	jg     f0100ebb <vprintfmt+0x12d>
f0100eb0:	8b 14 85 fc 1f 10 f0 	mov    -0xfefe004(,%eax,4),%edx
f0100eb7:	85 d2                	test   %edx,%edx
f0100eb9:	75 20                	jne    f0100edb <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f0100ebb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ebf:	c7 44 24 08 2d 1e 10 	movl   $0xf0101e2d,0x8(%esp)
f0100ec6:	f0 
f0100ec7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ecb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ece:	89 04 24             	mov    %eax,(%esp)
f0100ed1:	e8 90 fe ff ff       	call   f0100d66 <printfmt>
f0100ed6:	e9 d8 fe ff ff       	jmp    f0100db3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0100edb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100edf:	c7 44 24 08 36 1e 10 	movl   $0xf0101e36,0x8(%esp)
f0100ee6:	f0 
f0100ee7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100eeb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100eee:	89 04 24             	mov    %eax,(%esp)
f0100ef1:	e8 70 fe ff ff       	call   f0100d66 <printfmt>
f0100ef6:	e9 b8 fe ff ff       	jmp    f0100db3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100efb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100efe:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100f01:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f04:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f07:	8d 50 04             	lea    0x4(%eax),%edx
f0100f0a:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f0d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0100f0f:	85 f6                	test   %esi,%esi
f0100f11:	b8 26 1e 10 f0       	mov    $0xf0101e26,%eax
f0100f16:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0100f19:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0100f1d:	0f 84 97 00 00 00    	je     f0100fba <vprintfmt+0x22c>
f0100f23:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0100f27:	0f 8e 9b 00 00 00    	jle    f0100fc8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f2d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100f31:	89 34 24             	mov    %esi,(%esp)
f0100f34:	e8 9f 03 00 00       	call   f01012d8 <strnlen>
f0100f39:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100f3c:	29 c2                	sub    %eax,%edx
f0100f3e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0100f41:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0100f45:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100f48:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0100f4b:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f4e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0100f51:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f53:	eb 0f                	jmp    f0100f64 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0100f55:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f59:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100f5c:	89 04 24             	mov    %eax,(%esp)
f0100f5f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f61:	83 eb 01             	sub    $0x1,%ebx
f0100f64:	85 db                	test   %ebx,%ebx
f0100f66:	7f ed                	jg     f0100f55 <vprintfmt+0x1c7>
f0100f68:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0100f6b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100f6e:	85 d2                	test   %edx,%edx
f0100f70:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f75:	0f 49 c2             	cmovns %edx,%eax
f0100f78:	29 c2                	sub    %eax,%edx
f0100f7a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0100f7d:	89 d7                	mov    %edx,%edi
f0100f7f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100f82:	eb 50                	jmp    f0100fd4 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f84:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f88:	74 1e                	je     f0100fa8 <vprintfmt+0x21a>
f0100f8a:	0f be d2             	movsbl %dl,%edx
f0100f8d:	83 ea 20             	sub    $0x20,%edx
f0100f90:	83 fa 5e             	cmp    $0x5e,%edx
f0100f93:	76 13                	jbe    f0100fa8 <vprintfmt+0x21a>
					putch('?', putdat);
f0100f95:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f98:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f9c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100fa3:	ff 55 08             	call   *0x8(%ebp)
f0100fa6:	eb 0d                	jmp    f0100fb5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0100fa8:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100fab:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100faf:	89 04 24             	mov    %eax,(%esp)
f0100fb2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fb5:	83 ef 01             	sub    $0x1,%edi
f0100fb8:	eb 1a                	jmp    f0100fd4 <vprintfmt+0x246>
f0100fba:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0100fbd:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100fc0:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0100fc3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100fc6:	eb 0c                	jmp    f0100fd4 <vprintfmt+0x246>
f0100fc8:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0100fcb:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100fce:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0100fd1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100fd4:	83 c6 01             	add    $0x1,%esi
f0100fd7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0100fdb:	0f be c2             	movsbl %dl,%eax
f0100fde:	85 c0                	test   %eax,%eax
f0100fe0:	74 27                	je     f0101009 <vprintfmt+0x27b>
f0100fe2:	85 db                	test   %ebx,%ebx
f0100fe4:	78 9e                	js     f0100f84 <vprintfmt+0x1f6>
f0100fe6:	83 eb 01             	sub    $0x1,%ebx
f0100fe9:	79 99                	jns    f0100f84 <vprintfmt+0x1f6>
f0100feb:	89 f8                	mov    %edi,%eax
f0100fed:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100ff0:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ff3:	89 c3                	mov    %eax,%ebx
f0100ff5:	eb 1a                	jmp    f0101011 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100ff7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ffb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101002:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101004:	83 eb 01             	sub    $0x1,%ebx
f0101007:	eb 08                	jmp    f0101011 <vprintfmt+0x283>
f0101009:	89 fb                	mov    %edi,%ebx
f010100b:	8b 75 08             	mov    0x8(%ebp),%esi
f010100e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101011:	85 db                	test   %ebx,%ebx
f0101013:	7f e2                	jg     f0100ff7 <vprintfmt+0x269>
f0101015:	89 75 08             	mov    %esi,0x8(%ebp)
f0101018:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010101b:	e9 93 fd ff ff       	jmp    f0100db3 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101020:	83 fa 01             	cmp    $0x1,%edx
f0101023:	7e 16                	jle    f010103b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0101025:	8b 45 14             	mov    0x14(%ebp),%eax
f0101028:	8d 50 08             	lea    0x8(%eax),%edx
f010102b:	89 55 14             	mov    %edx,0x14(%ebp)
f010102e:	8b 50 04             	mov    0x4(%eax),%edx
f0101031:	8b 00                	mov    (%eax),%eax
f0101033:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101036:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101039:	eb 32                	jmp    f010106d <vprintfmt+0x2df>
	else if (lflag)
f010103b:	85 d2                	test   %edx,%edx
f010103d:	74 18                	je     f0101057 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010103f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101042:	8d 50 04             	lea    0x4(%eax),%edx
f0101045:	89 55 14             	mov    %edx,0x14(%ebp)
f0101048:	8b 30                	mov    (%eax),%esi
f010104a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010104d:	89 f0                	mov    %esi,%eax
f010104f:	c1 f8 1f             	sar    $0x1f,%eax
f0101052:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101055:	eb 16                	jmp    f010106d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0101057:	8b 45 14             	mov    0x14(%ebp),%eax
f010105a:	8d 50 04             	lea    0x4(%eax),%edx
f010105d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101060:	8b 30                	mov    (%eax),%esi
f0101062:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0101065:	89 f0                	mov    %esi,%eax
f0101067:	c1 f8 1f             	sar    $0x1f,%eax
f010106a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010106d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101070:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101073:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101078:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010107c:	0f 89 80 00 00 00    	jns    f0101102 <vprintfmt+0x374>
				putch('-', putdat);
f0101082:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101086:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010108d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101090:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101093:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101096:	f7 d8                	neg    %eax
f0101098:	83 d2 00             	adc    $0x0,%edx
f010109b:	f7 da                	neg    %edx
			}
			base = 10;
f010109d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01010a2:	eb 5e                	jmp    f0101102 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01010a4:	8d 45 14             	lea    0x14(%ebp),%eax
f01010a7:	e8 63 fc ff ff       	call   f0100d0f <getuint>
			base = 10;
f01010ac:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01010b1:	eb 4f                	jmp    f0101102 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01010b3:	8d 45 14             	lea    0x14(%ebp),%eax
f01010b6:	e8 54 fc ff ff       	call   f0100d0f <getuint>
			base = 8;
f01010bb:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01010c0:	eb 40                	jmp    f0101102 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f01010c2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010c6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01010cd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01010d0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010d4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01010db:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01010de:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e1:	8d 50 04             	lea    0x4(%eax),%edx
f01010e4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01010e7:	8b 00                	mov    (%eax),%eax
f01010e9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01010ee:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01010f3:	eb 0d                	jmp    f0101102 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01010f5:	8d 45 14             	lea    0x14(%ebp),%eax
f01010f8:	e8 12 fc ff ff       	call   f0100d0f <getuint>
			base = 16;
f01010fd:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101102:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0101106:	89 74 24 10          	mov    %esi,0x10(%esp)
f010110a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010110d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101111:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101115:	89 04 24             	mov    %eax,(%esp)
f0101118:	89 54 24 04          	mov    %edx,0x4(%esp)
f010111c:	89 fa                	mov    %edi,%edx
f010111e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101121:	e8 fa fa ff ff       	call   f0100c20 <printnum>
			break;
f0101126:	e9 88 fc ff ff       	jmp    f0100db3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010112b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010112f:	89 04 24             	mov    %eax,(%esp)
f0101132:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101135:	e9 79 fc ff ff       	jmp    f0100db3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010113a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010113e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101145:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101148:	89 f3                	mov    %esi,%ebx
f010114a:	eb 03                	jmp    f010114f <vprintfmt+0x3c1>
f010114c:	83 eb 01             	sub    $0x1,%ebx
f010114f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0101153:	75 f7                	jne    f010114c <vprintfmt+0x3be>
f0101155:	e9 59 fc ff ff       	jmp    f0100db3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010115a:	83 c4 3c             	add    $0x3c,%esp
f010115d:	5b                   	pop    %ebx
f010115e:	5e                   	pop    %esi
f010115f:	5f                   	pop    %edi
f0101160:	5d                   	pop    %ebp
f0101161:	c3                   	ret    

f0101162 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101162:	55                   	push   %ebp
f0101163:	89 e5                	mov    %esp,%ebp
f0101165:	83 ec 28             	sub    $0x28,%esp
f0101168:	8b 45 08             	mov    0x8(%ebp),%eax
f010116b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010116e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101171:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101175:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101178:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010117f:	85 c0                	test   %eax,%eax
f0101181:	74 30                	je     f01011b3 <vsnprintf+0x51>
f0101183:	85 d2                	test   %edx,%edx
f0101185:	7e 2c                	jle    f01011b3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101187:	8b 45 14             	mov    0x14(%ebp),%eax
f010118a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010118e:	8b 45 10             	mov    0x10(%ebp),%eax
f0101191:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101195:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101198:	89 44 24 04          	mov    %eax,0x4(%esp)
f010119c:	c7 04 24 49 0d 10 f0 	movl   $0xf0100d49,(%esp)
f01011a3:	e8 e6 fb ff ff       	call   f0100d8e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011a8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011ab:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011b1:	eb 05                	jmp    f01011b8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011b3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011b8:	c9                   	leave  
f01011b9:	c3                   	ret    

f01011ba <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011ba:	55                   	push   %ebp
f01011bb:	89 e5                	mov    %esp,%ebp
f01011bd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011c0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011c3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011c7:	8b 45 10             	mov    0x10(%ebp),%eax
f01011ca:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011ce:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011d1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011d5:	8b 45 08             	mov    0x8(%ebp),%eax
f01011d8:	89 04 24             	mov    %eax,(%esp)
f01011db:	e8 82 ff ff ff       	call   f0101162 <vsnprintf>
	va_end(ap);

	return rc;
}
f01011e0:	c9                   	leave  
f01011e1:	c3                   	ret    
f01011e2:	66 90                	xchg   %ax,%ax
f01011e4:	66 90                	xchg   %ax,%ax
f01011e6:	66 90                	xchg   %ax,%ax
f01011e8:	66 90                	xchg   %ax,%ax
f01011ea:	66 90                	xchg   %ax,%ax
f01011ec:	66 90                	xchg   %ax,%ax
f01011ee:	66 90                	xchg   %ax,%ax

f01011f0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01011f0:	55                   	push   %ebp
f01011f1:	89 e5                	mov    %esp,%ebp
f01011f3:	57                   	push   %edi
f01011f4:	56                   	push   %esi
f01011f5:	53                   	push   %ebx
f01011f6:	83 ec 1c             	sub    $0x1c,%esp
f01011f9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01011fc:	85 c0                	test   %eax,%eax
f01011fe:	74 10                	je     f0101210 <readline+0x20>
		cprintf("%s", prompt);
f0101200:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101204:	c7 04 24 36 1e 10 f0 	movl   $0xf0101e36,(%esp)
f010120b:	e8 3d f7 ff ff       	call   f010094d <cprintf>

	i = 0;
	echoing = iscons(0);
f0101210:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101217:	e8 66 f4 ff ff       	call   f0100682 <iscons>
f010121c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010121e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101223:	e8 49 f4 ff ff       	call   f0100671 <getchar>
f0101228:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010122a:	85 c0                	test   %eax,%eax
f010122c:	79 17                	jns    f0101245 <readline+0x55>
			cprintf("read error: %e\n", c);
f010122e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101232:	c7 04 24 18 20 10 f0 	movl   $0xf0102018,(%esp)
f0101239:	e8 0f f7 ff ff       	call   f010094d <cprintf>
			return NULL;
f010123e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101243:	eb 6d                	jmp    f01012b2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101245:	83 f8 7f             	cmp    $0x7f,%eax
f0101248:	74 05                	je     f010124f <readline+0x5f>
f010124a:	83 f8 08             	cmp    $0x8,%eax
f010124d:	75 19                	jne    f0101268 <readline+0x78>
f010124f:	85 f6                	test   %esi,%esi
f0101251:	7e 15                	jle    f0101268 <readline+0x78>
			if (echoing)
f0101253:	85 ff                	test   %edi,%edi
f0101255:	74 0c                	je     f0101263 <readline+0x73>
				cputchar('\b');
f0101257:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010125e:	e8 fe f3 ff ff       	call   f0100661 <cputchar>
			i--;
f0101263:	83 ee 01             	sub    $0x1,%esi
f0101266:	eb bb                	jmp    f0101223 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101268:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010126e:	7f 1c                	jg     f010128c <readline+0x9c>
f0101270:	83 fb 1f             	cmp    $0x1f,%ebx
f0101273:	7e 17                	jle    f010128c <readline+0x9c>
			if (echoing)
f0101275:	85 ff                	test   %edi,%edi
f0101277:	74 08                	je     f0101281 <readline+0x91>
				cputchar(c);
f0101279:	89 1c 24             	mov    %ebx,(%esp)
f010127c:	e8 e0 f3 ff ff       	call   f0100661 <cputchar>
			buf[i++] = c;
f0101281:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101287:	8d 76 01             	lea    0x1(%esi),%esi
f010128a:	eb 97                	jmp    f0101223 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010128c:	83 fb 0d             	cmp    $0xd,%ebx
f010128f:	74 05                	je     f0101296 <readline+0xa6>
f0101291:	83 fb 0a             	cmp    $0xa,%ebx
f0101294:	75 8d                	jne    f0101223 <readline+0x33>
			if (echoing)
f0101296:	85 ff                	test   %edi,%edi
f0101298:	74 0c                	je     f01012a6 <readline+0xb6>
				cputchar('\n');
f010129a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01012a1:	e8 bb f3 ff ff       	call   f0100661 <cputchar>
			buf[i] = 0;
f01012a6:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01012ad:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01012b2:	83 c4 1c             	add    $0x1c,%esp
f01012b5:	5b                   	pop    %ebx
f01012b6:	5e                   	pop    %esi
f01012b7:	5f                   	pop    %edi
f01012b8:	5d                   	pop    %ebp
f01012b9:	c3                   	ret    
f01012ba:	66 90                	xchg   %ax,%ax
f01012bc:	66 90                	xchg   %ax,%ax
f01012be:	66 90                	xchg   %ax,%ax

f01012c0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012c0:	55                   	push   %ebp
f01012c1:	89 e5                	mov    %esp,%ebp
f01012c3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01012cb:	eb 03                	jmp    f01012d0 <strlen+0x10>
		n++;
f01012cd:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012d0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012d4:	75 f7                	jne    f01012cd <strlen+0xd>
		n++;
	return n;
}
f01012d6:	5d                   	pop    %ebp
f01012d7:	c3                   	ret    

f01012d8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012d8:	55                   	push   %ebp
f01012d9:	89 e5                	mov    %esp,%ebp
f01012db:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01012de:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01012e6:	eb 03                	jmp    f01012eb <strnlen+0x13>
		n++;
f01012e8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012eb:	39 d0                	cmp    %edx,%eax
f01012ed:	74 06                	je     f01012f5 <strnlen+0x1d>
f01012ef:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01012f3:	75 f3                	jne    f01012e8 <strnlen+0x10>
		n++;
	return n;
}
f01012f5:	5d                   	pop    %ebp
f01012f6:	c3                   	ret    

f01012f7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01012f7:	55                   	push   %ebp
f01012f8:	89 e5                	mov    %esp,%ebp
f01012fa:	53                   	push   %ebx
f01012fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01012fe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101301:	89 c2                	mov    %eax,%edx
f0101303:	83 c2 01             	add    $0x1,%edx
f0101306:	83 c1 01             	add    $0x1,%ecx
f0101309:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010130d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101310:	84 db                	test   %bl,%bl
f0101312:	75 ef                	jne    f0101303 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101314:	5b                   	pop    %ebx
f0101315:	5d                   	pop    %ebp
f0101316:	c3                   	ret    

f0101317 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101317:	55                   	push   %ebp
f0101318:	89 e5                	mov    %esp,%ebp
f010131a:	53                   	push   %ebx
f010131b:	83 ec 08             	sub    $0x8,%esp
f010131e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101321:	89 1c 24             	mov    %ebx,(%esp)
f0101324:	e8 97 ff ff ff       	call   f01012c0 <strlen>
	strcpy(dst + len, src);
f0101329:	8b 55 0c             	mov    0xc(%ebp),%edx
f010132c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101330:	01 d8                	add    %ebx,%eax
f0101332:	89 04 24             	mov    %eax,(%esp)
f0101335:	e8 bd ff ff ff       	call   f01012f7 <strcpy>
	return dst;
}
f010133a:	89 d8                	mov    %ebx,%eax
f010133c:	83 c4 08             	add    $0x8,%esp
f010133f:	5b                   	pop    %ebx
f0101340:	5d                   	pop    %ebp
f0101341:	c3                   	ret    

f0101342 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101342:	55                   	push   %ebp
f0101343:	89 e5                	mov    %esp,%ebp
f0101345:	56                   	push   %esi
f0101346:	53                   	push   %ebx
f0101347:	8b 75 08             	mov    0x8(%ebp),%esi
f010134a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010134d:	89 f3                	mov    %esi,%ebx
f010134f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101352:	89 f2                	mov    %esi,%edx
f0101354:	eb 0f                	jmp    f0101365 <strncpy+0x23>
		*dst++ = *src;
f0101356:	83 c2 01             	add    $0x1,%edx
f0101359:	0f b6 01             	movzbl (%ecx),%eax
f010135c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010135f:	80 39 01             	cmpb   $0x1,(%ecx)
f0101362:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101365:	39 da                	cmp    %ebx,%edx
f0101367:	75 ed                	jne    f0101356 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101369:	89 f0                	mov    %esi,%eax
f010136b:	5b                   	pop    %ebx
f010136c:	5e                   	pop    %esi
f010136d:	5d                   	pop    %ebp
f010136e:	c3                   	ret    

f010136f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010136f:	55                   	push   %ebp
f0101370:	89 e5                	mov    %esp,%ebp
f0101372:	56                   	push   %esi
f0101373:	53                   	push   %ebx
f0101374:	8b 75 08             	mov    0x8(%ebp),%esi
f0101377:	8b 55 0c             	mov    0xc(%ebp),%edx
f010137a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010137d:	89 f0                	mov    %esi,%eax
f010137f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101383:	85 c9                	test   %ecx,%ecx
f0101385:	75 0b                	jne    f0101392 <strlcpy+0x23>
f0101387:	eb 1d                	jmp    f01013a6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101389:	83 c0 01             	add    $0x1,%eax
f010138c:	83 c2 01             	add    $0x1,%edx
f010138f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101392:	39 d8                	cmp    %ebx,%eax
f0101394:	74 0b                	je     f01013a1 <strlcpy+0x32>
f0101396:	0f b6 0a             	movzbl (%edx),%ecx
f0101399:	84 c9                	test   %cl,%cl
f010139b:	75 ec                	jne    f0101389 <strlcpy+0x1a>
f010139d:	89 c2                	mov    %eax,%edx
f010139f:	eb 02                	jmp    f01013a3 <strlcpy+0x34>
f01013a1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01013a3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01013a6:	29 f0                	sub    %esi,%eax
}
f01013a8:	5b                   	pop    %ebx
f01013a9:	5e                   	pop    %esi
f01013aa:	5d                   	pop    %ebp
f01013ab:	c3                   	ret    

f01013ac <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013ac:	55                   	push   %ebp
f01013ad:	89 e5                	mov    %esp,%ebp
f01013af:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013b2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013b5:	eb 06                	jmp    f01013bd <strcmp+0x11>
		p++, q++;
f01013b7:	83 c1 01             	add    $0x1,%ecx
f01013ba:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013bd:	0f b6 01             	movzbl (%ecx),%eax
f01013c0:	84 c0                	test   %al,%al
f01013c2:	74 04                	je     f01013c8 <strcmp+0x1c>
f01013c4:	3a 02                	cmp    (%edx),%al
f01013c6:	74 ef                	je     f01013b7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013c8:	0f b6 c0             	movzbl %al,%eax
f01013cb:	0f b6 12             	movzbl (%edx),%edx
f01013ce:	29 d0                	sub    %edx,%eax
}
f01013d0:	5d                   	pop    %ebp
f01013d1:	c3                   	ret    

f01013d2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013d2:	55                   	push   %ebp
f01013d3:	89 e5                	mov    %esp,%ebp
f01013d5:	53                   	push   %ebx
f01013d6:	8b 45 08             	mov    0x8(%ebp),%eax
f01013d9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013dc:	89 c3                	mov    %eax,%ebx
f01013de:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01013e1:	eb 06                	jmp    f01013e9 <strncmp+0x17>
		n--, p++, q++;
f01013e3:	83 c0 01             	add    $0x1,%eax
f01013e6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01013e9:	39 d8                	cmp    %ebx,%eax
f01013eb:	74 15                	je     f0101402 <strncmp+0x30>
f01013ed:	0f b6 08             	movzbl (%eax),%ecx
f01013f0:	84 c9                	test   %cl,%cl
f01013f2:	74 04                	je     f01013f8 <strncmp+0x26>
f01013f4:	3a 0a                	cmp    (%edx),%cl
f01013f6:	74 eb                	je     f01013e3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01013f8:	0f b6 00             	movzbl (%eax),%eax
f01013fb:	0f b6 12             	movzbl (%edx),%edx
f01013fe:	29 d0                	sub    %edx,%eax
f0101400:	eb 05                	jmp    f0101407 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101402:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101407:	5b                   	pop    %ebx
f0101408:	5d                   	pop    %ebp
f0101409:	c3                   	ret    

f010140a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010140a:	55                   	push   %ebp
f010140b:	89 e5                	mov    %esp,%ebp
f010140d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101410:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101414:	eb 07                	jmp    f010141d <strchr+0x13>
		if (*s == c)
f0101416:	38 ca                	cmp    %cl,%dl
f0101418:	74 0f                	je     f0101429 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010141a:	83 c0 01             	add    $0x1,%eax
f010141d:	0f b6 10             	movzbl (%eax),%edx
f0101420:	84 d2                	test   %dl,%dl
f0101422:	75 f2                	jne    f0101416 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101424:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101429:	5d                   	pop    %ebp
f010142a:	c3                   	ret    

f010142b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010142b:	55                   	push   %ebp
f010142c:	89 e5                	mov    %esp,%ebp
f010142e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101431:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101435:	eb 07                	jmp    f010143e <strfind+0x13>
		if (*s == c)
f0101437:	38 ca                	cmp    %cl,%dl
f0101439:	74 0a                	je     f0101445 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010143b:	83 c0 01             	add    $0x1,%eax
f010143e:	0f b6 10             	movzbl (%eax),%edx
f0101441:	84 d2                	test   %dl,%dl
f0101443:	75 f2                	jne    f0101437 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101445:	5d                   	pop    %ebp
f0101446:	c3                   	ret    

f0101447 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101447:	55                   	push   %ebp
f0101448:	89 e5                	mov    %esp,%ebp
f010144a:	57                   	push   %edi
f010144b:	56                   	push   %esi
f010144c:	53                   	push   %ebx
f010144d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101450:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101453:	85 c9                	test   %ecx,%ecx
f0101455:	74 36                	je     f010148d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101457:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010145d:	75 28                	jne    f0101487 <memset+0x40>
f010145f:	f6 c1 03             	test   $0x3,%cl
f0101462:	75 23                	jne    f0101487 <memset+0x40>
		c &= 0xFF;
f0101464:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101468:	89 d3                	mov    %edx,%ebx
f010146a:	c1 e3 08             	shl    $0x8,%ebx
f010146d:	89 d6                	mov    %edx,%esi
f010146f:	c1 e6 18             	shl    $0x18,%esi
f0101472:	89 d0                	mov    %edx,%eax
f0101474:	c1 e0 10             	shl    $0x10,%eax
f0101477:	09 f0                	or     %esi,%eax
f0101479:	09 c2                	or     %eax,%edx
f010147b:	89 d0                	mov    %edx,%eax
f010147d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010147f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101482:	fc                   	cld    
f0101483:	f3 ab                	rep stos %eax,%es:(%edi)
f0101485:	eb 06                	jmp    f010148d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101487:	8b 45 0c             	mov    0xc(%ebp),%eax
f010148a:	fc                   	cld    
f010148b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010148d:	89 f8                	mov    %edi,%eax
f010148f:	5b                   	pop    %ebx
f0101490:	5e                   	pop    %esi
f0101491:	5f                   	pop    %edi
f0101492:	5d                   	pop    %ebp
f0101493:	c3                   	ret    

f0101494 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101494:	55                   	push   %ebp
f0101495:	89 e5                	mov    %esp,%ebp
f0101497:	57                   	push   %edi
f0101498:	56                   	push   %esi
f0101499:	8b 45 08             	mov    0x8(%ebp),%eax
f010149c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010149f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014a2:	39 c6                	cmp    %eax,%esi
f01014a4:	73 35                	jae    f01014db <memmove+0x47>
f01014a6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014a9:	39 d0                	cmp    %edx,%eax
f01014ab:	73 2e                	jae    f01014db <memmove+0x47>
		s += n;
		d += n;
f01014ad:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01014b0:	89 d6                	mov    %edx,%esi
f01014b2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014b4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01014ba:	75 13                	jne    f01014cf <memmove+0x3b>
f01014bc:	f6 c1 03             	test   $0x3,%cl
f01014bf:	75 0e                	jne    f01014cf <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01014c1:	83 ef 04             	sub    $0x4,%edi
f01014c4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01014c7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01014ca:	fd                   	std    
f01014cb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014cd:	eb 09                	jmp    f01014d8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01014cf:	83 ef 01             	sub    $0x1,%edi
f01014d2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01014d5:	fd                   	std    
f01014d6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01014d8:	fc                   	cld    
f01014d9:	eb 1d                	jmp    f01014f8 <memmove+0x64>
f01014db:	89 f2                	mov    %esi,%edx
f01014dd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014df:	f6 c2 03             	test   $0x3,%dl
f01014e2:	75 0f                	jne    f01014f3 <memmove+0x5f>
f01014e4:	f6 c1 03             	test   $0x3,%cl
f01014e7:	75 0a                	jne    f01014f3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01014e9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01014ec:	89 c7                	mov    %eax,%edi
f01014ee:	fc                   	cld    
f01014ef:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014f1:	eb 05                	jmp    f01014f8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01014f3:	89 c7                	mov    %eax,%edi
f01014f5:	fc                   	cld    
f01014f6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01014f8:	5e                   	pop    %esi
f01014f9:	5f                   	pop    %edi
f01014fa:	5d                   	pop    %ebp
f01014fb:	c3                   	ret    

f01014fc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01014fc:	55                   	push   %ebp
f01014fd:	89 e5                	mov    %esp,%ebp
f01014ff:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101502:	8b 45 10             	mov    0x10(%ebp),%eax
f0101505:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101509:	8b 45 0c             	mov    0xc(%ebp),%eax
f010150c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101510:	8b 45 08             	mov    0x8(%ebp),%eax
f0101513:	89 04 24             	mov    %eax,(%esp)
f0101516:	e8 79 ff ff ff       	call   f0101494 <memmove>
}
f010151b:	c9                   	leave  
f010151c:	c3                   	ret    

f010151d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010151d:	55                   	push   %ebp
f010151e:	89 e5                	mov    %esp,%ebp
f0101520:	56                   	push   %esi
f0101521:	53                   	push   %ebx
f0101522:	8b 55 08             	mov    0x8(%ebp),%edx
f0101525:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101528:	89 d6                	mov    %edx,%esi
f010152a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010152d:	eb 1a                	jmp    f0101549 <memcmp+0x2c>
		if (*s1 != *s2)
f010152f:	0f b6 02             	movzbl (%edx),%eax
f0101532:	0f b6 19             	movzbl (%ecx),%ebx
f0101535:	38 d8                	cmp    %bl,%al
f0101537:	74 0a                	je     f0101543 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101539:	0f b6 c0             	movzbl %al,%eax
f010153c:	0f b6 db             	movzbl %bl,%ebx
f010153f:	29 d8                	sub    %ebx,%eax
f0101541:	eb 0f                	jmp    f0101552 <memcmp+0x35>
		s1++, s2++;
f0101543:	83 c2 01             	add    $0x1,%edx
f0101546:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101549:	39 f2                	cmp    %esi,%edx
f010154b:	75 e2                	jne    f010152f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010154d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101552:	5b                   	pop    %ebx
f0101553:	5e                   	pop    %esi
f0101554:	5d                   	pop    %ebp
f0101555:	c3                   	ret    

f0101556 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101556:	55                   	push   %ebp
f0101557:	89 e5                	mov    %esp,%ebp
f0101559:	8b 45 08             	mov    0x8(%ebp),%eax
f010155c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010155f:	89 c2                	mov    %eax,%edx
f0101561:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101564:	eb 07                	jmp    f010156d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101566:	38 08                	cmp    %cl,(%eax)
f0101568:	74 07                	je     f0101571 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010156a:	83 c0 01             	add    $0x1,%eax
f010156d:	39 d0                	cmp    %edx,%eax
f010156f:	72 f5                	jb     f0101566 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101571:	5d                   	pop    %ebp
f0101572:	c3                   	ret    

f0101573 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101573:	55                   	push   %ebp
f0101574:	89 e5                	mov    %esp,%ebp
f0101576:	57                   	push   %edi
f0101577:	56                   	push   %esi
f0101578:	53                   	push   %ebx
f0101579:	8b 55 08             	mov    0x8(%ebp),%edx
f010157c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010157f:	eb 03                	jmp    f0101584 <strtol+0x11>
		s++;
f0101581:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101584:	0f b6 0a             	movzbl (%edx),%ecx
f0101587:	80 f9 09             	cmp    $0x9,%cl
f010158a:	74 f5                	je     f0101581 <strtol+0xe>
f010158c:	80 f9 20             	cmp    $0x20,%cl
f010158f:	74 f0                	je     f0101581 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101591:	80 f9 2b             	cmp    $0x2b,%cl
f0101594:	75 0a                	jne    f01015a0 <strtol+0x2d>
		s++;
f0101596:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101599:	bf 00 00 00 00       	mov    $0x0,%edi
f010159e:	eb 11                	jmp    f01015b1 <strtol+0x3e>
f01015a0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015a5:	80 f9 2d             	cmp    $0x2d,%cl
f01015a8:	75 07                	jne    f01015b1 <strtol+0x3e>
		s++, neg = 1;
f01015aa:	8d 52 01             	lea    0x1(%edx),%edx
f01015ad:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015b1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f01015b6:	75 15                	jne    f01015cd <strtol+0x5a>
f01015b8:	80 3a 30             	cmpb   $0x30,(%edx)
f01015bb:	75 10                	jne    f01015cd <strtol+0x5a>
f01015bd:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01015c1:	75 0a                	jne    f01015cd <strtol+0x5a>
		s += 2, base = 16;
f01015c3:	83 c2 02             	add    $0x2,%edx
f01015c6:	b8 10 00 00 00       	mov    $0x10,%eax
f01015cb:	eb 10                	jmp    f01015dd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f01015cd:	85 c0                	test   %eax,%eax
f01015cf:	75 0c                	jne    f01015dd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01015d1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015d3:	80 3a 30             	cmpb   $0x30,(%edx)
f01015d6:	75 05                	jne    f01015dd <strtol+0x6a>
		s++, base = 8;
f01015d8:	83 c2 01             	add    $0x1,%edx
f01015db:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f01015dd:	bb 00 00 00 00       	mov    $0x0,%ebx
f01015e2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01015e5:	0f b6 0a             	movzbl (%edx),%ecx
f01015e8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01015eb:	89 f0                	mov    %esi,%eax
f01015ed:	3c 09                	cmp    $0x9,%al
f01015ef:	77 08                	ja     f01015f9 <strtol+0x86>
			dig = *s - '0';
f01015f1:	0f be c9             	movsbl %cl,%ecx
f01015f4:	83 e9 30             	sub    $0x30,%ecx
f01015f7:	eb 20                	jmp    f0101619 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f01015f9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01015fc:	89 f0                	mov    %esi,%eax
f01015fe:	3c 19                	cmp    $0x19,%al
f0101600:	77 08                	ja     f010160a <strtol+0x97>
			dig = *s - 'a' + 10;
f0101602:	0f be c9             	movsbl %cl,%ecx
f0101605:	83 e9 57             	sub    $0x57,%ecx
f0101608:	eb 0f                	jmp    f0101619 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010160a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010160d:	89 f0                	mov    %esi,%eax
f010160f:	3c 19                	cmp    $0x19,%al
f0101611:	77 16                	ja     f0101629 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0101613:	0f be c9             	movsbl %cl,%ecx
f0101616:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101619:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010161c:	7d 0f                	jge    f010162d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010161e:	83 c2 01             	add    $0x1,%edx
f0101621:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101625:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101627:	eb bc                	jmp    f01015e5 <strtol+0x72>
f0101629:	89 d8                	mov    %ebx,%eax
f010162b:	eb 02                	jmp    f010162f <strtol+0xbc>
f010162d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010162f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101633:	74 05                	je     f010163a <strtol+0xc7>
		*endptr = (char *) s;
f0101635:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101638:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010163a:	f7 d8                	neg    %eax
f010163c:	85 ff                	test   %edi,%edi
f010163e:	0f 44 c3             	cmove  %ebx,%eax
}
f0101641:	5b                   	pop    %ebx
f0101642:	5e                   	pop    %esi
f0101643:	5f                   	pop    %edi
f0101644:	5d                   	pop    %ebp
f0101645:	c3                   	ret    
f0101646:	66 90                	xchg   %ax,%ax
f0101648:	66 90                	xchg   %ax,%ax
f010164a:	66 90                	xchg   %ax,%ax
f010164c:	66 90                	xchg   %ax,%ax
f010164e:	66 90                	xchg   %ax,%ax

f0101650 <__udivdi3>:
f0101650:	55                   	push   %ebp
f0101651:	57                   	push   %edi
f0101652:	56                   	push   %esi
f0101653:	83 ec 0c             	sub    $0xc,%esp
f0101656:	8b 44 24 28          	mov    0x28(%esp),%eax
f010165a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010165e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101662:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101666:	85 c0                	test   %eax,%eax
f0101668:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010166c:	89 ea                	mov    %ebp,%edx
f010166e:	89 0c 24             	mov    %ecx,(%esp)
f0101671:	75 2d                	jne    f01016a0 <__udivdi3+0x50>
f0101673:	39 e9                	cmp    %ebp,%ecx
f0101675:	77 61                	ja     f01016d8 <__udivdi3+0x88>
f0101677:	85 c9                	test   %ecx,%ecx
f0101679:	89 ce                	mov    %ecx,%esi
f010167b:	75 0b                	jne    f0101688 <__udivdi3+0x38>
f010167d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101682:	31 d2                	xor    %edx,%edx
f0101684:	f7 f1                	div    %ecx
f0101686:	89 c6                	mov    %eax,%esi
f0101688:	31 d2                	xor    %edx,%edx
f010168a:	89 e8                	mov    %ebp,%eax
f010168c:	f7 f6                	div    %esi
f010168e:	89 c5                	mov    %eax,%ebp
f0101690:	89 f8                	mov    %edi,%eax
f0101692:	f7 f6                	div    %esi
f0101694:	89 ea                	mov    %ebp,%edx
f0101696:	83 c4 0c             	add    $0xc,%esp
f0101699:	5e                   	pop    %esi
f010169a:	5f                   	pop    %edi
f010169b:	5d                   	pop    %ebp
f010169c:	c3                   	ret    
f010169d:	8d 76 00             	lea    0x0(%esi),%esi
f01016a0:	39 e8                	cmp    %ebp,%eax
f01016a2:	77 24                	ja     f01016c8 <__udivdi3+0x78>
f01016a4:	0f bd e8             	bsr    %eax,%ebp
f01016a7:	83 f5 1f             	xor    $0x1f,%ebp
f01016aa:	75 3c                	jne    f01016e8 <__udivdi3+0x98>
f01016ac:	8b 74 24 04          	mov    0x4(%esp),%esi
f01016b0:	39 34 24             	cmp    %esi,(%esp)
f01016b3:	0f 86 9f 00 00 00    	jbe    f0101758 <__udivdi3+0x108>
f01016b9:	39 d0                	cmp    %edx,%eax
f01016bb:	0f 82 97 00 00 00    	jb     f0101758 <__udivdi3+0x108>
f01016c1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016c8:	31 d2                	xor    %edx,%edx
f01016ca:	31 c0                	xor    %eax,%eax
f01016cc:	83 c4 0c             	add    $0xc,%esp
f01016cf:	5e                   	pop    %esi
f01016d0:	5f                   	pop    %edi
f01016d1:	5d                   	pop    %ebp
f01016d2:	c3                   	ret    
f01016d3:	90                   	nop
f01016d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01016d8:	89 f8                	mov    %edi,%eax
f01016da:	f7 f1                	div    %ecx
f01016dc:	31 d2                	xor    %edx,%edx
f01016de:	83 c4 0c             	add    $0xc,%esp
f01016e1:	5e                   	pop    %esi
f01016e2:	5f                   	pop    %edi
f01016e3:	5d                   	pop    %ebp
f01016e4:	c3                   	ret    
f01016e5:	8d 76 00             	lea    0x0(%esi),%esi
f01016e8:	89 e9                	mov    %ebp,%ecx
f01016ea:	8b 3c 24             	mov    (%esp),%edi
f01016ed:	d3 e0                	shl    %cl,%eax
f01016ef:	89 c6                	mov    %eax,%esi
f01016f1:	b8 20 00 00 00       	mov    $0x20,%eax
f01016f6:	29 e8                	sub    %ebp,%eax
f01016f8:	89 c1                	mov    %eax,%ecx
f01016fa:	d3 ef                	shr    %cl,%edi
f01016fc:	89 e9                	mov    %ebp,%ecx
f01016fe:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101702:	8b 3c 24             	mov    (%esp),%edi
f0101705:	09 74 24 08          	or     %esi,0x8(%esp)
f0101709:	89 d6                	mov    %edx,%esi
f010170b:	d3 e7                	shl    %cl,%edi
f010170d:	89 c1                	mov    %eax,%ecx
f010170f:	89 3c 24             	mov    %edi,(%esp)
f0101712:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101716:	d3 ee                	shr    %cl,%esi
f0101718:	89 e9                	mov    %ebp,%ecx
f010171a:	d3 e2                	shl    %cl,%edx
f010171c:	89 c1                	mov    %eax,%ecx
f010171e:	d3 ef                	shr    %cl,%edi
f0101720:	09 d7                	or     %edx,%edi
f0101722:	89 f2                	mov    %esi,%edx
f0101724:	89 f8                	mov    %edi,%eax
f0101726:	f7 74 24 08          	divl   0x8(%esp)
f010172a:	89 d6                	mov    %edx,%esi
f010172c:	89 c7                	mov    %eax,%edi
f010172e:	f7 24 24             	mull   (%esp)
f0101731:	39 d6                	cmp    %edx,%esi
f0101733:	89 14 24             	mov    %edx,(%esp)
f0101736:	72 30                	jb     f0101768 <__udivdi3+0x118>
f0101738:	8b 54 24 04          	mov    0x4(%esp),%edx
f010173c:	89 e9                	mov    %ebp,%ecx
f010173e:	d3 e2                	shl    %cl,%edx
f0101740:	39 c2                	cmp    %eax,%edx
f0101742:	73 05                	jae    f0101749 <__udivdi3+0xf9>
f0101744:	3b 34 24             	cmp    (%esp),%esi
f0101747:	74 1f                	je     f0101768 <__udivdi3+0x118>
f0101749:	89 f8                	mov    %edi,%eax
f010174b:	31 d2                	xor    %edx,%edx
f010174d:	e9 7a ff ff ff       	jmp    f01016cc <__udivdi3+0x7c>
f0101752:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101758:	31 d2                	xor    %edx,%edx
f010175a:	b8 01 00 00 00       	mov    $0x1,%eax
f010175f:	e9 68 ff ff ff       	jmp    f01016cc <__udivdi3+0x7c>
f0101764:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101768:	8d 47 ff             	lea    -0x1(%edi),%eax
f010176b:	31 d2                	xor    %edx,%edx
f010176d:	83 c4 0c             	add    $0xc,%esp
f0101770:	5e                   	pop    %esi
f0101771:	5f                   	pop    %edi
f0101772:	5d                   	pop    %ebp
f0101773:	c3                   	ret    
f0101774:	66 90                	xchg   %ax,%ax
f0101776:	66 90                	xchg   %ax,%ax
f0101778:	66 90                	xchg   %ax,%ax
f010177a:	66 90                	xchg   %ax,%ax
f010177c:	66 90                	xchg   %ax,%ax
f010177e:	66 90                	xchg   %ax,%ax

f0101780 <__umoddi3>:
f0101780:	55                   	push   %ebp
f0101781:	57                   	push   %edi
f0101782:	56                   	push   %esi
f0101783:	83 ec 14             	sub    $0x14,%esp
f0101786:	8b 44 24 28          	mov    0x28(%esp),%eax
f010178a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010178e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101792:	89 c7                	mov    %eax,%edi
f0101794:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101798:	8b 44 24 30          	mov    0x30(%esp),%eax
f010179c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01017a0:	89 34 24             	mov    %esi,(%esp)
f01017a3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017a7:	85 c0                	test   %eax,%eax
f01017a9:	89 c2                	mov    %eax,%edx
f01017ab:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01017af:	75 17                	jne    f01017c8 <__umoddi3+0x48>
f01017b1:	39 fe                	cmp    %edi,%esi
f01017b3:	76 4b                	jbe    f0101800 <__umoddi3+0x80>
f01017b5:	89 c8                	mov    %ecx,%eax
f01017b7:	89 fa                	mov    %edi,%edx
f01017b9:	f7 f6                	div    %esi
f01017bb:	89 d0                	mov    %edx,%eax
f01017bd:	31 d2                	xor    %edx,%edx
f01017bf:	83 c4 14             	add    $0x14,%esp
f01017c2:	5e                   	pop    %esi
f01017c3:	5f                   	pop    %edi
f01017c4:	5d                   	pop    %ebp
f01017c5:	c3                   	ret    
f01017c6:	66 90                	xchg   %ax,%ax
f01017c8:	39 f8                	cmp    %edi,%eax
f01017ca:	77 54                	ja     f0101820 <__umoddi3+0xa0>
f01017cc:	0f bd e8             	bsr    %eax,%ebp
f01017cf:	83 f5 1f             	xor    $0x1f,%ebp
f01017d2:	75 5c                	jne    f0101830 <__umoddi3+0xb0>
f01017d4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01017d8:	39 3c 24             	cmp    %edi,(%esp)
f01017db:	0f 87 e7 00 00 00    	ja     f01018c8 <__umoddi3+0x148>
f01017e1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01017e5:	29 f1                	sub    %esi,%ecx
f01017e7:	19 c7                	sbb    %eax,%edi
f01017e9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017ed:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01017f1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01017f5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01017f9:	83 c4 14             	add    $0x14,%esp
f01017fc:	5e                   	pop    %esi
f01017fd:	5f                   	pop    %edi
f01017fe:	5d                   	pop    %ebp
f01017ff:	c3                   	ret    
f0101800:	85 f6                	test   %esi,%esi
f0101802:	89 f5                	mov    %esi,%ebp
f0101804:	75 0b                	jne    f0101811 <__umoddi3+0x91>
f0101806:	b8 01 00 00 00       	mov    $0x1,%eax
f010180b:	31 d2                	xor    %edx,%edx
f010180d:	f7 f6                	div    %esi
f010180f:	89 c5                	mov    %eax,%ebp
f0101811:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101815:	31 d2                	xor    %edx,%edx
f0101817:	f7 f5                	div    %ebp
f0101819:	89 c8                	mov    %ecx,%eax
f010181b:	f7 f5                	div    %ebp
f010181d:	eb 9c                	jmp    f01017bb <__umoddi3+0x3b>
f010181f:	90                   	nop
f0101820:	89 c8                	mov    %ecx,%eax
f0101822:	89 fa                	mov    %edi,%edx
f0101824:	83 c4 14             	add    $0x14,%esp
f0101827:	5e                   	pop    %esi
f0101828:	5f                   	pop    %edi
f0101829:	5d                   	pop    %ebp
f010182a:	c3                   	ret    
f010182b:	90                   	nop
f010182c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101830:	8b 04 24             	mov    (%esp),%eax
f0101833:	be 20 00 00 00       	mov    $0x20,%esi
f0101838:	89 e9                	mov    %ebp,%ecx
f010183a:	29 ee                	sub    %ebp,%esi
f010183c:	d3 e2                	shl    %cl,%edx
f010183e:	89 f1                	mov    %esi,%ecx
f0101840:	d3 e8                	shr    %cl,%eax
f0101842:	89 e9                	mov    %ebp,%ecx
f0101844:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101848:	8b 04 24             	mov    (%esp),%eax
f010184b:	09 54 24 04          	or     %edx,0x4(%esp)
f010184f:	89 fa                	mov    %edi,%edx
f0101851:	d3 e0                	shl    %cl,%eax
f0101853:	89 f1                	mov    %esi,%ecx
f0101855:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101859:	8b 44 24 10          	mov    0x10(%esp),%eax
f010185d:	d3 ea                	shr    %cl,%edx
f010185f:	89 e9                	mov    %ebp,%ecx
f0101861:	d3 e7                	shl    %cl,%edi
f0101863:	89 f1                	mov    %esi,%ecx
f0101865:	d3 e8                	shr    %cl,%eax
f0101867:	89 e9                	mov    %ebp,%ecx
f0101869:	09 f8                	or     %edi,%eax
f010186b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010186f:	f7 74 24 04          	divl   0x4(%esp)
f0101873:	d3 e7                	shl    %cl,%edi
f0101875:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101879:	89 d7                	mov    %edx,%edi
f010187b:	f7 64 24 08          	mull   0x8(%esp)
f010187f:	39 d7                	cmp    %edx,%edi
f0101881:	89 c1                	mov    %eax,%ecx
f0101883:	89 14 24             	mov    %edx,(%esp)
f0101886:	72 2c                	jb     f01018b4 <__umoddi3+0x134>
f0101888:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010188c:	72 22                	jb     f01018b0 <__umoddi3+0x130>
f010188e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101892:	29 c8                	sub    %ecx,%eax
f0101894:	19 d7                	sbb    %edx,%edi
f0101896:	89 e9                	mov    %ebp,%ecx
f0101898:	89 fa                	mov    %edi,%edx
f010189a:	d3 e8                	shr    %cl,%eax
f010189c:	89 f1                	mov    %esi,%ecx
f010189e:	d3 e2                	shl    %cl,%edx
f01018a0:	89 e9                	mov    %ebp,%ecx
f01018a2:	d3 ef                	shr    %cl,%edi
f01018a4:	09 d0                	or     %edx,%eax
f01018a6:	89 fa                	mov    %edi,%edx
f01018a8:	83 c4 14             	add    $0x14,%esp
f01018ab:	5e                   	pop    %esi
f01018ac:	5f                   	pop    %edi
f01018ad:	5d                   	pop    %ebp
f01018ae:	c3                   	ret    
f01018af:	90                   	nop
f01018b0:	39 d7                	cmp    %edx,%edi
f01018b2:	75 da                	jne    f010188e <__umoddi3+0x10e>
f01018b4:	8b 14 24             	mov    (%esp),%edx
f01018b7:	89 c1                	mov    %eax,%ecx
f01018b9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f01018bd:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01018c1:	eb cb                	jmp    f010188e <__umoddi3+0x10e>
f01018c3:	90                   	nop
f01018c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018c8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01018cc:	0f 82 0f ff ff ff    	jb     f01017e1 <__umoddi3+0x61>
f01018d2:	e9 1a ff ff ff       	jmp    f01017f1 <__umoddi3+0x71>
