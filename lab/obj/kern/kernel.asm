
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
f010004e:	c7 04 24 40 19 10 f0 	movl   $0xf0101940,(%esp)
f0100055:	e8 3d 09 00 00       	call   f0100997 <cprintf>
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
f010008b:	c7 04 24 5c 19 10 f0 	movl   $0xf010195c,(%esp)
f0100092:	e8 00 09 00 00       	call   f0100997 <cprintf>
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
f01000c0:	e8 d2 13 00 00       	call   f0101497 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a5 04 00 00       	call   f010056f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 77 19 10 f0 	movl   $0xf0101977,(%esp)
f01000d9:	e8 b9 08 00 00       	call   f0100997 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 16 07 00 00       	call   f010080c <monitor>
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
f0100125:	c7 04 24 92 19 10 f0 	movl   $0xf0101992,(%esp)
f010012c:	e8 66 08 00 00       	call   f0100997 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 27 08 00 00       	call   f0100964 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 ce 19 10 f0 	movl   $0xf01019ce,(%esp)
f0100144:	e8 4e 08 00 00       	call   f0100997 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 b7 06 00 00       	call   f010080c <monitor>
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
f010016f:	c7 04 24 aa 19 10 f0 	movl   $0xf01019aa,(%esp)
f0100176:	e8 1c 08 00 00       	call   f0100997 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 da 07 00 00       	call   f0100964 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 ce 19 10 f0 	movl   $0xf01019ce,(%esp)
f0100191:	e8 01 08 00 00       	call   f0100997 <cprintf>
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
f010024d:	0f b6 82 20 1b 10 f0 	movzbl -0xfefe4e0(%edx),%eax
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
f010028a:	0f b6 82 20 1b 10 f0 	movzbl -0xfefe4e0(%edx),%eax
f0100291:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f0100297:	0f b6 8a 20 1a 10 f0 	movzbl -0xfefe5e0(%edx),%ecx
f010029e:	31 c8                	xor    %ecx,%eax
f01002a0:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f01002a5:	89 c1                	mov    %eax,%ecx
f01002a7:	83 e1 03             	and    $0x3,%ecx
f01002aa:	8b 0c 8d 00 1a 10 f0 	mov    -0xfefe600(,%ecx,4),%ecx
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
f01002ea:	c7 04 24 c4 19 10 f0 	movl   $0xf01019c4,(%esp)
f01002f1:	e8 a1 06 00 00       	call   f0100997 <cprintf>
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
f0100499:	e8 46 10 00 00       	call   f01014e4 <memmove>
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
f010064d:	c7 04 24 d0 19 10 f0 	movl   $0xf01019d0,(%esp)
f0100654:	e8 3e 03 00 00       	call   f0100997 <cprintf>
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
f0100696:	c7 44 24 08 20 1c 10 	movl   $0xf0101c20,0x8(%esp)
f010069d:	f0 
f010069e:	c7 44 24 04 3e 1c 10 	movl   $0xf0101c3e,0x4(%esp)
f01006a5:	f0 
f01006a6:	c7 04 24 43 1c 10 f0 	movl   $0xf0101c43,(%esp)
f01006ad:	e8 e5 02 00 00       	call   f0100997 <cprintf>
f01006b2:	c7 44 24 08 e0 1c 10 	movl   $0xf0101ce0,0x8(%esp)
f01006b9:	f0 
f01006ba:	c7 44 24 04 4c 1c 10 	movl   $0xf0101c4c,0x4(%esp)
f01006c1:	f0 
f01006c2:	c7 04 24 43 1c 10 f0 	movl   $0xf0101c43,(%esp)
f01006c9:	e8 c9 02 00 00       	call   f0100997 <cprintf>
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
f01006db:	c7 04 24 55 1c 10 f0 	movl   $0xf0101c55,(%esp)
f01006e2:	e8 b0 02 00 00       	call   f0100997 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006e7:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006ee:	00 
f01006ef:	c7 04 24 08 1d 10 f0 	movl   $0xf0101d08,(%esp)
f01006f6:	e8 9c 02 00 00       	call   f0100997 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006fb:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100702:	00 
f0100703:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f010070a:	f0 
f010070b:	c7 04 24 30 1d 10 f0 	movl   $0xf0101d30,(%esp)
f0100712:	e8 80 02 00 00       	call   f0100997 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100717:	c7 44 24 08 27 19 10 	movl   $0x101927,0x8(%esp)
f010071e:	00 
f010071f:	c7 44 24 04 27 19 10 	movl   $0xf0101927,0x4(%esp)
f0100726:	f0 
f0100727:	c7 04 24 54 1d 10 f0 	movl   $0xf0101d54,(%esp)
f010072e:	e8 64 02 00 00       	call   f0100997 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100733:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f010073a:	00 
f010073b:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f0100742:	f0 
f0100743:	c7 04 24 78 1d 10 f0 	movl   $0xf0101d78,(%esp)
f010074a:	e8 48 02 00 00       	call   f0100997 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010074f:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100756:	00 
f0100757:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010075e:	f0 
f010075f:	c7 04 24 9c 1d 10 f0 	movl   $0xf0101d9c,(%esp)
f0100766:	e8 2c 02 00 00       	call   f0100997 <cprintf>
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
f010078c:	c7 04 24 c0 1d 10 f0 	movl   $0xf0101dc0,(%esp)
f0100793:	e8 ff 01 00 00       	call   f0100997 <cprintf>
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
f01007a2:	56                   	push   %esi
f01007a3:	53                   	push   %ebx
f01007a4:	83 ec 10             	sub    $0x10,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01007a7:	89 ee                	mov    %ebp,%esi
	// 每次压栈的顺序依次是：保存ebx、保存ebp、返回地址eip、五个参数
	uint32_t eip;
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f01007a9:	c7 04 24 6e 1c 10 f0 	movl   $0xf0101c6e,(%esp)
f01007b0:	e8 e2 01 00 00       	call   f0100997 <cprintf>
	while(ebp != 0){
f01007b5:	eb 45                	jmp    f01007fc <mon_backtrace+0x5d>
		eip = *((uint32_t *)ebp + 1);
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
f01007b7:	8b 46 04             	mov    0x4(%esi),%eax
f01007ba:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007be:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007c2:	c7 04 24 80 1c 10 f0 	movl   $0xf0101c80,(%esp)
f01007c9:	e8 c9 01 00 00       	call   f0100997 <cprintf>
		for(int i = 2; i < 7; i++){
f01007ce:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x", *((uint32_t*)ebp + i));
f01007d3:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f01007d6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007da:	c7 04 24 9b 1c 10 f0 	movl   $0xf0101c9b,(%esp)
f01007e1:	e8 b1 01 00 00       	call   f0100997 <cprintf>
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
		eip = *((uint32_t *)ebp + 1);
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
		for(int i = 2; i < 7; i++){
f01007e6:	83 c3 01             	add    $0x1,%ebx
f01007e9:	83 fb 07             	cmp    $0x7,%ebx
f01007ec:	75 e5                	jne    f01007d3 <mon_backtrace+0x34>
			cprintf(" %08x", *((uint32_t*)ebp + i));
		}
		cprintf("\n");
f01007ee:	c7 04 24 ce 19 10 f0 	movl   $0xf01019ce,(%esp)
f01007f5:	e8 9d 01 00 00       	call   f0100997 <cprintf>
		ebp = *((uint32_t *)ebp);
f01007fa:	8b 36                	mov    (%esi),%esi
{
	// 每次压栈的顺序依次是：保存ebx、保存ebp、返回地址eip、五个参数
	uint32_t eip;
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f01007fc:	85 f6                	test   %esi,%esi
f01007fe:	75 b7                	jne    f01007b7 <mon_backtrace+0x18>
		}
		cprintf("\n");
		ebp = *((uint32_t *)ebp);
	}
	return 0;
}
f0100800:	b8 00 00 00 00       	mov    $0x0,%eax
f0100805:	83 c4 10             	add    $0x10,%esp
f0100808:	5b                   	pop    %ebx
f0100809:	5e                   	pop    %esi
f010080a:	5d                   	pop    %ebp
f010080b:	c3                   	ret    

f010080c <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010080c:	55                   	push   %ebp
f010080d:	89 e5                	mov    %esp,%ebp
f010080f:	57                   	push   %edi
f0100810:	56                   	push   %esi
f0100811:	53                   	push   %ebx
f0100812:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100815:	c7 04 24 ec 1d 10 f0 	movl   $0xf0101dec,(%esp)
f010081c:	e8 76 01 00 00       	call   f0100997 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100821:	c7 04 24 10 1e 10 f0 	movl   $0xf0101e10,(%esp)
f0100828:	e8 6a 01 00 00       	call   f0100997 <cprintf>


	while (1) {
		buf = readline("K> ");
f010082d:	c7 04 24 a1 1c 10 f0 	movl   $0xf0101ca1,(%esp)
f0100834:	e8 07 0a 00 00       	call   f0101240 <readline>
f0100839:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010083b:	85 c0                	test   %eax,%eax
f010083d:	74 ee                	je     f010082d <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010083f:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100846:	be 00 00 00 00       	mov    $0x0,%esi
f010084b:	eb 0a                	jmp    f0100857 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010084d:	c6 03 00             	movb   $0x0,(%ebx)
f0100850:	89 f7                	mov    %esi,%edi
f0100852:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100855:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100857:	0f b6 03             	movzbl (%ebx),%eax
f010085a:	84 c0                	test   %al,%al
f010085c:	74 66                	je     f01008c4 <monitor+0xb8>
f010085e:	0f be c0             	movsbl %al,%eax
f0100861:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100865:	c7 04 24 a5 1c 10 f0 	movl   $0xf0101ca5,(%esp)
f010086c:	e8 e9 0b 00 00       	call   f010145a <strchr>
f0100871:	85 c0                	test   %eax,%eax
f0100873:	75 d8                	jne    f010084d <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100875:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100878:	74 4a                	je     f01008c4 <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010087a:	83 fe 0f             	cmp    $0xf,%esi
f010087d:	8d 76 00             	lea    0x0(%esi),%esi
f0100880:	75 16                	jne    f0100898 <monitor+0x8c>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100882:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100889:	00 
f010088a:	c7 04 24 aa 1c 10 f0 	movl   $0xf0101caa,(%esp)
f0100891:	e8 01 01 00 00       	call   f0100997 <cprintf>
f0100896:	eb 95                	jmp    f010082d <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100898:	8d 7e 01             	lea    0x1(%esi),%edi
f010089b:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010089f:	eb 03                	jmp    f01008a4 <monitor+0x98>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008a1:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008a4:	0f b6 03             	movzbl (%ebx),%eax
f01008a7:	84 c0                	test   %al,%al
f01008a9:	74 aa                	je     f0100855 <monitor+0x49>
f01008ab:	0f be c0             	movsbl %al,%eax
f01008ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008b2:	c7 04 24 a5 1c 10 f0 	movl   $0xf0101ca5,(%esp)
f01008b9:	e8 9c 0b 00 00       	call   f010145a <strchr>
f01008be:	85 c0                	test   %eax,%eax
f01008c0:	74 df                	je     f01008a1 <monitor+0x95>
f01008c2:	eb 91                	jmp    f0100855 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f01008c4:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008cb:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008cc:	85 f6                	test   %esi,%esi
f01008ce:	0f 84 59 ff ff ff    	je     f010082d <monitor+0x21>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008d4:	c7 44 24 04 3e 1c 10 	movl   $0xf0101c3e,0x4(%esp)
f01008db:	f0 
f01008dc:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008df:	89 04 24             	mov    %eax,(%esp)
f01008e2:	e8 15 0b 00 00       	call   f01013fc <strcmp>
f01008e7:	85 c0                	test   %eax,%eax
f01008e9:	74 1b                	je     f0100906 <monitor+0xfa>
f01008eb:	c7 44 24 04 4c 1c 10 	movl   $0xf0101c4c,0x4(%esp)
f01008f2:	f0 
f01008f3:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008f6:	89 04 24             	mov    %eax,(%esp)
f01008f9:	e8 fe 0a 00 00       	call   f01013fc <strcmp>
f01008fe:	85 c0                	test   %eax,%eax
f0100900:	75 2f                	jne    f0100931 <monitor+0x125>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100902:	b0 01                	mov    $0x1,%al
f0100904:	eb 05                	jmp    f010090b <monitor+0xff>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100906:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f010090b:	8d 14 00             	lea    (%eax,%eax,1),%edx
f010090e:	01 d0                	add    %edx,%eax
f0100910:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100913:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100917:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010091a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010091e:	89 34 24             	mov    %esi,(%esp)
f0100921:	ff 14 85 40 1e 10 f0 	call   *-0xfefe1c0(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100928:	85 c0                	test   %eax,%eax
f010092a:	78 1d                	js     f0100949 <monitor+0x13d>
f010092c:	e9 fc fe ff ff       	jmp    f010082d <monitor+0x21>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100931:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100934:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100938:	c7 04 24 c7 1c 10 f0 	movl   $0xf0101cc7,(%esp)
f010093f:	e8 53 00 00 00       	call   f0100997 <cprintf>
f0100944:	e9 e4 fe ff ff       	jmp    f010082d <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100949:	83 c4 5c             	add    $0x5c,%esp
f010094c:	5b                   	pop    %ebx
f010094d:	5e                   	pop    %esi
f010094e:	5f                   	pop    %edi
f010094f:	5d                   	pop    %ebp
f0100950:	c3                   	ret    

f0100951 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100951:	55                   	push   %ebp
f0100952:	89 e5                	mov    %esp,%ebp
f0100954:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100957:	8b 45 08             	mov    0x8(%ebp),%eax
f010095a:	89 04 24             	mov    %eax,(%esp)
f010095d:	e8 ff fc ff ff       	call   f0100661 <cputchar>
	*cnt++;
}
f0100962:	c9                   	leave  
f0100963:	c3                   	ret    

f0100964 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100964:	55                   	push   %ebp
f0100965:	89 e5                	mov    %esp,%ebp
f0100967:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010096a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100971:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100974:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100978:	8b 45 08             	mov    0x8(%ebp),%eax
f010097b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010097f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100982:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100986:	c7 04 24 51 09 10 f0 	movl   $0xf0100951,(%esp)
f010098d:	e8 4c 04 00 00       	call   f0100dde <vprintfmt>
	return cnt;
}
f0100992:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100995:	c9                   	leave  
f0100996:	c3                   	ret    

f0100997 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100997:	55                   	push   %ebp
f0100998:	89 e5                	mov    %esp,%ebp
f010099a:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010099d:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009a0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01009a7:	89 04 24             	mov    %eax,(%esp)
f01009aa:	e8 b5 ff ff ff       	call   f0100964 <vcprintf>
	va_end(ap);

	return cnt;
}
f01009af:	c9                   	leave  
f01009b0:	c3                   	ret    

f01009b1 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009b1:	55                   	push   %ebp
f01009b2:	89 e5                	mov    %esp,%ebp
f01009b4:	57                   	push   %edi
f01009b5:	56                   	push   %esi
f01009b6:	53                   	push   %ebx
f01009b7:	83 ec 10             	sub    $0x10,%esp
f01009ba:	89 c6                	mov    %eax,%esi
f01009bc:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01009bf:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01009c2:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009c5:	8b 1a                	mov    (%edx),%ebx
f01009c7:	8b 01                	mov    (%ecx),%eax
f01009c9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009cc:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f01009d3:	eb 77                	jmp    f0100a4c <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f01009d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009d8:	01 d8                	add    %ebx,%eax
f01009da:	b9 02 00 00 00       	mov    $0x2,%ecx
f01009df:	99                   	cltd   
f01009e0:	f7 f9                	idiv   %ecx
f01009e2:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009e4:	eb 01                	jmp    f01009e7 <stab_binsearch+0x36>
			m--;
f01009e6:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009e7:	39 d9                	cmp    %ebx,%ecx
f01009e9:	7c 1d                	jl     f0100a08 <stab_binsearch+0x57>
f01009eb:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01009ee:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f01009f3:	39 fa                	cmp    %edi,%edx
f01009f5:	75 ef                	jne    f01009e6 <stab_binsearch+0x35>
f01009f7:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009fa:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01009fd:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a01:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a04:	73 18                	jae    f0100a1e <stab_binsearch+0x6d>
f0100a06:	eb 05                	jmp    f0100a0d <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a08:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a0b:	eb 3f                	jmp    f0100a4c <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a0d:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a10:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a12:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a15:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a1c:	eb 2e                	jmp    f0100a4c <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a1e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a21:	73 15                	jae    f0100a38 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a23:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a26:	48                   	dec    %eax
f0100a27:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a2a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a2d:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a2f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a36:	eb 14                	jmp    f0100a4c <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a38:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a3b:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100a3e:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100a40:	ff 45 0c             	incl   0xc(%ebp)
f0100a43:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a45:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a4c:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a4f:	7e 84                	jle    f01009d5 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a51:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a55:	75 0d                	jne    f0100a64 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100a57:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a5a:	8b 00                	mov    (%eax),%eax
f0100a5c:	48                   	dec    %eax
f0100a5d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100a60:	89 07                	mov    %eax,(%edi)
f0100a62:	eb 22                	jmp    f0100a86 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a64:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a67:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a69:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a6c:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a6e:	eb 01                	jmp    f0100a71 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a70:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a71:	39 c1                	cmp    %eax,%ecx
f0100a73:	7d 0c                	jge    f0100a81 <stab_binsearch+0xd0>
f0100a75:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100a78:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a7d:	39 fa                	cmp    %edi,%edx
f0100a7f:	75 ef                	jne    f0100a70 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a81:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100a84:	89 07                	mov    %eax,(%edi)
	}
}
f0100a86:	83 c4 10             	add    $0x10,%esp
f0100a89:	5b                   	pop    %ebx
f0100a8a:	5e                   	pop    %esi
f0100a8b:	5f                   	pop    %edi
f0100a8c:	5d                   	pop    %ebp
f0100a8d:	c3                   	ret    

f0100a8e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a8e:	55                   	push   %ebp
f0100a8f:	89 e5                	mov    %esp,%ebp
f0100a91:	57                   	push   %edi
f0100a92:	56                   	push   %esi
f0100a93:	53                   	push   %ebx
f0100a94:	83 ec 2c             	sub    $0x2c,%esp
f0100a97:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a9a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a9d:	c7 03 50 1e 10 f0    	movl   $0xf0101e50,(%ebx)
	info->eip_line = 0;
f0100aa3:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100aaa:	c7 43 08 50 1e 10 f0 	movl   $0xf0101e50,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100ab1:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100ab8:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100abb:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ac2:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100ac8:	76 12                	jbe    f0100adc <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100aca:	b8 88 72 10 f0       	mov    $0xf0107288,%eax
f0100acf:	3d a1 59 10 f0       	cmp    $0xf01059a1,%eax
f0100ad4:	0f 86 6b 01 00 00    	jbe    f0100c45 <debuginfo_eip+0x1b7>
f0100ada:	eb 1c                	jmp    f0100af8 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100adc:	c7 44 24 08 5a 1e 10 	movl   $0xf0101e5a,0x8(%esp)
f0100ae3:	f0 
f0100ae4:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100aeb:	00 
f0100aec:	c7 04 24 67 1e 10 f0 	movl   $0xf0101e67,(%esp)
f0100af3:	e8 00 f6 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100af8:	80 3d 87 72 10 f0 00 	cmpb   $0x0,0xf0107287
f0100aff:	0f 85 47 01 00 00    	jne    f0100c4c <debuginfo_eip+0x1be>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b05:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b0c:	b8 a0 59 10 f0       	mov    $0xf01059a0,%eax
f0100b11:	2d 88 20 10 f0       	sub    $0xf0102088,%eax
f0100b16:	c1 f8 02             	sar    $0x2,%eax
f0100b19:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b1f:	83 e8 01             	sub    $0x1,%eax
f0100b22:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b25:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b29:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b30:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b33:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b36:	b8 88 20 10 f0       	mov    $0xf0102088,%eax
f0100b3b:	e8 71 fe ff ff       	call   f01009b1 <stab_binsearch>
	if (lfile == 0)
f0100b40:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b43:	85 c0                	test   %eax,%eax
f0100b45:	0f 84 08 01 00 00    	je     f0100c53 <debuginfo_eip+0x1c5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b4b:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b51:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b54:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b58:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b5f:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b62:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b65:	b8 88 20 10 f0       	mov    $0xf0102088,%eax
f0100b6a:	e8 42 fe ff ff       	call   f01009b1 <stab_binsearch>

	if (lfun <= rfun) {
f0100b6f:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100b72:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100b75:	7f 2e                	jg     f0100ba5 <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b77:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b7a:	8d 90 88 20 10 f0    	lea    -0xfefdf78(%eax),%edx
f0100b80:	8b 80 88 20 10 f0    	mov    -0xfefdf78(%eax),%eax
f0100b86:	b9 88 72 10 f0       	mov    $0xf0107288,%ecx
f0100b8b:	81 e9 a1 59 10 f0    	sub    $0xf01059a1,%ecx
f0100b91:	39 c8                	cmp    %ecx,%eax
f0100b93:	73 08                	jae    f0100b9d <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b95:	05 a1 59 10 f0       	add    $0xf01059a1,%eax
f0100b9a:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b9d:	8b 42 08             	mov    0x8(%edx),%eax
f0100ba0:	89 43 10             	mov    %eax,0x10(%ebx)
f0100ba3:	eb 06                	jmp    f0100bab <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100ba5:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100ba8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bab:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100bb2:	00 
f0100bb3:	8b 43 08             	mov    0x8(%ebx),%eax
f0100bb6:	89 04 24             	mov    %eax,(%esp)
f0100bb9:	e8 bd 08 00 00       	call   f010147b <strfind>
f0100bbe:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bc1:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bc4:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100bc7:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100bca:	05 88 20 10 f0       	add    $0xf0102088,%eax
f0100bcf:	eb 06                	jmp    f0100bd7 <debuginfo_eip+0x149>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100bd1:	83 ef 01             	sub    $0x1,%edi
f0100bd4:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bd7:	39 cf                	cmp    %ecx,%edi
f0100bd9:	7c 33                	jl     f0100c0e <debuginfo_eip+0x180>
	       && stabs[lline].n_type != N_SOL
f0100bdb:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100bdf:	80 fa 84             	cmp    $0x84,%dl
f0100be2:	74 0b                	je     f0100bef <debuginfo_eip+0x161>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100be4:	80 fa 64             	cmp    $0x64,%dl
f0100be7:	75 e8                	jne    f0100bd1 <debuginfo_eip+0x143>
f0100be9:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100bed:	74 e2                	je     f0100bd1 <debuginfo_eip+0x143>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100bef:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100bf2:	8b 87 88 20 10 f0    	mov    -0xfefdf78(%edi),%eax
f0100bf8:	ba 88 72 10 f0       	mov    $0xf0107288,%edx
f0100bfd:	81 ea a1 59 10 f0    	sub    $0xf01059a1,%edx
f0100c03:	39 d0                	cmp    %edx,%eax
f0100c05:	73 07                	jae    f0100c0e <debuginfo_eip+0x180>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c07:	05 a1 59 10 f0       	add    $0xf01059a1,%eax
f0100c0c:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c0e:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100c11:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c14:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c19:	39 f1                	cmp    %esi,%ecx
f0100c1b:	7d 42                	jge    f0100c5f <debuginfo_eip+0x1d1>
		for (lline = lfun + 1;
f0100c1d:	8d 51 01             	lea    0x1(%ecx),%edx
f0100c20:	6b c1 0c             	imul   $0xc,%ecx,%eax
f0100c23:	05 88 20 10 f0       	add    $0xf0102088,%eax
f0100c28:	eb 07                	jmp    f0100c31 <debuginfo_eip+0x1a3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c2a:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c2e:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c31:	39 f2                	cmp    %esi,%edx
f0100c33:	74 25                	je     f0100c5a <debuginfo_eip+0x1cc>
f0100c35:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c38:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100c3c:	74 ec                	je     f0100c2a <debuginfo_eip+0x19c>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c3e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c43:	eb 1a                	jmp    f0100c5f <debuginfo_eip+0x1d1>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c45:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c4a:	eb 13                	jmp    f0100c5f <debuginfo_eip+0x1d1>
f0100c4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c51:	eb 0c                	jmp    f0100c5f <debuginfo_eip+0x1d1>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c53:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c58:	eb 05                	jmp    f0100c5f <debuginfo_eip+0x1d1>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c5a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c5f:	83 c4 2c             	add    $0x2c,%esp
f0100c62:	5b                   	pop    %ebx
f0100c63:	5e                   	pop    %esi
f0100c64:	5f                   	pop    %edi
f0100c65:	5d                   	pop    %ebp
f0100c66:	c3                   	ret    
f0100c67:	66 90                	xchg   %ax,%ax
f0100c69:	66 90                	xchg   %ax,%ax
f0100c6b:	66 90                	xchg   %ax,%ax
f0100c6d:	66 90                	xchg   %ax,%ax
f0100c6f:	90                   	nop

f0100c70 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c70:	55                   	push   %ebp
f0100c71:	89 e5                	mov    %esp,%ebp
f0100c73:	57                   	push   %edi
f0100c74:	56                   	push   %esi
f0100c75:	53                   	push   %ebx
f0100c76:	83 ec 3c             	sub    $0x3c,%esp
f0100c79:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100c7c:	89 d7                	mov    %edx,%edi
f0100c7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c81:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100c84:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c87:	89 c3                	mov    %eax,%ebx
f0100c89:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100c8c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100c8f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c92:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100c97:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c9a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100c9d:	39 d9                	cmp    %ebx,%ecx
f0100c9f:	72 05                	jb     f0100ca6 <printnum+0x36>
f0100ca1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100ca4:	77 69                	ja     f0100d0f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ca6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100ca9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100cad:	83 ee 01             	sub    $0x1,%esi
f0100cb0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100cb4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cb8:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100cbc:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100cc0:	89 c3                	mov    %eax,%ebx
f0100cc2:	89 d6                	mov    %edx,%esi
f0100cc4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100cc7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100cca:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100cce:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100cd2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cd5:	89 04 24             	mov    %eax,(%esp)
f0100cd8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100cdb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cdf:	e8 bc 09 00 00       	call   f01016a0 <__udivdi3>
f0100ce4:	89 d9                	mov    %ebx,%ecx
f0100ce6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100cea:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100cee:	89 04 24             	mov    %eax,(%esp)
f0100cf1:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100cf5:	89 fa                	mov    %edi,%edx
f0100cf7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cfa:	e8 71 ff ff ff       	call   f0100c70 <printnum>
f0100cff:	eb 1b                	jmp    f0100d1c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d01:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d05:	8b 45 18             	mov    0x18(%ebp),%eax
f0100d08:	89 04 24             	mov    %eax,(%esp)
f0100d0b:	ff d3                	call   *%ebx
f0100d0d:	eb 03                	jmp    f0100d12 <printnum+0xa2>
f0100d0f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d12:	83 ee 01             	sub    $0x1,%esi
f0100d15:	85 f6                	test   %esi,%esi
f0100d17:	7f e8                	jg     f0100d01 <printnum+0x91>
f0100d19:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d1c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d20:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100d24:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100d27:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d2a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d2e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100d32:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d35:	89 04 24             	mov    %eax,(%esp)
f0100d38:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d3b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d3f:	e8 8c 0a 00 00       	call   f01017d0 <__umoddi3>
f0100d44:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d48:	0f be 80 75 1e 10 f0 	movsbl -0xfefe18b(%eax),%eax
f0100d4f:	89 04 24             	mov    %eax,(%esp)
f0100d52:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d55:	ff d0                	call   *%eax
}
f0100d57:	83 c4 3c             	add    $0x3c,%esp
f0100d5a:	5b                   	pop    %ebx
f0100d5b:	5e                   	pop    %esi
f0100d5c:	5f                   	pop    %edi
f0100d5d:	5d                   	pop    %ebp
f0100d5e:	c3                   	ret    

f0100d5f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d5f:	55                   	push   %ebp
f0100d60:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d62:	83 fa 01             	cmp    $0x1,%edx
f0100d65:	7e 0e                	jle    f0100d75 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d67:	8b 10                	mov    (%eax),%edx
f0100d69:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d6c:	89 08                	mov    %ecx,(%eax)
f0100d6e:	8b 02                	mov    (%edx),%eax
f0100d70:	8b 52 04             	mov    0x4(%edx),%edx
f0100d73:	eb 22                	jmp    f0100d97 <getuint+0x38>
	else if (lflag)
f0100d75:	85 d2                	test   %edx,%edx
f0100d77:	74 10                	je     f0100d89 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d79:	8b 10                	mov    (%eax),%edx
f0100d7b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d7e:	89 08                	mov    %ecx,(%eax)
f0100d80:	8b 02                	mov    (%edx),%eax
f0100d82:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d87:	eb 0e                	jmp    f0100d97 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d89:	8b 10                	mov    (%eax),%edx
f0100d8b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d8e:	89 08                	mov    %ecx,(%eax)
f0100d90:	8b 02                	mov    (%edx),%eax
f0100d92:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d97:	5d                   	pop    %ebp
f0100d98:	c3                   	ret    

f0100d99 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d99:	55                   	push   %ebp
f0100d9a:	89 e5                	mov    %esp,%ebp
f0100d9c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d9f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100da3:	8b 10                	mov    (%eax),%edx
f0100da5:	3b 50 04             	cmp    0x4(%eax),%edx
f0100da8:	73 0a                	jae    f0100db4 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100daa:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100dad:	89 08                	mov    %ecx,(%eax)
f0100daf:	8b 45 08             	mov    0x8(%ebp),%eax
f0100db2:	88 02                	mov    %al,(%edx)
}
f0100db4:	5d                   	pop    %ebp
f0100db5:	c3                   	ret    

f0100db6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100db6:	55                   	push   %ebp
f0100db7:	89 e5                	mov    %esp,%ebp
f0100db9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100dbc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100dbf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100dc3:	8b 45 10             	mov    0x10(%ebp),%eax
f0100dc6:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dca:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100dcd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dd1:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dd4:	89 04 24             	mov    %eax,(%esp)
f0100dd7:	e8 02 00 00 00       	call   f0100dde <vprintfmt>
	va_end(ap);
}
f0100ddc:	c9                   	leave  
f0100ddd:	c3                   	ret    

f0100dde <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100dde:	55                   	push   %ebp
f0100ddf:	89 e5                	mov    %esp,%ebp
f0100de1:	57                   	push   %edi
f0100de2:	56                   	push   %esi
f0100de3:	53                   	push   %ebx
f0100de4:	83 ec 3c             	sub    $0x3c,%esp
f0100de7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100dea:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100ded:	eb 14                	jmp    f0100e03 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100def:	85 c0                	test   %eax,%eax
f0100df1:	0f 84 b3 03 00 00    	je     f01011aa <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0100df7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dfb:	89 04 24             	mov    %eax,(%esp)
f0100dfe:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e01:	89 f3                	mov    %esi,%ebx
f0100e03:	8d 73 01             	lea    0x1(%ebx),%esi
f0100e06:	0f b6 03             	movzbl (%ebx),%eax
f0100e09:	83 f8 25             	cmp    $0x25,%eax
f0100e0c:	75 e1                	jne    f0100def <vprintfmt+0x11>
f0100e0e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100e12:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100e19:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100e20:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100e27:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e2c:	eb 1d                	jmp    f0100e4b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e2e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e30:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100e34:	eb 15                	jmp    f0100e4b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e36:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e38:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100e3c:	eb 0d                	jmp    f0100e4b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100e3e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e41:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100e44:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e4b:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100e4e:	0f b6 0e             	movzbl (%esi),%ecx
f0100e51:	0f b6 c1             	movzbl %cl,%eax
f0100e54:	83 e9 23             	sub    $0x23,%ecx
f0100e57:	80 f9 55             	cmp    $0x55,%cl
f0100e5a:	0f 87 2a 03 00 00    	ja     f010118a <vprintfmt+0x3ac>
f0100e60:	0f b6 c9             	movzbl %cl,%ecx
f0100e63:	ff 24 8d 04 1f 10 f0 	jmp    *-0xfefe0fc(,%ecx,4)
f0100e6a:	89 de                	mov    %ebx,%esi
f0100e6c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e71:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100e74:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100e78:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100e7b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100e7e:	83 fb 09             	cmp    $0x9,%ebx
f0100e81:	77 36                	ja     f0100eb9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e83:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e86:	eb e9                	jmp    f0100e71 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e88:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e8b:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e8e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e91:	8b 00                	mov    (%eax),%eax
f0100e93:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e96:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e98:	eb 22                	jmp    f0100ebc <vprintfmt+0xde>
f0100e9a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100e9d:	85 c9                	test   %ecx,%ecx
f0100e9f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ea4:	0f 49 c1             	cmovns %ecx,%eax
f0100ea7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eaa:	89 de                	mov    %ebx,%esi
f0100eac:	eb 9d                	jmp    f0100e4b <vprintfmt+0x6d>
f0100eae:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100eb0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0100eb7:	eb 92                	jmp    f0100e4b <vprintfmt+0x6d>
f0100eb9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f0100ebc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100ec0:	79 89                	jns    f0100e4b <vprintfmt+0x6d>
f0100ec2:	e9 77 ff ff ff       	jmp    f0100e3e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100ec7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eca:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100ecc:	e9 7a ff ff ff       	jmp    f0100e4b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ed1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ed4:	8d 50 04             	lea    0x4(%eax),%edx
f0100ed7:	89 55 14             	mov    %edx,0x14(%ebp)
f0100eda:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ede:	8b 00                	mov    (%eax),%eax
f0100ee0:	89 04 24             	mov    %eax,(%esp)
f0100ee3:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100ee6:	e9 18 ff ff ff       	jmp    f0100e03 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100eeb:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eee:	8d 50 04             	lea    0x4(%eax),%edx
f0100ef1:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ef4:	8b 00                	mov    (%eax),%eax
f0100ef6:	99                   	cltd   
f0100ef7:	31 d0                	xor    %edx,%eax
f0100ef9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100efb:	83 f8 06             	cmp    $0x6,%eax
f0100efe:	7f 0b                	jg     f0100f0b <vprintfmt+0x12d>
f0100f00:	8b 14 85 5c 20 10 f0 	mov    -0xfefdfa4(,%eax,4),%edx
f0100f07:	85 d2                	test   %edx,%edx
f0100f09:	75 20                	jne    f0100f2b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f0100f0b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f0f:	c7 44 24 08 8d 1e 10 	movl   $0xf0101e8d,0x8(%esp)
f0100f16:	f0 
f0100f17:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f1b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f1e:	89 04 24             	mov    %eax,(%esp)
f0100f21:	e8 90 fe ff ff       	call   f0100db6 <printfmt>
f0100f26:	e9 d8 fe ff ff       	jmp    f0100e03 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0100f2b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100f2f:	c7 44 24 08 96 1e 10 	movl   $0xf0101e96,0x8(%esp)
f0100f36:	f0 
f0100f37:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f3b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f3e:	89 04 24             	mov    %eax,(%esp)
f0100f41:	e8 70 fe ff ff       	call   f0100db6 <printfmt>
f0100f46:	e9 b8 fe ff ff       	jmp    f0100e03 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f4b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100f4e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100f51:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f54:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f57:	8d 50 04             	lea    0x4(%eax),%edx
f0100f5a:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f5d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0100f5f:	85 f6                	test   %esi,%esi
f0100f61:	b8 86 1e 10 f0       	mov    $0xf0101e86,%eax
f0100f66:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0100f69:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0100f6d:	0f 84 97 00 00 00    	je     f010100a <vprintfmt+0x22c>
f0100f73:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0100f77:	0f 8e 9b 00 00 00    	jle    f0101018 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f7d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100f81:	89 34 24             	mov    %esi,(%esp)
f0100f84:	e8 9f 03 00 00       	call   f0101328 <strnlen>
f0100f89:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100f8c:	29 c2                	sub    %eax,%edx
f0100f8e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0100f91:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0100f95:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100f98:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0100f9b:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f9e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0100fa1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fa3:	eb 0f                	jmp    f0100fb4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0100fa5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fa9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100fac:	89 04 24             	mov    %eax,(%esp)
f0100faf:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fb1:	83 eb 01             	sub    $0x1,%ebx
f0100fb4:	85 db                	test   %ebx,%ebx
f0100fb6:	7f ed                	jg     f0100fa5 <vprintfmt+0x1c7>
f0100fb8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0100fbb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100fbe:	85 d2                	test   %edx,%edx
f0100fc0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fc5:	0f 49 c2             	cmovns %edx,%eax
f0100fc8:	29 c2                	sub    %eax,%edx
f0100fca:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0100fcd:	89 d7                	mov    %edx,%edi
f0100fcf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100fd2:	eb 50                	jmp    f0101024 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fd4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100fd8:	74 1e                	je     f0100ff8 <vprintfmt+0x21a>
f0100fda:	0f be d2             	movsbl %dl,%edx
f0100fdd:	83 ea 20             	sub    $0x20,%edx
f0100fe0:	83 fa 5e             	cmp    $0x5e,%edx
f0100fe3:	76 13                	jbe    f0100ff8 <vprintfmt+0x21a>
					putch('?', putdat);
f0100fe5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fe8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100fec:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100ff3:	ff 55 08             	call   *0x8(%ebp)
f0100ff6:	eb 0d                	jmp    f0101005 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0100ff8:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100ffb:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100fff:	89 04 24             	mov    %eax,(%esp)
f0101002:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101005:	83 ef 01             	sub    $0x1,%edi
f0101008:	eb 1a                	jmp    f0101024 <vprintfmt+0x246>
f010100a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010100d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0101010:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101013:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101016:	eb 0c                	jmp    f0101024 <vprintfmt+0x246>
f0101018:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010101b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010101e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101021:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101024:	83 c6 01             	add    $0x1,%esi
f0101027:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010102b:	0f be c2             	movsbl %dl,%eax
f010102e:	85 c0                	test   %eax,%eax
f0101030:	74 27                	je     f0101059 <vprintfmt+0x27b>
f0101032:	85 db                	test   %ebx,%ebx
f0101034:	78 9e                	js     f0100fd4 <vprintfmt+0x1f6>
f0101036:	83 eb 01             	sub    $0x1,%ebx
f0101039:	79 99                	jns    f0100fd4 <vprintfmt+0x1f6>
f010103b:	89 f8                	mov    %edi,%eax
f010103d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101040:	8b 75 08             	mov    0x8(%ebp),%esi
f0101043:	89 c3                	mov    %eax,%ebx
f0101045:	eb 1a                	jmp    f0101061 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101047:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010104b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101052:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101054:	83 eb 01             	sub    $0x1,%ebx
f0101057:	eb 08                	jmp    f0101061 <vprintfmt+0x283>
f0101059:	89 fb                	mov    %edi,%ebx
f010105b:	8b 75 08             	mov    0x8(%ebp),%esi
f010105e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101061:	85 db                	test   %ebx,%ebx
f0101063:	7f e2                	jg     f0101047 <vprintfmt+0x269>
f0101065:	89 75 08             	mov    %esi,0x8(%ebp)
f0101068:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010106b:	e9 93 fd ff ff       	jmp    f0100e03 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101070:	83 fa 01             	cmp    $0x1,%edx
f0101073:	7e 16                	jle    f010108b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0101075:	8b 45 14             	mov    0x14(%ebp),%eax
f0101078:	8d 50 08             	lea    0x8(%eax),%edx
f010107b:	89 55 14             	mov    %edx,0x14(%ebp)
f010107e:	8b 50 04             	mov    0x4(%eax),%edx
f0101081:	8b 00                	mov    (%eax),%eax
f0101083:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101086:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101089:	eb 32                	jmp    f01010bd <vprintfmt+0x2df>
	else if (lflag)
f010108b:	85 d2                	test   %edx,%edx
f010108d:	74 18                	je     f01010a7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010108f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101092:	8d 50 04             	lea    0x4(%eax),%edx
f0101095:	89 55 14             	mov    %edx,0x14(%ebp)
f0101098:	8b 30                	mov    (%eax),%esi
f010109a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010109d:	89 f0                	mov    %esi,%eax
f010109f:	c1 f8 1f             	sar    $0x1f,%eax
f01010a2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01010a5:	eb 16                	jmp    f01010bd <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f01010a7:	8b 45 14             	mov    0x14(%ebp),%eax
f01010aa:	8d 50 04             	lea    0x4(%eax),%edx
f01010ad:	89 55 14             	mov    %edx,0x14(%ebp)
f01010b0:	8b 30                	mov    (%eax),%esi
f01010b2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01010b5:	89 f0                	mov    %esi,%eax
f01010b7:	c1 f8 1f             	sar    $0x1f,%eax
f01010ba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01010bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010c0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01010c3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01010c8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01010cc:	0f 89 80 00 00 00    	jns    f0101152 <vprintfmt+0x374>
				putch('-', putdat);
f01010d2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010d6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01010dd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01010e0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010e3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01010e6:	f7 d8                	neg    %eax
f01010e8:	83 d2 00             	adc    $0x0,%edx
f01010eb:	f7 da                	neg    %edx
			}
			base = 10;
f01010ed:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01010f2:	eb 5e                	jmp    f0101152 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01010f4:	8d 45 14             	lea    0x14(%ebp),%eax
f01010f7:	e8 63 fc ff ff       	call   f0100d5f <getuint>
			base = 10;
f01010fc:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101101:	eb 4f                	jmp    f0101152 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101103:	8d 45 14             	lea    0x14(%ebp),%eax
f0101106:	e8 54 fc ff ff       	call   f0100d5f <getuint>
			base = 8;
f010110b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101110:	eb 40                	jmp    f0101152 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f0101112:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101116:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010111d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101120:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101124:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010112b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010112e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101131:	8d 50 04             	lea    0x4(%eax),%edx
f0101134:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101137:	8b 00                	mov    (%eax),%eax
f0101139:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010113e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101143:	eb 0d                	jmp    f0101152 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101145:	8d 45 14             	lea    0x14(%ebp),%eax
f0101148:	e8 12 fc ff ff       	call   f0100d5f <getuint>
			base = 16;
f010114d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101152:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0101156:	89 74 24 10          	mov    %esi,0x10(%esp)
f010115a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010115d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101161:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101165:	89 04 24             	mov    %eax,(%esp)
f0101168:	89 54 24 04          	mov    %edx,0x4(%esp)
f010116c:	89 fa                	mov    %edi,%edx
f010116e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101171:	e8 fa fa ff ff       	call   f0100c70 <printnum>
			break;
f0101176:	e9 88 fc ff ff       	jmp    f0100e03 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010117b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010117f:	89 04 24             	mov    %eax,(%esp)
f0101182:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101185:	e9 79 fc ff ff       	jmp    f0100e03 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010118a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010118e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101195:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101198:	89 f3                	mov    %esi,%ebx
f010119a:	eb 03                	jmp    f010119f <vprintfmt+0x3c1>
f010119c:	83 eb 01             	sub    $0x1,%ebx
f010119f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01011a3:	75 f7                	jne    f010119c <vprintfmt+0x3be>
f01011a5:	e9 59 fc ff ff       	jmp    f0100e03 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01011aa:	83 c4 3c             	add    $0x3c,%esp
f01011ad:	5b                   	pop    %ebx
f01011ae:	5e                   	pop    %esi
f01011af:	5f                   	pop    %edi
f01011b0:	5d                   	pop    %ebp
f01011b1:	c3                   	ret    

f01011b2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011b2:	55                   	push   %ebp
f01011b3:	89 e5                	mov    %esp,%ebp
f01011b5:	83 ec 28             	sub    $0x28,%esp
f01011b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01011bb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011be:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011c1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011c5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011c8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011cf:	85 c0                	test   %eax,%eax
f01011d1:	74 30                	je     f0101203 <vsnprintf+0x51>
f01011d3:	85 d2                	test   %edx,%edx
f01011d5:	7e 2c                	jle    f0101203 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01011da:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011de:	8b 45 10             	mov    0x10(%ebp),%eax
f01011e1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011e5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011ec:	c7 04 24 99 0d 10 f0 	movl   $0xf0100d99,(%esp)
f01011f3:	e8 e6 fb ff ff       	call   f0100dde <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011f8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011fb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101201:	eb 05                	jmp    f0101208 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101203:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101208:	c9                   	leave  
f0101209:	c3                   	ret    

f010120a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010120a:	55                   	push   %ebp
f010120b:	89 e5                	mov    %esp,%ebp
f010120d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101210:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101213:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101217:	8b 45 10             	mov    0x10(%ebp),%eax
f010121a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010121e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101221:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101225:	8b 45 08             	mov    0x8(%ebp),%eax
f0101228:	89 04 24             	mov    %eax,(%esp)
f010122b:	e8 82 ff ff ff       	call   f01011b2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101230:	c9                   	leave  
f0101231:	c3                   	ret    
f0101232:	66 90                	xchg   %ax,%ax
f0101234:	66 90                	xchg   %ax,%ax
f0101236:	66 90                	xchg   %ax,%ax
f0101238:	66 90                	xchg   %ax,%ax
f010123a:	66 90                	xchg   %ax,%ax
f010123c:	66 90                	xchg   %ax,%ax
f010123e:	66 90                	xchg   %ax,%ax

f0101240 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101240:	55                   	push   %ebp
f0101241:	89 e5                	mov    %esp,%ebp
f0101243:	57                   	push   %edi
f0101244:	56                   	push   %esi
f0101245:	53                   	push   %ebx
f0101246:	83 ec 1c             	sub    $0x1c,%esp
f0101249:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010124c:	85 c0                	test   %eax,%eax
f010124e:	74 10                	je     f0101260 <readline+0x20>
		cprintf("%s", prompt);
f0101250:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101254:	c7 04 24 96 1e 10 f0 	movl   $0xf0101e96,(%esp)
f010125b:	e8 37 f7 ff ff       	call   f0100997 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101260:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101267:	e8 16 f4 ff ff       	call   f0100682 <iscons>
f010126c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010126e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101273:	e8 f9 f3 ff ff       	call   f0100671 <getchar>
f0101278:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010127a:	85 c0                	test   %eax,%eax
f010127c:	79 17                	jns    f0101295 <readline+0x55>
			cprintf("read error: %e\n", c);
f010127e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101282:	c7 04 24 78 20 10 f0 	movl   $0xf0102078,(%esp)
f0101289:	e8 09 f7 ff ff       	call   f0100997 <cprintf>
			return NULL;
f010128e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101293:	eb 6d                	jmp    f0101302 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101295:	83 f8 7f             	cmp    $0x7f,%eax
f0101298:	74 05                	je     f010129f <readline+0x5f>
f010129a:	83 f8 08             	cmp    $0x8,%eax
f010129d:	75 19                	jne    f01012b8 <readline+0x78>
f010129f:	85 f6                	test   %esi,%esi
f01012a1:	7e 15                	jle    f01012b8 <readline+0x78>
			if (echoing)
f01012a3:	85 ff                	test   %edi,%edi
f01012a5:	74 0c                	je     f01012b3 <readline+0x73>
				cputchar('\b');
f01012a7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01012ae:	e8 ae f3 ff ff       	call   f0100661 <cputchar>
			i--;
f01012b3:	83 ee 01             	sub    $0x1,%esi
f01012b6:	eb bb                	jmp    f0101273 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012b8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012be:	7f 1c                	jg     f01012dc <readline+0x9c>
f01012c0:	83 fb 1f             	cmp    $0x1f,%ebx
f01012c3:	7e 17                	jle    f01012dc <readline+0x9c>
			if (echoing)
f01012c5:	85 ff                	test   %edi,%edi
f01012c7:	74 08                	je     f01012d1 <readline+0x91>
				cputchar(c);
f01012c9:	89 1c 24             	mov    %ebx,(%esp)
f01012cc:	e8 90 f3 ff ff       	call   f0100661 <cputchar>
			buf[i++] = c;
f01012d1:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01012d7:	8d 76 01             	lea    0x1(%esi),%esi
f01012da:	eb 97                	jmp    f0101273 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01012dc:	83 fb 0d             	cmp    $0xd,%ebx
f01012df:	74 05                	je     f01012e6 <readline+0xa6>
f01012e1:	83 fb 0a             	cmp    $0xa,%ebx
f01012e4:	75 8d                	jne    f0101273 <readline+0x33>
			if (echoing)
f01012e6:	85 ff                	test   %edi,%edi
f01012e8:	74 0c                	je     f01012f6 <readline+0xb6>
				cputchar('\n');
f01012ea:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01012f1:	e8 6b f3 ff ff       	call   f0100661 <cputchar>
			buf[i] = 0;
f01012f6:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01012fd:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101302:	83 c4 1c             	add    $0x1c,%esp
f0101305:	5b                   	pop    %ebx
f0101306:	5e                   	pop    %esi
f0101307:	5f                   	pop    %edi
f0101308:	5d                   	pop    %ebp
f0101309:	c3                   	ret    
f010130a:	66 90                	xchg   %ax,%ax
f010130c:	66 90                	xchg   %ax,%ax
f010130e:	66 90                	xchg   %ax,%ax

f0101310 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101310:	55                   	push   %ebp
f0101311:	89 e5                	mov    %esp,%ebp
f0101313:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101316:	b8 00 00 00 00       	mov    $0x0,%eax
f010131b:	eb 03                	jmp    f0101320 <strlen+0x10>
		n++;
f010131d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101320:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101324:	75 f7                	jne    f010131d <strlen+0xd>
		n++;
	return n;
}
f0101326:	5d                   	pop    %ebp
f0101327:	c3                   	ret    

f0101328 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101328:	55                   	push   %ebp
f0101329:	89 e5                	mov    %esp,%ebp
f010132b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010132e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101331:	b8 00 00 00 00       	mov    $0x0,%eax
f0101336:	eb 03                	jmp    f010133b <strnlen+0x13>
		n++;
f0101338:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010133b:	39 d0                	cmp    %edx,%eax
f010133d:	74 06                	je     f0101345 <strnlen+0x1d>
f010133f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101343:	75 f3                	jne    f0101338 <strnlen+0x10>
		n++;
	return n;
}
f0101345:	5d                   	pop    %ebp
f0101346:	c3                   	ret    

f0101347 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101347:	55                   	push   %ebp
f0101348:	89 e5                	mov    %esp,%ebp
f010134a:	53                   	push   %ebx
f010134b:	8b 45 08             	mov    0x8(%ebp),%eax
f010134e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101351:	89 c2                	mov    %eax,%edx
f0101353:	83 c2 01             	add    $0x1,%edx
f0101356:	83 c1 01             	add    $0x1,%ecx
f0101359:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010135d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101360:	84 db                	test   %bl,%bl
f0101362:	75 ef                	jne    f0101353 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101364:	5b                   	pop    %ebx
f0101365:	5d                   	pop    %ebp
f0101366:	c3                   	ret    

f0101367 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101367:	55                   	push   %ebp
f0101368:	89 e5                	mov    %esp,%ebp
f010136a:	53                   	push   %ebx
f010136b:	83 ec 08             	sub    $0x8,%esp
f010136e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101371:	89 1c 24             	mov    %ebx,(%esp)
f0101374:	e8 97 ff ff ff       	call   f0101310 <strlen>
	strcpy(dst + len, src);
f0101379:	8b 55 0c             	mov    0xc(%ebp),%edx
f010137c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101380:	01 d8                	add    %ebx,%eax
f0101382:	89 04 24             	mov    %eax,(%esp)
f0101385:	e8 bd ff ff ff       	call   f0101347 <strcpy>
	return dst;
}
f010138a:	89 d8                	mov    %ebx,%eax
f010138c:	83 c4 08             	add    $0x8,%esp
f010138f:	5b                   	pop    %ebx
f0101390:	5d                   	pop    %ebp
f0101391:	c3                   	ret    

f0101392 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101392:	55                   	push   %ebp
f0101393:	89 e5                	mov    %esp,%ebp
f0101395:	56                   	push   %esi
f0101396:	53                   	push   %ebx
f0101397:	8b 75 08             	mov    0x8(%ebp),%esi
f010139a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010139d:	89 f3                	mov    %esi,%ebx
f010139f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013a2:	89 f2                	mov    %esi,%edx
f01013a4:	eb 0f                	jmp    f01013b5 <strncpy+0x23>
		*dst++ = *src;
f01013a6:	83 c2 01             	add    $0x1,%edx
f01013a9:	0f b6 01             	movzbl (%ecx),%eax
f01013ac:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01013af:	80 39 01             	cmpb   $0x1,(%ecx)
f01013b2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013b5:	39 da                	cmp    %ebx,%edx
f01013b7:	75 ed                	jne    f01013a6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013b9:	89 f0                	mov    %esi,%eax
f01013bb:	5b                   	pop    %ebx
f01013bc:	5e                   	pop    %esi
f01013bd:	5d                   	pop    %ebp
f01013be:	c3                   	ret    

f01013bf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013bf:	55                   	push   %ebp
f01013c0:	89 e5                	mov    %esp,%ebp
f01013c2:	56                   	push   %esi
f01013c3:	53                   	push   %ebx
f01013c4:	8b 75 08             	mov    0x8(%ebp),%esi
f01013c7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013ca:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01013cd:	89 f0                	mov    %esi,%eax
f01013cf:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013d3:	85 c9                	test   %ecx,%ecx
f01013d5:	75 0b                	jne    f01013e2 <strlcpy+0x23>
f01013d7:	eb 1d                	jmp    f01013f6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013d9:	83 c0 01             	add    $0x1,%eax
f01013dc:	83 c2 01             	add    $0x1,%edx
f01013df:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013e2:	39 d8                	cmp    %ebx,%eax
f01013e4:	74 0b                	je     f01013f1 <strlcpy+0x32>
f01013e6:	0f b6 0a             	movzbl (%edx),%ecx
f01013e9:	84 c9                	test   %cl,%cl
f01013eb:	75 ec                	jne    f01013d9 <strlcpy+0x1a>
f01013ed:	89 c2                	mov    %eax,%edx
f01013ef:	eb 02                	jmp    f01013f3 <strlcpy+0x34>
f01013f1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01013f3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01013f6:	29 f0                	sub    %esi,%eax
}
f01013f8:	5b                   	pop    %ebx
f01013f9:	5e                   	pop    %esi
f01013fa:	5d                   	pop    %ebp
f01013fb:	c3                   	ret    

f01013fc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013fc:	55                   	push   %ebp
f01013fd:	89 e5                	mov    %esp,%ebp
f01013ff:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101402:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101405:	eb 06                	jmp    f010140d <strcmp+0x11>
		p++, q++;
f0101407:	83 c1 01             	add    $0x1,%ecx
f010140a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010140d:	0f b6 01             	movzbl (%ecx),%eax
f0101410:	84 c0                	test   %al,%al
f0101412:	74 04                	je     f0101418 <strcmp+0x1c>
f0101414:	3a 02                	cmp    (%edx),%al
f0101416:	74 ef                	je     f0101407 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101418:	0f b6 c0             	movzbl %al,%eax
f010141b:	0f b6 12             	movzbl (%edx),%edx
f010141e:	29 d0                	sub    %edx,%eax
}
f0101420:	5d                   	pop    %ebp
f0101421:	c3                   	ret    

f0101422 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101422:	55                   	push   %ebp
f0101423:	89 e5                	mov    %esp,%ebp
f0101425:	53                   	push   %ebx
f0101426:	8b 45 08             	mov    0x8(%ebp),%eax
f0101429:	8b 55 0c             	mov    0xc(%ebp),%edx
f010142c:	89 c3                	mov    %eax,%ebx
f010142e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101431:	eb 06                	jmp    f0101439 <strncmp+0x17>
		n--, p++, q++;
f0101433:	83 c0 01             	add    $0x1,%eax
f0101436:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101439:	39 d8                	cmp    %ebx,%eax
f010143b:	74 15                	je     f0101452 <strncmp+0x30>
f010143d:	0f b6 08             	movzbl (%eax),%ecx
f0101440:	84 c9                	test   %cl,%cl
f0101442:	74 04                	je     f0101448 <strncmp+0x26>
f0101444:	3a 0a                	cmp    (%edx),%cl
f0101446:	74 eb                	je     f0101433 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101448:	0f b6 00             	movzbl (%eax),%eax
f010144b:	0f b6 12             	movzbl (%edx),%edx
f010144e:	29 d0                	sub    %edx,%eax
f0101450:	eb 05                	jmp    f0101457 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101452:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101457:	5b                   	pop    %ebx
f0101458:	5d                   	pop    %ebp
f0101459:	c3                   	ret    

f010145a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010145a:	55                   	push   %ebp
f010145b:	89 e5                	mov    %esp,%ebp
f010145d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101460:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101464:	eb 07                	jmp    f010146d <strchr+0x13>
		if (*s == c)
f0101466:	38 ca                	cmp    %cl,%dl
f0101468:	74 0f                	je     f0101479 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010146a:	83 c0 01             	add    $0x1,%eax
f010146d:	0f b6 10             	movzbl (%eax),%edx
f0101470:	84 d2                	test   %dl,%dl
f0101472:	75 f2                	jne    f0101466 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101474:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101479:	5d                   	pop    %ebp
f010147a:	c3                   	ret    

f010147b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010147b:	55                   	push   %ebp
f010147c:	89 e5                	mov    %esp,%ebp
f010147e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101481:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101485:	eb 07                	jmp    f010148e <strfind+0x13>
		if (*s == c)
f0101487:	38 ca                	cmp    %cl,%dl
f0101489:	74 0a                	je     f0101495 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010148b:	83 c0 01             	add    $0x1,%eax
f010148e:	0f b6 10             	movzbl (%eax),%edx
f0101491:	84 d2                	test   %dl,%dl
f0101493:	75 f2                	jne    f0101487 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101495:	5d                   	pop    %ebp
f0101496:	c3                   	ret    

f0101497 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101497:	55                   	push   %ebp
f0101498:	89 e5                	mov    %esp,%ebp
f010149a:	57                   	push   %edi
f010149b:	56                   	push   %esi
f010149c:	53                   	push   %ebx
f010149d:	8b 7d 08             	mov    0x8(%ebp),%edi
f01014a0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01014a3:	85 c9                	test   %ecx,%ecx
f01014a5:	74 36                	je     f01014dd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01014a7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01014ad:	75 28                	jne    f01014d7 <memset+0x40>
f01014af:	f6 c1 03             	test   $0x3,%cl
f01014b2:	75 23                	jne    f01014d7 <memset+0x40>
		c &= 0xFF;
f01014b4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01014b8:	89 d3                	mov    %edx,%ebx
f01014ba:	c1 e3 08             	shl    $0x8,%ebx
f01014bd:	89 d6                	mov    %edx,%esi
f01014bf:	c1 e6 18             	shl    $0x18,%esi
f01014c2:	89 d0                	mov    %edx,%eax
f01014c4:	c1 e0 10             	shl    $0x10,%eax
f01014c7:	09 f0                	or     %esi,%eax
f01014c9:	09 c2                	or     %eax,%edx
f01014cb:	89 d0                	mov    %edx,%eax
f01014cd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01014cf:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01014d2:	fc                   	cld    
f01014d3:	f3 ab                	rep stos %eax,%es:(%edi)
f01014d5:	eb 06                	jmp    f01014dd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014d7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014da:	fc                   	cld    
f01014db:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014dd:	89 f8                	mov    %edi,%eax
f01014df:	5b                   	pop    %ebx
f01014e0:	5e                   	pop    %esi
f01014e1:	5f                   	pop    %edi
f01014e2:	5d                   	pop    %ebp
f01014e3:	c3                   	ret    

f01014e4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014e4:	55                   	push   %ebp
f01014e5:	89 e5                	mov    %esp,%ebp
f01014e7:	57                   	push   %edi
f01014e8:	56                   	push   %esi
f01014e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01014ec:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014ef:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014f2:	39 c6                	cmp    %eax,%esi
f01014f4:	73 35                	jae    f010152b <memmove+0x47>
f01014f6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014f9:	39 d0                	cmp    %edx,%eax
f01014fb:	73 2e                	jae    f010152b <memmove+0x47>
		s += n;
		d += n;
f01014fd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101500:	89 d6                	mov    %edx,%esi
f0101502:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101504:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010150a:	75 13                	jne    f010151f <memmove+0x3b>
f010150c:	f6 c1 03             	test   $0x3,%cl
f010150f:	75 0e                	jne    f010151f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101511:	83 ef 04             	sub    $0x4,%edi
f0101514:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101517:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010151a:	fd                   	std    
f010151b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010151d:	eb 09                	jmp    f0101528 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010151f:	83 ef 01             	sub    $0x1,%edi
f0101522:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101525:	fd                   	std    
f0101526:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101528:	fc                   	cld    
f0101529:	eb 1d                	jmp    f0101548 <memmove+0x64>
f010152b:	89 f2                	mov    %esi,%edx
f010152d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010152f:	f6 c2 03             	test   $0x3,%dl
f0101532:	75 0f                	jne    f0101543 <memmove+0x5f>
f0101534:	f6 c1 03             	test   $0x3,%cl
f0101537:	75 0a                	jne    f0101543 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101539:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010153c:	89 c7                	mov    %eax,%edi
f010153e:	fc                   	cld    
f010153f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101541:	eb 05                	jmp    f0101548 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101543:	89 c7                	mov    %eax,%edi
f0101545:	fc                   	cld    
f0101546:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101548:	5e                   	pop    %esi
f0101549:	5f                   	pop    %edi
f010154a:	5d                   	pop    %ebp
f010154b:	c3                   	ret    

f010154c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010154c:	55                   	push   %ebp
f010154d:	89 e5                	mov    %esp,%ebp
f010154f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101552:	8b 45 10             	mov    0x10(%ebp),%eax
f0101555:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101559:	8b 45 0c             	mov    0xc(%ebp),%eax
f010155c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101560:	8b 45 08             	mov    0x8(%ebp),%eax
f0101563:	89 04 24             	mov    %eax,(%esp)
f0101566:	e8 79 ff ff ff       	call   f01014e4 <memmove>
}
f010156b:	c9                   	leave  
f010156c:	c3                   	ret    

f010156d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010156d:	55                   	push   %ebp
f010156e:	89 e5                	mov    %esp,%ebp
f0101570:	56                   	push   %esi
f0101571:	53                   	push   %ebx
f0101572:	8b 55 08             	mov    0x8(%ebp),%edx
f0101575:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101578:	89 d6                	mov    %edx,%esi
f010157a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010157d:	eb 1a                	jmp    f0101599 <memcmp+0x2c>
		if (*s1 != *s2)
f010157f:	0f b6 02             	movzbl (%edx),%eax
f0101582:	0f b6 19             	movzbl (%ecx),%ebx
f0101585:	38 d8                	cmp    %bl,%al
f0101587:	74 0a                	je     f0101593 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101589:	0f b6 c0             	movzbl %al,%eax
f010158c:	0f b6 db             	movzbl %bl,%ebx
f010158f:	29 d8                	sub    %ebx,%eax
f0101591:	eb 0f                	jmp    f01015a2 <memcmp+0x35>
		s1++, s2++;
f0101593:	83 c2 01             	add    $0x1,%edx
f0101596:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101599:	39 f2                	cmp    %esi,%edx
f010159b:	75 e2                	jne    f010157f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010159d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015a2:	5b                   	pop    %ebx
f01015a3:	5e                   	pop    %esi
f01015a4:	5d                   	pop    %ebp
f01015a5:	c3                   	ret    

f01015a6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01015a6:	55                   	push   %ebp
f01015a7:	89 e5                	mov    %esp,%ebp
f01015a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01015ac:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01015af:	89 c2                	mov    %eax,%edx
f01015b1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01015b4:	eb 07                	jmp    f01015bd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01015b6:	38 08                	cmp    %cl,(%eax)
f01015b8:	74 07                	je     f01015c1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015ba:	83 c0 01             	add    $0x1,%eax
f01015bd:	39 d0                	cmp    %edx,%eax
f01015bf:	72 f5                	jb     f01015b6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01015c1:	5d                   	pop    %ebp
f01015c2:	c3                   	ret    

f01015c3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01015c3:	55                   	push   %ebp
f01015c4:	89 e5                	mov    %esp,%ebp
f01015c6:	57                   	push   %edi
f01015c7:	56                   	push   %esi
f01015c8:	53                   	push   %ebx
f01015c9:	8b 55 08             	mov    0x8(%ebp),%edx
f01015cc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015cf:	eb 03                	jmp    f01015d4 <strtol+0x11>
		s++;
f01015d1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015d4:	0f b6 0a             	movzbl (%edx),%ecx
f01015d7:	80 f9 09             	cmp    $0x9,%cl
f01015da:	74 f5                	je     f01015d1 <strtol+0xe>
f01015dc:	80 f9 20             	cmp    $0x20,%cl
f01015df:	74 f0                	je     f01015d1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01015e1:	80 f9 2b             	cmp    $0x2b,%cl
f01015e4:	75 0a                	jne    f01015f0 <strtol+0x2d>
		s++;
f01015e6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015e9:	bf 00 00 00 00       	mov    $0x0,%edi
f01015ee:	eb 11                	jmp    f0101601 <strtol+0x3e>
f01015f0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015f5:	80 f9 2d             	cmp    $0x2d,%cl
f01015f8:	75 07                	jne    f0101601 <strtol+0x3e>
		s++, neg = 1;
f01015fa:	8d 52 01             	lea    0x1(%edx),%edx
f01015fd:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101601:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101606:	75 15                	jne    f010161d <strtol+0x5a>
f0101608:	80 3a 30             	cmpb   $0x30,(%edx)
f010160b:	75 10                	jne    f010161d <strtol+0x5a>
f010160d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101611:	75 0a                	jne    f010161d <strtol+0x5a>
		s += 2, base = 16;
f0101613:	83 c2 02             	add    $0x2,%edx
f0101616:	b8 10 00 00 00       	mov    $0x10,%eax
f010161b:	eb 10                	jmp    f010162d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010161d:	85 c0                	test   %eax,%eax
f010161f:	75 0c                	jne    f010162d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101621:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101623:	80 3a 30             	cmpb   $0x30,(%edx)
f0101626:	75 05                	jne    f010162d <strtol+0x6a>
		s++, base = 8;
f0101628:	83 c2 01             	add    $0x1,%edx
f010162b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010162d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101632:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101635:	0f b6 0a             	movzbl (%edx),%ecx
f0101638:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010163b:	89 f0                	mov    %esi,%eax
f010163d:	3c 09                	cmp    $0x9,%al
f010163f:	77 08                	ja     f0101649 <strtol+0x86>
			dig = *s - '0';
f0101641:	0f be c9             	movsbl %cl,%ecx
f0101644:	83 e9 30             	sub    $0x30,%ecx
f0101647:	eb 20                	jmp    f0101669 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0101649:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010164c:	89 f0                	mov    %esi,%eax
f010164e:	3c 19                	cmp    $0x19,%al
f0101650:	77 08                	ja     f010165a <strtol+0x97>
			dig = *s - 'a' + 10;
f0101652:	0f be c9             	movsbl %cl,%ecx
f0101655:	83 e9 57             	sub    $0x57,%ecx
f0101658:	eb 0f                	jmp    f0101669 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010165a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010165d:	89 f0                	mov    %esi,%eax
f010165f:	3c 19                	cmp    $0x19,%al
f0101661:	77 16                	ja     f0101679 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0101663:	0f be c9             	movsbl %cl,%ecx
f0101666:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101669:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010166c:	7d 0f                	jge    f010167d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010166e:	83 c2 01             	add    $0x1,%edx
f0101671:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101675:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101677:	eb bc                	jmp    f0101635 <strtol+0x72>
f0101679:	89 d8                	mov    %ebx,%eax
f010167b:	eb 02                	jmp    f010167f <strtol+0xbc>
f010167d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010167f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101683:	74 05                	je     f010168a <strtol+0xc7>
		*endptr = (char *) s;
f0101685:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101688:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010168a:	f7 d8                	neg    %eax
f010168c:	85 ff                	test   %edi,%edi
f010168e:	0f 44 c3             	cmove  %ebx,%eax
}
f0101691:	5b                   	pop    %ebx
f0101692:	5e                   	pop    %esi
f0101693:	5f                   	pop    %edi
f0101694:	5d                   	pop    %ebp
f0101695:	c3                   	ret    
f0101696:	66 90                	xchg   %ax,%ax
f0101698:	66 90                	xchg   %ax,%ax
f010169a:	66 90                	xchg   %ax,%ax
f010169c:	66 90                	xchg   %ax,%ax
f010169e:	66 90                	xchg   %ax,%ax

f01016a0 <__udivdi3>:
f01016a0:	55                   	push   %ebp
f01016a1:	57                   	push   %edi
f01016a2:	56                   	push   %esi
f01016a3:	83 ec 0c             	sub    $0xc,%esp
f01016a6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01016aa:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01016ae:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01016b2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01016b6:	85 c0                	test   %eax,%eax
f01016b8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01016bc:	89 ea                	mov    %ebp,%edx
f01016be:	89 0c 24             	mov    %ecx,(%esp)
f01016c1:	75 2d                	jne    f01016f0 <__udivdi3+0x50>
f01016c3:	39 e9                	cmp    %ebp,%ecx
f01016c5:	77 61                	ja     f0101728 <__udivdi3+0x88>
f01016c7:	85 c9                	test   %ecx,%ecx
f01016c9:	89 ce                	mov    %ecx,%esi
f01016cb:	75 0b                	jne    f01016d8 <__udivdi3+0x38>
f01016cd:	b8 01 00 00 00       	mov    $0x1,%eax
f01016d2:	31 d2                	xor    %edx,%edx
f01016d4:	f7 f1                	div    %ecx
f01016d6:	89 c6                	mov    %eax,%esi
f01016d8:	31 d2                	xor    %edx,%edx
f01016da:	89 e8                	mov    %ebp,%eax
f01016dc:	f7 f6                	div    %esi
f01016de:	89 c5                	mov    %eax,%ebp
f01016e0:	89 f8                	mov    %edi,%eax
f01016e2:	f7 f6                	div    %esi
f01016e4:	89 ea                	mov    %ebp,%edx
f01016e6:	83 c4 0c             	add    $0xc,%esp
f01016e9:	5e                   	pop    %esi
f01016ea:	5f                   	pop    %edi
f01016eb:	5d                   	pop    %ebp
f01016ec:	c3                   	ret    
f01016ed:	8d 76 00             	lea    0x0(%esi),%esi
f01016f0:	39 e8                	cmp    %ebp,%eax
f01016f2:	77 24                	ja     f0101718 <__udivdi3+0x78>
f01016f4:	0f bd e8             	bsr    %eax,%ebp
f01016f7:	83 f5 1f             	xor    $0x1f,%ebp
f01016fa:	75 3c                	jne    f0101738 <__udivdi3+0x98>
f01016fc:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101700:	39 34 24             	cmp    %esi,(%esp)
f0101703:	0f 86 9f 00 00 00    	jbe    f01017a8 <__udivdi3+0x108>
f0101709:	39 d0                	cmp    %edx,%eax
f010170b:	0f 82 97 00 00 00    	jb     f01017a8 <__udivdi3+0x108>
f0101711:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101718:	31 d2                	xor    %edx,%edx
f010171a:	31 c0                	xor    %eax,%eax
f010171c:	83 c4 0c             	add    $0xc,%esp
f010171f:	5e                   	pop    %esi
f0101720:	5f                   	pop    %edi
f0101721:	5d                   	pop    %ebp
f0101722:	c3                   	ret    
f0101723:	90                   	nop
f0101724:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101728:	89 f8                	mov    %edi,%eax
f010172a:	f7 f1                	div    %ecx
f010172c:	31 d2                	xor    %edx,%edx
f010172e:	83 c4 0c             	add    $0xc,%esp
f0101731:	5e                   	pop    %esi
f0101732:	5f                   	pop    %edi
f0101733:	5d                   	pop    %ebp
f0101734:	c3                   	ret    
f0101735:	8d 76 00             	lea    0x0(%esi),%esi
f0101738:	89 e9                	mov    %ebp,%ecx
f010173a:	8b 3c 24             	mov    (%esp),%edi
f010173d:	d3 e0                	shl    %cl,%eax
f010173f:	89 c6                	mov    %eax,%esi
f0101741:	b8 20 00 00 00       	mov    $0x20,%eax
f0101746:	29 e8                	sub    %ebp,%eax
f0101748:	89 c1                	mov    %eax,%ecx
f010174a:	d3 ef                	shr    %cl,%edi
f010174c:	89 e9                	mov    %ebp,%ecx
f010174e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101752:	8b 3c 24             	mov    (%esp),%edi
f0101755:	09 74 24 08          	or     %esi,0x8(%esp)
f0101759:	89 d6                	mov    %edx,%esi
f010175b:	d3 e7                	shl    %cl,%edi
f010175d:	89 c1                	mov    %eax,%ecx
f010175f:	89 3c 24             	mov    %edi,(%esp)
f0101762:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101766:	d3 ee                	shr    %cl,%esi
f0101768:	89 e9                	mov    %ebp,%ecx
f010176a:	d3 e2                	shl    %cl,%edx
f010176c:	89 c1                	mov    %eax,%ecx
f010176e:	d3 ef                	shr    %cl,%edi
f0101770:	09 d7                	or     %edx,%edi
f0101772:	89 f2                	mov    %esi,%edx
f0101774:	89 f8                	mov    %edi,%eax
f0101776:	f7 74 24 08          	divl   0x8(%esp)
f010177a:	89 d6                	mov    %edx,%esi
f010177c:	89 c7                	mov    %eax,%edi
f010177e:	f7 24 24             	mull   (%esp)
f0101781:	39 d6                	cmp    %edx,%esi
f0101783:	89 14 24             	mov    %edx,(%esp)
f0101786:	72 30                	jb     f01017b8 <__udivdi3+0x118>
f0101788:	8b 54 24 04          	mov    0x4(%esp),%edx
f010178c:	89 e9                	mov    %ebp,%ecx
f010178e:	d3 e2                	shl    %cl,%edx
f0101790:	39 c2                	cmp    %eax,%edx
f0101792:	73 05                	jae    f0101799 <__udivdi3+0xf9>
f0101794:	3b 34 24             	cmp    (%esp),%esi
f0101797:	74 1f                	je     f01017b8 <__udivdi3+0x118>
f0101799:	89 f8                	mov    %edi,%eax
f010179b:	31 d2                	xor    %edx,%edx
f010179d:	e9 7a ff ff ff       	jmp    f010171c <__udivdi3+0x7c>
f01017a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01017a8:	31 d2                	xor    %edx,%edx
f01017aa:	b8 01 00 00 00       	mov    $0x1,%eax
f01017af:	e9 68 ff ff ff       	jmp    f010171c <__udivdi3+0x7c>
f01017b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017b8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01017bb:	31 d2                	xor    %edx,%edx
f01017bd:	83 c4 0c             	add    $0xc,%esp
f01017c0:	5e                   	pop    %esi
f01017c1:	5f                   	pop    %edi
f01017c2:	5d                   	pop    %ebp
f01017c3:	c3                   	ret    
f01017c4:	66 90                	xchg   %ax,%ax
f01017c6:	66 90                	xchg   %ax,%ax
f01017c8:	66 90                	xchg   %ax,%ax
f01017ca:	66 90                	xchg   %ax,%ax
f01017cc:	66 90                	xchg   %ax,%ax
f01017ce:	66 90                	xchg   %ax,%ax

f01017d0 <__umoddi3>:
f01017d0:	55                   	push   %ebp
f01017d1:	57                   	push   %edi
f01017d2:	56                   	push   %esi
f01017d3:	83 ec 14             	sub    $0x14,%esp
f01017d6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01017da:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01017de:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f01017e2:	89 c7                	mov    %eax,%edi
f01017e4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01017e8:	8b 44 24 30          	mov    0x30(%esp),%eax
f01017ec:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01017f0:	89 34 24             	mov    %esi,(%esp)
f01017f3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017f7:	85 c0                	test   %eax,%eax
f01017f9:	89 c2                	mov    %eax,%edx
f01017fb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01017ff:	75 17                	jne    f0101818 <__umoddi3+0x48>
f0101801:	39 fe                	cmp    %edi,%esi
f0101803:	76 4b                	jbe    f0101850 <__umoddi3+0x80>
f0101805:	89 c8                	mov    %ecx,%eax
f0101807:	89 fa                	mov    %edi,%edx
f0101809:	f7 f6                	div    %esi
f010180b:	89 d0                	mov    %edx,%eax
f010180d:	31 d2                	xor    %edx,%edx
f010180f:	83 c4 14             	add    $0x14,%esp
f0101812:	5e                   	pop    %esi
f0101813:	5f                   	pop    %edi
f0101814:	5d                   	pop    %ebp
f0101815:	c3                   	ret    
f0101816:	66 90                	xchg   %ax,%ax
f0101818:	39 f8                	cmp    %edi,%eax
f010181a:	77 54                	ja     f0101870 <__umoddi3+0xa0>
f010181c:	0f bd e8             	bsr    %eax,%ebp
f010181f:	83 f5 1f             	xor    $0x1f,%ebp
f0101822:	75 5c                	jne    f0101880 <__umoddi3+0xb0>
f0101824:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101828:	39 3c 24             	cmp    %edi,(%esp)
f010182b:	0f 87 e7 00 00 00    	ja     f0101918 <__umoddi3+0x148>
f0101831:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101835:	29 f1                	sub    %esi,%ecx
f0101837:	19 c7                	sbb    %eax,%edi
f0101839:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010183d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101841:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101845:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101849:	83 c4 14             	add    $0x14,%esp
f010184c:	5e                   	pop    %esi
f010184d:	5f                   	pop    %edi
f010184e:	5d                   	pop    %ebp
f010184f:	c3                   	ret    
f0101850:	85 f6                	test   %esi,%esi
f0101852:	89 f5                	mov    %esi,%ebp
f0101854:	75 0b                	jne    f0101861 <__umoddi3+0x91>
f0101856:	b8 01 00 00 00       	mov    $0x1,%eax
f010185b:	31 d2                	xor    %edx,%edx
f010185d:	f7 f6                	div    %esi
f010185f:	89 c5                	mov    %eax,%ebp
f0101861:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101865:	31 d2                	xor    %edx,%edx
f0101867:	f7 f5                	div    %ebp
f0101869:	89 c8                	mov    %ecx,%eax
f010186b:	f7 f5                	div    %ebp
f010186d:	eb 9c                	jmp    f010180b <__umoddi3+0x3b>
f010186f:	90                   	nop
f0101870:	89 c8                	mov    %ecx,%eax
f0101872:	89 fa                	mov    %edi,%edx
f0101874:	83 c4 14             	add    $0x14,%esp
f0101877:	5e                   	pop    %esi
f0101878:	5f                   	pop    %edi
f0101879:	5d                   	pop    %ebp
f010187a:	c3                   	ret    
f010187b:	90                   	nop
f010187c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101880:	8b 04 24             	mov    (%esp),%eax
f0101883:	be 20 00 00 00       	mov    $0x20,%esi
f0101888:	89 e9                	mov    %ebp,%ecx
f010188a:	29 ee                	sub    %ebp,%esi
f010188c:	d3 e2                	shl    %cl,%edx
f010188e:	89 f1                	mov    %esi,%ecx
f0101890:	d3 e8                	shr    %cl,%eax
f0101892:	89 e9                	mov    %ebp,%ecx
f0101894:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101898:	8b 04 24             	mov    (%esp),%eax
f010189b:	09 54 24 04          	or     %edx,0x4(%esp)
f010189f:	89 fa                	mov    %edi,%edx
f01018a1:	d3 e0                	shl    %cl,%eax
f01018a3:	89 f1                	mov    %esi,%ecx
f01018a5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01018a9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01018ad:	d3 ea                	shr    %cl,%edx
f01018af:	89 e9                	mov    %ebp,%ecx
f01018b1:	d3 e7                	shl    %cl,%edi
f01018b3:	89 f1                	mov    %esi,%ecx
f01018b5:	d3 e8                	shr    %cl,%eax
f01018b7:	89 e9                	mov    %ebp,%ecx
f01018b9:	09 f8                	or     %edi,%eax
f01018bb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01018bf:	f7 74 24 04          	divl   0x4(%esp)
f01018c3:	d3 e7                	shl    %cl,%edi
f01018c5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018c9:	89 d7                	mov    %edx,%edi
f01018cb:	f7 64 24 08          	mull   0x8(%esp)
f01018cf:	39 d7                	cmp    %edx,%edi
f01018d1:	89 c1                	mov    %eax,%ecx
f01018d3:	89 14 24             	mov    %edx,(%esp)
f01018d6:	72 2c                	jb     f0101904 <__umoddi3+0x134>
f01018d8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f01018dc:	72 22                	jb     f0101900 <__umoddi3+0x130>
f01018de:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01018e2:	29 c8                	sub    %ecx,%eax
f01018e4:	19 d7                	sbb    %edx,%edi
f01018e6:	89 e9                	mov    %ebp,%ecx
f01018e8:	89 fa                	mov    %edi,%edx
f01018ea:	d3 e8                	shr    %cl,%eax
f01018ec:	89 f1                	mov    %esi,%ecx
f01018ee:	d3 e2                	shl    %cl,%edx
f01018f0:	89 e9                	mov    %ebp,%ecx
f01018f2:	d3 ef                	shr    %cl,%edi
f01018f4:	09 d0                	or     %edx,%eax
f01018f6:	89 fa                	mov    %edi,%edx
f01018f8:	83 c4 14             	add    $0x14,%esp
f01018fb:	5e                   	pop    %esi
f01018fc:	5f                   	pop    %edi
f01018fd:	5d                   	pop    %ebp
f01018fe:	c3                   	ret    
f01018ff:	90                   	nop
f0101900:	39 d7                	cmp    %edx,%edi
f0101902:	75 da                	jne    f01018de <__umoddi3+0x10e>
f0101904:	8b 14 24             	mov    (%esp),%edx
f0101907:	89 c1                	mov    %eax,%ecx
f0101909:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010190d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101911:	eb cb                	jmp    f01018de <__umoddi3+0x10e>
f0101913:	90                   	nop
f0101914:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101918:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010191c:	0f 82 0f ff ff ff    	jb     f0101831 <__umoddi3+0x61>
f0101922:	e9 1a ff ff ff       	jmp    f0101841 <__umoddi3+0x71>
