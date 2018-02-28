
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
f010004e:	c7 04 24 e0 19 10 f0 	movl   $0xf01019e0,(%esp)
f0100055:	e8 6e 09 00 00       	call   f01009c8 <cprintf>
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
f010008b:	c7 04 24 fc 19 10 f0 	movl   $0xf01019fc,(%esp)
f0100092:	e8 31 09 00 00       	call   f01009c8 <cprintf>
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
f01000c0:	e8 72 14 00 00       	call   f0101537 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a5 04 00 00       	call   f010056f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 17 1a 10 f0 	movl   $0xf0101a17,(%esp)
f01000d9:	e8 ea 08 00 00       	call   f01009c8 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 4a 07 00 00       	call   f0100840 <monitor>
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
f0100125:	c7 04 24 32 1a 10 f0 	movl   $0xf0101a32,(%esp)
f010012c:	e8 97 08 00 00       	call   f01009c8 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 58 08 00 00       	call   f0100995 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 6e 1a 10 f0 	movl   $0xf0101a6e,(%esp)
f0100144:	e8 7f 08 00 00       	call   f01009c8 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 eb 06 00 00       	call   f0100840 <monitor>
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
f010016f:	c7 04 24 4a 1a 10 f0 	movl   $0xf0101a4a,(%esp)
f0100176:	e8 4d 08 00 00       	call   f01009c8 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 0b 08 00 00       	call   f0100995 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 6e 1a 10 f0 	movl   $0xf0101a6e,(%esp)
f0100191:	e8 32 08 00 00       	call   f01009c8 <cprintf>
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
f010024d:	0f b6 82 c0 1b 10 f0 	movzbl -0xfefe440(%edx),%eax
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
f010028a:	0f b6 82 c0 1b 10 f0 	movzbl -0xfefe440(%edx),%eax
f0100291:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f0100297:	0f b6 8a c0 1a 10 f0 	movzbl -0xfefe540(%edx),%ecx
f010029e:	31 c8                	xor    %ecx,%eax
f01002a0:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f01002a5:	89 c1                	mov    %eax,%ecx
f01002a7:	83 e1 03             	and    $0x3,%ecx
f01002aa:	8b 0c 8d a0 1a 10 f0 	mov    -0xfefe560(,%ecx,4),%ecx
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
f01002ea:	c7 04 24 64 1a 10 f0 	movl   $0xf0101a64,(%esp)
f01002f1:	e8 d2 06 00 00       	call   f01009c8 <cprintf>
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
f0100499:	e8 e6 10 00 00       	call   f0101584 <memmove>
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
f010064d:	c7 04 24 70 1a 10 f0 	movl   $0xf0101a70,(%esp)
f0100654:	e8 6f 03 00 00       	call   f01009c8 <cprintf>
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
f0100696:	c7 44 24 08 c0 1c 10 	movl   $0xf0101cc0,0x8(%esp)
f010069d:	f0 
f010069e:	c7 44 24 04 de 1c 10 	movl   $0xf0101cde,0x4(%esp)
f01006a5:	f0 
f01006a6:	c7 04 24 e3 1c 10 f0 	movl   $0xf0101ce3,(%esp)
f01006ad:	e8 16 03 00 00       	call   f01009c8 <cprintf>
f01006b2:	c7 44 24 08 98 1d 10 	movl   $0xf0101d98,0x8(%esp)
f01006b9:	f0 
f01006ba:	c7 44 24 04 ec 1c 10 	movl   $0xf0101cec,0x4(%esp)
f01006c1:	f0 
f01006c2:	c7 04 24 e3 1c 10 f0 	movl   $0xf0101ce3,(%esp)
f01006c9:	e8 fa 02 00 00       	call   f01009c8 <cprintf>
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
f01006db:	c7 04 24 f5 1c 10 f0 	movl   $0xf0101cf5,(%esp)
f01006e2:	e8 e1 02 00 00       	call   f01009c8 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006e7:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006ee:	00 
f01006ef:	c7 04 24 c0 1d 10 f0 	movl   $0xf0101dc0,(%esp)
f01006f6:	e8 cd 02 00 00       	call   f01009c8 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006fb:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100702:	00 
f0100703:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f010070a:	f0 
f010070b:	c7 04 24 e8 1d 10 f0 	movl   $0xf0101de8,(%esp)
f0100712:	e8 b1 02 00 00       	call   f01009c8 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100717:	c7 44 24 08 c7 19 10 	movl   $0x1019c7,0x8(%esp)
f010071e:	00 
f010071f:	c7 44 24 04 c7 19 10 	movl   $0xf01019c7,0x4(%esp)
f0100726:	f0 
f0100727:	c7 04 24 0c 1e 10 f0 	movl   $0xf0101e0c,(%esp)
f010072e:	e8 95 02 00 00       	call   f01009c8 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100733:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f010073a:	00 
f010073b:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f0100742:	f0 
f0100743:	c7 04 24 30 1e 10 f0 	movl   $0xf0101e30,(%esp)
f010074a:	e8 79 02 00 00       	call   f01009c8 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010074f:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100756:	00 
f0100757:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010075e:	f0 
f010075f:	c7 04 24 54 1e 10 f0 	movl   $0xf0101e54,(%esp)
f0100766:	e8 5d 02 00 00       	call   f01009c8 <cprintf>
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
f010078c:	c7 04 24 78 1e 10 f0 	movl   $0xf0101e78,(%esp)
f0100793:	e8 30 02 00 00       	call   f01009c8 <cprintf>
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
f01007a2:	57                   	push   %edi
f01007a3:	56                   	push   %esi
f01007a4:	53                   	push   %ebx
f01007a5:	83 ec 4c             	sub    $0x4c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01007a8:	89 ee                	mov    %ebp,%esi
	// 每次压栈的顺序依次是：保存ebx、保存ebp、返回地址eip、五个参数
	uint32_t eip;
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f01007aa:	c7 04 24 0e 1d 10 f0 	movl   $0xf0101d0e,(%esp)
f01007b1:	e8 12 02 00 00       	call   f01009c8 <cprintf>
	while(ebp != 0){
f01007b6:	eb 77                	jmp    f010082f <mon_backtrace+0x90>
		eip = *((uint32_t *)ebp + 1);
f01007b8:	8b 7e 04             	mov    0x4(%esi),%edi
		debuginfo_eip(eip, &info);
f01007bb:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007be:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007c2:	89 3c 24             	mov    %edi,(%esp)
f01007c5:	e8 f5 02 00 00       	call   f0100abf <debuginfo_eip>
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
f01007ca:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01007ce:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007d2:	c7 04 24 20 1d 10 f0 	movl   $0xf0101d20,(%esp)
f01007d9:	e8 ea 01 00 00       	call   f01009c8 <cprintf>
		for(int i = 2; i < 7; i++){
f01007de:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x", *((uint32_t*)ebp + i));
f01007e3:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f01007e6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007ea:	c7 04 24 3b 1d 10 f0 	movl   $0xf0101d3b,(%esp)
f01007f1:	e8 d2 01 00 00       	call   f01009c8 <cprintf>
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
		eip = *((uint32_t *)ebp + 1);
		debuginfo_eip(eip, &info);
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
		for(int i = 2; i < 7; i++){
f01007f6:	83 c3 01             	add    $0x1,%ebx
f01007f9:	83 fb 07             	cmp    $0x7,%ebx
f01007fc:	75 e5                	jne    f01007e3 <mon_backtrace+0x44>
			cprintf(" %08x", *((uint32_t*)ebp + i));
		}
		cprintf("\n         %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
f01007fe:	2b 7d e0             	sub    -0x20(%ebp),%edi
f0100801:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0100805:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100808:	89 44 24 10          	mov    %eax,0x10(%esp)
f010080c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010080f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100813:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100816:	89 44 24 08          	mov    %eax,0x8(%esp)
f010081a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010081d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100821:	c7 04 24 41 1d 10 f0 	movl   $0xf0101d41,(%esp)
f0100828:	e8 9b 01 00 00       	call   f01009c8 <cprintf>
		ebp = *((uint32_t *)ebp);
f010082d:	8b 36                	mov    (%esi),%esi
	// 每次压栈的顺序依次是：保存ebx、保存ebp、返回地址eip、五个参数
	uint32_t eip;
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f010082f:	85 f6                	test   %esi,%esi
f0100831:	75 85                	jne    f01007b8 <mon_backtrace+0x19>
		}
		cprintf("\n         %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
		ebp = *((uint32_t *)ebp);
	}
	return 0;
}
f0100833:	b8 00 00 00 00       	mov    $0x0,%eax
f0100838:	83 c4 4c             	add    $0x4c,%esp
f010083b:	5b                   	pop    %ebx
f010083c:	5e                   	pop    %esi
f010083d:	5f                   	pop    %edi
f010083e:	5d                   	pop    %ebp
f010083f:	c3                   	ret    

f0100840 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100840:	55                   	push   %ebp
f0100841:	89 e5                	mov    %esp,%ebp
f0100843:	57                   	push   %edi
f0100844:	56                   	push   %esi
f0100845:	53                   	push   %ebx
f0100846:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100849:	c7 04 24 a4 1e 10 f0 	movl   $0xf0101ea4,(%esp)
f0100850:	e8 73 01 00 00       	call   f01009c8 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100855:	c7 04 24 c8 1e 10 f0 	movl   $0xf0101ec8,(%esp)
f010085c:	e8 67 01 00 00       	call   f01009c8 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100861:	c7 04 24 5b 1d 10 f0 	movl   $0xf0101d5b,(%esp)
f0100868:	e8 73 0a 00 00       	call   f01012e0 <readline>
f010086d:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010086f:	85 c0                	test   %eax,%eax
f0100871:	74 ee                	je     f0100861 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100873:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010087a:	be 00 00 00 00       	mov    $0x0,%esi
f010087f:	eb 0a                	jmp    f010088b <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100881:	c6 03 00             	movb   $0x0,(%ebx)
f0100884:	89 f7                	mov    %esi,%edi
f0100886:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100889:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010088b:	0f b6 03             	movzbl (%ebx),%eax
f010088e:	84 c0                	test   %al,%al
f0100890:	74 63                	je     f01008f5 <monitor+0xb5>
f0100892:	0f be c0             	movsbl %al,%eax
f0100895:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100899:	c7 04 24 5f 1d 10 f0 	movl   $0xf0101d5f,(%esp)
f01008a0:	e8 55 0c 00 00       	call   f01014fa <strchr>
f01008a5:	85 c0                	test   %eax,%eax
f01008a7:	75 d8                	jne    f0100881 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008a9:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008ac:	74 47                	je     f01008f5 <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008ae:	83 fe 0f             	cmp    $0xf,%esi
f01008b1:	75 16                	jne    f01008c9 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008b3:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008ba:	00 
f01008bb:	c7 04 24 64 1d 10 f0 	movl   $0xf0101d64,(%esp)
f01008c2:	e8 01 01 00 00       	call   f01009c8 <cprintf>
f01008c7:	eb 98                	jmp    f0100861 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008c9:	8d 7e 01             	lea    0x1(%esi),%edi
f01008cc:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008d0:	eb 03                	jmp    f01008d5 <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008d2:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008d5:	0f b6 03             	movzbl (%ebx),%eax
f01008d8:	84 c0                	test   %al,%al
f01008da:	74 ad                	je     f0100889 <monitor+0x49>
f01008dc:	0f be c0             	movsbl %al,%eax
f01008df:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008e3:	c7 04 24 5f 1d 10 f0 	movl   $0xf0101d5f,(%esp)
f01008ea:	e8 0b 0c 00 00       	call   f01014fa <strchr>
f01008ef:	85 c0                	test   %eax,%eax
f01008f1:	74 df                	je     f01008d2 <monitor+0x92>
f01008f3:	eb 94                	jmp    f0100889 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f01008f5:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008fc:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008fd:	85 f6                	test   %esi,%esi
f01008ff:	0f 84 5c ff ff ff    	je     f0100861 <monitor+0x21>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100905:	c7 44 24 04 de 1c 10 	movl   $0xf0101cde,0x4(%esp)
f010090c:	f0 
f010090d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100910:	89 04 24             	mov    %eax,(%esp)
f0100913:	e8 84 0b 00 00       	call   f010149c <strcmp>
f0100918:	85 c0                	test   %eax,%eax
f010091a:	74 1b                	je     f0100937 <monitor+0xf7>
f010091c:	c7 44 24 04 ec 1c 10 	movl   $0xf0101cec,0x4(%esp)
f0100923:	f0 
f0100924:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100927:	89 04 24             	mov    %eax,(%esp)
f010092a:	e8 6d 0b 00 00       	call   f010149c <strcmp>
f010092f:	85 c0                	test   %eax,%eax
f0100931:	75 2f                	jne    f0100962 <monitor+0x122>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100933:	b0 01                	mov    $0x1,%al
f0100935:	eb 05                	jmp    f010093c <monitor+0xfc>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100937:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f010093c:	8d 14 00             	lea    (%eax,%eax,1),%edx
f010093f:	01 d0                	add    %edx,%eax
f0100941:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100944:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100948:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010094b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010094f:	89 34 24             	mov    %esi,(%esp)
f0100952:	ff 14 85 f8 1e 10 f0 	call   *-0xfefe108(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100959:	85 c0                	test   %eax,%eax
f010095b:	78 1d                	js     f010097a <monitor+0x13a>
f010095d:	e9 ff fe ff ff       	jmp    f0100861 <monitor+0x21>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100962:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100965:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100969:	c7 04 24 81 1d 10 f0 	movl   $0xf0101d81,(%esp)
f0100970:	e8 53 00 00 00       	call   f01009c8 <cprintf>
f0100975:	e9 e7 fe ff ff       	jmp    f0100861 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010097a:	83 c4 5c             	add    $0x5c,%esp
f010097d:	5b                   	pop    %ebx
f010097e:	5e                   	pop    %esi
f010097f:	5f                   	pop    %edi
f0100980:	5d                   	pop    %ebp
f0100981:	c3                   	ret    

f0100982 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100982:	55                   	push   %ebp
f0100983:	89 e5                	mov    %esp,%ebp
f0100985:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100988:	8b 45 08             	mov    0x8(%ebp),%eax
f010098b:	89 04 24             	mov    %eax,(%esp)
f010098e:	e8 ce fc ff ff       	call   f0100661 <cputchar>
	*cnt++;
}
f0100993:	c9                   	leave  
f0100994:	c3                   	ret    

f0100995 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100995:	55                   	push   %ebp
f0100996:	89 e5                	mov    %esp,%ebp
f0100998:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010099b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009a2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009a5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01009ac:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009b0:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009b3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009b7:	c7 04 24 82 09 10 f0 	movl   $0xf0100982,(%esp)
f01009be:	e8 bb 04 00 00       	call   f0100e7e <vprintfmt>
	return cnt;
}
f01009c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009c6:	c9                   	leave  
f01009c7:	c3                   	ret    

f01009c8 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009c8:	55                   	push   %ebp
f01009c9:	89 e5                	mov    %esp,%ebp
f01009cb:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009ce:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009d1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009d5:	8b 45 08             	mov    0x8(%ebp),%eax
f01009d8:	89 04 24             	mov    %eax,(%esp)
f01009db:	e8 b5 ff ff ff       	call   f0100995 <vcprintf>
	va_end(ap);

	return cnt;
}
f01009e0:	c9                   	leave  
f01009e1:	c3                   	ret    

f01009e2 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009e2:	55                   	push   %ebp
f01009e3:	89 e5                	mov    %esp,%ebp
f01009e5:	57                   	push   %edi
f01009e6:	56                   	push   %esi
f01009e7:	53                   	push   %ebx
f01009e8:	83 ec 10             	sub    $0x10,%esp
f01009eb:	89 c6                	mov    %eax,%esi
f01009ed:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01009f0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01009f3:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009f6:	8b 1a                	mov    (%edx),%ebx
f01009f8:	8b 01                	mov    (%ecx),%eax
f01009fa:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009fd:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100a04:	eb 77                	jmp    f0100a7d <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a06:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a09:	01 d8                	add    %ebx,%eax
f0100a0b:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a10:	99                   	cltd   
f0100a11:	f7 f9                	idiv   %ecx
f0100a13:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a15:	eb 01                	jmp    f0100a18 <stab_binsearch+0x36>
			m--;
f0100a17:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a18:	39 d9                	cmp    %ebx,%ecx
f0100a1a:	7c 1d                	jl     f0100a39 <stab_binsearch+0x57>
f0100a1c:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a1f:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a24:	39 fa                	cmp    %edi,%edx
f0100a26:	75 ef                	jne    f0100a17 <stab_binsearch+0x35>
f0100a28:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a2b:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a2e:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a32:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a35:	73 18                	jae    f0100a4f <stab_binsearch+0x6d>
f0100a37:	eb 05                	jmp    f0100a3e <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a39:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a3c:	eb 3f                	jmp    f0100a7d <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a3e:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a41:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a43:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a46:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a4d:	eb 2e                	jmp    f0100a7d <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a4f:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a52:	73 15                	jae    f0100a69 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a54:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a57:	48                   	dec    %eax
f0100a58:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a5b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a5e:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a60:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a67:	eb 14                	jmp    f0100a7d <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a69:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a6c:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100a6f:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100a71:	ff 45 0c             	incl   0xc(%ebp)
f0100a74:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a76:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a7d:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a80:	7e 84                	jle    f0100a06 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a82:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a86:	75 0d                	jne    f0100a95 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100a88:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a8b:	8b 00                	mov    (%eax),%eax
f0100a8d:	48                   	dec    %eax
f0100a8e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100a91:	89 07                	mov    %eax,(%edi)
f0100a93:	eb 22                	jmp    f0100ab7 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a95:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a98:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a9a:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a9d:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a9f:	eb 01                	jmp    f0100aa2 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100aa1:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aa2:	39 c1                	cmp    %eax,%ecx
f0100aa4:	7d 0c                	jge    f0100ab2 <stab_binsearch+0xd0>
f0100aa6:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100aa9:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100aae:	39 fa                	cmp    %edi,%edx
f0100ab0:	75 ef                	jne    f0100aa1 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100ab2:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100ab5:	89 07                	mov    %eax,(%edi)
	}
}
f0100ab7:	83 c4 10             	add    $0x10,%esp
f0100aba:	5b                   	pop    %ebx
f0100abb:	5e                   	pop    %esi
f0100abc:	5f                   	pop    %edi
f0100abd:	5d                   	pop    %ebp
f0100abe:	c3                   	ret    

f0100abf <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100abf:	55                   	push   %ebp
f0100ac0:	89 e5                	mov    %esp,%ebp
f0100ac2:	57                   	push   %edi
f0100ac3:	56                   	push   %esi
f0100ac4:	53                   	push   %ebx
f0100ac5:	83 ec 3c             	sub    $0x3c,%esp
f0100ac8:	8b 75 08             	mov    0x8(%ebp),%esi
f0100acb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ace:	c7 03 08 1f 10 f0    	movl   $0xf0101f08,(%ebx)
	info->eip_line = 0;
f0100ad4:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100adb:	c7 43 08 08 1f 10 f0 	movl   $0xf0101f08,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100ae2:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100ae9:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100aec:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100af3:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100af9:	76 12                	jbe    f0100b0d <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100afb:	b8 fe 73 10 f0       	mov    $0xf01073fe,%eax
f0100b00:	3d e9 5a 10 f0       	cmp    $0xf0105ae9,%eax
f0100b05:	0f 86 cd 01 00 00    	jbe    f0100cd8 <debuginfo_eip+0x219>
f0100b0b:	eb 1c                	jmp    f0100b29 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b0d:	c7 44 24 08 12 1f 10 	movl   $0xf0101f12,0x8(%esp)
f0100b14:	f0 
f0100b15:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b1c:	00 
f0100b1d:	c7 04 24 1f 1f 10 f0 	movl   $0xf0101f1f,(%esp)
f0100b24:	e8 cf f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b29:	80 3d fd 73 10 f0 00 	cmpb   $0x0,0xf01073fd
f0100b30:	0f 85 a9 01 00 00    	jne    f0100cdf <debuginfo_eip+0x220>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b36:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b3d:	b8 e8 5a 10 f0       	mov    $0xf0105ae8,%eax
f0100b42:	2d 40 21 10 f0       	sub    $0xf0102140,%eax
f0100b47:	c1 f8 02             	sar    $0x2,%eax
f0100b4a:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b50:	83 e8 01             	sub    $0x1,%eax
f0100b53:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b56:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b5a:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b61:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b64:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b67:	b8 40 21 10 f0       	mov    $0xf0102140,%eax
f0100b6c:	e8 71 fe ff ff       	call   f01009e2 <stab_binsearch>
	if (lfile == 0)
f0100b71:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b74:	85 c0                	test   %eax,%eax
f0100b76:	0f 84 6a 01 00 00    	je     f0100ce6 <debuginfo_eip+0x227>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b7c:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b7f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b82:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b85:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b89:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b90:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b93:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b96:	b8 40 21 10 f0       	mov    $0xf0102140,%eax
f0100b9b:	e8 42 fe ff ff       	call   f01009e2 <stab_binsearch>

	if (lfun <= rfun) {
f0100ba0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ba3:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100ba6:	39 d0                	cmp    %edx,%eax
f0100ba8:	7f 3d                	jg     f0100be7 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100baa:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100bad:	8d b9 40 21 10 f0    	lea    -0xfefdec0(%ecx),%edi
f0100bb3:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100bb6:	8b 89 40 21 10 f0    	mov    -0xfefdec0(%ecx),%ecx
f0100bbc:	bf fe 73 10 f0       	mov    $0xf01073fe,%edi
f0100bc1:	81 ef e9 5a 10 f0    	sub    $0xf0105ae9,%edi
f0100bc7:	39 f9                	cmp    %edi,%ecx
f0100bc9:	73 09                	jae    f0100bd4 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bcb:	81 c1 e9 5a 10 f0    	add    $0xf0105ae9,%ecx
f0100bd1:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bd4:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100bd7:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100bda:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100bdd:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100bdf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100be2:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100be5:	eb 0f                	jmp    f0100bf6 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100be7:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bed:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100bf0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bf3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bf6:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100bfd:	00 
f0100bfe:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c01:	89 04 24             	mov    %eax,(%esp)
f0100c04:	e8 12 09 00 00       	call   f010151b <strfind>
f0100c09:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c0c:	89 43 0c             	mov    %eax,0xc(%ebx)
	//
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100c0f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c13:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c1a:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c1d:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c20:	b8 40 21 10 f0       	mov    $0xf0102140,%eax
f0100c25:	e8 b8 fd ff ff       	call   f01009e2 <stab_binsearch>
	
	if(lline <= rline){
f0100c2a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c2d:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100c30:	0f 8f b7 00 00 00    	jg     f0100ced <debuginfo_eip+0x22e>
		info->eip_line = stabs[lline].n_desc;
f0100c36:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c39:	0f b7 80 46 21 10 f0 	movzwl -0xfefdeba(%eax),%eax
f0100c40:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c43:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c46:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100c49:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c4c:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100c4f:	81 c2 40 21 10 f0    	add    $0xf0102140,%edx
f0100c55:	eb 06                	jmp    f0100c5d <debuginfo_eip+0x19e>
f0100c57:	83 e8 01             	sub    $0x1,%eax
f0100c5a:	83 ea 0c             	sub    $0xc,%edx
f0100c5d:	89 c6                	mov    %eax,%esi
f0100c5f:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100c62:	7f 33                	jg     f0100c97 <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f0100c64:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c68:	80 f9 84             	cmp    $0x84,%cl
f0100c6b:	74 0b                	je     f0100c78 <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c6d:	80 f9 64             	cmp    $0x64,%cl
f0100c70:	75 e5                	jne    f0100c57 <debuginfo_eip+0x198>
f0100c72:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100c76:	74 df                	je     f0100c57 <debuginfo_eip+0x198>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c78:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100c7b:	8b 86 40 21 10 f0    	mov    -0xfefdec0(%esi),%eax
f0100c81:	ba fe 73 10 f0       	mov    $0xf01073fe,%edx
f0100c86:	81 ea e9 5a 10 f0    	sub    $0xf0105ae9,%edx
f0100c8c:	39 d0                	cmp    %edx,%eax
f0100c8e:	73 07                	jae    f0100c97 <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c90:	05 e9 5a 10 f0       	add    $0xf0105ae9,%eax
f0100c95:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c97:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c9a:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c9d:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ca2:	39 ca                	cmp    %ecx,%edx
f0100ca4:	7d 53                	jge    f0100cf9 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f0100ca6:	8d 42 01             	lea    0x1(%edx),%eax
f0100ca9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100cac:	89 c2                	mov    %eax,%edx
f0100cae:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100cb1:	05 40 21 10 f0       	add    $0xf0102140,%eax
f0100cb6:	89 ce                	mov    %ecx,%esi
f0100cb8:	eb 04                	jmp    f0100cbe <debuginfo_eip+0x1ff>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100cba:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100cbe:	39 d6                	cmp    %edx,%esi
f0100cc0:	7e 32                	jle    f0100cf4 <debuginfo_eip+0x235>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cc2:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100cc6:	83 c2 01             	add    $0x1,%edx
f0100cc9:	83 c0 0c             	add    $0xc,%eax
f0100ccc:	80 f9 a0             	cmp    $0xa0,%cl
f0100ccf:	74 e9                	je     f0100cba <debuginfo_eip+0x1fb>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cd1:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cd6:	eb 21                	jmp    f0100cf9 <debuginfo_eip+0x23a>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100cd8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cdd:	eb 1a                	jmp    f0100cf9 <debuginfo_eip+0x23a>
f0100cdf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ce4:	eb 13                	jmp    f0100cf9 <debuginfo_eip+0x23a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100ce6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ceb:	eb 0c                	jmp    f0100cf9 <debuginfo_eip+0x23a>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	
	if(lline <= rline){
		info->eip_line = stabs[lline].n_desc;
	}else{
		return -1;
f0100ced:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cf2:	eb 05                	jmp    f0100cf9 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cf4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cf9:	83 c4 3c             	add    $0x3c,%esp
f0100cfc:	5b                   	pop    %ebx
f0100cfd:	5e                   	pop    %esi
f0100cfe:	5f                   	pop    %edi
f0100cff:	5d                   	pop    %ebp
f0100d00:	c3                   	ret    
f0100d01:	66 90                	xchg   %ax,%ax
f0100d03:	66 90                	xchg   %ax,%ax
f0100d05:	66 90                	xchg   %ax,%ax
f0100d07:	66 90                	xchg   %ax,%ax
f0100d09:	66 90                	xchg   %ax,%ax
f0100d0b:	66 90                	xchg   %ax,%ax
f0100d0d:	66 90                	xchg   %ax,%ax
f0100d0f:	90                   	nop

f0100d10 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d10:	55                   	push   %ebp
f0100d11:	89 e5                	mov    %esp,%ebp
f0100d13:	57                   	push   %edi
f0100d14:	56                   	push   %esi
f0100d15:	53                   	push   %ebx
f0100d16:	83 ec 3c             	sub    $0x3c,%esp
f0100d19:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d1c:	89 d7                	mov    %edx,%edi
f0100d1e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d21:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d24:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d27:	89 c3                	mov    %eax,%ebx
f0100d29:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d2c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d2f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d32:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d37:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d3a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d3d:	39 d9                	cmp    %ebx,%ecx
f0100d3f:	72 05                	jb     f0100d46 <printnum+0x36>
f0100d41:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d44:	77 69                	ja     f0100daf <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d46:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100d49:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100d4d:	83 ee 01             	sub    $0x1,%esi
f0100d50:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d54:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d58:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100d5c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100d60:	89 c3                	mov    %eax,%ebx
f0100d62:	89 d6                	mov    %edx,%esi
f0100d64:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d67:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100d6a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100d6e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d72:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d75:	89 04 24             	mov    %eax,(%esp)
f0100d78:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d7b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d7f:	e8 bc 09 00 00       	call   f0101740 <__udivdi3>
f0100d84:	89 d9                	mov    %ebx,%ecx
f0100d86:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100d8a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d8e:	89 04 24             	mov    %eax,(%esp)
f0100d91:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d95:	89 fa                	mov    %edi,%edx
f0100d97:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d9a:	e8 71 ff ff ff       	call   f0100d10 <printnum>
f0100d9f:	eb 1b                	jmp    f0100dbc <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100da1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100da5:	8b 45 18             	mov    0x18(%ebp),%eax
f0100da8:	89 04 24             	mov    %eax,(%esp)
f0100dab:	ff d3                	call   *%ebx
f0100dad:	eb 03                	jmp    f0100db2 <printnum+0xa2>
f0100daf:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100db2:	83 ee 01             	sub    $0x1,%esi
f0100db5:	85 f6                	test   %esi,%esi
f0100db7:	7f e8                	jg     f0100da1 <printnum+0x91>
f0100db9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100dbc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dc0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100dc4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100dc7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100dca:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dce:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100dd2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100dd5:	89 04 24             	mov    %eax,(%esp)
f0100dd8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ddb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ddf:	e8 8c 0a 00 00       	call   f0101870 <__umoddi3>
f0100de4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100de8:	0f be 80 2d 1f 10 f0 	movsbl -0xfefe0d3(%eax),%eax
f0100def:	89 04 24             	mov    %eax,(%esp)
f0100df2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100df5:	ff d0                	call   *%eax
}
f0100df7:	83 c4 3c             	add    $0x3c,%esp
f0100dfa:	5b                   	pop    %ebx
f0100dfb:	5e                   	pop    %esi
f0100dfc:	5f                   	pop    %edi
f0100dfd:	5d                   	pop    %ebp
f0100dfe:	c3                   	ret    

f0100dff <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100dff:	55                   	push   %ebp
f0100e00:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e02:	83 fa 01             	cmp    $0x1,%edx
f0100e05:	7e 0e                	jle    f0100e15 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e07:	8b 10                	mov    (%eax),%edx
f0100e09:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e0c:	89 08                	mov    %ecx,(%eax)
f0100e0e:	8b 02                	mov    (%edx),%eax
f0100e10:	8b 52 04             	mov    0x4(%edx),%edx
f0100e13:	eb 22                	jmp    f0100e37 <getuint+0x38>
	else if (lflag)
f0100e15:	85 d2                	test   %edx,%edx
f0100e17:	74 10                	je     f0100e29 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e19:	8b 10                	mov    (%eax),%edx
f0100e1b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e1e:	89 08                	mov    %ecx,(%eax)
f0100e20:	8b 02                	mov    (%edx),%eax
f0100e22:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e27:	eb 0e                	jmp    f0100e37 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e29:	8b 10                	mov    (%eax),%edx
f0100e2b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e2e:	89 08                	mov    %ecx,(%eax)
f0100e30:	8b 02                	mov    (%edx),%eax
f0100e32:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e37:	5d                   	pop    %ebp
f0100e38:	c3                   	ret    

f0100e39 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e39:	55                   	push   %ebp
f0100e3a:	89 e5                	mov    %esp,%ebp
f0100e3c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e3f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e43:	8b 10                	mov    (%eax),%edx
f0100e45:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e48:	73 0a                	jae    f0100e54 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e4a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e4d:	89 08                	mov    %ecx,(%eax)
f0100e4f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e52:	88 02                	mov    %al,(%edx)
}
f0100e54:	5d                   	pop    %ebp
f0100e55:	c3                   	ret    

f0100e56 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e56:	55                   	push   %ebp
f0100e57:	89 e5                	mov    %esp,%ebp
f0100e59:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e5c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e5f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e63:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e66:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e6a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e6d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e71:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e74:	89 04 24             	mov    %eax,(%esp)
f0100e77:	e8 02 00 00 00       	call   f0100e7e <vprintfmt>
	va_end(ap);
}
f0100e7c:	c9                   	leave  
f0100e7d:	c3                   	ret    

f0100e7e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e7e:	55                   	push   %ebp
f0100e7f:	89 e5                	mov    %esp,%ebp
f0100e81:	57                   	push   %edi
f0100e82:	56                   	push   %esi
f0100e83:	53                   	push   %ebx
f0100e84:	83 ec 3c             	sub    $0x3c,%esp
f0100e87:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100e8a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100e8d:	eb 14                	jmp    f0100ea3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e8f:	85 c0                	test   %eax,%eax
f0100e91:	0f 84 b3 03 00 00    	je     f010124a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0100e97:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e9b:	89 04 24             	mov    %eax,(%esp)
f0100e9e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ea1:	89 f3                	mov    %esi,%ebx
f0100ea3:	8d 73 01             	lea    0x1(%ebx),%esi
f0100ea6:	0f b6 03             	movzbl (%ebx),%eax
f0100ea9:	83 f8 25             	cmp    $0x25,%eax
f0100eac:	75 e1                	jne    f0100e8f <vprintfmt+0x11>
f0100eae:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100eb2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100eb9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100ec0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100ec7:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ecc:	eb 1d                	jmp    f0100eeb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ece:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100ed0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100ed4:	eb 15                	jmp    f0100eeb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ed6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100ed8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100edc:	eb 0d                	jmp    f0100eeb <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100ede:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ee1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100ee4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eeb:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100eee:	0f b6 0e             	movzbl (%esi),%ecx
f0100ef1:	0f b6 c1             	movzbl %cl,%eax
f0100ef4:	83 e9 23             	sub    $0x23,%ecx
f0100ef7:	80 f9 55             	cmp    $0x55,%cl
f0100efa:	0f 87 2a 03 00 00    	ja     f010122a <vprintfmt+0x3ac>
f0100f00:	0f b6 c9             	movzbl %cl,%ecx
f0100f03:	ff 24 8d bc 1f 10 f0 	jmp    *-0xfefe044(,%ecx,4)
f0100f0a:	89 de                	mov    %ebx,%esi
f0100f0c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f11:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100f14:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100f18:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f1b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100f1e:	83 fb 09             	cmp    $0x9,%ebx
f0100f21:	77 36                	ja     f0100f59 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f23:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100f26:	eb e9                	jmp    f0100f11 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f28:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f2b:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f2e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f31:	8b 00                	mov    (%eax),%eax
f0100f33:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f36:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f38:	eb 22                	jmp    f0100f5c <vprintfmt+0xde>
f0100f3a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f3d:	85 c9                	test   %ecx,%ecx
f0100f3f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f44:	0f 49 c1             	cmovns %ecx,%eax
f0100f47:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f4a:	89 de                	mov    %ebx,%esi
f0100f4c:	eb 9d                	jmp    f0100eeb <vprintfmt+0x6d>
f0100f4e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f50:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0100f57:	eb 92                	jmp    f0100eeb <vprintfmt+0x6d>
f0100f59:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f0100f5c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100f60:	79 89                	jns    f0100eeb <vprintfmt+0x6d>
f0100f62:	e9 77 ff ff ff       	jmp    f0100ede <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f67:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f6a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100f6c:	e9 7a ff ff ff       	jmp    f0100eeb <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f71:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f74:	8d 50 04             	lea    0x4(%eax),%edx
f0100f77:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f7a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f7e:	8b 00                	mov    (%eax),%eax
f0100f80:	89 04 24             	mov    %eax,(%esp)
f0100f83:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100f86:	e9 18 ff ff ff       	jmp    f0100ea3 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f8b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f8e:	8d 50 04             	lea    0x4(%eax),%edx
f0100f91:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f94:	8b 00                	mov    (%eax),%eax
f0100f96:	99                   	cltd   
f0100f97:	31 d0                	xor    %edx,%eax
f0100f99:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f9b:	83 f8 06             	cmp    $0x6,%eax
f0100f9e:	7f 0b                	jg     f0100fab <vprintfmt+0x12d>
f0100fa0:	8b 14 85 14 21 10 f0 	mov    -0xfefdeec(,%eax,4),%edx
f0100fa7:	85 d2                	test   %edx,%edx
f0100fa9:	75 20                	jne    f0100fcb <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f0100fab:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100faf:	c7 44 24 08 45 1f 10 	movl   $0xf0101f45,0x8(%esp)
f0100fb6:	f0 
f0100fb7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fbb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fbe:	89 04 24             	mov    %eax,(%esp)
f0100fc1:	e8 90 fe ff ff       	call   f0100e56 <printfmt>
f0100fc6:	e9 d8 fe ff ff       	jmp    f0100ea3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0100fcb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100fcf:	c7 44 24 08 4e 1f 10 	movl   $0xf0101f4e,0x8(%esp)
f0100fd6:	f0 
f0100fd7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fdb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fde:	89 04 24             	mov    %eax,(%esp)
f0100fe1:	e8 70 fe ff ff       	call   f0100e56 <printfmt>
f0100fe6:	e9 b8 fe ff ff       	jmp    f0100ea3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100feb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100fee:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ff1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100ff4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ff7:	8d 50 04             	lea    0x4(%eax),%edx
f0100ffa:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ffd:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0100fff:	85 f6                	test   %esi,%esi
f0101001:	b8 3e 1f 10 f0       	mov    $0xf0101f3e,%eax
f0101006:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0101009:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010100d:	0f 84 97 00 00 00    	je     f01010aa <vprintfmt+0x22c>
f0101013:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101017:	0f 8e 9b 00 00 00    	jle    f01010b8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010101d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101021:	89 34 24             	mov    %esi,(%esp)
f0101024:	e8 9f 03 00 00       	call   f01013c8 <strnlen>
f0101029:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010102c:	29 c2                	sub    %eax,%edx
f010102e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0101031:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0101035:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101038:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010103b:	8b 75 08             	mov    0x8(%ebp),%esi
f010103e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101041:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101043:	eb 0f                	jmp    f0101054 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0101045:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101049:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010104c:	89 04 24             	mov    %eax,(%esp)
f010104f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101051:	83 eb 01             	sub    $0x1,%ebx
f0101054:	85 db                	test   %ebx,%ebx
f0101056:	7f ed                	jg     f0101045 <vprintfmt+0x1c7>
f0101058:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010105b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010105e:	85 d2                	test   %edx,%edx
f0101060:	b8 00 00 00 00       	mov    $0x0,%eax
f0101065:	0f 49 c2             	cmovns %edx,%eax
f0101068:	29 c2                	sub    %eax,%edx
f010106a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010106d:	89 d7                	mov    %edx,%edi
f010106f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101072:	eb 50                	jmp    f01010c4 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101074:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101078:	74 1e                	je     f0101098 <vprintfmt+0x21a>
f010107a:	0f be d2             	movsbl %dl,%edx
f010107d:	83 ea 20             	sub    $0x20,%edx
f0101080:	83 fa 5e             	cmp    $0x5e,%edx
f0101083:	76 13                	jbe    f0101098 <vprintfmt+0x21a>
					putch('?', putdat);
f0101085:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101088:	89 44 24 04          	mov    %eax,0x4(%esp)
f010108c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101093:	ff 55 08             	call   *0x8(%ebp)
f0101096:	eb 0d                	jmp    f01010a5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0101098:	8b 55 0c             	mov    0xc(%ebp),%edx
f010109b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010109f:	89 04 24             	mov    %eax,(%esp)
f01010a2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010a5:	83 ef 01             	sub    $0x1,%edi
f01010a8:	eb 1a                	jmp    f01010c4 <vprintfmt+0x246>
f01010aa:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010ad:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01010b0:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010b3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010b6:	eb 0c                	jmp    f01010c4 <vprintfmt+0x246>
f01010b8:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010bb:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01010be:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010c1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010c4:	83 c6 01             	add    $0x1,%esi
f01010c7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01010cb:	0f be c2             	movsbl %dl,%eax
f01010ce:	85 c0                	test   %eax,%eax
f01010d0:	74 27                	je     f01010f9 <vprintfmt+0x27b>
f01010d2:	85 db                	test   %ebx,%ebx
f01010d4:	78 9e                	js     f0101074 <vprintfmt+0x1f6>
f01010d6:	83 eb 01             	sub    $0x1,%ebx
f01010d9:	79 99                	jns    f0101074 <vprintfmt+0x1f6>
f01010db:	89 f8                	mov    %edi,%eax
f01010dd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01010e0:	8b 75 08             	mov    0x8(%ebp),%esi
f01010e3:	89 c3                	mov    %eax,%ebx
f01010e5:	eb 1a                	jmp    f0101101 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01010e7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010eb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01010f2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01010f4:	83 eb 01             	sub    $0x1,%ebx
f01010f7:	eb 08                	jmp    f0101101 <vprintfmt+0x283>
f01010f9:	89 fb                	mov    %edi,%ebx
f01010fb:	8b 75 08             	mov    0x8(%ebp),%esi
f01010fe:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101101:	85 db                	test   %ebx,%ebx
f0101103:	7f e2                	jg     f01010e7 <vprintfmt+0x269>
f0101105:	89 75 08             	mov    %esi,0x8(%ebp)
f0101108:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010110b:	e9 93 fd ff ff       	jmp    f0100ea3 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101110:	83 fa 01             	cmp    $0x1,%edx
f0101113:	7e 16                	jle    f010112b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0101115:	8b 45 14             	mov    0x14(%ebp),%eax
f0101118:	8d 50 08             	lea    0x8(%eax),%edx
f010111b:	89 55 14             	mov    %edx,0x14(%ebp)
f010111e:	8b 50 04             	mov    0x4(%eax),%edx
f0101121:	8b 00                	mov    (%eax),%eax
f0101123:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101126:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101129:	eb 32                	jmp    f010115d <vprintfmt+0x2df>
	else if (lflag)
f010112b:	85 d2                	test   %edx,%edx
f010112d:	74 18                	je     f0101147 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010112f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101132:	8d 50 04             	lea    0x4(%eax),%edx
f0101135:	89 55 14             	mov    %edx,0x14(%ebp)
f0101138:	8b 30                	mov    (%eax),%esi
f010113a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010113d:	89 f0                	mov    %esi,%eax
f010113f:	c1 f8 1f             	sar    $0x1f,%eax
f0101142:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101145:	eb 16                	jmp    f010115d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0101147:	8b 45 14             	mov    0x14(%ebp),%eax
f010114a:	8d 50 04             	lea    0x4(%eax),%edx
f010114d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101150:	8b 30                	mov    (%eax),%esi
f0101152:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0101155:	89 f0                	mov    %esi,%eax
f0101157:	c1 f8 1f             	sar    $0x1f,%eax
f010115a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010115d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101160:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101163:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101168:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010116c:	0f 89 80 00 00 00    	jns    f01011f2 <vprintfmt+0x374>
				putch('-', putdat);
f0101172:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101176:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010117d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101180:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101183:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101186:	f7 d8                	neg    %eax
f0101188:	83 d2 00             	adc    $0x0,%edx
f010118b:	f7 da                	neg    %edx
			}
			base = 10;
f010118d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101192:	eb 5e                	jmp    f01011f2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101194:	8d 45 14             	lea    0x14(%ebp),%eax
f0101197:	e8 63 fc ff ff       	call   f0100dff <getuint>
			base = 10;
f010119c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01011a1:	eb 4f                	jmp    f01011f2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f01011a3:	8d 45 14             	lea    0x14(%ebp),%eax
f01011a6:	e8 54 fc ff ff       	call   f0100dff <getuint>
			base = 8;
f01011ab:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01011b0:	eb 40                	jmp    f01011f2 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f01011b2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011b6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011bd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011c0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011c4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01011cb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01011ce:	8b 45 14             	mov    0x14(%ebp),%eax
f01011d1:	8d 50 04             	lea    0x4(%eax),%edx
f01011d4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01011d7:	8b 00                	mov    (%eax),%eax
f01011d9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01011de:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01011e3:	eb 0d                	jmp    f01011f2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01011e5:	8d 45 14             	lea    0x14(%ebp),%eax
f01011e8:	e8 12 fc ff ff       	call   f0100dff <getuint>
			base = 16;
f01011ed:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01011f2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f01011f6:	89 74 24 10          	mov    %esi,0x10(%esp)
f01011fa:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01011fd:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101201:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101205:	89 04 24             	mov    %eax,(%esp)
f0101208:	89 54 24 04          	mov    %edx,0x4(%esp)
f010120c:	89 fa                	mov    %edi,%edx
f010120e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101211:	e8 fa fa ff ff       	call   f0100d10 <printnum>
			break;
f0101216:	e9 88 fc ff ff       	jmp    f0100ea3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010121b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010121f:	89 04 24             	mov    %eax,(%esp)
f0101222:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101225:	e9 79 fc ff ff       	jmp    f0100ea3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010122a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010122e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101235:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101238:	89 f3                	mov    %esi,%ebx
f010123a:	eb 03                	jmp    f010123f <vprintfmt+0x3c1>
f010123c:	83 eb 01             	sub    $0x1,%ebx
f010123f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0101243:	75 f7                	jne    f010123c <vprintfmt+0x3be>
f0101245:	e9 59 fc ff ff       	jmp    f0100ea3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010124a:	83 c4 3c             	add    $0x3c,%esp
f010124d:	5b                   	pop    %ebx
f010124e:	5e                   	pop    %esi
f010124f:	5f                   	pop    %edi
f0101250:	5d                   	pop    %ebp
f0101251:	c3                   	ret    

f0101252 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101252:	55                   	push   %ebp
f0101253:	89 e5                	mov    %esp,%ebp
f0101255:	83 ec 28             	sub    $0x28,%esp
f0101258:	8b 45 08             	mov    0x8(%ebp),%eax
f010125b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010125e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101261:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101265:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101268:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010126f:	85 c0                	test   %eax,%eax
f0101271:	74 30                	je     f01012a3 <vsnprintf+0x51>
f0101273:	85 d2                	test   %edx,%edx
f0101275:	7e 2c                	jle    f01012a3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101277:	8b 45 14             	mov    0x14(%ebp),%eax
f010127a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010127e:	8b 45 10             	mov    0x10(%ebp),%eax
f0101281:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101285:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101288:	89 44 24 04          	mov    %eax,0x4(%esp)
f010128c:	c7 04 24 39 0e 10 f0 	movl   $0xf0100e39,(%esp)
f0101293:	e8 e6 fb ff ff       	call   f0100e7e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101298:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010129b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010129e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012a1:	eb 05                	jmp    f01012a8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01012a3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01012a8:	c9                   	leave  
f01012a9:	c3                   	ret    

f01012aa <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012aa:	55                   	push   %ebp
f01012ab:	89 e5                	mov    %esp,%ebp
f01012ad:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012b0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012b3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012b7:	8b 45 10             	mov    0x10(%ebp),%eax
f01012ba:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012be:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012c1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01012c8:	89 04 24             	mov    %eax,(%esp)
f01012cb:	e8 82 ff ff ff       	call   f0101252 <vsnprintf>
	va_end(ap);

	return rc;
}
f01012d0:	c9                   	leave  
f01012d1:	c3                   	ret    
f01012d2:	66 90                	xchg   %ax,%ax
f01012d4:	66 90                	xchg   %ax,%ax
f01012d6:	66 90                	xchg   %ax,%ax
f01012d8:	66 90                	xchg   %ax,%ax
f01012da:	66 90                	xchg   %ax,%ax
f01012dc:	66 90                	xchg   %ax,%ax
f01012de:	66 90                	xchg   %ax,%ax

f01012e0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012e0:	55                   	push   %ebp
f01012e1:	89 e5                	mov    %esp,%ebp
f01012e3:	57                   	push   %edi
f01012e4:	56                   	push   %esi
f01012e5:	53                   	push   %ebx
f01012e6:	83 ec 1c             	sub    $0x1c,%esp
f01012e9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012ec:	85 c0                	test   %eax,%eax
f01012ee:	74 10                	je     f0101300 <readline+0x20>
		cprintf("%s", prompt);
f01012f0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012f4:	c7 04 24 4e 1f 10 f0 	movl   $0xf0101f4e,(%esp)
f01012fb:	e8 c8 f6 ff ff       	call   f01009c8 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101300:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101307:	e8 76 f3 ff ff       	call   f0100682 <iscons>
f010130c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010130e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101313:	e8 59 f3 ff ff       	call   f0100671 <getchar>
f0101318:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010131a:	85 c0                	test   %eax,%eax
f010131c:	79 17                	jns    f0101335 <readline+0x55>
			cprintf("read error: %e\n", c);
f010131e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101322:	c7 04 24 30 21 10 f0 	movl   $0xf0102130,(%esp)
f0101329:	e8 9a f6 ff ff       	call   f01009c8 <cprintf>
			return NULL;
f010132e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101333:	eb 6d                	jmp    f01013a2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101335:	83 f8 7f             	cmp    $0x7f,%eax
f0101338:	74 05                	je     f010133f <readline+0x5f>
f010133a:	83 f8 08             	cmp    $0x8,%eax
f010133d:	75 19                	jne    f0101358 <readline+0x78>
f010133f:	85 f6                	test   %esi,%esi
f0101341:	7e 15                	jle    f0101358 <readline+0x78>
			if (echoing)
f0101343:	85 ff                	test   %edi,%edi
f0101345:	74 0c                	je     f0101353 <readline+0x73>
				cputchar('\b');
f0101347:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010134e:	e8 0e f3 ff ff       	call   f0100661 <cputchar>
			i--;
f0101353:	83 ee 01             	sub    $0x1,%esi
f0101356:	eb bb                	jmp    f0101313 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101358:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010135e:	7f 1c                	jg     f010137c <readline+0x9c>
f0101360:	83 fb 1f             	cmp    $0x1f,%ebx
f0101363:	7e 17                	jle    f010137c <readline+0x9c>
			if (echoing)
f0101365:	85 ff                	test   %edi,%edi
f0101367:	74 08                	je     f0101371 <readline+0x91>
				cputchar(c);
f0101369:	89 1c 24             	mov    %ebx,(%esp)
f010136c:	e8 f0 f2 ff ff       	call   f0100661 <cputchar>
			buf[i++] = c;
f0101371:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101377:	8d 76 01             	lea    0x1(%esi),%esi
f010137a:	eb 97                	jmp    f0101313 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010137c:	83 fb 0d             	cmp    $0xd,%ebx
f010137f:	74 05                	je     f0101386 <readline+0xa6>
f0101381:	83 fb 0a             	cmp    $0xa,%ebx
f0101384:	75 8d                	jne    f0101313 <readline+0x33>
			if (echoing)
f0101386:	85 ff                	test   %edi,%edi
f0101388:	74 0c                	je     f0101396 <readline+0xb6>
				cputchar('\n');
f010138a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101391:	e8 cb f2 ff ff       	call   f0100661 <cputchar>
			buf[i] = 0;
f0101396:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010139d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01013a2:	83 c4 1c             	add    $0x1c,%esp
f01013a5:	5b                   	pop    %ebx
f01013a6:	5e                   	pop    %esi
f01013a7:	5f                   	pop    %edi
f01013a8:	5d                   	pop    %ebp
f01013a9:	c3                   	ret    
f01013aa:	66 90                	xchg   %ax,%ax
f01013ac:	66 90                	xchg   %ax,%ax
f01013ae:	66 90                	xchg   %ax,%ax

f01013b0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013b0:	55                   	push   %ebp
f01013b1:	89 e5                	mov    %esp,%ebp
f01013b3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013b6:	b8 00 00 00 00       	mov    $0x0,%eax
f01013bb:	eb 03                	jmp    f01013c0 <strlen+0x10>
		n++;
f01013bd:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01013c0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013c4:	75 f7                	jne    f01013bd <strlen+0xd>
		n++;
	return n;
}
f01013c6:	5d                   	pop    %ebp
f01013c7:	c3                   	ret    

f01013c8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013c8:	55                   	push   %ebp
f01013c9:	89 e5                	mov    %esp,%ebp
f01013cb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013ce:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01013d6:	eb 03                	jmp    f01013db <strnlen+0x13>
		n++;
f01013d8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013db:	39 d0                	cmp    %edx,%eax
f01013dd:	74 06                	je     f01013e5 <strnlen+0x1d>
f01013df:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01013e3:	75 f3                	jne    f01013d8 <strnlen+0x10>
		n++;
	return n;
}
f01013e5:	5d                   	pop    %ebp
f01013e6:	c3                   	ret    

f01013e7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01013e7:	55                   	push   %ebp
f01013e8:	89 e5                	mov    %esp,%ebp
f01013ea:	53                   	push   %ebx
f01013eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01013ee:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01013f1:	89 c2                	mov    %eax,%edx
f01013f3:	83 c2 01             	add    $0x1,%edx
f01013f6:	83 c1 01             	add    $0x1,%ecx
f01013f9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01013fd:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101400:	84 db                	test   %bl,%bl
f0101402:	75 ef                	jne    f01013f3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101404:	5b                   	pop    %ebx
f0101405:	5d                   	pop    %ebp
f0101406:	c3                   	ret    

f0101407 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101407:	55                   	push   %ebp
f0101408:	89 e5                	mov    %esp,%ebp
f010140a:	53                   	push   %ebx
f010140b:	83 ec 08             	sub    $0x8,%esp
f010140e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101411:	89 1c 24             	mov    %ebx,(%esp)
f0101414:	e8 97 ff ff ff       	call   f01013b0 <strlen>
	strcpy(dst + len, src);
f0101419:	8b 55 0c             	mov    0xc(%ebp),%edx
f010141c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101420:	01 d8                	add    %ebx,%eax
f0101422:	89 04 24             	mov    %eax,(%esp)
f0101425:	e8 bd ff ff ff       	call   f01013e7 <strcpy>
	return dst;
}
f010142a:	89 d8                	mov    %ebx,%eax
f010142c:	83 c4 08             	add    $0x8,%esp
f010142f:	5b                   	pop    %ebx
f0101430:	5d                   	pop    %ebp
f0101431:	c3                   	ret    

f0101432 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101432:	55                   	push   %ebp
f0101433:	89 e5                	mov    %esp,%ebp
f0101435:	56                   	push   %esi
f0101436:	53                   	push   %ebx
f0101437:	8b 75 08             	mov    0x8(%ebp),%esi
f010143a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010143d:	89 f3                	mov    %esi,%ebx
f010143f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101442:	89 f2                	mov    %esi,%edx
f0101444:	eb 0f                	jmp    f0101455 <strncpy+0x23>
		*dst++ = *src;
f0101446:	83 c2 01             	add    $0x1,%edx
f0101449:	0f b6 01             	movzbl (%ecx),%eax
f010144c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010144f:	80 39 01             	cmpb   $0x1,(%ecx)
f0101452:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101455:	39 da                	cmp    %ebx,%edx
f0101457:	75 ed                	jne    f0101446 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101459:	89 f0                	mov    %esi,%eax
f010145b:	5b                   	pop    %ebx
f010145c:	5e                   	pop    %esi
f010145d:	5d                   	pop    %ebp
f010145e:	c3                   	ret    

f010145f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010145f:	55                   	push   %ebp
f0101460:	89 e5                	mov    %esp,%ebp
f0101462:	56                   	push   %esi
f0101463:	53                   	push   %ebx
f0101464:	8b 75 08             	mov    0x8(%ebp),%esi
f0101467:	8b 55 0c             	mov    0xc(%ebp),%edx
f010146a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010146d:	89 f0                	mov    %esi,%eax
f010146f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101473:	85 c9                	test   %ecx,%ecx
f0101475:	75 0b                	jne    f0101482 <strlcpy+0x23>
f0101477:	eb 1d                	jmp    f0101496 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101479:	83 c0 01             	add    $0x1,%eax
f010147c:	83 c2 01             	add    $0x1,%edx
f010147f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101482:	39 d8                	cmp    %ebx,%eax
f0101484:	74 0b                	je     f0101491 <strlcpy+0x32>
f0101486:	0f b6 0a             	movzbl (%edx),%ecx
f0101489:	84 c9                	test   %cl,%cl
f010148b:	75 ec                	jne    f0101479 <strlcpy+0x1a>
f010148d:	89 c2                	mov    %eax,%edx
f010148f:	eb 02                	jmp    f0101493 <strlcpy+0x34>
f0101491:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0101493:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0101496:	29 f0                	sub    %esi,%eax
}
f0101498:	5b                   	pop    %ebx
f0101499:	5e                   	pop    %esi
f010149a:	5d                   	pop    %ebp
f010149b:	c3                   	ret    

f010149c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010149c:	55                   	push   %ebp
f010149d:	89 e5                	mov    %esp,%ebp
f010149f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014a2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01014a5:	eb 06                	jmp    f01014ad <strcmp+0x11>
		p++, q++;
f01014a7:	83 c1 01             	add    $0x1,%ecx
f01014aa:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01014ad:	0f b6 01             	movzbl (%ecx),%eax
f01014b0:	84 c0                	test   %al,%al
f01014b2:	74 04                	je     f01014b8 <strcmp+0x1c>
f01014b4:	3a 02                	cmp    (%edx),%al
f01014b6:	74 ef                	je     f01014a7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014b8:	0f b6 c0             	movzbl %al,%eax
f01014bb:	0f b6 12             	movzbl (%edx),%edx
f01014be:	29 d0                	sub    %edx,%eax
}
f01014c0:	5d                   	pop    %ebp
f01014c1:	c3                   	ret    

f01014c2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014c2:	55                   	push   %ebp
f01014c3:	89 e5                	mov    %esp,%ebp
f01014c5:	53                   	push   %ebx
f01014c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01014c9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014cc:	89 c3                	mov    %eax,%ebx
f01014ce:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01014d1:	eb 06                	jmp    f01014d9 <strncmp+0x17>
		n--, p++, q++;
f01014d3:	83 c0 01             	add    $0x1,%eax
f01014d6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01014d9:	39 d8                	cmp    %ebx,%eax
f01014db:	74 15                	je     f01014f2 <strncmp+0x30>
f01014dd:	0f b6 08             	movzbl (%eax),%ecx
f01014e0:	84 c9                	test   %cl,%cl
f01014e2:	74 04                	je     f01014e8 <strncmp+0x26>
f01014e4:	3a 0a                	cmp    (%edx),%cl
f01014e6:	74 eb                	je     f01014d3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01014e8:	0f b6 00             	movzbl (%eax),%eax
f01014eb:	0f b6 12             	movzbl (%edx),%edx
f01014ee:	29 d0                	sub    %edx,%eax
f01014f0:	eb 05                	jmp    f01014f7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01014f2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01014f7:	5b                   	pop    %ebx
f01014f8:	5d                   	pop    %ebp
f01014f9:	c3                   	ret    

f01014fa <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01014fa:	55                   	push   %ebp
f01014fb:	89 e5                	mov    %esp,%ebp
f01014fd:	8b 45 08             	mov    0x8(%ebp),%eax
f0101500:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101504:	eb 07                	jmp    f010150d <strchr+0x13>
		if (*s == c)
f0101506:	38 ca                	cmp    %cl,%dl
f0101508:	74 0f                	je     f0101519 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010150a:	83 c0 01             	add    $0x1,%eax
f010150d:	0f b6 10             	movzbl (%eax),%edx
f0101510:	84 d2                	test   %dl,%dl
f0101512:	75 f2                	jne    f0101506 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101514:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101519:	5d                   	pop    %ebp
f010151a:	c3                   	ret    

f010151b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010151b:	55                   	push   %ebp
f010151c:	89 e5                	mov    %esp,%ebp
f010151e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101521:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101525:	eb 07                	jmp    f010152e <strfind+0x13>
		if (*s == c)
f0101527:	38 ca                	cmp    %cl,%dl
f0101529:	74 0a                	je     f0101535 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010152b:	83 c0 01             	add    $0x1,%eax
f010152e:	0f b6 10             	movzbl (%eax),%edx
f0101531:	84 d2                	test   %dl,%dl
f0101533:	75 f2                	jne    f0101527 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101535:	5d                   	pop    %ebp
f0101536:	c3                   	ret    

f0101537 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101537:	55                   	push   %ebp
f0101538:	89 e5                	mov    %esp,%ebp
f010153a:	57                   	push   %edi
f010153b:	56                   	push   %esi
f010153c:	53                   	push   %ebx
f010153d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101540:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101543:	85 c9                	test   %ecx,%ecx
f0101545:	74 36                	je     f010157d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101547:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010154d:	75 28                	jne    f0101577 <memset+0x40>
f010154f:	f6 c1 03             	test   $0x3,%cl
f0101552:	75 23                	jne    f0101577 <memset+0x40>
		c &= 0xFF;
f0101554:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101558:	89 d3                	mov    %edx,%ebx
f010155a:	c1 e3 08             	shl    $0x8,%ebx
f010155d:	89 d6                	mov    %edx,%esi
f010155f:	c1 e6 18             	shl    $0x18,%esi
f0101562:	89 d0                	mov    %edx,%eax
f0101564:	c1 e0 10             	shl    $0x10,%eax
f0101567:	09 f0                	or     %esi,%eax
f0101569:	09 c2                	or     %eax,%edx
f010156b:	89 d0                	mov    %edx,%eax
f010156d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010156f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101572:	fc                   	cld    
f0101573:	f3 ab                	rep stos %eax,%es:(%edi)
f0101575:	eb 06                	jmp    f010157d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101577:	8b 45 0c             	mov    0xc(%ebp),%eax
f010157a:	fc                   	cld    
f010157b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010157d:	89 f8                	mov    %edi,%eax
f010157f:	5b                   	pop    %ebx
f0101580:	5e                   	pop    %esi
f0101581:	5f                   	pop    %edi
f0101582:	5d                   	pop    %ebp
f0101583:	c3                   	ret    

f0101584 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101584:	55                   	push   %ebp
f0101585:	89 e5                	mov    %esp,%ebp
f0101587:	57                   	push   %edi
f0101588:	56                   	push   %esi
f0101589:	8b 45 08             	mov    0x8(%ebp),%eax
f010158c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010158f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101592:	39 c6                	cmp    %eax,%esi
f0101594:	73 35                	jae    f01015cb <memmove+0x47>
f0101596:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101599:	39 d0                	cmp    %edx,%eax
f010159b:	73 2e                	jae    f01015cb <memmove+0x47>
		s += n;
		d += n;
f010159d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01015a0:	89 d6                	mov    %edx,%esi
f01015a2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015a4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015aa:	75 13                	jne    f01015bf <memmove+0x3b>
f01015ac:	f6 c1 03             	test   $0x3,%cl
f01015af:	75 0e                	jne    f01015bf <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01015b1:	83 ef 04             	sub    $0x4,%edi
f01015b4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01015b7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01015ba:	fd                   	std    
f01015bb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015bd:	eb 09                	jmp    f01015c8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01015bf:	83 ef 01             	sub    $0x1,%edi
f01015c2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01015c5:	fd                   	std    
f01015c6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01015c8:	fc                   	cld    
f01015c9:	eb 1d                	jmp    f01015e8 <memmove+0x64>
f01015cb:	89 f2                	mov    %esi,%edx
f01015cd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015cf:	f6 c2 03             	test   $0x3,%dl
f01015d2:	75 0f                	jne    f01015e3 <memmove+0x5f>
f01015d4:	f6 c1 03             	test   $0x3,%cl
f01015d7:	75 0a                	jne    f01015e3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01015d9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01015dc:	89 c7                	mov    %eax,%edi
f01015de:	fc                   	cld    
f01015df:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015e1:	eb 05                	jmp    f01015e8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01015e3:	89 c7                	mov    %eax,%edi
f01015e5:	fc                   	cld    
f01015e6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01015e8:	5e                   	pop    %esi
f01015e9:	5f                   	pop    %edi
f01015ea:	5d                   	pop    %ebp
f01015eb:	c3                   	ret    

f01015ec <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01015ec:	55                   	push   %ebp
f01015ed:	89 e5                	mov    %esp,%ebp
f01015ef:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01015f2:	8b 45 10             	mov    0x10(%ebp),%eax
f01015f5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01015f9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101600:	8b 45 08             	mov    0x8(%ebp),%eax
f0101603:	89 04 24             	mov    %eax,(%esp)
f0101606:	e8 79 ff ff ff       	call   f0101584 <memmove>
}
f010160b:	c9                   	leave  
f010160c:	c3                   	ret    

f010160d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010160d:	55                   	push   %ebp
f010160e:	89 e5                	mov    %esp,%ebp
f0101610:	56                   	push   %esi
f0101611:	53                   	push   %ebx
f0101612:	8b 55 08             	mov    0x8(%ebp),%edx
f0101615:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101618:	89 d6                	mov    %edx,%esi
f010161a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010161d:	eb 1a                	jmp    f0101639 <memcmp+0x2c>
		if (*s1 != *s2)
f010161f:	0f b6 02             	movzbl (%edx),%eax
f0101622:	0f b6 19             	movzbl (%ecx),%ebx
f0101625:	38 d8                	cmp    %bl,%al
f0101627:	74 0a                	je     f0101633 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101629:	0f b6 c0             	movzbl %al,%eax
f010162c:	0f b6 db             	movzbl %bl,%ebx
f010162f:	29 d8                	sub    %ebx,%eax
f0101631:	eb 0f                	jmp    f0101642 <memcmp+0x35>
		s1++, s2++;
f0101633:	83 c2 01             	add    $0x1,%edx
f0101636:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101639:	39 f2                	cmp    %esi,%edx
f010163b:	75 e2                	jne    f010161f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010163d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101642:	5b                   	pop    %ebx
f0101643:	5e                   	pop    %esi
f0101644:	5d                   	pop    %ebp
f0101645:	c3                   	ret    

f0101646 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101646:	55                   	push   %ebp
f0101647:	89 e5                	mov    %esp,%ebp
f0101649:	8b 45 08             	mov    0x8(%ebp),%eax
f010164c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010164f:	89 c2                	mov    %eax,%edx
f0101651:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101654:	eb 07                	jmp    f010165d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101656:	38 08                	cmp    %cl,(%eax)
f0101658:	74 07                	je     f0101661 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010165a:	83 c0 01             	add    $0x1,%eax
f010165d:	39 d0                	cmp    %edx,%eax
f010165f:	72 f5                	jb     f0101656 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101661:	5d                   	pop    %ebp
f0101662:	c3                   	ret    

f0101663 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101663:	55                   	push   %ebp
f0101664:	89 e5                	mov    %esp,%ebp
f0101666:	57                   	push   %edi
f0101667:	56                   	push   %esi
f0101668:	53                   	push   %ebx
f0101669:	8b 55 08             	mov    0x8(%ebp),%edx
f010166c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010166f:	eb 03                	jmp    f0101674 <strtol+0x11>
		s++;
f0101671:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101674:	0f b6 0a             	movzbl (%edx),%ecx
f0101677:	80 f9 09             	cmp    $0x9,%cl
f010167a:	74 f5                	je     f0101671 <strtol+0xe>
f010167c:	80 f9 20             	cmp    $0x20,%cl
f010167f:	74 f0                	je     f0101671 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101681:	80 f9 2b             	cmp    $0x2b,%cl
f0101684:	75 0a                	jne    f0101690 <strtol+0x2d>
		s++;
f0101686:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101689:	bf 00 00 00 00       	mov    $0x0,%edi
f010168e:	eb 11                	jmp    f01016a1 <strtol+0x3e>
f0101690:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101695:	80 f9 2d             	cmp    $0x2d,%cl
f0101698:	75 07                	jne    f01016a1 <strtol+0x3e>
		s++, neg = 1;
f010169a:	8d 52 01             	lea    0x1(%edx),%edx
f010169d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016a1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f01016a6:	75 15                	jne    f01016bd <strtol+0x5a>
f01016a8:	80 3a 30             	cmpb   $0x30,(%edx)
f01016ab:	75 10                	jne    f01016bd <strtol+0x5a>
f01016ad:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01016b1:	75 0a                	jne    f01016bd <strtol+0x5a>
		s += 2, base = 16;
f01016b3:	83 c2 02             	add    $0x2,%edx
f01016b6:	b8 10 00 00 00       	mov    $0x10,%eax
f01016bb:	eb 10                	jmp    f01016cd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f01016bd:	85 c0                	test   %eax,%eax
f01016bf:	75 0c                	jne    f01016cd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01016c1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016c3:	80 3a 30             	cmpb   $0x30,(%edx)
f01016c6:	75 05                	jne    f01016cd <strtol+0x6a>
		s++, base = 8;
f01016c8:	83 c2 01             	add    $0x1,%edx
f01016cb:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f01016cd:	bb 00 00 00 00       	mov    $0x0,%ebx
f01016d2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016d5:	0f b6 0a             	movzbl (%edx),%ecx
f01016d8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01016db:	89 f0                	mov    %esi,%eax
f01016dd:	3c 09                	cmp    $0x9,%al
f01016df:	77 08                	ja     f01016e9 <strtol+0x86>
			dig = *s - '0';
f01016e1:	0f be c9             	movsbl %cl,%ecx
f01016e4:	83 e9 30             	sub    $0x30,%ecx
f01016e7:	eb 20                	jmp    f0101709 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f01016e9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01016ec:	89 f0                	mov    %esi,%eax
f01016ee:	3c 19                	cmp    $0x19,%al
f01016f0:	77 08                	ja     f01016fa <strtol+0x97>
			dig = *s - 'a' + 10;
f01016f2:	0f be c9             	movsbl %cl,%ecx
f01016f5:	83 e9 57             	sub    $0x57,%ecx
f01016f8:	eb 0f                	jmp    f0101709 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f01016fa:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01016fd:	89 f0                	mov    %esi,%eax
f01016ff:	3c 19                	cmp    $0x19,%al
f0101701:	77 16                	ja     f0101719 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0101703:	0f be c9             	movsbl %cl,%ecx
f0101706:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101709:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010170c:	7d 0f                	jge    f010171d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010170e:	83 c2 01             	add    $0x1,%edx
f0101711:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101715:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101717:	eb bc                	jmp    f01016d5 <strtol+0x72>
f0101719:	89 d8                	mov    %ebx,%eax
f010171b:	eb 02                	jmp    f010171f <strtol+0xbc>
f010171d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010171f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101723:	74 05                	je     f010172a <strtol+0xc7>
		*endptr = (char *) s;
f0101725:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101728:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010172a:	f7 d8                	neg    %eax
f010172c:	85 ff                	test   %edi,%edi
f010172e:	0f 44 c3             	cmove  %ebx,%eax
}
f0101731:	5b                   	pop    %ebx
f0101732:	5e                   	pop    %esi
f0101733:	5f                   	pop    %edi
f0101734:	5d                   	pop    %ebp
f0101735:	c3                   	ret    
f0101736:	66 90                	xchg   %ax,%ax
f0101738:	66 90                	xchg   %ax,%ax
f010173a:	66 90                	xchg   %ax,%ax
f010173c:	66 90                	xchg   %ax,%ax
f010173e:	66 90                	xchg   %ax,%ax

f0101740 <__udivdi3>:
f0101740:	55                   	push   %ebp
f0101741:	57                   	push   %edi
f0101742:	56                   	push   %esi
f0101743:	83 ec 0c             	sub    $0xc,%esp
f0101746:	8b 44 24 28          	mov    0x28(%esp),%eax
f010174a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010174e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101752:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101756:	85 c0                	test   %eax,%eax
f0101758:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010175c:	89 ea                	mov    %ebp,%edx
f010175e:	89 0c 24             	mov    %ecx,(%esp)
f0101761:	75 2d                	jne    f0101790 <__udivdi3+0x50>
f0101763:	39 e9                	cmp    %ebp,%ecx
f0101765:	77 61                	ja     f01017c8 <__udivdi3+0x88>
f0101767:	85 c9                	test   %ecx,%ecx
f0101769:	89 ce                	mov    %ecx,%esi
f010176b:	75 0b                	jne    f0101778 <__udivdi3+0x38>
f010176d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101772:	31 d2                	xor    %edx,%edx
f0101774:	f7 f1                	div    %ecx
f0101776:	89 c6                	mov    %eax,%esi
f0101778:	31 d2                	xor    %edx,%edx
f010177a:	89 e8                	mov    %ebp,%eax
f010177c:	f7 f6                	div    %esi
f010177e:	89 c5                	mov    %eax,%ebp
f0101780:	89 f8                	mov    %edi,%eax
f0101782:	f7 f6                	div    %esi
f0101784:	89 ea                	mov    %ebp,%edx
f0101786:	83 c4 0c             	add    $0xc,%esp
f0101789:	5e                   	pop    %esi
f010178a:	5f                   	pop    %edi
f010178b:	5d                   	pop    %ebp
f010178c:	c3                   	ret    
f010178d:	8d 76 00             	lea    0x0(%esi),%esi
f0101790:	39 e8                	cmp    %ebp,%eax
f0101792:	77 24                	ja     f01017b8 <__udivdi3+0x78>
f0101794:	0f bd e8             	bsr    %eax,%ebp
f0101797:	83 f5 1f             	xor    $0x1f,%ebp
f010179a:	75 3c                	jne    f01017d8 <__udivdi3+0x98>
f010179c:	8b 74 24 04          	mov    0x4(%esp),%esi
f01017a0:	39 34 24             	cmp    %esi,(%esp)
f01017a3:	0f 86 9f 00 00 00    	jbe    f0101848 <__udivdi3+0x108>
f01017a9:	39 d0                	cmp    %edx,%eax
f01017ab:	0f 82 97 00 00 00    	jb     f0101848 <__udivdi3+0x108>
f01017b1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017b8:	31 d2                	xor    %edx,%edx
f01017ba:	31 c0                	xor    %eax,%eax
f01017bc:	83 c4 0c             	add    $0xc,%esp
f01017bf:	5e                   	pop    %esi
f01017c0:	5f                   	pop    %edi
f01017c1:	5d                   	pop    %ebp
f01017c2:	c3                   	ret    
f01017c3:	90                   	nop
f01017c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017c8:	89 f8                	mov    %edi,%eax
f01017ca:	f7 f1                	div    %ecx
f01017cc:	31 d2                	xor    %edx,%edx
f01017ce:	83 c4 0c             	add    $0xc,%esp
f01017d1:	5e                   	pop    %esi
f01017d2:	5f                   	pop    %edi
f01017d3:	5d                   	pop    %ebp
f01017d4:	c3                   	ret    
f01017d5:	8d 76 00             	lea    0x0(%esi),%esi
f01017d8:	89 e9                	mov    %ebp,%ecx
f01017da:	8b 3c 24             	mov    (%esp),%edi
f01017dd:	d3 e0                	shl    %cl,%eax
f01017df:	89 c6                	mov    %eax,%esi
f01017e1:	b8 20 00 00 00       	mov    $0x20,%eax
f01017e6:	29 e8                	sub    %ebp,%eax
f01017e8:	89 c1                	mov    %eax,%ecx
f01017ea:	d3 ef                	shr    %cl,%edi
f01017ec:	89 e9                	mov    %ebp,%ecx
f01017ee:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01017f2:	8b 3c 24             	mov    (%esp),%edi
f01017f5:	09 74 24 08          	or     %esi,0x8(%esp)
f01017f9:	89 d6                	mov    %edx,%esi
f01017fb:	d3 e7                	shl    %cl,%edi
f01017fd:	89 c1                	mov    %eax,%ecx
f01017ff:	89 3c 24             	mov    %edi,(%esp)
f0101802:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101806:	d3 ee                	shr    %cl,%esi
f0101808:	89 e9                	mov    %ebp,%ecx
f010180a:	d3 e2                	shl    %cl,%edx
f010180c:	89 c1                	mov    %eax,%ecx
f010180e:	d3 ef                	shr    %cl,%edi
f0101810:	09 d7                	or     %edx,%edi
f0101812:	89 f2                	mov    %esi,%edx
f0101814:	89 f8                	mov    %edi,%eax
f0101816:	f7 74 24 08          	divl   0x8(%esp)
f010181a:	89 d6                	mov    %edx,%esi
f010181c:	89 c7                	mov    %eax,%edi
f010181e:	f7 24 24             	mull   (%esp)
f0101821:	39 d6                	cmp    %edx,%esi
f0101823:	89 14 24             	mov    %edx,(%esp)
f0101826:	72 30                	jb     f0101858 <__udivdi3+0x118>
f0101828:	8b 54 24 04          	mov    0x4(%esp),%edx
f010182c:	89 e9                	mov    %ebp,%ecx
f010182e:	d3 e2                	shl    %cl,%edx
f0101830:	39 c2                	cmp    %eax,%edx
f0101832:	73 05                	jae    f0101839 <__udivdi3+0xf9>
f0101834:	3b 34 24             	cmp    (%esp),%esi
f0101837:	74 1f                	je     f0101858 <__udivdi3+0x118>
f0101839:	89 f8                	mov    %edi,%eax
f010183b:	31 d2                	xor    %edx,%edx
f010183d:	e9 7a ff ff ff       	jmp    f01017bc <__udivdi3+0x7c>
f0101842:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101848:	31 d2                	xor    %edx,%edx
f010184a:	b8 01 00 00 00       	mov    $0x1,%eax
f010184f:	e9 68 ff ff ff       	jmp    f01017bc <__udivdi3+0x7c>
f0101854:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101858:	8d 47 ff             	lea    -0x1(%edi),%eax
f010185b:	31 d2                	xor    %edx,%edx
f010185d:	83 c4 0c             	add    $0xc,%esp
f0101860:	5e                   	pop    %esi
f0101861:	5f                   	pop    %edi
f0101862:	5d                   	pop    %ebp
f0101863:	c3                   	ret    
f0101864:	66 90                	xchg   %ax,%ax
f0101866:	66 90                	xchg   %ax,%ax
f0101868:	66 90                	xchg   %ax,%ax
f010186a:	66 90                	xchg   %ax,%ax
f010186c:	66 90                	xchg   %ax,%ax
f010186e:	66 90                	xchg   %ax,%ax

f0101870 <__umoddi3>:
f0101870:	55                   	push   %ebp
f0101871:	57                   	push   %edi
f0101872:	56                   	push   %esi
f0101873:	83 ec 14             	sub    $0x14,%esp
f0101876:	8b 44 24 28          	mov    0x28(%esp),%eax
f010187a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010187e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101882:	89 c7                	mov    %eax,%edi
f0101884:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101888:	8b 44 24 30          	mov    0x30(%esp),%eax
f010188c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101890:	89 34 24             	mov    %esi,(%esp)
f0101893:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101897:	85 c0                	test   %eax,%eax
f0101899:	89 c2                	mov    %eax,%edx
f010189b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010189f:	75 17                	jne    f01018b8 <__umoddi3+0x48>
f01018a1:	39 fe                	cmp    %edi,%esi
f01018a3:	76 4b                	jbe    f01018f0 <__umoddi3+0x80>
f01018a5:	89 c8                	mov    %ecx,%eax
f01018a7:	89 fa                	mov    %edi,%edx
f01018a9:	f7 f6                	div    %esi
f01018ab:	89 d0                	mov    %edx,%eax
f01018ad:	31 d2                	xor    %edx,%edx
f01018af:	83 c4 14             	add    $0x14,%esp
f01018b2:	5e                   	pop    %esi
f01018b3:	5f                   	pop    %edi
f01018b4:	5d                   	pop    %ebp
f01018b5:	c3                   	ret    
f01018b6:	66 90                	xchg   %ax,%ax
f01018b8:	39 f8                	cmp    %edi,%eax
f01018ba:	77 54                	ja     f0101910 <__umoddi3+0xa0>
f01018bc:	0f bd e8             	bsr    %eax,%ebp
f01018bf:	83 f5 1f             	xor    $0x1f,%ebp
f01018c2:	75 5c                	jne    f0101920 <__umoddi3+0xb0>
f01018c4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01018c8:	39 3c 24             	cmp    %edi,(%esp)
f01018cb:	0f 87 e7 00 00 00    	ja     f01019b8 <__umoddi3+0x148>
f01018d1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01018d5:	29 f1                	sub    %esi,%ecx
f01018d7:	19 c7                	sbb    %eax,%edi
f01018d9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018dd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018e1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01018e5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01018e9:	83 c4 14             	add    $0x14,%esp
f01018ec:	5e                   	pop    %esi
f01018ed:	5f                   	pop    %edi
f01018ee:	5d                   	pop    %ebp
f01018ef:	c3                   	ret    
f01018f0:	85 f6                	test   %esi,%esi
f01018f2:	89 f5                	mov    %esi,%ebp
f01018f4:	75 0b                	jne    f0101901 <__umoddi3+0x91>
f01018f6:	b8 01 00 00 00       	mov    $0x1,%eax
f01018fb:	31 d2                	xor    %edx,%edx
f01018fd:	f7 f6                	div    %esi
f01018ff:	89 c5                	mov    %eax,%ebp
f0101901:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101905:	31 d2                	xor    %edx,%edx
f0101907:	f7 f5                	div    %ebp
f0101909:	89 c8                	mov    %ecx,%eax
f010190b:	f7 f5                	div    %ebp
f010190d:	eb 9c                	jmp    f01018ab <__umoddi3+0x3b>
f010190f:	90                   	nop
f0101910:	89 c8                	mov    %ecx,%eax
f0101912:	89 fa                	mov    %edi,%edx
f0101914:	83 c4 14             	add    $0x14,%esp
f0101917:	5e                   	pop    %esi
f0101918:	5f                   	pop    %edi
f0101919:	5d                   	pop    %ebp
f010191a:	c3                   	ret    
f010191b:	90                   	nop
f010191c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101920:	8b 04 24             	mov    (%esp),%eax
f0101923:	be 20 00 00 00       	mov    $0x20,%esi
f0101928:	89 e9                	mov    %ebp,%ecx
f010192a:	29 ee                	sub    %ebp,%esi
f010192c:	d3 e2                	shl    %cl,%edx
f010192e:	89 f1                	mov    %esi,%ecx
f0101930:	d3 e8                	shr    %cl,%eax
f0101932:	89 e9                	mov    %ebp,%ecx
f0101934:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101938:	8b 04 24             	mov    (%esp),%eax
f010193b:	09 54 24 04          	or     %edx,0x4(%esp)
f010193f:	89 fa                	mov    %edi,%edx
f0101941:	d3 e0                	shl    %cl,%eax
f0101943:	89 f1                	mov    %esi,%ecx
f0101945:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101949:	8b 44 24 10          	mov    0x10(%esp),%eax
f010194d:	d3 ea                	shr    %cl,%edx
f010194f:	89 e9                	mov    %ebp,%ecx
f0101951:	d3 e7                	shl    %cl,%edi
f0101953:	89 f1                	mov    %esi,%ecx
f0101955:	d3 e8                	shr    %cl,%eax
f0101957:	89 e9                	mov    %ebp,%ecx
f0101959:	09 f8                	or     %edi,%eax
f010195b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010195f:	f7 74 24 04          	divl   0x4(%esp)
f0101963:	d3 e7                	shl    %cl,%edi
f0101965:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101969:	89 d7                	mov    %edx,%edi
f010196b:	f7 64 24 08          	mull   0x8(%esp)
f010196f:	39 d7                	cmp    %edx,%edi
f0101971:	89 c1                	mov    %eax,%ecx
f0101973:	89 14 24             	mov    %edx,(%esp)
f0101976:	72 2c                	jb     f01019a4 <__umoddi3+0x134>
f0101978:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010197c:	72 22                	jb     f01019a0 <__umoddi3+0x130>
f010197e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101982:	29 c8                	sub    %ecx,%eax
f0101984:	19 d7                	sbb    %edx,%edi
f0101986:	89 e9                	mov    %ebp,%ecx
f0101988:	89 fa                	mov    %edi,%edx
f010198a:	d3 e8                	shr    %cl,%eax
f010198c:	89 f1                	mov    %esi,%ecx
f010198e:	d3 e2                	shl    %cl,%edx
f0101990:	89 e9                	mov    %ebp,%ecx
f0101992:	d3 ef                	shr    %cl,%edi
f0101994:	09 d0                	or     %edx,%eax
f0101996:	89 fa                	mov    %edi,%edx
f0101998:	83 c4 14             	add    $0x14,%esp
f010199b:	5e                   	pop    %esi
f010199c:	5f                   	pop    %edi
f010199d:	5d                   	pop    %ebp
f010199e:	c3                   	ret    
f010199f:	90                   	nop
f01019a0:	39 d7                	cmp    %edx,%edi
f01019a2:	75 da                	jne    f010197e <__umoddi3+0x10e>
f01019a4:	8b 14 24             	mov    (%esp),%edx
f01019a7:	89 c1                	mov    %eax,%ecx
f01019a9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f01019ad:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01019b1:	eb cb                	jmp    f010197e <__umoddi3+0x10e>
f01019b3:	90                   	nop
f01019b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019b8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01019bc:	0f 82 0f ff ff ff    	jb     f01018d1 <__umoddi3+0x61>
f01019c2:	e9 1a ff ff ff       	jmp    f01018e1 <__umoddi3+0x71>
