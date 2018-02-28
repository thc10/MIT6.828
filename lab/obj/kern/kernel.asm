
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 79 11 f0       	mov    $0xf0117970,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 73 11 f0 	movl   $0xf0117300,(%esp)
f0100063:	e8 8f 38 00 00       	call   f01038f7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 a2 04 00 00       	call   f010050f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 a0 3d 10 f0 	movl   $0xf0103da0,(%esp)
f010007c:	e8 0f 2d 00 00       	call   f0102d90 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 64 11 00 00       	call   f01011ea <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 4e 07 00 00       	call   f01007e0 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 bb 3d 10 f0 	movl   $0xf0103dbb,(%esp)
f01000c8:	e8 c3 2c 00 00       	call   f0102d90 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 84 2c 00 00       	call   f0102d5d <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 f5 4c 10 f0 	movl   $0xf0104cf5,(%esp)
f01000e0:	e8 ab 2c 00 00       	call   f0102d90 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 ef 06 00 00       	call   f01007e0 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 d3 3d 10 f0 	movl   $0xf0103dd3,(%esp)
f0100112:	e8 79 2c 00 00       	call   f0102d90 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 37 2c 00 00       	call   f0102d5d <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 f5 4c 10 f0 	movl   $0xf0104cf5,(%esp)
f010012d:	e8 5e 2c 00 00       	call   f0102d90 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
f0100138:	66 90                	xchg   %ax,%ax
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100148:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100149:	a8 01                	test   $0x1,%al
f010014b:	74 08                	je     f0100155 <serial_proc_data+0x15>
f010014d:	b2 f8                	mov    $0xf8,%dl
f010014f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100150:	0f b6 c0             	movzbl %al,%eax
f0100153:	eb 05                	jmp    f010015a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100155:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010015a:	5d                   	pop    %ebp
f010015b:	c3                   	ret    

f010015c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010015c:	55                   	push   %ebp
f010015d:	89 e5                	mov    %esp,%ebp
f010015f:	53                   	push   %ebx
f0100160:	83 ec 04             	sub    $0x4,%esp
f0100163:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100165:	eb 2a                	jmp    f0100191 <cons_intr+0x35>
		if (c == 0)
f0100167:	85 d2                	test   %edx,%edx
f0100169:	74 26                	je     f0100191 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010016b:	a1 24 75 11 f0       	mov    0xf0117524,%eax
f0100170:	8d 48 01             	lea    0x1(%eax),%ecx
f0100173:	89 0d 24 75 11 f0    	mov    %ecx,0xf0117524
f0100179:	88 90 20 73 11 f0    	mov    %dl,-0xfee8ce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010017f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100185:	75 0a                	jne    f0100191 <cons_intr+0x35>
			cons.wpos = 0;
f0100187:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010018e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100191:	ff d3                	call   *%ebx
f0100193:	89 c2                	mov    %eax,%edx
f0100195:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100198:	75 cd                	jne    f0100167 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010019a:	83 c4 04             	add    $0x4,%esp
f010019d:	5b                   	pop    %ebx
f010019e:	5d                   	pop    %ebp
f010019f:	c3                   	ret    

f01001a0 <kbd_proc_data>:
f01001a0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001a5:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001a6:	a8 01                	test   $0x1,%al
f01001a8:	0f 84 f7 00 00 00    	je     f01002a5 <kbd_proc_data+0x105>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001ae:	a8 20                	test   $0x20,%al
f01001b0:	0f 85 f5 00 00 00    	jne    f01002ab <kbd_proc_data+0x10b>
f01001b6:	b2 60                	mov    $0x60,%dl
f01001b8:	ec                   	in     (%dx),%al
f01001b9:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001bb:	3c e0                	cmp    $0xe0,%al
f01001bd:	75 0d                	jne    f01001cc <kbd_proc_data+0x2c>
		// E0 escape character
		shift |= E0ESC;
f01001bf:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01001c6:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001cb:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001cc:	55                   	push   %ebp
f01001cd:	89 e5                	mov    %esp,%ebp
f01001cf:	53                   	push   %ebx
f01001d0:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001d3:	84 c0                	test   %al,%al
f01001d5:	79 37                	jns    f010020e <kbd_proc_data+0x6e>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001d7:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001dd:	89 cb                	mov    %ecx,%ebx
f01001df:	83 e3 40             	and    $0x40,%ebx
f01001e2:	83 e0 7f             	and    $0x7f,%eax
f01001e5:	85 db                	test   %ebx,%ebx
f01001e7:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001ea:	0f b6 d2             	movzbl %dl,%edx
f01001ed:	0f b6 82 40 3f 10 f0 	movzbl -0xfefc0c0(%edx),%eax
f01001f4:	83 c8 40             	or     $0x40,%eax
f01001f7:	0f b6 c0             	movzbl %al,%eax
f01001fa:	f7 d0                	not    %eax
f01001fc:	21 c1                	and    %eax,%ecx
f01001fe:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
		return 0;
f0100204:	b8 00 00 00 00       	mov    $0x0,%eax
f0100209:	e9 a3 00 00 00       	jmp    f01002b1 <kbd_proc_data+0x111>
	} else if (shift & E0ESC) {
f010020e:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f0100214:	f6 c1 40             	test   $0x40,%cl
f0100217:	74 0e                	je     f0100227 <kbd_proc_data+0x87>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100219:	83 c8 80             	or     $0xffffff80,%eax
f010021c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010021e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100221:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f0100227:	0f b6 d2             	movzbl %dl,%edx
f010022a:	0f b6 82 40 3f 10 f0 	movzbl -0xfefc0c0(%edx),%eax
f0100231:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
	shift ^= togglecode[data];
f0100237:	0f b6 8a 40 3e 10 f0 	movzbl -0xfefc1c0(%edx),%ecx
f010023e:	31 c8                	xor    %ecx,%eax
f0100240:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100245:	89 c1                	mov    %eax,%ecx
f0100247:	83 e1 03             	and    $0x3,%ecx
f010024a:	8b 0c 8d 20 3e 10 f0 	mov    -0xfefc1e0(,%ecx,4),%ecx
f0100251:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100255:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100258:	a8 08                	test   $0x8,%al
f010025a:	74 1b                	je     f0100277 <kbd_proc_data+0xd7>
		if ('a' <= c && c <= 'z')
f010025c:	89 da                	mov    %ebx,%edx
f010025e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100261:	83 f9 19             	cmp    $0x19,%ecx
f0100264:	77 05                	ja     f010026b <kbd_proc_data+0xcb>
			c += 'A' - 'a';
f0100266:	83 eb 20             	sub    $0x20,%ebx
f0100269:	eb 0c                	jmp    f0100277 <kbd_proc_data+0xd7>
		else if ('A' <= c && c <= 'Z')
f010026b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010026e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100271:	83 fa 19             	cmp    $0x19,%edx
f0100274:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100277:	f7 d0                	not    %eax
f0100279:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010027b:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010027d:	f6 c2 06             	test   $0x6,%dl
f0100280:	75 2f                	jne    f01002b1 <kbd_proc_data+0x111>
f0100282:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100288:	75 27                	jne    f01002b1 <kbd_proc_data+0x111>
		cprintf("Rebooting!\n");
f010028a:	c7 04 24 ed 3d 10 f0 	movl   $0xf0103ded,(%esp)
f0100291:	e8 fa 2a 00 00       	call   f0102d90 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100296:	ba 92 00 00 00       	mov    $0x92,%edx
f010029b:	b8 03 00 00 00       	mov    $0x3,%eax
f01002a0:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002a1:	89 d8                	mov    %ebx,%eax
f01002a3:	eb 0c                	jmp    f01002b1 <kbd_proc_data+0x111>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002a5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002aa:	c3                   	ret    
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002b0:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002b1:	83 c4 14             	add    $0x14,%esp
f01002b4:	5b                   	pop    %ebx
f01002b5:	5d                   	pop    %ebp
f01002b6:	c3                   	ret    

f01002b7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002b7:	55                   	push   %ebp
f01002b8:	89 e5                	mov    %esp,%ebp
f01002ba:	57                   	push   %edi
f01002bb:	56                   	push   %esi
f01002bc:	53                   	push   %ebx
f01002bd:	83 ec 1c             	sub    $0x1c,%esp
f01002c0:	89 c7                	mov    %eax,%edi
f01002c2:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002c7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002cc:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d1:	eb 06                	jmp    f01002d9 <cons_putc+0x22>
f01002d3:	89 ca                	mov    %ecx,%edx
f01002d5:	ec                   	in     (%dx),%al
f01002d6:	ec                   	in     (%dx),%al
f01002d7:	ec                   	in     (%dx),%al
f01002d8:	ec                   	in     (%dx),%al
f01002d9:	89 f2                	mov    %esi,%edx
f01002db:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002dc:	a8 20                	test   $0x20,%al
f01002de:	75 05                	jne    f01002e5 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002e0:	83 eb 01             	sub    $0x1,%ebx
f01002e3:	75 ee                	jne    f01002d3 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01002e5:	89 f8                	mov    %edi,%eax
f01002e7:	0f b6 c0             	movzbl %al,%eax
f01002ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ed:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002f2:	ee                   	out    %al,(%dx)
f01002f3:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f8:	be 79 03 00 00       	mov    $0x379,%esi
f01002fd:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100302:	eb 06                	jmp    f010030a <cons_putc+0x53>
f0100304:	89 ca                	mov    %ecx,%edx
f0100306:	ec                   	in     (%dx),%al
f0100307:	ec                   	in     (%dx),%al
f0100308:	ec                   	in     (%dx),%al
f0100309:	ec                   	in     (%dx),%al
f010030a:	89 f2                	mov    %esi,%edx
f010030c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010030d:	84 c0                	test   %al,%al
f010030f:	78 05                	js     f0100316 <cons_putc+0x5f>
f0100311:	83 eb 01             	sub    $0x1,%ebx
f0100314:	75 ee                	jne    f0100304 <cons_putc+0x4d>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100316:	ba 78 03 00 00       	mov    $0x378,%edx
f010031b:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010031f:	ee                   	out    %al,(%dx)
f0100320:	b2 7a                	mov    $0x7a,%dl
f0100322:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100327:	ee                   	out    %al,(%dx)
f0100328:	b8 08 00 00 00       	mov    $0x8,%eax
f010032d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010032e:	89 fa                	mov    %edi,%edx
f0100330:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100336:	89 f8                	mov    %edi,%eax
f0100338:	80 cc 07             	or     $0x7,%ah
f010033b:	85 d2                	test   %edx,%edx
f010033d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100340:	89 f8                	mov    %edi,%eax
f0100342:	0f b6 c0             	movzbl %al,%eax
f0100345:	83 f8 09             	cmp    $0x9,%eax
f0100348:	74 78                	je     f01003c2 <cons_putc+0x10b>
f010034a:	83 f8 09             	cmp    $0x9,%eax
f010034d:	7f 0a                	jg     f0100359 <cons_putc+0xa2>
f010034f:	83 f8 08             	cmp    $0x8,%eax
f0100352:	74 18                	je     f010036c <cons_putc+0xb5>
f0100354:	e9 9d 00 00 00       	jmp    f01003f6 <cons_putc+0x13f>
f0100359:	83 f8 0a             	cmp    $0xa,%eax
f010035c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100360:	74 3a                	je     f010039c <cons_putc+0xe5>
f0100362:	83 f8 0d             	cmp    $0xd,%eax
f0100365:	74 3d                	je     f01003a4 <cons_putc+0xed>
f0100367:	e9 8a 00 00 00       	jmp    f01003f6 <cons_putc+0x13f>
	case '\b':
		if (crt_pos > 0) {
f010036c:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100373:	66 85 c0             	test   %ax,%ax
f0100376:	0f 84 e5 00 00 00    	je     f0100461 <cons_putc+0x1aa>
			crt_pos--;
f010037c:	83 e8 01             	sub    $0x1,%eax
f010037f:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100385:	0f b7 c0             	movzwl %ax,%eax
f0100388:	66 81 e7 00 ff       	and    $0xff00,%di
f010038d:	83 cf 20             	or     $0x20,%edi
f0100390:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100396:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010039a:	eb 78                	jmp    f0100414 <cons_putc+0x15d>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010039c:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f01003a3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a4:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003ab:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003b1:	c1 e8 16             	shr    $0x16,%eax
f01003b4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b7:	c1 e0 04             	shl    $0x4,%eax
f01003ba:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f01003c0:	eb 52                	jmp    f0100414 <cons_putc+0x15d>
		break;
	case '\t':
		cons_putc(' ');
f01003c2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c7:	e8 eb fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003cc:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d1:	e8 e1 fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003d6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003db:	e8 d7 fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003e0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e5:	e8 cd fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003ea:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ef:	e8 c3 fe ff ff       	call   f01002b7 <cons_putc>
f01003f4:	eb 1e                	jmp    f0100414 <cons_putc+0x15d>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f6:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003fd:	8d 50 01             	lea    0x1(%eax),%edx
f0100400:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f0100407:	0f b7 c0             	movzwl %ax,%eax
f010040a:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100410:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100414:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f010041b:	cf 07 
f010041d:	76 42                	jbe    f0100461 <cons_putc+0x1aa>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041f:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f0100424:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010042b:	00 
f010042c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100432:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100436:	89 04 24             	mov    %eax,(%esp)
f0100439:	e8 06 35 00 00       	call   f0103944 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010043e:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100444:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100449:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010044f:	83 c0 01             	add    $0x1,%eax
f0100452:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100457:	75 f0                	jne    f0100449 <cons_putc+0x192>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100459:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100460:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100461:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100467:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046c:	89 ca                	mov    %ecx,%edx
f010046e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046f:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f0100476:	8d 71 01             	lea    0x1(%ecx),%esi
f0100479:	89 d8                	mov    %ebx,%eax
f010047b:	66 c1 e8 08          	shr    $0x8,%ax
f010047f:	89 f2                	mov    %esi,%edx
f0100481:	ee                   	out    %al,(%dx)
f0100482:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100487:	89 ca                	mov    %ecx,%edx
f0100489:	ee                   	out    %al,(%dx)
f010048a:	89 d8                	mov    %ebx,%eax
f010048c:	89 f2                	mov    %esi,%edx
f010048e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010048f:	83 c4 1c             	add    $0x1c,%esp
f0100492:	5b                   	pop    %ebx
f0100493:	5e                   	pop    %esi
f0100494:	5f                   	pop    %edi
f0100495:	5d                   	pop    %ebp
f0100496:	c3                   	ret    

f0100497 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100497:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f010049e:	74 11                	je     f01004b1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004a0:	55                   	push   %ebp
f01004a1:	89 e5                	mov    %esp,%ebp
f01004a3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004a6:	b8 40 01 10 f0       	mov    $0xf0100140,%eax
f01004ab:	e8 ac fc ff ff       	call   f010015c <cons_intr>
}
f01004b0:	c9                   	leave  
f01004b1:	f3 c3                	repz ret 

f01004b3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004b3:	55                   	push   %ebp
f01004b4:	89 e5                	mov    %esp,%ebp
f01004b6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004b9:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004be:	e8 99 fc ff ff       	call   f010015c <cons_intr>
}
f01004c3:	c9                   	leave  
f01004c4:	c3                   	ret    

f01004c5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004c5:	55                   	push   %ebp
f01004c6:	89 e5                	mov    %esp,%ebp
f01004c8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004cb:	e8 c7 ff ff ff       	call   f0100497 <serial_intr>
	kbd_intr();
f01004d0:	e8 de ff ff ff       	call   f01004b3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d5:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004da:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004e0:	74 26                	je     f0100508 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e2:	8d 50 01             	lea    0x1(%eax),%edx
f01004e5:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004eb:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004f2:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004f4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004fa:	75 11                	jne    f010050d <cons_getc+0x48>
			cons.rpos = 0;
f01004fc:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f0100503:	00 00 00 
f0100506:	eb 05                	jmp    f010050d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100508:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010050d:	c9                   	leave  
f010050e:	c3                   	ret    

f010050f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010050f:	55                   	push   %ebp
f0100510:	89 e5                	mov    %esp,%ebp
f0100512:	57                   	push   %edi
f0100513:	56                   	push   %esi
f0100514:	53                   	push   %ebx
f0100515:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100518:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010051f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100526:	5a a5 
	if (*cp != 0xA55A) {
f0100528:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010052f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100533:	74 11                	je     f0100546 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100535:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f010053c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010053f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100544:	eb 16                	jmp    f010055c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100546:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010054d:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f0100554:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100557:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010055c:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100562:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100567:	89 ca                	mov    %ecx,%edx
f0100569:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010056a:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056d:	89 da                	mov    %ebx,%edx
f010056f:	ec                   	in     (%dx),%al
f0100570:	0f b6 f0             	movzbl %al,%esi
f0100573:	c1 e6 08             	shl    $0x8,%esi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100576:	b8 0f 00 00 00       	mov    $0xf,%eax
f010057b:	89 ca                	mov    %ecx,%edx
f010057d:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057e:	89 da                	mov    %ebx,%edx
f0100580:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100581:	89 3d 2c 75 11 f0    	mov    %edi,0xf011752c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100587:	0f b6 d8             	movzbl %al,%ebx
f010058a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010058c:	66 89 35 28 75 11 f0 	mov    %si,0xf0117528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100593:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100598:	b8 00 00 00 00       	mov    $0x0,%eax
f010059d:	89 f2                	mov    %esi,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	b2 fb                	mov    $0xfb,%dl
f01005a2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005ad:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005b2:	89 da                	mov    %ebx,%edx
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	b2 f9                	mov    $0xf9,%dl
f01005b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	b2 fb                	mov    $0xfb,%dl
f01005bf:	b8 03 00 00 00       	mov    $0x3,%eax
f01005c4:	ee                   	out    %al,(%dx)
f01005c5:	b2 fc                	mov    $0xfc,%dl
f01005c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005cc:	ee                   	out    %al,(%dx)
f01005cd:	b2 f9                	mov    $0xf9,%dl
f01005cf:	b8 01 00 00 00       	mov    $0x1,%eax
f01005d4:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d5:	b2 fd                	mov    $0xfd,%dl
f01005d7:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d8:	3c ff                	cmp    $0xff,%al
f01005da:	0f 95 c1             	setne  %cl
f01005dd:	88 0d 34 75 11 f0    	mov    %cl,0xf0117534
f01005e3:	89 f2                	mov    %esi,%edx
f01005e5:	ec                   	in     (%dx),%al
f01005e6:	89 da                	mov    %ebx,%edx
f01005e8:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e9:	84 c9                	test   %cl,%cl
f01005eb:	75 0c                	jne    f01005f9 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005ed:	c7 04 24 f9 3d 10 f0 	movl   $0xf0103df9,(%esp)
f01005f4:	e8 97 27 00 00       	call   f0102d90 <cprintf>
}
f01005f9:	83 c4 1c             	add    $0x1c,%esp
f01005fc:	5b                   	pop    %ebx
f01005fd:	5e                   	pop    %esi
f01005fe:	5f                   	pop    %edi
f01005ff:	5d                   	pop    %ebp
f0100600:	c3                   	ret    

f0100601 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100601:	55                   	push   %ebp
f0100602:	89 e5                	mov    %esp,%ebp
f0100604:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100607:	8b 45 08             	mov    0x8(%ebp),%eax
f010060a:	e8 a8 fc ff ff       	call   f01002b7 <cons_putc>
}
f010060f:	c9                   	leave  
f0100610:	c3                   	ret    

f0100611 <getchar>:

int
getchar(void)
{
f0100611:	55                   	push   %ebp
f0100612:	89 e5                	mov    %esp,%ebp
f0100614:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100617:	e8 a9 fe ff ff       	call   f01004c5 <cons_getc>
f010061c:	85 c0                	test   %eax,%eax
f010061e:	74 f7                	je     f0100617 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100620:	c9                   	leave  
f0100621:	c3                   	ret    

f0100622 <iscons>:

int
iscons(int fdnum)
{
f0100622:	55                   	push   %ebp
f0100623:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100625:	b8 01 00 00 00       	mov    $0x1,%eax
f010062a:	5d                   	pop    %ebp
f010062b:	c3                   	ret    
f010062c:	66 90                	xchg   %ax,%ax
f010062e:	66 90                	xchg   %ax,%ax

f0100630 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100630:	55                   	push   %ebp
f0100631:	89 e5                	mov    %esp,%ebp
f0100633:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100636:	c7 44 24 08 40 40 10 	movl   $0xf0104040,0x8(%esp)
f010063d:	f0 
f010063e:	c7 44 24 04 5e 40 10 	movl   $0xf010405e,0x4(%esp)
f0100645:	f0 
f0100646:	c7 04 24 63 40 10 f0 	movl   $0xf0104063,(%esp)
f010064d:	e8 3e 27 00 00       	call   f0102d90 <cprintf>
f0100652:	c7 44 24 08 18 41 10 	movl   $0xf0104118,0x8(%esp)
f0100659:	f0 
f010065a:	c7 44 24 04 6c 40 10 	movl   $0xf010406c,0x4(%esp)
f0100661:	f0 
f0100662:	c7 04 24 63 40 10 f0 	movl   $0xf0104063,(%esp)
f0100669:	e8 22 27 00 00       	call   f0102d90 <cprintf>
	return 0;
}
f010066e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100673:	c9                   	leave  
f0100674:	c3                   	ret    

f0100675 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100675:	55                   	push   %ebp
f0100676:	89 e5                	mov    %esp,%ebp
f0100678:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010067b:	c7 04 24 75 40 10 f0 	movl   $0xf0104075,(%esp)
f0100682:	e8 09 27 00 00       	call   f0102d90 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100687:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010068e:	00 
f010068f:	c7 04 24 40 41 10 f0 	movl   $0xf0104140,(%esp)
f0100696:	e8 f5 26 00 00       	call   f0102d90 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069b:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006a2:	00 
f01006a3:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006aa:	f0 
f01006ab:	c7 04 24 68 41 10 f0 	movl   $0xf0104168,(%esp)
f01006b2:	e8 d9 26 00 00       	call   f0102d90 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b7:	c7 44 24 08 87 3d 10 	movl   $0x103d87,0x8(%esp)
f01006be:	00 
f01006bf:	c7 44 24 04 87 3d 10 	movl   $0xf0103d87,0x4(%esp)
f01006c6:	f0 
f01006c7:	c7 04 24 8c 41 10 f0 	movl   $0xf010418c,(%esp)
f01006ce:	e8 bd 26 00 00       	call   f0102d90 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006d3:	c7 44 24 08 00 73 11 	movl   $0x117300,0x8(%esp)
f01006da:	00 
f01006db:	c7 44 24 04 00 73 11 	movl   $0xf0117300,0x4(%esp)
f01006e2:	f0 
f01006e3:	c7 04 24 b0 41 10 f0 	movl   $0xf01041b0,(%esp)
f01006ea:	e8 a1 26 00 00       	call   f0102d90 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ef:	c7 44 24 08 70 79 11 	movl   $0x117970,0x8(%esp)
f01006f6:	00 
f01006f7:	c7 44 24 04 70 79 11 	movl   $0xf0117970,0x4(%esp)
f01006fe:	f0 
f01006ff:	c7 04 24 d4 41 10 f0 	movl   $0xf01041d4,(%esp)
f0100706:	e8 85 26 00 00       	call   f0102d90 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010070b:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
f0100710:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100715:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010071a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100720:	85 c0                	test   %eax,%eax
f0100722:	0f 48 c2             	cmovs  %edx,%eax
f0100725:	c1 f8 0a             	sar    $0xa,%eax
f0100728:	89 44 24 04          	mov    %eax,0x4(%esp)
f010072c:	c7 04 24 f8 41 10 f0 	movl   $0xf01041f8,(%esp)
f0100733:	e8 58 26 00 00       	call   f0102d90 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100738:	b8 00 00 00 00       	mov    $0x0,%eax
f010073d:	c9                   	leave  
f010073e:	c3                   	ret    

f010073f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010073f:	55                   	push   %ebp
f0100740:	89 e5                	mov    %esp,%ebp
f0100742:	57                   	push   %edi
f0100743:	56                   	push   %esi
f0100744:	53                   	push   %ebx
f0100745:	83 ec 4c             	sub    $0x4c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100748:	89 ee                	mov    %ebp,%esi
	// 每次压栈的顺序依次是：保存ebx、保存ebp、返回地址eip、五个参数
	uint32_t eip;
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f010074a:	c7 04 24 8e 40 10 f0 	movl   $0xf010408e,(%esp)
f0100751:	e8 3a 26 00 00       	call   f0102d90 <cprintf>
	while(ebp != 0){
f0100756:	eb 77                	jmp    f01007cf <mon_backtrace+0x90>
		eip = *((uint32_t *)ebp + 1);
f0100758:	8b 7e 04             	mov    0x4(%esi),%edi
		debuginfo_eip(eip, &info);
f010075b:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010075e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100762:	89 3c 24             	mov    %edi,(%esp)
f0100765:	e8 1d 27 00 00       	call   f0102e87 <debuginfo_eip>
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
f010076a:	89 7c 24 08          	mov    %edi,0x8(%esp)
f010076e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100772:	c7 04 24 a0 40 10 f0 	movl   $0xf01040a0,(%esp)
f0100779:	e8 12 26 00 00       	call   f0102d90 <cprintf>
		for(int i = 2; i < 7; i++){
f010077e:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x", *((uint32_t*)ebp + i));
f0100783:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f0100786:	89 44 24 04          	mov    %eax,0x4(%esp)
f010078a:	c7 04 24 bb 40 10 f0 	movl   $0xf01040bb,(%esp)
f0100791:	e8 fa 25 00 00       	call   f0102d90 <cprintf>
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
		eip = *((uint32_t *)ebp + 1);
		debuginfo_eip(eip, &info);
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
		for(int i = 2; i < 7; i++){
f0100796:	83 c3 01             	add    $0x1,%ebx
f0100799:	83 fb 07             	cmp    $0x7,%ebx
f010079c:	75 e5                	jne    f0100783 <mon_backtrace+0x44>
			cprintf(" %08x", *((uint32_t*)ebp + i));
		}
		cprintf("\n         %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
f010079e:	2b 7d e0             	sub    -0x20(%ebp),%edi
f01007a1:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01007a5:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007a8:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007ac:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007af:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007b3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007ba:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007c1:	c7 04 24 c1 40 10 f0 	movl   $0xf01040c1,(%esp)
f01007c8:	e8 c3 25 00 00       	call   f0102d90 <cprintf>
		ebp = *((uint32_t *)ebp);
f01007cd:	8b 36                	mov    (%esi),%esi
	// 每次压栈的顺序依次是：保存ebx、保存ebp、返回地址eip、五个参数
	uint32_t eip;
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f01007cf:	85 f6                	test   %esi,%esi
f01007d1:	75 85                	jne    f0100758 <mon_backtrace+0x19>
		}
		cprintf("\n         %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
		ebp = *((uint32_t *)ebp);
	}
	return 0;
}
f01007d3:	b8 00 00 00 00       	mov    $0x0,%eax
f01007d8:	83 c4 4c             	add    $0x4c,%esp
f01007db:	5b                   	pop    %ebx
f01007dc:	5e                   	pop    %esi
f01007dd:	5f                   	pop    %edi
f01007de:	5d                   	pop    %ebp
f01007df:	c3                   	ret    

f01007e0 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007e0:	55                   	push   %ebp
f01007e1:	89 e5                	mov    %esp,%ebp
f01007e3:	57                   	push   %edi
f01007e4:	56                   	push   %esi
f01007e5:	53                   	push   %ebx
f01007e6:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007e9:	c7 04 24 24 42 10 f0 	movl   $0xf0104224,(%esp)
f01007f0:	e8 9b 25 00 00       	call   f0102d90 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007f5:	c7 04 24 48 42 10 f0 	movl   $0xf0104248,(%esp)
f01007fc:	e8 8f 25 00 00       	call   f0102d90 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100801:	c7 04 24 db 40 10 f0 	movl   $0xf01040db,(%esp)
f0100808:	e8 93 2e 00 00       	call   f01036a0 <readline>
f010080d:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010080f:	85 c0                	test   %eax,%eax
f0100811:	74 ee                	je     f0100801 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100813:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010081a:	be 00 00 00 00       	mov    $0x0,%esi
f010081f:	eb 0a                	jmp    f010082b <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100821:	c6 03 00             	movb   $0x0,(%ebx)
f0100824:	89 f7                	mov    %esi,%edi
f0100826:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100829:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010082b:	0f b6 03             	movzbl (%ebx),%eax
f010082e:	84 c0                	test   %al,%al
f0100830:	74 63                	je     f0100895 <monitor+0xb5>
f0100832:	0f be c0             	movsbl %al,%eax
f0100835:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100839:	c7 04 24 df 40 10 f0 	movl   $0xf01040df,(%esp)
f0100840:	e8 75 30 00 00       	call   f01038ba <strchr>
f0100845:	85 c0                	test   %eax,%eax
f0100847:	75 d8                	jne    f0100821 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100849:	80 3b 00             	cmpb   $0x0,(%ebx)
f010084c:	74 47                	je     f0100895 <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010084e:	83 fe 0f             	cmp    $0xf,%esi
f0100851:	75 16                	jne    f0100869 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100853:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010085a:	00 
f010085b:	c7 04 24 e4 40 10 f0 	movl   $0xf01040e4,(%esp)
f0100862:	e8 29 25 00 00       	call   f0102d90 <cprintf>
f0100867:	eb 98                	jmp    f0100801 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100869:	8d 7e 01             	lea    0x1(%esi),%edi
f010086c:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100870:	eb 03                	jmp    f0100875 <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100872:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100875:	0f b6 03             	movzbl (%ebx),%eax
f0100878:	84 c0                	test   %al,%al
f010087a:	74 ad                	je     f0100829 <monitor+0x49>
f010087c:	0f be c0             	movsbl %al,%eax
f010087f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100883:	c7 04 24 df 40 10 f0 	movl   $0xf01040df,(%esp)
f010088a:	e8 2b 30 00 00       	call   f01038ba <strchr>
f010088f:	85 c0                	test   %eax,%eax
f0100891:	74 df                	je     f0100872 <monitor+0x92>
f0100893:	eb 94                	jmp    f0100829 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f0100895:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010089c:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010089d:	85 f6                	test   %esi,%esi
f010089f:	0f 84 5c ff ff ff    	je     f0100801 <monitor+0x21>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008a5:	c7 44 24 04 5e 40 10 	movl   $0xf010405e,0x4(%esp)
f01008ac:	f0 
f01008ad:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008b0:	89 04 24             	mov    %eax,(%esp)
f01008b3:	e8 a4 2f 00 00       	call   f010385c <strcmp>
f01008b8:	85 c0                	test   %eax,%eax
f01008ba:	74 1b                	je     f01008d7 <monitor+0xf7>
f01008bc:	c7 44 24 04 6c 40 10 	movl   $0xf010406c,0x4(%esp)
f01008c3:	f0 
f01008c4:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008c7:	89 04 24             	mov    %eax,(%esp)
f01008ca:	e8 8d 2f 00 00       	call   f010385c <strcmp>
f01008cf:	85 c0                	test   %eax,%eax
f01008d1:	75 2f                	jne    f0100902 <monitor+0x122>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008d3:	b0 01                	mov    $0x1,%al
f01008d5:	eb 05                	jmp    f01008dc <monitor+0xfc>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008d7:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008dc:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008df:	01 d0                	add    %edx,%eax
f01008e1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01008e4:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01008e8:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008eb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008ef:	89 34 24             	mov    %esi,(%esp)
f01008f2:	ff 14 85 78 42 10 f0 	call   *-0xfefbd88(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008f9:	85 c0                	test   %eax,%eax
f01008fb:	78 1d                	js     f010091a <monitor+0x13a>
f01008fd:	e9 ff fe ff ff       	jmp    f0100801 <monitor+0x21>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100902:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100905:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100909:	c7 04 24 01 41 10 f0 	movl   $0xf0104101,(%esp)
f0100910:	e8 7b 24 00 00       	call   f0102d90 <cprintf>
f0100915:	e9 e7 fe ff ff       	jmp    f0100801 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010091a:	83 c4 5c             	add    $0x5c,%esp
f010091d:	5b                   	pop    %ebx
f010091e:	5e                   	pop    %esi
f010091f:	5f                   	pop    %edi
f0100920:	5d                   	pop    %ebp
f0100921:	c3                   	ret    
f0100922:	66 90                	xchg   %ax,%ax
f0100924:	66 90                	xchg   %ax,%ax
f0100926:	66 90                	xchg   %ax,%ax
f0100928:	66 90                	xchg   %ax,%ax
f010092a:	66 90                	xchg   %ax,%ax
f010092c:	66 90                	xchg   %ax,%ax
f010092e:	66 90                	xchg   %ax,%ax

f0100930 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100930:	55                   	push   %ebp
f0100931:	89 e5                	mov    %esp,%ebp
f0100933:	56                   	push   %esi
f0100934:	53                   	push   %ebx
f0100935:	83 ec 10             	sub    $0x10,%esp
f0100938:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010093a:	89 04 24             	mov    %eax,(%esp)
f010093d:	e8 de 23 00 00       	call   f0102d20 <mc146818_read>
f0100942:	89 c6                	mov    %eax,%esi
f0100944:	83 c3 01             	add    $0x1,%ebx
f0100947:	89 1c 24             	mov    %ebx,(%esp)
f010094a:	e8 d1 23 00 00       	call   f0102d20 <mc146818_read>
f010094f:	c1 e0 08             	shl    $0x8,%eax
f0100952:	09 f0                	or     %esi,%eax
}
f0100954:	83 c4 10             	add    $0x10,%esp
f0100957:	5b                   	pop    %ebx
f0100958:	5e                   	pop    %esi
f0100959:	5d                   	pop    %ebp
f010095a:	c3                   	ret    

f010095b <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f010095b:	55                   	push   %ebp
f010095c:	89 e5                	mov    %esp,%ebp
f010095e:	83 ec 18             	sub    $0x18,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100961:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f0100968:	0f 85 8a 00 00 00    	jne    f01009f8 <boot_alloc+0x9d>
		extern char end[];	//end point to the end of segment bss
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010096e:	ba 6f 89 11 f0       	mov    $0xf011896f,%edx
f0100973:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100979:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0)
f010097f:	85 c0                	test   %eax,%eax
f0100981:	75 07                	jne    f010098a <boot_alloc+0x2f>
		return nextfree;
f0100983:	a1 38 75 11 f0       	mov    0xf0117538,%eax
f0100988:	eb 78                	jmp    f0100a02 <boot_alloc+0xa7>
	else if (n > 0){
		result = nextfree;
f010098a:	8b 15 38 75 11 f0    	mov    0xf0117538,%edx
		nextfree += n;
		nextfree = ROUNDUP((char *) nextfree, PGSIZE);
f0100990:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100997:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010099c:	a3 38 75 11 f0       	mov    %eax,0xf0117538
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009a1:	81 3d 64 79 11 f0 00 	cmpl   $0x400,0xf0117964
f01009a8:	04 00 00 
f01009ab:	77 24                	ja     f01009d1 <boot_alloc+0x76>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009ad:	c7 44 24 0c 00 00 40 	movl   $0x400000,0xc(%esp)
f01009b4:	00 
f01009b5:	c7 44 24 08 88 42 10 	movl   $0xf0104288,0x8(%esp)
f01009bc:	f0 
f01009bd:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
f01009c4:	00 
f01009c5:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01009cc:	e8 c3 f6 ff ff       	call   f0100094 <_panic>
		//nextfree should be less than the size of kernel virtual address: 4MB
		if(nextfree >= (char *)KADDR(0x400000))
f01009d1:	3d ff ff 3f f0       	cmp    $0xf03fffff,%eax
f01009d6:	76 1c                	jbe    f01009f4 <boot_alloc+0x99>
			panic("error: nextfree out of the size of kernel virtual address\n");
f01009d8:	c7 44 24 08 ac 42 10 	movl   $0xf01042ac,0x8(%esp)
f01009df:	f0 
f01009e0:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
f01009e7:	00 
f01009e8:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01009ef:	e8 a0 f6 ff ff       	call   f0100094 <_panic>
		return result;
f01009f4:	89 d0                	mov    %edx,%eax
f01009f6:	eb 0a                	jmp    f0100a02 <boot_alloc+0xa7>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0)
f01009f8:	85 c0                	test   %eax,%eax
f01009fa:	75 8e                	jne    f010098a <boot_alloc+0x2f>
f01009fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100a00:	eb 81                	jmp    f0100983 <boot_alloc+0x28>
		if(nextfree >= (char *)KADDR(0x400000))
			panic("error: nextfree out of the size of kernel virtual address\n");
		return result;
	}
	return NULL;
}
f0100a02:	c9                   	leave  
f0100a03:	c3                   	ret    

f0100a04 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a04:	89 d1                	mov    %edx,%ecx
f0100a06:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100a09:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a0c:	a8 01                	test   $0x1,%al
f0100a0e:	74 5d                	je     f0100a6d <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a10:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a15:	89 c1                	mov    %eax,%ecx
f0100a17:	c1 e9 0c             	shr    $0xc,%ecx
f0100a1a:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0100a20:	72 26                	jb     f0100a48 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a22:	55                   	push   %ebp
f0100a23:	89 e5                	mov    %esp,%ebp
f0100a25:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a28:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a2c:	c7 44 24 08 88 42 10 	movl   $0xf0104288,0x8(%esp)
f0100a33:	f0 
f0100a34:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
f0100a3b:	00 
f0100a3c:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0100a43:	e8 4c f6 ff ff       	call   f0100094 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a48:	c1 ea 0c             	shr    $0xc,%edx
f0100a4b:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a51:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a58:	89 c2                	mov    %eax,%edx
f0100a5a:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a5d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a62:	85 d2                	test   %edx,%edx
f0100a64:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a69:	0f 44 c2             	cmove  %edx,%eax
f0100a6c:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a6d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a72:	c3                   	ret    

f0100a73 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a73:	55                   	push   %ebp
f0100a74:	89 e5                	mov    %esp,%ebp
f0100a76:	57                   	push   %edi
f0100a77:	56                   	push   %esi
f0100a78:	53                   	push   %ebx
f0100a79:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a7c:	84 c0                	test   %al,%al
f0100a7e:	0f 85 07 03 00 00    	jne    f0100d8b <check_page_free_list+0x318>
f0100a84:	e9 14 03 00 00       	jmp    f0100d9d <check_page_free_list+0x32a>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a89:	c7 44 24 08 e8 42 10 	movl   $0xf01042e8,0x8(%esp)
f0100a90:	f0 
f0100a91:	c7 44 24 04 1f 02 00 	movl   $0x21f,0x4(%esp)
f0100a98:	00 
f0100a99:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0100aa0:	e8 ef f5 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100aa5:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100aa8:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100aab:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100aae:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ab1:	89 c2                	mov    %eax,%edx
f0100ab3:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ab9:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100abf:	0f 95 c2             	setne  %dl
f0100ac2:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ac5:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ac9:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100acb:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100acf:	8b 00                	mov    (%eax),%eax
f0100ad1:	85 c0                	test   %eax,%eax
f0100ad3:	75 dc                	jne    f0100ab1 <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100ad5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ad8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100ade:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ae1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ae4:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ae6:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ae9:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100aee:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100af3:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100af9:	eb 63                	jmp    f0100b5e <check_page_free_list+0xeb>
f0100afb:	89 d8                	mov    %ebx,%eax
f0100afd:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100b03:	c1 f8 03             	sar    $0x3,%eax
f0100b06:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b09:	89 c2                	mov    %eax,%edx
f0100b0b:	c1 ea 16             	shr    $0x16,%edx
f0100b0e:	39 f2                	cmp    %esi,%edx
f0100b10:	73 4a                	jae    f0100b5c <check_page_free_list+0xe9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b12:	89 c2                	mov    %eax,%edx
f0100b14:	c1 ea 0c             	shr    $0xc,%edx
f0100b17:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100b1d:	72 20                	jb     f0100b3f <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b1f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b23:	c7 44 24 08 88 42 10 	movl   $0xf0104288,0x8(%esp)
f0100b2a:	f0 
f0100b2b:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b32:	00 
f0100b33:	c7 04 24 50 4a 10 f0 	movl   $0xf0104a50,(%esp)
f0100b3a:	e8 55 f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b3f:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b46:	00 
f0100b47:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b4e:	00 
	return (void *)(pa + KERNBASE);
f0100b4f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b54:	89 04 24             	mov    %eax,(%esp)
f0100b57:	e8 9b 2d 00 00       	call   f01038f7 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b5c:	8b 1b                	mov    (%ebx),%ebx
f0100b5e:	85 db                	test   %ebx,%ebx
f0100b60:	75 99                	jne    f0100afb <check_page_free_list+0x88>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b62:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b67:	e8 ef fd ff ff       	call   f010095b <boot_alloc>
f0100b6c:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b6f:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b75:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
		assert(pp < pages + npages);
f0100b7b:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100b80:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100b83:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100b86:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b89:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b8c:	bf 00 00 00 00       	mov    $0x0,%edi
f0100b91:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b94:	e9 97 01 00 00       	jmp    f0100d30 <check_page_free_list+0x2bd>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b99:	39 ca                	cmp    %ecx,%edx
f0100b9b:	73 24                	jae    f0100bc1 <check_page_free_list+0x14e>
f0100b9d:	c7 44 24 0c 5e 4a 10 	movl   $0xf0104a5e,0xc(%esp)
f0100ba4:	f0 
f0100ba5:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0100bac:	f0 
f0100bad:	c7 44 24 04 39 02 00 	movl   $0x239,0x4(%esp)
f0100bb4:	00 
f0100bb5:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0100bbc:	e8 d3 f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100bc1:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bc4:	72 24                	jb     f0100bea <check_page_free_list+0x177>
f0100bc6:	c7 44 24 0c 7f 4a 10 	movl   $0xf0104a7f,0xc(%esp)
f0100bcd:	f0 
f0100bce:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0100bd5:	f0 
f0100bd6:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
f0100bdd:	00 
f0100bde:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0100be5:	e8 aa f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bea:	89 d0                	mov    %edx,%eax
f0100bec:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bef:	a8 07                	test   $0x7,%al
f0100bf1:	74 24                	je     f0100c17 <check_page_free_list+0x1a4>
f0100bf3:	c7 44 24 0c 0c 43 10 	movl   $0xf010430c,0xc(%esp)
f0100bfa:	f0 
f0100bfb:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0100c02:	f0 
f0100c03:	c7 44 24 04 3b 02 00 	movl   $0x23b,0x4(%esp)
f0100c0a:	00 
f0100c0b:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0100c12:	e8 7d f4 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c17:	c1 f8 03             	sar    $0x3,%eax
f0100c1a:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c1d:	85 c0                	test   %eax,%eax
f0100c1f:	75 24                	jne    f0100c45 <check_page_free_list+0x1d2>
f0100c21:	c7 44 24 0c 93 4a 10 	movl   $0xf0104a93,0xc(%esp)
f0100c28:	f0 
f0100c29:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0100c30:	f0 
f0100c31:	c7 44 24 04 3e 02 00 	movl   $0x23e,0x4(%esp)
f0100c38:	00 
f0100c39:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0100c40:	e8 4f f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c45:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c4a:	75 24                	jne    f0100c70 <check_page_free_list+0x1fd>
f0100c4c:	c7 44 24 0c a4 4a 10 	movl   $0xf0104aa4,0xc(%esp)
f0100c53:	f0 
f0100c54:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0100c5b:	f0 
f0100c5c:	c7 44 24 04 3f 02 00 	movl   $0x23f,0x4(%esp)
f0100c63:	00 
f0100c64:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0100c6b:	e8 24 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c70:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c75:	75 24                	jne    f0100c9b <check_page_free_list+0x228>
f0100c77:	c7 44 24 0c 40 43 10 	movl   $0xf0104340,0xc(%esp)
f0100c7e:	f0 
f0100c7f:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0100c86:	f0 
f0100c87:	c7 44 24 04 40 02 00 	movl   $0x240,0x4(%esp)
f0100c8e:	00 
f0100c8f:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0100c96:	e8 f9 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c9b:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100ca0:	75 24                	jne    f0100cc6 <check_page_free_list+0x253>
f0100ca2:	c7 44 24 0c bd 4a 10 	movl   $0xf0104abd,0xc(%esp)
f0100ca9:	f0 
f0100caa:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0100cb1:	f0 
f0100cb2:	c7 44 24 04 41 02 00 	movl   $0x241,0x4(%esp)
f0100cb9:	00 
f0100cba:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0100cc1:	e8 ce f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cc6:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100ccb:	76 58                	jbe    f0100d25 <check_page_free_list+0x2b2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ccd:	89 c3                	mov    %eax,%ebx
f0100ccf:	c1 eb 0c             	shr    $0xc,%ebx
f0100cd2:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100cd5:	77 20                	ja     f0100cf7 <check_page_free_list+0x284>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cd7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cdb:	c7 44 24 08 88 42 10 	movl   $0xf0104288,0x8(%esp)
f0100ce2:	f0 
f0100ce3:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100cea:	00 
f0100ceb:	c7 04 24 50 4a 10 f0 	movl   $0xf0104a50,(%esp)
f0100cf2:	e8 9d f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100cf7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cfc:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100cff:	76 2a                	jbe    f0100d2b <check_page_free_list+0x2b8>
f0100d01:	c7 44 24 0c 64 43 10 	movl   $0xf0104364,0xc(%esp)
f0100d08:	f0 
f0100d09:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0100d10:	f0 
f0100d11:	c7 44 24 04 42 02 00 	movl   $0x242,0x4(%esp)
f0100d18:	00 
f0100d19:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0100d20:	e8 6f f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d25:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100d29:	eb 03                	jmp    f0100d2e <check_page_free_list+0x2bb>
		else
			++nfree_extmem;
f0100d2b:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d2e:	8b 12                	mov    (%edx),%edx
f0100d30:	85 d2                	test   %edx,%edx
f0100d32:	0f 85 61 fe ff ff    	jne    f0100b99 <check_page_free_list+0x126>
f0100d38:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d3b:	85 db                	test   %ebx,%ebx
f0100d3d:	7f 24                	jg     f0100d63 <check_page_free_list+0x2f0>
f0100d3f:	c7 44 24 0c d7 4a 10 	movl   $0xf0104ad7,0xc(%esp)
f0100d46:	f0 
f0100d47:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0100d4e:	f0 
f0100d4f:	c7 44 24 04 4a 02 00 	movl   $0x24a,0x4(%esp)
f0100d56:	00 
f0100d57:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0100d5e:	e8 31 f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d63:	85 ff                	test   %edi,%edi
f0100d65:	7f 4d                	jg     f0100db4 <check_page_free_list+0x341>
f0100d67:	c7 44 24 0c e9 4a 10 	movl   $0xf0104ae9,0xc(%esp)
f0100d6e:	f0 
f0100d6f:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0100d76:	f0 
f0100d77:	c7 44 24 04 4b 02 00 	movl   $0x24b,0x4(%esp)
f0100d7e:	00 
f0100d7f:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0100d86:	e8 09 f3 ff ff       	call   f0100094 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d8b:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100d90:	85 c0                	test   %eax,%eax
f0100d92:	0f 85 0d fd ff ff    	jne    f0100aa5 <check_page_free_list+0x32>
f0100d98:	e9 ec fc ff ff       	jmp    f0100a89 <check_page_free_list+0x16>
f0100d9d:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100da4:	0f 84 df fc ff ff    	je     f0100a89 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100daa:	be 00 04 00 00       	mov    $0x400,%esi
f0100daf:	e9 3f fd ff ff       	jmp    f0100af3 <check_page_free_list+0x80>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100db4:	83 c4 4c             	add    $0x4c,%esp
f0100db7:	5b                   	pop    %ebx
f0100db8:	5e                   	pop    %esi
f0100db9:	5f                   	pop    %edi
f0100dba:	5d                   	pop    %ebp
f0100dbb:	c3                   	ret    

f0100dbc <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100dbc:	55                   	push   %ebp
f0100dbd:	89 e5                	mov    %esp,%ebp
f0100dbf:	56                   	push   %esi
f0100dc0:	53                   	push   %ebx
f0100dc1:	83 ec 10             	sub    $0x10,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100dc4:	be 00 00 00 00       	mov    $0x0,%esi
f0100dc9:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100dce:	e9 ef 00 00 00       	jmp    f0100ec2 <page_init+0x106>
		if (i == 0){
f0100dd3:	85 db                	test   %ebx,%ebx
f0100dd5:	75 16                	jne    f0100ded <page_init+0x31>
			//Mark physical page 0 as in use
			pages[i].pp_ref = 1;
f0100dd7:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100ddc:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;	//pp_link = NULL means this page has been alloced
f0100de2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100de8:	e9 cf 00 00 00       	jmp    f0100ebc <page_init+0x100>
		}else if (i >= 1 && i < npages_basemem){
f0100ded:	3b 1d 40 75 11 f0    	cmp    0xf0117540,%ebx
f0100df3:	73 28                	jae    f0100e1d <page_init+0x61>
			//The rest of base memory [PGSIZE, npages_basemen * PGSIZE]
			pages[i].pp_ref = 0;
f0100df5:	89 f0                	mov    %esi,%eax
f0100df7:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100dfd:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100e03:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100e09:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100e0b:	89 f0                	mov    %esi,%eax
f0100e0d:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100e13:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
f0100e18:	e9 9f 00 00 00       	jmp    f0100ebc <page_init+0x100>
f0100e1d:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
		}else if (i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE){
f0100e23:	83 f8 5f             	cmp    $0x5f,%eax
f0100e26:	77 16                	ja     f0100e3e <page_init+0x82>
			//The IO hole [IOPHYSMEM, EXTPHYSMEM)
			pages[i].pp_ref = 1;
f0100e28:	89 f0                	mov    %esi,%eax
f0100e2a:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100e30:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100e36:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100e3c:	eb 7e                	jmp    f0100ebc <page_init+0x100>
		}else if (i >= EXTPHYSMEM/PGSIZE && i < PADDR(boot_alloc(0))/PGSIZE){	//use PADDR() to change the kernel virtual addresss to physical address
f0100e3e:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100e44:	76 53                	jbe    f0100e99 <page_init+0xdd>
f0100e46:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e4b:	e8 0b fb ff ff       	call   f010095b <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100e50:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100e55:	77 20                	ja     f0100e77 <page_init+0xbb>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100e57:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e5b:	c7 44 24 08 ac 43 10 	movl   $0xf01043ac,0x8(%esp)
f0100e62:	f0 
f0100e63:	c7 44 24 04 18 01 00 	movl   $0x118,0x4(%esp)
f0100e6a:	00 
f0100e6b:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0100e72:	e8 1d f2 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100e77:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e7c:	c1 e8 0c             	shr    $0xc,%eax
f0100e7f:	39 c3                	cmp    %eax,%ebx
f0100e81:	73 16                	jae    f0100e99 <page_init+0xdd>
			//The extended memory [EXTPHYSMEM, ...)
			pages[i].pp_ref = 1;
f0100e83:	89 f0                	mov    %esi,%eax
f0100e85:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100e8b:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100e91:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100e97:	eb 23                	jmp    f0100ebc <page_init+0x100>
		}else{
			pages[i].pp_ref = 0;
f0100e99:	89 f0                	mov    %esi,%eax
f0100e9b:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100ea1:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100ea7:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100ead:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100eaf:	89 f0                	mov    %esi,%eax
f0100eb1:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100eb7:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100ebc:	83 c3 01             	add    $0x1,%ebx
f0100ebf:	83 c6 08             	add    $0x8,%esi
f0100ec2:	3b 1d 64 79 11 f0    	cmp    0xf0117964,%ebx
f0100ec8:	0f 82 05 ff ff ff    	jb     f0100dd3 <page_init+0x17>
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100ece:	83 c4 10             	add    $0x10,%esp
f0100ed1:	5b                   	pop    %ebx
f0100ed2:	5e                   	pop    %esi
f0100ed3:	5d                   	pop    %ebp
f0100ed4:	c3                   	ret    

f0100ed5 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100ed5:	55                   	push   %ebp
f0100ed6:	89 e5                	mov    %esp,%ebp
f0100ed8:	53                   	push   %ebx
f0100ed9:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if (page_free_list == NULL)	//out of free memory
f0100edc:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100ee2:	85 db                	test   %ebx,%ebx
f0100ee4:	74 6f                	je     f0100f55 <page_alloc+0x80>
		return NULL;

	struct PageInfo *page = page_free_list;
	page_free_list = page_free_list->pp_link;
f0100ee6:	8b 03                	mov    (%ebx),%eax
f0100ee8:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	page->pp_link = NULL;
f0100eed:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO)
		memset(page2kva(page), '\0', PGSIZE);	//page2kva():get kernel virtual address by pageNum 
	return page;
f0100ef3:	89 d8                	mov    %ebx,%eax
		return NULL;

	struct PageInfo *page = page_free_list;
	page_free_list = page_free_list->pp_link;
	page->pp_link = NULL;
	if (alloc_flags & ALLOC_ZERO)
f0100ef5:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ef9:	74 5f                	je     f0100f5a <page_alloc+0x85>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100efb:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100f01:	c1 f8 03             	sar    $0x3,%eax
f0100f04:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f07:	89 c2                	mov    %eax,%edx
f0100f09:	c1 ea 0c             	shr    $0xc,%edx
f0100f0c:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100f12:	72 20                	jb     f0100f34 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f14:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f18:	c7 44 24 08 88 42 10 	movl   $0xf0104288,0x8(%esp)
f0100f1f:	f0 
f0100f20:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100f27:	00 
f0100f28:	c7 04 24 50 4a 10 f0 	movl   $0xf0104a50,(%esp)
f0100f2f:	e8 60 f1 ff ff       	call   f0100094 <_panic>
		memset(page2kva(page), '\0', PGSIZE);	//page2kva():get kernel virtual address by pageNum 
f0100f34:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f3b:	00 
f0100f3c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f43:	00 
	return (void *)(pa + KERNBASE);
f0100f44:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f49:	89 04 24             	mov    %eax,(%esp)
f0100f4c:	e8 a6 29 00 00       	call   f01038f7 <memset>
	return page;
f0100f51:	89 d8                	mov    %ebx,%eax
f0100f53:	eb 05                	jmp    f0100f5a <page_alloc+0x85>
struct PageInfo *
page_alloc(int alloc_flags)
{
	// Fill this function in
	if (page_free_list == NULL)	//out of free memory
		return NULL;
f0100f55:	b8 00 00 00 00       	mov    $0x0,%eax
	page_free_list = page_free_list->pp_link;
	page->pp_link = NULL;
	if (alloc_flags & ALLOC_ZERO)
		memset(page2kva(page), '\0', PGSIZE);	//page2kva():get kernel virtual address by pageNum 
	return page;
}
f0100f5a:	83 c4 14             	add    $0x14,%esp
f0100f5d:	5b                   	pop    %ebx
f0100f5e:	5d                   	pop    %ebp
f0100f5f:	c3                   	ret    

f0100f60 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100f60:	55                   	push   %ebp
f0100f61:	89 e5                	mov    %esp,%ebp
f0100f63:	83 ec 18             	sub    $0x18,%esp
f0100f66:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref  != 0 || pp->pp_link != NULL){
f0100f69:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f6e:	75 05                	jne    f0100f75 <page_free+0x15>
f0100f70:	83 38 00             	cmpl   $0x0,(%eax)
f0100f73:	74 1c                	je     f0100f91 <page_free+0x31>
		panic("error(page_free):check before free a page\n");
f0100f75:	c7 44 24 08 d0 43 10 	movl   $0xf01043d0,0x8(%esp)
f0100f7c:	f0 
f0100f7d:	c7 44 24 04 4a 01 00 	movl   $0x14a,0x4(%esp)
f0100f84:	00 
f0100f85:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0100f8c:	e8 03 f1 ff ff       	call   f0100094 <_panic>
		return;
	}
	pp->pp_link = page_free_list;
f0100f91:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100f97:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f99:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	return;
}
f0100f9e:	c9                   	leave  
f0100f9f:	c3                   	ret    

f0100fa0 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100fa0:	55                   	push   %ebp
f0100fa1:	89 e5                	mov    %esp,%ebp
f0100fa3:	83 ec 18             	sub    $0x18,%esp
f0100fa6:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100fa9:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0100fad:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100fb0:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100fb4:	66 85 d2             	test   %dx,%dx
f0100fb7:	75 08                	jne    f0100fc1 <page_decref+0x21>
		page_free(pp);
f0100fb9:	89 04 24             	mov    %eax,(%esp)
f0100fbc:	e8 9f ff ff ff       	call   f0100f60 <page_free>
}
f0100fc1:	c9                   	leave  
f0100fc2:	c3                   	ret    

f0100fc3 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100fc3:	55                   	push   %ebp
f0100fc4:	89 e5                	mov    %esp,%ebp
f0100fc6:	56                   	push   %esi
f0100fc7:	53                   	push   %ebx
f0100fc8:	83 ec 10             	sub    $0x10,%esp
f0100fcb:	8b 45 0c             	mov    0xc(%ebp),%eax
	uint32_t page_dir_index = PDX(va);
	uint32_t page_table_index = PTX(va);
f0100fce:	89 c3                	mov    %eax,%ebx
f0100fd0:	c1 eb 0c             	shr    $0xc,%ebx
f0100fd3:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
	uint32_t page_dir_index = PDX(va);
f0100fd9:	c1 e8 16             	shr    $0x16,%eax
	uint32_t page_table_index = PTX(va);
	pte_t *page_tab;
	if (pgdir[page_dir_index] & PTE_P){		//test is exist or not
f0100fdc:	8d 34 85 00 00 00 00 	lea    0x0(,%eax,4),%esi
f0100fe3:	03 75 08             	add    0x8(%ebp),%esi
f0100fe6:	8b 16                	mov    (%esi),%edx
f0100fe8:	f6 c2 01             	test   $0x1,%dl
f0100feb:	74 3e                	je     f010102b <pgdir_walk+0x68>
		page_tab = KADDR(PTE_ADDR(pgdir[page_dir_index]));
f0100fed:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ff3:	89 d0                	mov    %edx,%eax
f0100ff5:	c1 e8 0c             	shr    $0xc,%eax
f0100ff8:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0100ffe:	72 20                	jb     f0101020 <pgdir_walk+0x5d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101000:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101004:	c7 44 24 08 88 42 10 	movl   $0xf0104288,0x8(%esp)
f010100b:	f0 
f010100c:	c7 44 24 04 7a 01 00 	movl   $0x17a,0x4(%esp)
f0101013:	00 
f0101014:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f010101b:	e8 74 f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101020:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101026:	e9 8d 00 00 00       	jmp    f01010b8 <pgdir_walk+0xf5>
	}else{
		if (create){
f010102b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010102f:	0f 84 88 00 00 00    	je     f01010bd <pgdir_walk+0xfa>
			struct PageInfo *newPage = page_alloc(ALLOC_ZERO);
f0101035:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010103c:	e8 94 fe ff ff       	call   f0100ed5 <page_alloc>
			if (!newPage)
f0101041:	85 c0                	test   %eax,%eax
f0101043:	74 7f                	je     f01010c4 <pgdir_walk+0x101>
				return NULL;
			newPage->pp_ref++;
f0101045:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010104a:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101050:	c1 f8 03             	sar    $0x3,%eax
f0101053:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101056:	89 c2                	mov    %eax,%edx
f0101058:	c1 ea 0c             	shr    $0xc,%edx
f010105b:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101061:	72 20                	jb     f0101083 <pgdir_walk+0xc0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101063:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101067:	c7 44 24 08 88 42 10 	movl   $0xf0104288,0x8(%esp)
f010106e:	f0 
f010106f:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101076:	00 
f0101077:	c7 04 24 50 4a 10 f0 	movl   $0xf0104a50,(%esp)
f010107e:	e8 11 f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101083:	8d 88 00 00 00 f0    	lea    -0x10000000(%eax),%ecx
f0101089:	89 ca                	mov    %ecx,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010108b:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0101091:	77 20                	ja     f01010b3 <pgdir_walk+0xf0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101093:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0101097:	c7 44 24 08 ac 43 10 	movl   $0xf01043ac,0x8(%esp)
f010109e:	f0 
f010109f:	c7 44 24 04 82 01 00 	movl   $0x182,0x4(%esp)
f01010a6:	00 
f01010a7:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01010ae:	e8 e1 ef ff ff       	call   f0100094 <_panic>
			page_tab = (pte_t *)page2kva(newPage);
			pgdir[page_dir_index] = PADDR(page_tab) | PTE_P | PTE_W | PTE_U;
f01010b3:	83 c8 07             	or     $0x7,%eax
f01010b6:	89 06                	mov    %eax,(%esi)
		}else{
			return NULL;
		}
	}
	return &page_tab[page_table_index];
f01010b8:	8d 04 9a             	lea    (%edx,%ebx,4),%eax
f01010bb:	eb 0c                	jmp    f01010c9 <pgdir_walk+0x106>
				return NULL;
			newPage->pp_ref++;
			page_tab = (pte_t *)page2kva(newPage);
			pgdir[page_dir_index] = PADDR(page_tab) | PTE_P | PTE_W | PTE_U;
		}else{
			return NULL;
f01010bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01010c2:	eb 05                	jmp    f01010c9 <pgdir_walk+0x106>
		page_tab = KADDR(PTE_ADDR(pgdir[page_dir_index]));
	}else{
		if (create){
			struct PageInfo *newPage = page_alloc(ALLOC_ZERO);
			if (!newPage)
				return NULL;
f01010c4:	b8 00 00 00 00       	mov    $0x0,%eax
		}else{
			return NULL;
		}
	}
	return &page_tab[page_table_index];
}
f01010c9:	83 c4 10             	add    $0x10,%esp
f01010cc:	5b                   	pop    %ebx
f01010cd:	5e                   	pop    %esi
f01010ce:	5d                   	pop    %ebp
f01010cf:	c3                   	ret    

f01010d0 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01010d0:	55                   	push   %ebp
f01010d1:	89 e5                	mov    %esp,%ebp
f01010d3:	53                   	push   %ebx
f01010d4:	83 ec 14             	sub    $0x14,%esp
f01010d7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// search without create, so the third parameter is 0
	pte_t *page_tab = pgdir_walk(pgdir, va, 0);
f01010da:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01010e1:	00 
f01010e2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010e5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01010ec:	89 04 24             	mov    %eax,(%esp)
f01010ef:	e8 cf fe ff ff       	call   f0100fc3 <pgdir_walk>
	if (!page_tab)
f01010f4:	85 c0                	test   %eax,%eax
f01010f6:	74 3a                	je     f0101132 <page_lookup+0x62>
		return NULL;	//fail to find
	if (pte_store){
f01010f8:	85 db                	test   %ebx,%ebx
f01010fa:	74 02                	je     f01010fe <page_lookup+0x2e>
		*pte_store = page_tab;
f01010fc:	89 03                	mov    %eax,(%ebx)
	}
	return pa2page(PTE_ADDR(*page_tab));
f01010fe:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101100:	c1 e8 0c             	shr    $0xc,%eax
f0101103:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0101109:	72 1c                	jb     f0101127 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f010110b:	c7 44 24 08 fc 43 10 	movl   $0xf01043fc,0x8(%esp)
f0101112:	f0 
f0101113:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f010111a:	00 
f010111b:	c7 04 24 50 4a 10 f0 	movl   $0xf0104a50,(%esp)
f0101122:	e8 6d ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0101127:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f010112d:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0101130:	eb 05                	jmp    f0101137 <page_lookup+0x67>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// search without create, so the third parameter is 0
	pte_t *page_tab = pgdir_walk(pgdir, va, 0);
	if (!page_tab)
		return NULL;	//fail to find
f0101132:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store){
		*pte_store = page_tab;
	}
	return pa2page(PTE_ADDR(*page_tab));
}
f0101137:	83 c4 14             	add    $0x14,%esp
f010113a:	5b                   	pop    %ebx
f010113b:	5d                   	pop    %ebp
f010113c:	c3                   	ret    

f010113d <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010113d:	55                   	push   %ebp
f010113e:	89 e5                	mov    %esp,%ebp
f0101140:	53                   	push   %ebx
f0101141:	83 ec 24             	sub    $0x24,%esp
f0101144:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *page_tab;
	pte_t **pte_store = &page_tab;
	struct PageInfo *pageInfo = page_lookup(pgdir, va, pte_store);
f0101147:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010114a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010114e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101152:	8b 45 08             	mov    0x8(%ebp),%eax
f0101155:	89 04 24             	mov    %eax,(%esp)
f0101158:	e8 73 ff ff ff       	call   f01010d0 <page_lookup>
	if (!pageInfo){
f010115d:	85 c0                	test   %eax,%eax
f010115f:	74 14                	je     f0101175 <page_remove+0x38>
		return;
	}
	page_decref(pageInfo);
f0101161:	89 04 24             	mov    %eax,(%esp)
f0101164:	e8 37 fe ff ff       	call   f0100fa0 <page_decref>
	*page_tab = 0;	//remove
f0101169:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010116c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101172:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);
}
f0101175:	83 c4 24             	add    $0x24,%esp
f0101178:	5b                   	pop    %ebx
f0101179:	5d                   	pop    %ebp
f010117a:	c3                   	ret    

f010117b <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010117b:	55                   	push   %ebp
f010117c:	89 e5                	mov    %esp,%ebp
f010117e:	57                   	push   %edi
f010117f:	56                   	push   %esi
f0101180:	53                   	push   %ebx
f0101181:	83 ec 1c             	sub    $0x1c,%esp
f0101184:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101187:	8b 7d 10             	mov    0x10(%ebp),%edi
	// search with create, if not find, create page
	pte_t *page_tab = pgdir_walk(pgdir, va, 1);
f010118a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101191:	00 
f0101192:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101196:	8b 45 08             	mov    0x8(%ebp),%eax
f0101199:	89 04 24             	mov    %eax,(%esp)
f010119c:	e8 22 fe ff ff       	call   f0100fc3 <pgdir_walk>
f01011a1:	89 c3                	mov    %eax,%ebx
	if (!page_tab)
f01011a3:	85 c0                	test   %eax,%eax
f01011a5:	74 36                	je     f01011dd <page_insert+0x62>
		return -E_NO_MEM;	// lack of memory
	pp->pp_ref++;
f01011a7:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	if (*page_tab & PTE_P)	// test is exist or not
f01011ac:	f6 00 01             	testb  $0x1,(%eax)
f01011af:	74 0f                	je     f01011c0 <page_insert+0x45>
		page_remove(pgdir, va);
f01011b1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01011b8:	89 04 24             	mov    %eax,(%esp)
f01011bb:	e8 7d ff ff ff       	call   f010113d <page_remove>
	*page_tab = page2pa(pp) | perm | PTE_P;
f01011c0:	8b 45 14             	mov    0x14(%ebp),%eax
f01011c3:	83 c8 01             	or     $0x1,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01011c6:	2b 35 6c 79 11 f0    	sub    0xf011796c,%esi
f01011cc:	c1 fe 03             	sar    $0x3,%esi
f01011cf:	c1 e6 0c             	shl    $0xc,%esi
f01011d2:	09 c6                	or     %eax,%esi
f01011d4:	89 33                	mov    %esi,(%ebx)
	return 0;
f01011d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01011db:	eb 05                	jmp    f01011e2 <page_insert+0x67>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// search with create, if not find, create page
	pte_t *page_tab = pgdir_walk(pgdir, va, 1);
	if (!page_tab)
		return -E_NO_MEM;	// lack of memory
f01011dd:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	pp->pp_ref++;
	if (*page_tab & PTE_P)	// test is exist or not
		page_remove(pgdir, va);
	*page_tab = page2pa(pp) | perm | PTE_P;
	return 0;
}
f01011e2:	83 c4 1c             	add    $0x1c,%esp
f01011e5:	5b                   	pop    %ebx
f01011e6:	5e                   	pop    %esi
f01011e7:	5f                   	pop    %edi
f01011e8:	5d                   	pop    %ebp
f01011e9:	c3                   	ret    

f01011ea <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01011ea:	55                   	push   %ebp
f01011eb:	89 e5                	mov    %esp,%ebp
f01011ed:	57                   	push   %edi
f01011ee:	56                   	push   %esi
f01011ef:	53                   	push   %ebx
f01011f0:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01011f3:	b8 15 00 00 00       	mov    $0x15,%eax
f01011f8:	e8 33 f7 ff ff       	call   f0100930 <nvram_read>
f01011fd:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01011ff:	b8 17 00 00 00       	mov    $0x17,%eax
f0101204:	e8 27 f7 ff ff       	call   f0100930 <nvram_read>
f0101209:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010120b:	b8 34 00 00 00       	mov    $0x34,%eax
f0101210:	e8 1b f7 ff ff       	call   f0100930 <nvram_read>
f0101215:	c1 e0 06             	shl    $0x6,%eax
f0101218:	89 c2                	mov    %eax,%edx

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
		totalmem = 16 * 1024 + ext16mem;
f010121a:	8d 80 00 40 00 00    	lea    0x4000(%eax),%eax
	extmem = nvram_read(NVRAM_EXTLO);
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0101220:	85 d2                	test   %edx,%edx
f0101222:	75 0b                	jne    f010122f <mem_init+0x45>
		totalmem = 16 * 1024 + ext16mem;
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0101224:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f010122a:	85 f6                	test   %esi,%esi
f010122c:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f010122f:	89 c2                	mov    %eax,%edx
f0101231:	c1 ea 02             	shr    $0x2,%edx
f0101234:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
	npages_basemem = basemem / (PGSIZE / 1024);
f010123a:	89 da                	mov    %ebx,%edx
f010123c:	c1 ea 02             	shr    $0x2,%edx
f010123f:	89 15 40 75 11 f0    	mov    %edx,0xf0117540

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101245:	89 c2                	mov    %eax,%edx
f0101247:	29 da                	sub    %ebx,%edx
f0101249:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010124d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101251:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101255:	c7 04 24 1c 44 10 f0 	movl   $0xf010441c,(%esp)
f010125c:	e8 2f 1b 00 00       	call   f0102d90 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101261:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101266:	e8 f0 f6 ff ff       	call   f010095b <boot_alloc>
f010126b:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f0101270:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101277:	00 
f0101278:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010127f:	00 
f0101280:	89 04 24             	mov    %eax,(%esp)
f0101283:	e8 6f 26 00 00       	call   f01038f7 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101288:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010128d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101292:	77 20                	ja     f01012b4 <mem_init+0xca>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101294:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101298:	c7 44 24 08 ac 43 10 	movl   $0xf01043ac,0x8(%esp)
f010129f:	f0 
f01012a0:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f01012a7:	00 
f01012a8:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01012af:	e8 e0 ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01012b4:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01012ba:	83 ca 05             	or     $0x5,%edx
f01012bd:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(sizeof(struct PageInfo) * npages);
f01012c3:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01012c8:	c1 e0 03             	shl    $0x3,%eax
f01012cb:	e8 8b f6 ff ff       	call   f010095b <boot_alloc>
f01012d0:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	memset(pages, 0, sizeof(struct PageInfo) * npages);
f01012d5:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f01012db:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01012e2:	89 54 24 08          	mov    %edx,0x8(%esp)
f01012e6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012ed:	00 
f01012ee:	89 04 24             	mov    %eax,(%esp)
f01012f1:	e8 01 26 00 00       	call   f01038f7 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01012f6:	e8 c1 fa ff ff       	call   f0100dbc <page_init>

	check_page_free_list(1);
f01012fb:	b8 01 00 00 00       	mov    $0x1,%eax
f0101300:	e8 6e f7 ff ff       	call   f0100a73 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101305:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f010130c:	75 1c                	jne    f010132a <mem_init+0x140>
		panic("'pages' is a null pointer!");
f010130e:	c7 44 24 08 fa 4a 10 	movl   $0xf0104afa,0x8(%esp)
f0101315:	f0 
f0101316:	c7 44 24 04 5c 02 00 	movl   $0x25c,0x4(%esp)
f010131d:	00 
f010131e:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101325:	e8 6a ed ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010132a:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010132f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101334:	eb 05                	jmp    f010133b <mem_init+0x151>
		++nfree;
f0101336:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101339:	8b 00                	mov    (%eax),%eax
f010133b:	85 c0                	test   %eax,%eax
f010133d:	75 f7                	jne    f0101336 <mem_init+0x14c>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010133f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101346:	e8 8a fb ff ff       	call   f0100ed5 <page_alloc>
f010134b:	89 c7                	mov    %eax,%edi
f010134d:	85 c0                	test   %eax,%eax
f010134f:	75 24                	jne    f0101375 <mem_init+0x18b>
f0101351:	c7 44 24 0c 15 4b 10 	movl   $0xf0104b15,0xc(%esp)
f0101358:	f0 
f0101359:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101360:	f0 
f0101361:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
f0101368:	00 
f0101369:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101370:	e8 1f ed ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101375:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010137c:	e8 54 fb ff ff       	call   f0100ed5 <page_alloc>
f0101381:	89 c6                	mov    %eax,%esi
f0101383:	85 c0                	test   %eax,%eax
f0101385:	75 24                	jne    f01013ab <mem_init+0x1c1>
f0101387:	c7 44 24 0c 2b 4b 10 	movl   $0xf0104b2b,0xc(%esp)
f010138e:	f0 
f010138f:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101396:	f0 
f0101397:	c7 44 24 04 65 02 00 	movl   $0x265,0x4(%esp)
f010139e:	00 
f010139f:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01013a6:	e8 e9 ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01013ab:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013b2:	e8 1e fb ff ff       	call   f0100ed5 <page_alloc>
f01013b7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013ba:	85 c0                	test   %eax,%eax
f01013bc:	75 24                	jne    f01013e2 <mem_init+0x1f8>
f01013be:	c7 44 24 0c 41 4b 10 	movl   $0xf0104b41,0xc(%esp)
f01013c5:	f0 
f01013c6:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01013cd:	f0 
f01013ce:	c7 44 24 04 66 02 00 	movl   $0x266,0x4(%esp)
f01013d5:	00 
f01013d6:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01013dd:	e8 b2 ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013e2:	39 f7                	cmp    %esi,%edi
f01013e4:	75 24                	jne    f010140a <mem_init+0x220>
f01013e6:	c7 44 24 0c 57 4b 10 	movl   $0xf0104b57,0xc(%esp)
f01013ed:	f0 
f01013ee:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01013f5:	f0 
f01013f6:	c7 44 24 04 69 02 00 	movl   $0x269,0x4(%esp)
f01013fd:	00 
f01013fe:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101405:	e8 8a ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010140a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010140d:	39 c6                	cmp    %eax,%esi
f010140f:	74 04                	je     f0101415 <mem_init+0x22b>
f0101411:	39 c7                	cmp    %eax,%edi
f0101413:	75 24                	jne    f0101439 <mem_init+0x24f>
f0101415:	c7 44 24 0c 58 44 10 	movl   $0xf0104458,0xc(%esp)
f010141c:	f0 
f010141d:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101424:	f0 
f0101425:	c7 44 24 04 6a 02 00 	movl   $0x26a,0x4(%esp)
f010142c:	00 
f010142d:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101434:	e8 5b ec ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101439:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010143f:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0101444:	c1 e0 0c             	shl    $0xc,%eax
f0101447:	89 f9                	mov    %edi,%ecx
f0101449:	29 d1                	sub    %edx,%ecx
f010144b:	c1 f9 03             	sar    $0x3,%ecx
f010144e:	c1 e1 0c             	shl    $0xc,%ecx
f0101451:	39 c1                	cmp    %eax,%ecx
f0101453:	72 24                	jb     f0101479 <mem_init+0x28f>
f0101455:	c7 44 24 0c 69 4b 10 	movl   $0xf0104b69,0xc(%esp)
f010145c:	f0 
f010145d:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101464:	f0 
f0101465:	c7 44 24 04 6b 02 00 	movl   $0x26b,0x4(%esp)
f010146c:	00 
f010146d:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101474:	e8 1b ec ff ff       	call   f0100094 <_panic>
f0101479:	89 f1                	mov    %esi,%ecx
f010147b:	29 d1                	sub    %edx,%ecx
f010147d:	c1 f9 03             	sar    $0x3,%ecx
f0101480:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101483:	39 c8                	cmp    %ecx,%eax
f0101485:	77 24                	ja     f01014ab <mem_init+0x2c1>
f0101487:	c7 44 24 0c 86 4b 10 	movl   $0xf0104b86,0xc(%esp)
f010148e:	f0 
f010148f:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101496:	f0 
f0101497:	c7 44 24 04 6c 02 00 	movl   $0x26c,0x4(%esp)
f010149e:	00 
f010149f:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01014a6:	e8 e9 eb ff ff       	call   f0100094 <_panic>
f01014ab:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01014ae:	29 d1                	sub    %edx,%ecx
f01014b0:	89 ca                	mov    %ecx,%edx
f01014b2:	c1 fa 03             	sar    $0x3,%edx
f01014b5:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01014b8:	39 d0                	cmp    %edx,%eax
f01014ba:	77 24                	ja     f01014e0 <mem_init+0x2f6>
f01014bc:	c7 44 24 0c a3 4b 10 	movl   $0xf0104ba3,0xc(%esp)
f01014c3:	f0 
f01014c4:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01014cb:	f0 
f01014cc:	c7 44 24 04 6d 02 00 	movl   $0x26d,0x4(%esp)
f01014d3:	00 
f01014d4:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01014db:	e8 b4 eb ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01014e0:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01014e5:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01014e8:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01014ef:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01014f2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014f9:	e8 d7 f9 ff ff       	call   f0100ed5 <page_alloc>
f01014fe:	85 c0                	test   %eax,%eax
f0101500:	74 24                	je     f0101526 <mem_init+0x33c>
f0101502:	c7 44 24 0c c0 4b 10 	movl   $0xf0104bc0,0xc(%esp)
f0101509:	f0 
f010150a:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101511:	f0 
f0101512:	c7 44 24 04 74 02 00 	movl   $0x274,0x4(%esp)
f0101519:	00 
f010151a:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101521:	e8 6e eb ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101526:	89 3c 24             	mov    %edi,(%esp)
f0101529:	e8 32 fa ff ff       	call   f0100f60 <page_free>
	page_free(pp1);
f010152e:	89 34 24             	mov    %esi,(%esp)
f0101531:	e8 2a fa ff ff       	call   f0100f60 <page_free>
	page_free(pp2);
f0101536:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101539:	89 04 24             	mov    %eax,(%esp)
f010153c:	e8 1f fa ff ff       	call   f0100f60 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101541:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101548:	e8 88 f9 ff ff       	call   f0100ed5 <page_alloc>
f010154d:	89 c6                	mov    %eax,%esi
f010154f:	85 c0                	test   %eax,%eax
f0101551:	75 24                	jne    f0101577 <mem_init+0x38d>
f0101553:	c7 44 24 0c 15 4b 10 	movl   $0xf0104b15,0xc(%esp)
f010155a:	f0 
f010155b:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101562:	f0 
f0101563:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
f010156a:	00 
f010156b:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101572:	e8 1d eb ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101577:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010157e:	e8 52 f9 ff ff       	call   f0100ed5 <page_alloc>
f0101583:	89 c7                	mov    %eax,%edi
f0101585:	85 c0                	test   %eax,%eax
f0101587:	75 24                	jne    f01015ad <mem_init+0x3c3>
f0101589:	c7 44 24 0c 2b 4b 10 	movl   $0xf0104b2b,0xc(%esp)
f0101590:	f0 
f0101591:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101598:	f0 
f0101599:	c7 44 24 04 7c 02 00 	movl   $0x27c,0x4(%esp)
f01015a0:	00 
f01015a1:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01015a8:	e8 e7 ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01015ad:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015b4:	e8 1c f9 ff ff       	call   f0100ed5 <page_alloc>
f01015b9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015bc:	85 c0                	test   %eax,%eax
f01015be:	75 24                	jne    f01015e4 <mem_init+0x3fa>
f01015c0:	c7 44 24 0c 41 4b 10 	movl   $0xf0104b41,0xc(%esp)
f01015c7:	f0 
f01015c8:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01015cf:	f0 
f01015d0:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f01015d7:	00 
f01015d8:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01015df:	e8 b0 ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015e4:	39 fe                	cmp    %edi,%esi
f01015e6:	75 24                	jne    f010160c <mem_init+0x422>
f01015e8:	c7 44 24 0c 57 4b 10 	movl   $0xf0104b57,0xc(%esp)
f01015ef:	f0 
f01015f0:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01015f7:	f0 
f01015f8:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f01015ff:	00 
f0101600:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101607:	e8 88 ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010160c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010160f:	39 c7                	cmp    %eax,%edi
f0101611:	74 04                	je     f0101617 <mem_init+0x42d>
f0101613:	39 c6                	cmp    %eax,%esi
f0101615:	75 24                	jne    f010163b <mem_init+0x451>
f0101617:	c7 44 24 0c 58 44 10 	movl   $0xf0104458,0xc(%esp)
f010161e:	f0 
f010161f:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101626:	f0 
f0101627:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f010162e:	00 
f010162f:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101636:	e8 59 ea ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f010163b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101642:	e8 8e f8 ff ff       	call   f0100ed5 <page_alloc>
f0101647:	85 c0                	test   %eax,%eax
f0101649:	74 24                	je     f010166f <mem_init+0x485>
f010164b:	c7 44 24 0c c0 4b 10 	movl   $0xf0104bc0,0xc(%esp)
f0101652:	f0 
f0101653:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f010165a:	f0 
f010165b:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f0101662:	00 
f0101663:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f010166a:	e8 25 ea ff ff       	call   f0100094 <_panic>
f010166f:	89 f0                	mov    %esi,%eax
f0101671:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101677:	c1 f8 03             	sar    $0x3,%eax
f010167a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010167d:	89 c2                	mov    %eax,%edx
f010167f:	c1 ea 0c             	shr    $0xc,%edx
f0101682:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101688:	72 20                	jb     f01016aa <mem_init+0x4c0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010168a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010168e:	c7 44 24 08 88 42 10 	movl   $0xf0104288,0x8(%esp)
f0101695:	f0 
f0101696:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010169d:	00 
f010169e:	c7 04 24 50 4a 10 f0 	movl   $0xf0104a50,(%esp)
f01016a5:	e8 ea e9 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01016aa:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01016b1:	00 
f01016b2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01016b9:	00 
	return (void *)(pa + KERNBASE);
f01016ba:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016bf:	89 04 24             	mov    %eax,(%esp)
f01016c2:	e8 30 22 00 00       	call   f01038f7 <memset>
	page_free(pp0);
f01016c7:	89 34 24             	mov    %esi,(%esp)
f01016ca:	e8 91 f8 ff ff       	call   f0100f60 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016cf:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016d6:	e8 fa f7 ff ff       	call   f0100ed5 <page_alloc>
f01016db:	85 c0                	test   %eax,%eax
f01016dd:	75 24                	jne    f0101703 <mem_init+0x519>
f01016df:	c7 44 24 0c cf 4b 10 	movl   $0xf0104bcf,0xc(%esp)
f01016e6:	f0 
f01016e7:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01016ee:	f0 
f01016ef:	c7 44 24 04 86 02 00 	movl   $0x286,0x4(%esp)
f01016f6:	00 
f01016f7:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01016fe:	e8 91 e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101703:	39 c6                	cmp    %eax,%esi
f0101705:	74 24                	je     f010172b <mem_init+0x541>
f0101707:	c7 44 24 0c ed 4b 10 	movl   $0xf0104bed,0xc(%esp)
f010170e:	f0 
f010170f:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101716:	f0 
f0101717:	c7 44 24 04 87 02 00 	movl   $0x287,0x4(%esp)
f010171e:	00 
f010171f:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101726:	e8 69 e9 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010172b:	89 f0                	mov    %esi,%eax
f010172d:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101733:	c1 f8 03             	sar    $0x3,%eax
f0101736:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101739:	89 c2                	mov    %eax,%edx
f010173b:	c1 ea 0c             	shr    $0xc,%edx
f010173e:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101744:	72 20                	jb     f0101766 <mem_init+0x57c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101746:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010174a:	c7 44 24 08 88 42 10 	movl   $0xf0104288,0x8(%esp)
f0101751:	f0 
f0101752:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101759:	00 
f010175a:	c7 04 24 50 4a 10 f0 	movl   $0xf0104a50,(%esp)
f0101761:	e8 2e e9 ff ff       	call   f0100094 <_panic>
f0101766:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010176c:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101772:	80 38 00             	cmpb   $0x0,(%eax)
f0101775:	74 24                	je     f010179b <mem_init+0x5b1>
f0101777:	c7 44 24 0c fd 4b 10 	movl   $0xf0104bfd,0xc(%esp)
f010177e:	f0 
f010177f:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101786:	f0 
f0101787:	c7 44 24 04 8a 02 00 	movl   $0x28a,0x4(%esp)
f010178e:	00 
f010178f:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101796:	e8 f9 e8 ff ff       	call   f0100094 <_panic>
f010179b:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010179e:	39 d0                	cmp    %edx,%eax
f01017a0:	75 d0                	jne    f0101772 <mem_init+0x588>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01017a2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01017a5:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f01017aa:	89 34 24             	mov    %esi,(%esp)
f01017ad:	e8 ae f7 ff ff       	call   f0100f60 <page_free>
	page_free(pp1);
f01017b2:	89 3c 24             	mov    %edi,(%esp)
f01017b5:	e8 a6 f7 ff ff       	call   f0100f60 <page_free>
	page_free(pp2);
f01017ba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017bd:	89 04 24             	mov    %eax,(%esp)
f01017c0:	e8 9b f7 ff ff       	call   f0100f60 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017c5:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01017ca:	eb 05                	jmp    f01017d1 <mem_init+0x5e7>
		--nfree;
f01017cc:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017cf:	8b 00                	mov    (%eax),%eax
f01017d1:	85 c0                	test   %eax,%eax
f01017d3:	75 f7                	jne    f01017cc <mem_init+0x5e2>
		--nfree;
	assert(nfree == 0);
f01017d5:	85 db                	test   %ebx,%ebx
f01017d7:	74 24                	je     f01017fd <mem_init+0x613>
f01017d9:	c7 44 24 0c 07 4c 10 	movl   $0xf0104c07,0xc(%esp)
f01017e0:	f0 
f01017e1:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01017e8:	f0 
f01017e9:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
f01017f0:	00 
f01017f1:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01017f8:	e8 97 e8 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01017fd:	c7 04 24 78 44 10 f0 	movl   $0xf0104478,(%esp)
f0101804:	e8 87 15 00 00       	call   f0102d90 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101809:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101810:	e8 c0 f6 ff ff       	call   f0100ed5 <page_alloc>
f0101815:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101818:	85 c0                	test   %eax,%eax
f010181a:	75 24                	jne    f0101840 <mem_init+0x656>
f010181c:	c7 44 24 0c 15 4b 10 	movl   $0xf0104b15,0xc(%esp)
f0101823:	f0 
f0101824:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f010182b:	f0 
f010182c:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
f0101833:	00 
f0101834:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f010183b:	e8 54 e8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101840:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101847:	e8 89 f6 ff ff       	call   f0100ed5 <page_alloc>
f010184c:	89 c3                	mov    %eax,%ebx
f010184e:	85 c0                	test   %eax,%eax
f0101850:	75 24                	jne    f0101876 <mem_init+0x68c>
f0101852:	c7 44 24 0c 2b 4b 10 	movl   $0xf0104b2b,0xc(%esp)
f0101859:	f0 
f010185a:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101861:	f0 
f0101862:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f0101869:	00 
f010186a:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101871:	e8 1e e8 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101876:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010187d:	e8 53 f6 ff ff       	call   f0100ed5 <page_alloc>
f0101882:	89 c6                	mov    %eax,%esi
f0101884:	85 c0                	test   %eax,%eax
f0101886:	75 24                	jne    f01018ac <mem_init+0x6c2>
f0101888:	c7 44 24 0c 41 4b 10 	movl   $0xf0104b41,0xc(%esp)
f010188f:	f0 
f0101890:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101897:	f0 
f0101898:	c7 44 24 04 f2 02 00 	movl   $0x2f2,0x4(%esp)
f010189f:	00 
f01018a0:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01018a7:	e8 e8 e7 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018ac:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01018af:	75 24                	jne    f01018d5 <mem_init+0x6eb>
f01018b1:	c7 44 24 0c 57 4b 10 	movl   $0xf0104b57,0xc(%esp)
f01018b8:	f0 
f01018b9:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01018c0:	f0 
f01018c1:	c7 44 24 04 f5 02 00 	movl   $0x2f5,0x4(%esp)
f01018c8:	00 
f01018c9:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01018d0:	e8 bf e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018d5:	39 c3                	cmp    %eax,%ebx
f01018d7:	74 05                	je     f01018de <mem_init+0x6f4>
f01018d9:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01018dc:	75 24                	jne    f0101902 <mem_init+0x718>
f01018de:	c7 44 24 0c 58 44 10 	movl   $0xf0104458,0xc(%esp)
f01018e5:	f0 
f01018e6:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01018ed:	f0 
f01018ee:	c7 44 24 04 f6 02 00 	movl   $0x2f6,0x4(%esp)
f01018f5:	00 
f01018f6:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01018fd:	e8 92 e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101902:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101907:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010190a:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101911:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101914:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010191b:	e8 b5 f5 ff ff       	call   f0100ed5 <page_alloc>
f0101920:	85 c0                	test   %eax,%eax
f0101922:	74 24                	je     f0101948 <mem_init+0x75e>
f0101924:	c7 44 24 0c c0 4b 10 	movl   $0xf0104bc0,0xc(%esp)
f010192b:	f0 
f010192c:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101933:	f0 
f0101934:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f010193b:	00 
f010193c:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101943:	e8 4c e7 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101948:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010194b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010194f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101956:	00 
f0101957:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010195c:	89 04 24             	mov    %eax,(%esp)
f010195f:	e8 6c f7 ff ff       	call   f01010d0 <page_lookup>
f0101964:	85 c0                	test   %eax,%eax
f0101966:	74 24                	je     f010198c <mem_init+0x7a2>
f0101968:	c7 44 24 0c 98 44 10 	movl   $0xf0104498,0xc(%esp)
f010196f:	f0 
f0101970:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101977:	f0 
f0101978:	c7 44 24 04 00 03 00 	movl   $0x300,0x4(%esp)
f010197f:	00 
f0101980:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101987:	e8 08 e7 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010198c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101993:	00 
f0101994:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010199b:	00 
f010199c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01019a0:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01019a5:	89 04 24             	mov    %eax,(%esp)
f01019a8:	e8 ce f7 ff ff       	call   f010117b <page_insert>
f01019ad:	85 c0                	test   %eax,%eax
f01019af:	78 24                	js     f01019d5 <mem_init+0x7eb>
f01019b1:	c7 44 24 0c d0 44 10 	movl   $0xf01044d0,0xc(%esp)
f01019b8:	f0 
f01019b9:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01019c0:	f0 
f01019c1:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f01019c8:	00 
f01019c9:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01019d0:	e8 bf e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019d5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019d8:	89 04 24             	mov    %eax,(%esp)
f01019db:	e8 80 f5 ff ff       	call   f0100f60 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019e0:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01019e7:	00 
f01019e8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019ef:	00 
f01019f0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01019f4:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01019f9:	89 04 24             	mov    %eax,(%esp)
f01019fc:	e8 7a f7 ff ff       	call   f010117b <page_insert>
f0101a01:	85 c0                	test   %eax,%eax
f0101a03:	74 24                	je     f0101a29 <mem_init+0x83f>
f0101a05:	c7 44 24 0c 00 45 10 	movl   $0xf0104500,0xc(%esp)
f0101a0c:	f0 
f0101a0d:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101a14:	f0 
f0101a15:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f0101a1c:	00 
f0101a1d:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101a24:	e8 6b e6 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a29:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a2f:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101a34:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a37:	8b 17                	mov    (%edi),%edx
f0101a39:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a3f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101a42:	29 c1                	sub    %eax,%ecx
f0101a44:	89 c8                	mov    %ecx,%eax
f0101a46:	c1 f8 03             	sar    $0x3,%eax
f0101a49:	c1 e0 0c             	shl    $0xc,%eax
f0101a4c:	39 c2                	cmp    %eax,%edx
f0101a4e:	74 24                	je     f0101a74 <mem_init+0x88a>
f0101a50:	c7 44 24 0c 30 45 10 	movl   $0xf0104530,0xc(%esp)
f0101a57:	f0 
f0101a58:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101a5f:	f0 
f0101a60:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f0101a67:	00 
f0101a68:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101a6f:	e8 20 e6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a74:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a79:	89 f8                	mov    %edi,%eax
f0101a7b:	e8 84 ef ff ff       	call   f0100a04 <check_va2pa>
f0101a80:	89 da                	mov    %ebx,%edx
f0101a82:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101a85:	c1 fa 03             	sar    $0x3,%edx
f0101a88:	c1 e2 0c             	shl    $0xc,%edx
f0101a8b:	39 d0                	cmp    %edx,%eax
f0101a8d:	74 24                	je     f0101ab3 <mem_init+0x8c9>
f0101a8f:	c7 44 24 0c 58 45 10 	movl   $0xf0104558,0xc(%esp)
f0101a96:	f0 
f0101a97:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101a9e:	f0 
f0101a9f:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0101aa6:	00 
f0101aa7:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101aae:	e8 e1 e5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101ab3:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ab8:	74 24                	je     f0101ade <mem_init+0x8f4>
f0101aba:	c7 44 24 0c 12 4c 10 	movl   $0xf0104c12,0xc(%esp)
f0101ac1:	f0 
f0101ac2:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101ac9:	f0 
f0101aca:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0101ad1:	00 
f0101ad2:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101ad9:	e8 b6 e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101ade:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ae1:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ae6:	74 24                	je     f0101b0c <mem_init+0x922>
f0101ae8:	c7 44 24 0c 23 4c 10 	movl   $0xf0104c23,0xc(%esp)
f0101aef:	f0 
f0101af0:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101af7:	f0 
f0101af8:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0101aff:	00 
f0101b00:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101b07:	e8 88 e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b0c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b13:	00 
f0101b14:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b1b:	00 
f0101b1c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101b20:	89 3c 24             	mov    %edi,(%esp)
f0101b23:	e8 53 f6 ff ff       	call   f010117b <page_insert>
f0101b28:	85 c0                	test   %eax,%eax
f0101b2a:	74 24                	je     f0101b50 <mem_init+0x966>
f0101b2c:	c7 44 24 0c 88 45 10 	movl   $0xf0104588,0xc(%esp)
f0101b33:	f0 
f0101b34:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101b3b:	f0 
f0101b3c:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0101b43:	00 
f0101b44:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101b4b:	e8 44 e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b50:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b55:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101b5a:	e8 a5 ee ff ff       	call   f0100a04 <check_va2pa>
f0101b5f:	89 f2                	mov    %esi,%edx
f0101b61:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101b67:	c1 fa 03             	sar    $0x3,%edx
f0101b6a:	c1 e2 0c             	shl    $0xc,%edx
f0101b6d:	39 d0                	cmp    %edx,%eax
f0101b6f:	74 24                	je     f0101b95 <mem_init+0x9ab>
f0101b71:	c7 44 24 0c c4 45 10 	movl   $0xf01045c4,0xc(%esp)
f0101b78:	f0 
f0101b79:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101b80:	f0 
f0101b81:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f0101b88:	00 
f0101b89:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101b90:	e8 ff e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101b95:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b9a:	74 24                	je     f0101bc0 <mem_init+0x9d6>
f0101b9c:	c7 44 24 0c 34 4c 10 	movl   $0xf0104c34,0xc(%esp)
f0101ba3:	f0 
f0101ba4:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101bab:	f0 
f0101bac:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f0101bb3:	00 
f0101bb4:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101bbb:	e8 d4 e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101bc0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bc7:	e8 09 f3 ff ff       	call   f0100ed5 <page_alloc>
f0101bcc:	85 c0                	test   %eax,%eax
f0101bce:	74 24                	je     f0101bf4 <mem_init+0xa0a>
f0101bd0:	c7 44 24 0c c0 4b 10 	movl   $0xf0104bc0,0xc(%esp)
f0101bd7:	f0 
f0101bd8:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101bdf:	f0 
f0101be0:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f0101be7:	00 
f0101be8:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101bef:	e8 a0 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bf4:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101bfb:	00 
f0101bfc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c03:	00 
f0101c04:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c08:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101c0d:	89 04 24             	mov    %eax,(%esp)
f0101c10:	e8 66 f5 ff ff       	call   f010117b <page_insert>
f0101c15:	85 c0                	test   %eax,%eax
f0101c17:	74 24                	je     f0101c3d <mem_init+0xa53>
f0101c19:	c7 44 24 0c 88 45 10 	movl   $0xf0104588,0xc(%esp)
f0101c20:	f0 
f0101c21:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101c28:	f0 
f0101c29:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
f0101c30:	00 
f0101c31:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101c38:	e8 57 e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c3d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c42:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101c47:	e8 b8 ed ff ff       	call   f0100a04 <check_va2pa>
f0101c4c:	89 f2                	mov    %esi,%edx
f0101c4e:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101c54:	c1 fa 03             	sar    $0x3,%edx
f0101c57:	c1 e2 0c             	shl    $0xc,%edx
f0101c5a:	39 d0                	cmp    %edx,%eax
f0101c5c:	74 24                	je     f0101c82 <mem_init+0xa98>
f0101c5e:	c7 44 24 0c c4 45 10 	movl   $0xf01045c4,0xc(%esp)
f0101c65:	f0 
f0101c66:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101c6d:	f0 
f0101c6e:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101c75:	00 
f0101c76:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101c7d:	e8 12 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c82:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c87:	74 24                	je     f0101cad <mem_init+0xac3>
f0101c89:	c7 44 24 0c 34 4c 10 	movl   $0xf0104c34,0xc(%esp)
f0101c90:	f0 
f0101c91:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101c98:	f0 
f0101c99:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f0101ca0:	00 
f0101ca1:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101ca8:	e8 e7 e3 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101cad:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cb4:	e8 1c f2 ff ff       	call   f0100ed5 <page_alloc>
f0101cb9:	85 c0                	test   %eax,%eax
f0101cbb:	74 24                	je     f0101ce1 <mem_init+0xaf7>
f0101cbd:	c7 44 24 0c c0 4b 10 	movl   $0xf0104bc0,0xc(%esp)
f0101cc4:	f0 
f0101cc5:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101ccc:	f0 
f0101ccd:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0101cd4:	00 
f0101cd5:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101cdc:	e8 b3 e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101ce1:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f0101ce7:	8b 02                	mov    (%edx),%eax
f0101ce9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101cee:	89 c1                	mov    %eax,%ecx
f0101cf0:	c1 e9 0c             	shr    $0xc,%ecx
f0101cf3:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0101cf9:	72 20                	jb     f0101d1b <mem_init+0xb31>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101cfb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101cff:	c7 44 24 08 88 42 10 	movl   $0xf0104288,0x8(%esp)
f0101d06:	f0 
f0101d07:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0101d0e:	00 
f0101d0f:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101d16:	e8 79 e3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101d1b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d20:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d23:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d2a:	00 
f0101d2b:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d32:	00 
f0101d33:	89 14 24             	mov    %edx,(%esp)
f0101d36:	e8 88 f2 ff ff       	call   f0100fc3 <pgdir_walk>
f0101d3b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d3e:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d41:	39 d0                	cmp    %edx,%eax
f0101d43:	74 24                	je     f0101d69 <mem_init+0xb7f>
f0101d45:	c7 44 24 0c f4 45 10 	movl   $0xf01045f4,0xc(%esp)
f0101d4c:	f0 
f0101d4d:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101d54:	f0 
f0101d55:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0101d5c:	00 
f0101d5d:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101d64:	e8 2b e3 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d69:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101d70:	00 
f0101d71:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d78:	00 
f0101d79:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101d7d:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101d82:	89 04 24             	mov    %eax,(%esp)
f0101d85:	e8 f1 f3 ff ff       	call   f010117b <page_insert>
f0101d8a:	85 c0                	test   %eax,%eax
f0101d8c:	74 24                	je     f0101db2 <mem_init+0xbc8>
f0101d8e:	c7 44 24 0c 34 46 10 	movl   $0xf0104634,0xc(%esp)
f0101d95:	f0 
f0101d96:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101d9d:	f0 
f0101d9e:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0101da5:	00 
f0101da6:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101dad:	e8 e2 e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101db2:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101db8:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dbd:	89 f8                	mov    %edi,%eax
f0101dbf:	e8 40 ec ff ff       	call   f0100a04 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101dc4:	89 f2                	mov    %esi,%edx
f0101dc6:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101dcc:	c1 fa 03             	sar    $0x3,%edx
f0101dcf:	c1 e2 0c             	shl    $0xc,%edx
f0101dd2:	39 d0                	cmp    %edx,%eax
f0101dd4:	74 24                	je     f0101dfa <mem_init+0xc10>
f0101dd6:	c7 44 24 0c c4 45 10 	movl   $0xf01045c4,0xc(%esp)
f0101ddd:	f0 
f0101dde:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101de5:	f0 
f0101de6:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0101ded:	00 
f0101dee:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101df5:	e8 9a e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101dfa:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101dff:	74 24                	je     f0101e25 <mem_init+0xc3b>
f0101e01:	c7 44 24 0c 34 4c 10 	movl   $0xf0104c34,0xc(%esp)
f0101e08:	f0 
f0101e09:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101e10:	f0 
f0101e11:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101e18:	00 
f0101e19:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101e20:	e8 6f e2 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e25:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e2c:	00 
f0101e2d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e34:	00 
f0101e35:	89 3c 24             	mov    %edi,(%esp)
f0101e38:	e8 86 f1 ff ff       	call   f0100fc3 <pgdir_walk>
f0101e3d:	f6 00 04             	testb  $0x4,(%eax)
f0101e40:	75 24                	jne    f0101e66 <mem_init+0xc7c>
f0101e42:	c7 44 24 0c 74 46 10 	movl   $0xf0104674,0xc(%esp)
f0101e49:	f0 
f0101e4a:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101e51:	f0 
f0101e52:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0101e59:	00 
f0101e5a:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101e61:	e8 2e e2 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e66:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101e6b:	f6 00 04             	testb  $0x4,(%eax)
f0101e6e:	75 24                	jne    f0101e94 <mem_init+0xcaa>
f0101e70:	c7 44 24 0c 45 4c 10 	movl   $0xf0104c45,0xc(%esp)
f0101e77:	f0 
f0101e78:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101e7f:	f0 
f0101e80:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0101e87:	00 
f0101e88:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101e8f:	e8 00 e2 ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e94:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e9b:	00 
f0101e9c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ea3:	00 
f0101ea4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101ea8:	89 04 24             	mov    %eax,(%esp)
f0101eab:	e8 cb f2 ff ff       	call   f010117b <page_insert>
f0101eb0:	85 c0                	test   %eax,%eax
f0101eb2:	74 24                	je     f0101ed8 <mem_init+0xcee>
f0101eb4:	c7 44 24 0c 88 45 10 	movl   $0xf0104588,0xc(%esp)
f0101ebb:	f0 
f0101ebc:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101ec3:	f0 
f0101ec4:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0101ecb:	00 
f0101ecc:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101ed3:	e8 bc e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ed8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101edf:	00 
f0101ee0:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ee7:	00 
f0101ee8:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101eed:	89 04 24             	mov    %eax,(%esp)
f0101ef0:	e8 ce f0 ff ff       	call   f0100fc3 <pgdir_walk>
f0101ef5:	f6 00 02             	testb  $0x2,(%eax)
f0101ef8:	75 24                	jne    f0101f1e <mem_init+0xd34>
f0101efa:	c7 44 24 0c a8 46 10 	movl   $0xf01046a8,0xc(%esp)
f0101f01:	f0 
f0101f02:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101f09:	f0 
f0101f0a:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0101f11:	00 
f0101f12:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101f19:	e8 76 e1 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f1e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f25:	00 
f0101f26:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f2d:	00 
f0101f2e:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101f33:	89 04 24             	mov    %eax,(%esp)
f0101f36:	e8 88 f0 ff ff       	call   f0100fc3 <pgdir_walk>
f0101f3b:	f6 00 04             	testb  $0x4,(%eax)
f0101f3e:	74 24                	je     f0101f64 <mem_init+0xd7a>
f0101f40:	c7 44 24 0c dc 46 10 	movl   $0xf01046dc,0xc(%esp)
f0101f47:	f0 
f0101f48:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101f4f:	f0 
f0101f50:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0101f57:	00 
f0101f58:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101f5f:	e8 30 e1 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f64:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f6b:	00 
f0101f6c:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101f73:	00 
f0101f74:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f77:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101f7b:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101f80:	89 04 24             	mov    %eax,(%esp)
f0101f83:	e8 f3 f1 ff ff       	call   f010117b <page_insert>
f0101f88:	85 c0                	test   %eax,%eax
f0101f8a:	78 24                	js     f0101fb0 <mem_init+0xdc6>
f0101f8c:	c7 44 24 0c 14 47 10 	movl   $0xf0104714,0xc(%esp)
f0101f93:	f0 
f0101f94:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101f9b:	f0 
f0101f9c:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0101fa3:	00 
f0101fa4:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101fab:	e8 e4 e0 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101fb0:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fb7:	00 
f0101fb8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101fbf:	00 
f0101fc0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101fc4:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101fc9:	89 04 24             	mov    %eax,(%esp)
f0101fcc:	e8 aa f1 ff ff       	call   f010117b <page_insert>
f0101fd1:	85 c0                	test   %eax,%eax
f0101fd3:	74 24                	je     f0101ff9 <mem_init+0xe0f>
f0101fd5:	c7 44 24 0c 4c 47 10 	movl   $0xf010474c,0xc(%esp)
f0101fdc:	f0 
f0101fdd:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0101fe4:	f0 
f0101fe5:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f0101fec:	00 
f0101fed:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0101ff4:	e8 9b e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ff9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102000:	00 
f0102001:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102008:	00 
f0102009:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010200e:	89 04 24             	mov    %eax,(%esp)
f0102011:	e8 ad ef ff ff       	call   f0100fc3 <pgdir_walk>
f0102016:	f6 00 04             	testb  $0x4,(%eax)
f0102019:	74 24                	je     f010203f <mem_init+0xe55>
f010201b:	c7 44 24 0c dc 46 10 	movl   $0xf01046dc,0xc(%esp)
f0102022:	f0 
f0102023:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f010202a:	f0 
f010202b:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0102032:	00 
f0102033:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f010203a:	e8 55 e0 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010203f:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0102045:	ba 00 00 00 00       	mov    $0x0,%edx
f010204a:	89 f8                	mov    %edi,%eax
f010204c:	e8 b3 e9 ff ff       	call   f0100a04 <check_va2pa>
f0102051:	89 c1                	mov    %eax,%ecx
f0102053:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102056:	89 d8                	mov    %ebx,%eax
f0102058:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010205e:	c1 f8 03             	sar    $0x3,%eax
f0102061:	c1 e0 0c             	shl    $0xc,%eax
f0102064:	39 c1                	cmp    %eax,%ecx
f0102066:	74 24                	je     f010208c <mem_init+0xea2>
f0102068:	c7 44 24 0c 88 47 10 	movl   $0xf0104788,0xc(%esp)
f010206f:	f0 
f0102070:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102077:	f0 
f0102078:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f010207f:	00 
f0102080:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102087:	e8 08 e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010208c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102091:	89 f8                	mov    %edi,%eax
f0102093:	e8 6c e9 ff ff       	call   f0100a04 <check_va2pa>
f0102098:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f010209b:	74 24                	je     f01020c1 <mem_init+0xed7>
f010209d:	c7 44 24 0c b4 47 10 	movl   $0xf01047b4,0xc(%esp)
f01020a4:	f0 
f01020a5:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01020ac:	f0 
f01020ad:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f01020b4:	00 
f01020b5:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01020bc:	e8 d3 df ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01020c1:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01020c6:	74 24                	je     f01020ec <mem_init+0xf02>
f01020c8:	c7 44 24 0c 5b 4c 10 	movl   $0xf0104c5b,0xc(%esp)
f01020cf:	f0 
f01020d0:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01020d7:	f0 
f01020d8:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f01020df:	00 
f01020e0:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01020e7:	e8 a8 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01020ec:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01020f1:	74 24                	je     f0102117 <mem_init+0xf2d>
f01020f3:	c7 44 24 0c 6c 4c 10 	movl   $0xf0104c6c,0xc(%esp)
f01020fa:	f0 
f01020fb:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102102:	f0 
f0102103:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f010210a:	00 
f010210b:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102112:	e8 7d df ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102117:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010211e:	e8 b2 ed ff ff       	call   f0100ed5 <page_alloc>
f0102123:	85 c0                	test   %eax,%eax
f0102125:	74 04                	je     f010212b <mem_init+0xf41>
f0102127:	39 c6                	cmp    %eax,%esi
f0102129:	74 24                	je     f010214f <mem_init+0xf65>
f010212b:	c7 44 24 0c e4 47 10 	movl   $0xf01047e4,0xc(%esp)
f0102132:	f0 
f0102133:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f010213a:	f0 
f010213b:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0102142:	00 
f0102143:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f010214a:	e8 45 df ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010214f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102156:	00 
f0102157:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010215c:	89 04 24             	mov    %eax,(%esp)
f010215f:	e8 d9 ef ff ff       	call   f010113d <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102164:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f010216a:	ba 00 00 00 00       	mov    $0x0,%edx
f010216f:	89 f8                	mov    %edi,%eax
f0102171:	e8 8e e8 ff ff       	call   f0100a04 <check_va2pa>
f0102176:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102179:	74 24                	je     f010219f <mem_init+0xfb5>
f010217b:	c7 44 24 0c 08 48 10 	movl   $0xf0104808,0xc(%esp)
f0102182:	f0 
f0102183:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f010218a:	f0 
f010218b:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0102192:	00 
f0102193:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f010219a:	e8 f5 de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010219f:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021a4:	89 f8                	mov    %edi,%eax
f01021a6:	e8 59 e8 ff ff       	call   f0100a04 <check_va2pa>
f01021ab:	89 da                	mov    %ebx,%edx
f01021ad:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01021b3:	c1 fa 03             	sar    $0x3,%edx
f01021b6:	c1 e2 0c             	shl    $0xc,%edx
f01021b9:	39 d0                	cmp    %edx,%eax
f01021bb:	74 24                	je     f01021e1 <mem_init+0xff7>
f01021bd:	c7 44 24 0c b4 47 10 	movl   $0xf01047b4,0xc(%esp)
f01021c4:	f0 
f01021c5:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01021cc:	f0 
f01021cd:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f01021d4:	00 
f01021d5:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01021dc:	e8 b3 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01021e1:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01021e6:	74 24                	je     f010220c <mem_init+0x1022>
f01021e8:	c7 44 24 0c 12 4c 10 	movl   $0xf0104c12,0xc(%esp)
f01021ef:	f0 
f01021f0:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01021f7:	f0 
f01021f8:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f01021ff:	00 
f0102200:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102207:	e8 88 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010220c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102211:	74 24                	je     f0102237 <mem_init+0x104d>
f0102213:	c7 44 24 0c 6c 4c 10 	movl   $0xf0104c6c,0xc(%esp)
f010221a:	f0 
f010221b:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102222:	f0 
f0102223:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f010222a:	00 
f010222b:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102232:	e8 5d de ff ff       	call   f0100094 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102237:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010223e:	00 
f010223f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102246:	00 
f0102247:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010224b:	89 3c 24             	mov    %edi,(%esp)
f010224e:	e8 28 ef ff ff       	call   f010117b <page_insert>
f0102253:	85 c0                	test   %eax,%eax
f0102255:	74 24                	je     f010227b <mem_init+0x1091>
f0102257:	c7 44 24 0c 2c 48 10 	movl   $0xf010482c,0xc(%esp)
f010225e:	f0 
f010225f:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102266:	f0 
f0102267:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f010226e:	00 
f010226f:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102276:	e8 19 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref);
f010227b:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102280:	75 24                	jne    f01022a6 <mem_init+0x10bc>
f0102282:	c7 44 24 0c 7d 4c 10 	movl   $0xf0104c7d,0xc(%esp)
f0102289:	f0 
f010228a:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102291:	f0 
f0102292:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0102299:	00 
f010229a:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01022a1:	e8 ee dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_link == NULL);
f01022a6:	83 3b 00             	cmpl   $0x0,(%ebx)
f01022a9:	74 24                	je     f01022cf <mem_init+0x10e5>
f01022ab:	c7 44 24 0c 89 4c 10 	movl   $0xf0104c89,0xc(%esp)
f01022b2:	f0 
f01022b3:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01022ba:	f0 
f01022bb:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f01022c2:	00 
f01022c3:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01022ca:	e8 c5 dd ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01022cf:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01022d6:	00 
f01022d7:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01022dc:	89 04 24             	mov    %eax,(%esp)
f01022df:	e8 59 ee ff ff       	call   f010113d <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01022e4:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f01022ea:	ba 00 00 00 00       	mov    $0x0,%edx
f01022ef:	89 f8                	mov    %edi,%eax
f01022f1:	e8 0e e7 ff ff       	call   f0100a04 <check_va2pa>
f01022f6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022f9:	74 24                	je     f010231f <mem_init+0x1135>
f01022fb:	c7 44 24 0c 08 48 10 	movl   $0xf0104808,0xc(%esp)
f0102302:	f0 
f0102303:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f010230a:	f0 
f010230b:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0102312:	00 
f0102313:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f010231a:	e8 75 dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010231f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102324:	89 f8                	mov    %edi,%eax
f0102326:	e8 d9 e6 ff ff       	call   f0100a04 <check_va2pa>
f010232b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010232e:	74 24                	je     f0102354 <mem_init+0x116a>
f0102330:	c7 44 24 0c 64 48 10 	movl   $0xf0104864,0xc(%esp)
f0102337:	f0 
f0102338:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f010233f:	f0 
f0102340:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0102347:	00 
f0102348:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f010234f:	e8 40 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102354:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102359:	74 24                	je     f010237f <mem_init+0x1195>
f010235b:	c7 44 24 0c 9e 4c 10 	movl   $0xf0104c9e,0xc(%esp)
f0102362:	f0 
f0102363:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f010236a:	f0 
f010236b:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f0102372:	00 
f0102373:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f010237a:	e8 15 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010237f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102384:	74 24                	je     f01023aa <mem_init+0x11c0>
f0102386:	c7 44 24 0c 6c 4c 10 	movl   $0xf0104c6c,0xc(%esp)
f010238d:	f0 
f010238e:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102395:	f0 
f0102396:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f010239d:	00 
f010239e:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01023a5:	e8 ea dc ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01023aa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023b1:	e8 1f eb ff ff       	call   f0100ed5 <page_alloc>
f01023b6:	85 c0                	test   %eax,%eax
f01023b8:	74 04                	je     f01023be <mem_init+0x11d4>
f01023ba:	39 c3                	cmp    %eax,%ebx
f01023bc:	74 24                	je     f01023e2 <mem_init+0x11f8>
f01023be:	c7 44 24 0c 8c 48 10 	movl   $0xf010488c,0xc(%esp)
f01023c5:	f0 
f01023c6:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01023cd:	f0 
f01023ce:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f01023d5:	00 
f01023d6:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01023dd:	e8 b2 dc ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01023e2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023e9:	e8 e7 ea ff ff       	call   f0100ed5 <page_alloc>
f01023ee:	85 c0                	test   %eax,%eax
f01023f0:	74 24                	je     f0102416 <mem_init+0x122c>
f01023f2:	c7 44 24 0c c0 4b 10 	movl   $0xf0104bc0,0xc(%esp)
f01023f9:	f0 
f01023fa:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102401:	f0 
f0102402:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0102409:	00 
f010240a:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102411:	e8 7e dc ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102416:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010241b:	8b 08                	mov    (%eax),%ecx
f010241d:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102423:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102426:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f010242c:	c1 fa 03             	sar    $0x3,%edx
f010242f:	c1 e2 0c             	shl    $0xc,%edx
f0102432:	39 d1                	cmp    %edx,%ecx
f0102434:	74 24                	je     f010245a <mem_init+0x1270>
f0102436:	c7 44 24 0c 30 45 10 	movl   $0xf0104530,0xc(%esp)
f010243d:	f0 
f010243e:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102445:	f0 
f0102446:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f010244d:	00 
f010244e:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102455:	e8 3a dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f010245a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102460:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102463:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102468:	74 24                	je     f010248e <mem_init+0x12a4>
f010246a:	c7 44 24 0c 23 4c 10 	movl   $0xf0104c23,0xc(%esp)
f0102471:	f0 
f0102472:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102479:	f0 
f010247a:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f0102481:	00 
f0102482:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102489:	e8 06 dc ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f010248e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102491:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102497:	89 04 24             	mov    %eax,(%esp)
f010249a:	e8 c1 ea ff ff       	call   f0100f60 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010249f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01024a6:	00 
f01024a7:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01024ae:	00 
f01024af:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01024b4:	89 04 24             	mov    %eax,(%esp)
f01024b7:	e8 07 eb ff ff       	call   f0100fc3 <pgdir_walk>
f01024bc:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01024bf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01024c2:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f01024c8:	8b 7a 04             	mov    0x4(%edx),%edi
f01024cb:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024d1:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f01024d7:	89 f8                	mov    %edi,%eax
f01024d9:	c1 e8 0c             	shr    $0xc,%eax
f01024dc:	39 c8                	cmp    %ecx,%eax
f01024de:	72 20                	jb     f0102500 <mem_init+0x1316>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024e0:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01024e4:	c7 44 24 08 88 42 10 	movl   $0xf0104288,0x8(%esp)
f01024eb:	f0 
f01024ec:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f01024f3:	00 
f01024f4:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01024fb:	e8 94 db ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102500:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102506:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102509:	74 24                	je     f010252f <mem_init+0x1345>
f010250b:	c7 44 24 0c af 4c 10 	movl   $0xf0104caf,0xc(%esp)
f0102512:	f0 
f0102513:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f010251a:	f0 
f010251b:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f0102522:	00 
f0102523:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f010252a:	e8 65 db ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010252f:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102536:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102539:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010253f:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102545:	c1 f8 03             	sar    $0x3,%eax
f0102548:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010254b:	89 c2                	mov    %eax,%edx
f010254d:	c1 ea 0c             	shr    $0xc,%edx
f0102550:	39 d1                	cmp    %edx,%ecx
f0102552:	77 20                	ja     f0102574 <mem_init+0x138a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102554:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102558:	c7 44 24 08 88 42 10 	movl   $0xf0104288,0x8(%esp)
f010255f:	f0 
f0102560:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102567:	00 
f0102568:	c7 04 24 50 4a 10 f0 	movl   $0xf0104a50,(%esp)
f010256f:	e8 20 db ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102574:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010257b:	00 
f010257c:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102583:	00 
	return (void *)(pa + KERNBASE);
f0102584:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102589:	89 04 24             	mov    %eax,(%esp)
f010258c:	e8 66 13 00 00       	call   f01038f7 <memset>
	page_free(pp0);
f0102591:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102594:	89 3c 24             	mov    %edi,(%esp)
f0102597:	e8 c4 e9 ff ff       	call   f0100f60 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010259c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01025a3:	00 
f01025a4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01025ab:	00 
f01025ac:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01025b1:	89 04 24             	mov    %eax,(%esp)
f01025b4:	e8 0a ea ff ff       	call   f0100fc3 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025b9:	89 fa                	mov    %edi,%edx
f01025bb:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01025c1:	c1 fa 03             	sar    $0x3,%edx
f01025c4:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025c7:	89 d0                	mov    %edx,%eax
f01025c9:	c1 e8 0c             	shr    $0xc,%eax
f01025cc:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f01025d2:	72 20                	jb     f01025f4 <mem_init+0x140a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025d4:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01025d8:	c7 44 24 08 88 42 10 	movl   $0xf0104288,0x8(%esp)
f01025df:	f0 
f01025e0:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01025e7:	00 
f01025e8:	c7 04 24 50 4a 10 f0 	movl   $0xf0104a50,(%esp)
f01025ef:	e8 a0 da ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01025f4:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01025fa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01025fd:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102603:	f6 00 01             	testb  $0x1,(%eax)
f0102606:	74 24                	je     f010262c <mem_init+0x1442>
f0102608:	c7 44 24 0c c7 4c 10 	movl   $0xf0104cc7,0xc(%esp)
f010260f:	f0 
f0102610:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102617:	f0 
f0102618:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f010261f:	00 
f0102620:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102627:	e8 68 da ff ff       	call   f0100094 <_panic>
f010262c:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010262f:	39 d0                	cmp    %edx,%eax
f0102631:	75 d0                	jne    f0102603 <mem_init+0x1419>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102633:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102638:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010263e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102641:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102647:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010264a:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f0102650:	89 04 24             	mov    %eax,(%esp)
f0102653:	e8 08 e9 ff ff       	call   f0100f60 <page_free>
	page_free(pp1);
f0102658:	89 1c 24             	mov    %ebx,(%esp)
f010265b:	e8 00 e9 ff ff       	call   f0100f60 <page_free>
	page_free(pp2);
f0102660:	89 34 24             	mov    %esi,(%esp)
f0102663:	e8 f8 e8 ff ff       	call   f0100f60 <page_free>

	cprintf("check_page() succeeded!\n");
f0102668:	c7 04 24 de 4c 10 f0 	movl   $0xf0104cde,(%esp)
f010266f:	e8 1c 07 00 00       	call   f0102d90 <cprintf>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102674:	8b 35 68 79 11 f0    	mov    0xf0117968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010267a:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f010267f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102682:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102689:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010268e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102691:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0102696:	89 45 c8             	mov    %eax,-0x38(%ebp)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102699:	89 45 d0             	mov    %eax,-0x30(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f010269c:	8d b8 00 00 00 10    	lea    0x10000000(%eax),%edi

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026a2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01026a7:	eb 6a                	jmp    f0102713 <mem_init+0x1529>
f01026a9:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026af:	89 f0                	mov    %esi,%eax
f01026b1:	e8 4e e3 ff ff       	call   f0100a04 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026b6:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01026bd:	77 23                	ja     f01026e2 <mem_init+0x14f8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026bf:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01026c2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01026c6:	c7 44 24 08 ac 43 10 	movl   $0xf01043ac,0x8(%esp)
f01026cd:	f0 
f01026ce:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f01026d5:	00 
f01026d6:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01026dd:	e8 b2 d9 ff ff       	call   f0100094 <_panic>
f01026e2:	8d 14 3b             	lea    (%ebx,%edi,1),%edx
f01026e5:	39 c2                	cmp    %eax,%edx
f01026e7:	74 24                	je     f010270d <mem_init+0x1523>
f01026e9:	c7 44 24 0c b0 48 10 	movl   $0xf01048b0,0xc(%esp)
f01026f0:	f0 
f01026f1:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01026f8:	f0 
f01026f9:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f0102700:	00 
f0102701:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102708:	e8 87 d9 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010270d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102713:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102716:	77 91                	ja     f01026a9 <mem_init+0x14bf>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102718:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010271b:	c1 e7 0c             	shl    $0xc,%edi
f010271e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102723:	eb 3b                	jmp    f0102760 <mem_init+0x1576>
f0102725:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010272b:	89 f0                	mov    %esi,%eax
f010272d:	e8 d2 e2 ff ff       	call   f0100a04 <check_va2pa>
f0102732:	39 c3                	cmp    %eax,%ebx
f0102734:	74 24                	je     f010275a <mem_init+0x1570>
f0102736:	c7 44 24 0c e4 48 10 	movl   $0xf01048e4,0xc(%esp)
f010273d:	f0 
f010273e:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102745:	f0 
f0102746:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
f010274d:	00 
f010274e:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102755:	e8 3a d9 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010275a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102760:	39 fb                	cmp    %edi,%ebx
f0102762:	72 c1                	jb     f0102725 <mem_init+0x153b>
f0102764:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102769:	bf 00 d0 10 f0       	mov    $0xf010d000,%edi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010276e:	89 da                	mov    %ebx,%edx
f0102770:	89 f0                	mov    %esi,%eax
f0102772:	e8 8d e2 ff ff       	call   f0100a04 <check_va2pa>
f0102777:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f010277d:	77 24                	ja     f01027a3 <mem_init+0x15b9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010277f:	c7 44 24 0c 00 d0 10 	movl   $0xf010d000,0xc(%esp)
f0102786:	f0 
f0102787:	c7 44 24 08 ac 43 10 	movl   $0xf01043ac,0x8(%esp)
f010278e:	f0 
f010278f:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f0102796:	00 
f0102797:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f010279e:	e8 f1 d8 ff ff       	call   f0100094 <_panic>
f01027a3:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f01027a9:	39 d0                	cmp    %edx,%eax
f01027ab:	74 24                	je     f01027d1 <mem_init+0x15e7>
f01027ad:	c7 44 24 0c 0c 49 10 	movl   $0xf010490c,0xc(%esp)
f01027b4:	f0 
f01027b5:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01027bc:	f0 
f01027bd:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f01027c4:	00 
f01027c5:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01027cc:	e8 c3 d8 ff ff       	call   f0100094 <_panic>
f01027d1:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01027d7:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01027dd:	75 8f                	jne    f010276e <mem_init+0x1584>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01027df:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01027e4:	89 f0                	mov    %esi,%eax
f01027e6:	e8 19 e2 ff ff       	call   f0100a04 <check_va2pa>
f01027eb:	83 f8 ff             	cmp    $0xffffffff,%eax
f01027ee:	75 0a                	jne    f01027fa <mem_init+0x1610>
f01027f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01027f5:	e9 f0 00 00 00       	jmp    f01028ea <mem_init+0x1700>
f01027fa:	c7 44 24 0c 54 49 10 	movl   $0xf0104954,0xc(%esp)
f0102801:	f0 
f0102802:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102809:	f0 
f010280a:	c7 44 24 04 b9 02 00 	movl   $0x2b9,0x4(%esp)
f0102811:	00 
f0102812:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102819:	e8 76 d8 ff ff       	call   f0100094 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010281e:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102823:	72 3c                	jb     f0102861 <mem_init+0x1677>
f0102825:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010282a:	76 07                	jbe    f0102833 <mem_init+0x1649>
f010282c:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102831:	75 2e                	jne    f0102861 <mem_init+0x1677>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102833:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102837:	0f 85 aa 00 00 00    	jne    f01028e7 <mem_init+0x16fd>
f010283d:	c7 44 24 0c f7 4c 10 	movl   $0xf0104cf7,0xc(%esp)
f0102844:	f0 
f0102845:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f010284c:	f0 
f010284d:	c7 44 24 04 c1 02 00 	movl   $0x2c1,0x4(%esp)
f0102854:	00 
f0102855:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f010285c:	e8 33 d8 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102861:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102866:	76 55                	jbe    f01028bd <mem_init+0x16d3>
				assert(pgdir[i] & PTE_P);
f0102868:	8b 14 86             	mov    (%esi,%eax,4),%edx
f010286b:	f6 c2 01             	test   $0x1,%dl
f010286e:	75 24                	jne    f0102894 <mem_init+0x16aa>
f0102870:	c7 44 24 0c f7 4c 10 	movl   $0xf0104cf7,0xc(%esp)
f0102877:	f0 
f0102878:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f010287f:	f0 
f0102880:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f0102887:	00 
f0102888:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f010288f:	e8 00 d8 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102894:	f6 c2 02             	test   $0x2,%dl
f0102897:	75 4e                	jne    f01028e7 <mem_init+0x16fd>
f0102899:	c7 44 24 0c 08 4d 10 	movl   $0xf0104d08,0xc(%esp)
f01028a0:	f0 
f01028a1:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01028a8:	f0 
f01028a9:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f01028b0:	00 
f01028b1:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01028b8:	e8 d7 d7 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f01028bd:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f01028c1:	74 24                	je     f01028e7 <mem_init+0x16fd>
f01028c3:	c7 44 24 0c 19 4d 10 	movl   $0xf0104d19,0xc(%esp)
f01028ca:	f0 
f01028cb:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01028d2:	f0 
f01028d3:	c7 44 24 04 c8 02 00 	movl   $0x2c8,0x4(%esp)
f01028da:	00 
f01028db:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01028e2:	e8 ad d7 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01028e7:	83 c0 01             	add    $0x1,%eax
f01028ea:	3d 00 04 00 00       	cmp    $0x400,%eax
f01028ef:	0f 85 29 ff ff ff    	jne    f010281e <mem_init+0x1634>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01028f5:	c7 04 24 84 49 10 f0 	movl   $0xf0104984,(%esp)
f01028fc:	e8 8f 04 00 00       	call   f0102d90 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102901:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102906:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010290b:	77 20                	ja     f010292d <mem_init+0x1743>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010290d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102911:	c7 44 24 08 ac 43 10 	movl   $0xf01043ac,0x8(%esp)
f0102918:	f0 
f0102919:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
f0102920:	00 
f0102921:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102928:	e8 67 d7 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010292d:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102932:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102935:	b8 00 00 00 00       	mov    $0x0,%eax
f010293a:	e8 34 e1 ff ff       	call   f0100a73 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f010293f:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102942:	83 e0 f3             	and    $0xfffffff3,%eax
f0102945:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f010294a:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010294d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102954:	e8 7c e5 ff ff       	call   f0100ed5 <page_alloc>
f0102959:	89 c3                	mov    %eax,%ebx
f010295b:	85 c0                	test   %eax,%eax
f010295d:	75 24                	jne    f0102983 <mem_init+0x1799>
f010295f:	c7 44 24 0c 15 4b 10 	movl   $0xf0104b15,0xc(%esp)
f0102966:	f0 
f0102967:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f010296e:	f0 
f010296f:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f0102976:	00 
f0102977:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f010297e:	e8 11 d7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102983:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010298a:	e8 46 e5 ff ff       	call   f0100ed5 <page_alloc>
f010298f:	89 c7                	mov    %eax,%edi
f0102991:	85 c0                	test   %eax,%eax
f0102993:	75 24                	jne    f01029b9 <mem_init+0x17cf>
f0102995:	c7 44 24 0c 2b 4b 10 	movl   $0xf0104b2b,0xc(%esp)
f010299c:	f0 
f010299d:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01029a4:	f0 
f01029a5:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f01029ac:	00 
f01029ad:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01029b4:	e8 db d6 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01029b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01029c0:	e8 10 e5 ff ff       	call   f0100ed5 <page_alloc>
f01029c5:	89 c6                	mov    %eax,%esi
f01029c7:	85 c0                	test   %eax,%eax
f01029c9:	75 24                	jne    f01029ef <mem_init+0x1805>
f01029cb:	c7 44 24 0c 41 4b 10 	movl   $0xf0104b41,0xc(%esp)
f01029d2:	f0 
f01029d3:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f01029da:	f0 
f01029db:	c7 44 24 04 8a 03 00 	movl   $0x38a,0x4(%esp)
f01029e2:	00 
f01029e3:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f01029ea:	e8 a5 d6 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f01029ef:	89 1c 24             	mov    %ebx,(%esp)
f01029f2:	e8 69 e5 ff ff       	call   f0100f60 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029f7:	89 f8                	mov    %edi,%eax
f01029f9:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01029ff:	c1 f8 03             	sar    $0x3,%eax
f0102a02:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a05:	89 c2                	mov    %eax,%edx
f0102a07:	c1 ea 0c             	shr    $0xc,%edx
f0102a0a:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102a10:	72 20                	jb     f0102a32 <mem_init+0x1848>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a12:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a16:	c7 44 24 08 88 42 10 	movl   $0xf0104288,0x8(%esp)
f0102a1d:	f0 
f0102a1e:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102a25:	00 
f0102a26:	c7 04 24 50 4a 10 f0 	movl   $0xf0104a50,(%esp)
f0102a2d:	e8 62 d6 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102a32:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a39:	00 
f0102a3a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102a41:	00 
	return (void *)(pa + KERNBASE);
f0102a42:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a47:	89 04 24             	mov    %eax,(%esp)
f0102a4a:	e8 a8 0e 00 00       	call   f01038f7 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a4f:	89 f0                	mov    %esi,%eax
f0102a51:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102a57:	c1 f8 03             	sar    $0x3,%eax
f0102a5a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a5d:	89 c2                	mov    %eax,%edx
f0102a5f:	c1 ea 0c             	shr    $0xc,%edx
f0102a62:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102a68:	72 20                	jb     f0102a8a <mem_init+0x18a0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a6a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a6e:	c7 44 24 08 88 42 10 	movl   $0xf0104288,0x8(%esp)
f0102a75:	f0 
f0102a76:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102a7d:	00 
f0102a7e:	c7 04 24 50 4a 10 f0 	movl   $0xf0104a50,(%esp)
f0102a85:	e8 0a d6 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102a8a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a91:	00 
f0102a92:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102a99:	00 
	return (void *)(pa + KERNBASE);
f0102a9a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a9f:	89 04 24             	mov    %eax,(%esp)
f0102aa2:	e8 50 0e 00 00       	call   f01038f7 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102aa7:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102aae:	00 
f0102aaf:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ab6:	00 
f0102ab7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102abb:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102ac0:	89 04 24             	mov    %eax,(%esp)
f0102ac3:	e8 b3 e6 ff ff       	call   f010117b <page_insert>
	assert(pp1->pp_ref == 1);
f0102ac8:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102acd:	74 24                	je     f0102af3 <mem_init+0x1909>
f0102acf:	c7 44 24 0c 12 4c 10 	movl   $0xf0104c12,0xc(%esp)
f0102ad6:	f0 
f0102ad7:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102ade:	f0 
f0102adf:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f0102ae6:	00 
f0102ae7:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102aee:	e8 a1 d5 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102af3:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102afa:	01 01 01 
f0102afd:	74 24                	je     f0102b23 <mem_init+0x1939>
f0102aff:	c7 44 24 0c a4 49 10 	movl   $0xf01049a4,0xc(%esp)
f0102b06:	f0 
f0102b07:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102b0e:	f0 
f0102b0f:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f0102b16:	00 
f0102b17:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102b1e:	e8 71 d5 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b23:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102b2a:	00 
f0102b2b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b32:	00 
f0102b33:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102b37:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102b3c:	89 04 24             	mov    %eax,(%esp)
f0102b3f:	e8 37 e6 ff ff       	call   f010117b <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102b44:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102b4b:	02 02 02 
f0102b4e:	74 24                	je     f0102b74 <mem_init+0x198a>
f0102b50:	c7 44 24 0c c8 49 10 	movl   $0xf01049c8,0xc(%esp)
f0102b57:	f0 
f0102b58:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102b5f:	f0 
f0102b60:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f0102b67:	00 
f0102b68:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102b6f:	e8 20 d5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102b74:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b79:	74 24                	je     f0102b9f <mem_init+0x19b5>
f0102b7b:	c7 44 24 0c 34 4c 10 	movl   $0xf0104c34,0xc(%esp)
f0102b82:	f0 
f0102b83:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102b8a:	f0 
f0102b8b:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0102b92:	00 
f0102b93:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102b9a:	e8 f5 d4 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102b9f:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102ba4:	74 24                	je     f0102bca <mem_init+0x19e0>
f0102ba6:	c7 44 24 0c 9e 4c 10 	movl   $0xf0104c9e,0xc(%esp)
f0102bad:	f0 
f0102bae:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102bb5:	f0 
f0102bb6:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0102bbd:	00 
f0102bbe:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102bc5:	e8 ca d4 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102bca:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102bd1:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bd4:	89 f0                	mov    %esi,%eax
f0102bd6:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102bdc:	c1 f8 03             	sar    $0x3,%eax
f0102bdf:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102be2:	89 c2                	mov    %eax,%edx
f0102be4:	c1 ea 0c             	shr    $0xc,%edx
f0102be7:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102bed:	72 20                	jb     f0102c0f <mem_init+0x1a25>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bef:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102bf3:	c7 44 24 08 88 42 10 	movl   $0xf0104288,0x8(%esp)
f0102bfa:	f0 
f0102bfb:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102c02:	00 
f0102c03:	c7 04 24 50 4a 10 f0 	movl   $0xf0104a50,(%esp)
f0102c0a:	e8 85 d4 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c0f:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102c16:	03 03 03 
f0102c19:	74 24                	je     f0102c3f <mem_init+0x1a55>
f0102c1b:	c7 44 24 0c ec 49 10 	movl   $0xf01049ec,0xc(%esp)
f0102c22:	f0 
f0102c23:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102c2a:	f0 
f0102c2b:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0102c32:	00 
f0102c33:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102c3a:	e8 55 d4 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c3f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102c46:	00 
f0102c47:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102c4c:	89 04 24             	mov    %eax,(%esp)
f0102c4f:	e8 e9 e4 ff ff       	call   f010113d <page_remove>
	assert(pp2->pp_ref == 0);
f0102c54:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102c59:	74 24                	je     f0102c7f <mem_init+0x1a95>
f0102c5b:	c7 44 24 0c 6c 4c 10 	movl   $0xf0104c6c,0xc(%esp)
f0102c62:	f0 
f0102c63:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102c6a:	f0 
f0102c6b:	c7 44 24 04 98 03 00 	movl   $0x398,0x4(%esp)
f0102c72:	00 
f0102c73:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102c7a:	e8 15 d4 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c7f:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102c84:	8b 08                	mov    (%eax),%ecx
f0102c86:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c8c:	89 da                	mov    %ebx,%edx
f0102c8e:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102c94:	c1 fa 03             	sar    $0x3,%edx
f0102c97:	c1 e2 0c             	shl    $0xc,%edx
f0102c9a:	39 d1                	cmp    %edx,%ecx
f0102c9c:	74 24                	je     f0102cc2 <mem_init+0x1ad8>
f0102c9e:	c7 44 24 0c 30 45 10 	movl   $0xf0104530,0xc(%esp)
f0102ca5:	f0 
f0102ca6:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102cad:	f0 
f0102cae:	c7 44 24 04 9b 03 00 	movl   $0x39b,0x4(%esp)
f0102cb5:	00 
f0102cb6:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102cbd:	e8 d2 d3 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102cc2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102cc8:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102ccd:	74 24                	je     f0102cf3 <mem_init+0x1b09>
f0102ccf:	c7 44 24 0c 23 4c 10 	movl   $0xf0104c23,0xc(%esp)
f0102cd6:	f0 
f0102cd7:	c7 44 24 08 6a 4a 10 	movl   $0xf0104a6a,0x8(%esp)
f0102cde:	f0 
f0102cdf:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f0102ce6:	00 
f0102ce7:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0102cee:	e8 a1 d3 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102cf3:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102cf9:	89 1c 24             	mov    %ebx,(%esp)
f0102cfc:	e8 5f e2 ff ff       	call   f0100f60 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102d01:	c7 04 24 18 4a 10 f0 	movl   $0xf0104a18,(%esp)
f0102d08:	e8 83 00 00 00       	call   f0102d90 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102d0d:	83 c4 3c             	add    $0x3c,%esp
f0102d10:	5b                   	pop    %ebx
f0102d11:	5e                   	pop    %esi
f0102d12:	5f                   	pop    %edi
f0102d13:	5d                   	pop    %ebp
f0102d14:	c3                   	ret    

f0102d15 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102d15:	55                   	push   %ebp
f0102d16:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102d18:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d1b:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102d1e:	5d                   	pop    %ebp
f0102d1f:	c3                   	ret    

f0102d20 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102d20:	55                   	push   %ebp
f0102d21:	89 e5                	mov    %esp,%ebp
f0102d23:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d27:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d2c:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102d2d:	b2 71                	mov    $0x71,%dl
f0102d2f:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102d30:	0f b6 c0             	movzbl %al,%eax
}
f0102d33:	5d                   	pop    %ebp
f0102d34:	c3                   	ret    

f0102d35 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102d35:	55                   	push   %ebp
f0102d36:	89 e5                	mov    %esp,%ebp
f0102d38:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d3c:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d41:	ee                   	out    %al,(%dx)
f0102d42:	b2 71                	mov    $0x71,%dl
f0102d44:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d47:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102d48:	5d                   	pop    %ebp
f0102d49:	c3                   	ret    

f0102d4a <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102d4a:	55                   	push   %ebp
f0102d4b:	89 e5                	mov    %esp,%ebp
f0102d4d:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102d50:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d53:	89 04 24             	mov    %eax,(%esp)
f0102d56:	e8 a6 d8 ff ff       	call   f0100601 <cputchar>
	*cnt++;
}
f0102d5b:	c9                   	leave  
f0102d5c:	c3                   	ret    

f0102d5d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102d5d:	55                   	push   %ebp
f0102d5e:	89 e5                	mov    %esp,%ebp
f0102d60:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102d63:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102d6a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d6d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d71:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d74:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102d78:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102d7b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d7f:	c7 04 24 4a 2d 10 f0 	movl   $0xf0102d4a,(%esp)
f0102d86:	e8 b3 04 00 00       	call   f010323e <vprintfmt>
	return cnt;
}
f0102d8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d8e:	c9                   	leave  
f0102d8f:	c3                   	ret    

f0102d90 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102d90:	55                   	push   %ebp
f0102d91:	89 e5                	mov    %esp,%ebp
f0102d93:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102d96:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102d99:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d9d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102da0:	89 04 24             	mov    %eax,(%esp)
f0102da3:	e8 b5 ff ff ff       	call   f0102d5d <vcprintf>
	va_end(ap);

	return cnt;
}
f0102da8:	c9                   	leave  
f0102da9:	c3                   	ret    

f0102daa <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102daa:	55                   	push   %ebp
f0102dab:	89 e5                	mov    %esp,%ebp
f0102dad:	57                   	push   %edi
f0102dae:	56                   	push   %esi
f0102daf:	53                   	push   %ebx
f0102db0:	83 ec 10             	sub    $0x10,%esp
f0102db3:	89 c6                	mov    %eax,%esi
f0102db5:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102db8:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102dbb:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102dbe:	8b 1a                	mov    (%edx),%ebx
f0102dc0:	8b 01                	mov    (%ecx),%eax
f0102dc2:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102dc5:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0102dcc:	eb 77                	jmp    f0102e45 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0102dce:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102dd1:	01 d8                	add    %ebx,%eax
f0102dd3:	b9 02 00 00 00       	mov    $0x2,%ecx
f0102dd8:	99                   	cltd   
f0102dd9:	f7 f9                	idiv   %ecx
f0102ddb:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102ddd:	eb 01                	jmp    f0102de0 <stab_binsearch+0x36>
			m--;
f0102ddf:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102de0:	39 d9                	cmp    %ebx,%ecx
f0102de2:	7c 1d                	jl     f0102e01 <stab_binsearch+0x57>
f0102de4:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102de7:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102dec:	39 fa                	cmp    %edi,%edx
f0102dee:	75 ef                	jne    f0102ddf <stab_binsearch+0x35>
f0102df0:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102df3:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102df6:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0102dfa:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102dfd:	73 18                	jae    f0102e17 <stab_binsearch+0x6d>
f0102dff:	eb 05                	jmp    f0102e06 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102e01:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0102e04:	eb 3f                	jmp    f0102e45 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102e06:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102e09:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0102e0b:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e0e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102e15:	eb 2e                	jmp    f0102e45 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102e17:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102e1a:	73 15                	jae    f0102e31 <stab_binsearch+0x87>
			*region_right = m - 1;
f0102e1c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102e1f:	48                   	dec    %eax
f0102e20:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102e23:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e26:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e28:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102e2f:	eb 14                	jmp    f0102e45 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102e31:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102e34:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0102e37:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0102e39:	ff 45 0c             	incl   0xc(%ebp)
f0102e3c:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e3e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102e45:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102e48:	7e 84                	jle    f0102dce <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102e4a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102e4e:	75 0d                	jne    f0102e5d <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102e50:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102e53:	8b 00                	mov    (%eax),%eax
f0102e55:	48                   	dec    %eax
f0102e56:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e59:	89 07                	mov    %eax,(%edi)
f0102e5b:	eb 22                	jmp    f0102e7f <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e5d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102e60:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102e62:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102e65:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e67:	eb 01                	jmp    f0102e6a <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102e69:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e6a:	39 c1                	cmp    %eax,%ecx
f0102e6c:	7d 0c                	jge    f0102e7a <stab_binsearch+0xd0>
f0102e6e:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0102e71:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102e76:	39 fa                	cmp    %edi,%edx
f0102e78:	75 ef                	jne    f0102e69 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102e7a:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0102e7d:	89 07                	mov    %eax,(%edi)
	}
}
f0102e7f:	83 c4 10             	add    $0x10,%esp
f0102e82:	5b                   	pop    %ebx
f0102e83:	5e                   	pop    %esi
f0102e84:	5f                   	pop    %edi
f0102e85:	5d                   	pop    %ebp
f0102e86:	c3                   	ret    

f0102e87 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102e87:	55                   	push   %ebp
f0102e88:	89 e5                	mov    %esp,%ebp
f0102e8a:	57                   	push   %edi
f0102e8b:	56                   	push   %esi
f0102e8c:	53                   	push   %ebx
f0102e8d:	83 ec 3c             	sub    $0x3c,%esp
f0102e90:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e93:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102e96:	c7 03 27 4d 10 f0    	movl   $0xf0104d27,(%ebx)
	info->eip_line = 0;
f0102e9c:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102ea3:	c7 43 08 27 4d 10 f0 	movl   $0xf0104d27,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102eaa:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102eb1:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102eb4:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102ebb:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102ec1:	76 12                	jbe    f0102ed5 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102ec3:	b8 01 ca 10 f0       	mov    $0xf010ca01,%eax
f0102ec8:	3d 5d ac 10 f0       	cmp    $0xf010ac5d,%eax
f0102ecd:	0f 86 cd 01 00 00    	jbe    f01030a0 <debuginfo_eip+0x219>
f0102ed3:	eb 1c                	jmp    f0102ef1 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102ed5:	c7 44 24 08 31 4d 10 	movl   $0xf0104d31,0x8(%esp)
f0102edc:	f0 
f0102edd:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102ee4:	00 
f0102ee5:	c7 04 24 3e 4d 10 f0 	movl   $0xf0104d3e,(%esp)
f0102eec:	e8 a3 d1 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102ef1:	80 3d 00 ca 10 f0 00 	cmpb   $0x0,0xf010ca00
f0102ef8:	0f 85 a9 01 00 00    	jne    f01030a7 <debuginfo_eip+0x220>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102efe:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102f05:	b8 5c ac 10 f0       	mov    $0xf010ac5c,%eax
f0102f0a:	2d 5c 4f 10 f0       	sub    $0xf0104f5c,%eax
f0102f0f:	c1 f8 02             	sar    $0x2,%eax
f0102f12:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102f18:	83 e8 01             	sub    $0x1,%eax
f0102f1b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102f1e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f22:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102f29:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102f2c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102f2f:	b8 5c 4f 10 f0       	mov    $0xf0104f5c,%eax
f0102f34:	e8 71 fe ff ff       	call   f0102daa <stab_binsearch>
	if (lfile == 0)
f0102f39:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102f3c:	85 c0                	test   %eax,%eax
f0102f3e:	0f 84 6a 01 00 00    	je     f01030ae <debuginfo_eip+0x227>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102f44:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102f47:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f4a:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102f4d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f51:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102f58:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102f5b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102f5e:	b8 5c 4f 10 f0       	mov    $0xf0104f5c,%eax
f0102f63:	e8 42 fe ff ff       	call   f0102daa <stab_binsearch>

	if (lfun <= rfun) {
f0102f68:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102f6b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102f6e:	39 d0                	cmp    %edx,%eax
f0102f70:	7f 3d                	jg     f0102faf <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102f72:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0102f75:	8d b9 5c 4f 10 f0    	lea    -0xfefb0a4(%ecx),%edi
f0102f7b:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102f7e:	8b 89 5c 4f 10 f0    	mov    -0xfefb0a4(%ecx),%ecx
f0102f84:	bf 01 ca 10 f0       	mov    $0xf010ca01,%edi
f0102f89:	81 ef 5d ac 10 f0    	sub    $0xf010ac5d,%edi
f0102f8f:	39 f9                	cmp    %edi,%ecx
f0102f91:	73 09                	jae    f0102f9c <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102f93:	81 c1 5d ac 10 f0    	add    $0xf010ac5d,%ecx
f0102f99:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102f9c:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102f9f:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102fa2:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102fa5:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102fa7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102faa:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102fad:	eb 0f                	jmp    f0102fbe <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102faf:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102fb2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fb5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102fb8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102fbb:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102fbe:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102fc5:	00 
f0102fc6:	8b 43 08             	mov    0x8(%ebx),%eax
f0102fc9:	89 04 24             	mov    %eax,(%esp)
f0102fcc:	e8 0a 09 00 00       	call   f01038db <strfind>
f0102fd1:	2b 43 08             	sub    0x8(%ebx),%eax
f0102fd4:	89 43 0c             	mov    %eax,0xc(%ebx)
	//
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102fd7:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102fdb:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0102fe2:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102fe5:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102fe8:	b8 5c 4f 10 f0       	mov    $0xf0104f5c,%eax
f0102fed:	e8 b8 fd ff ff       	call   f0102daa <stab_binsearch>
	
	if(lline <= rline){
f0102ff2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ff5:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0102ff8:	0f 8f b7 00 00 00    	jg     f01030b5 <debuginfo_eip+0x22e>
		info->eip_line = stabs[lline].n_desc;
f0102ffe:	6b c0 0c             	imul   $0xc,%eax,%eax
f0103001:	0f b7 80 62 4f 10 f0 	movzwl -0xfefb09e(%eax),%eax
f0103008:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010300b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010300e:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0103011:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103014:	6b d0 0c             	imul   $0xc,%eax,%edx
f0103017:	81 c2 5c 4f 10 f0    	add    $0xf0104f5c,%edx
f010301d:	eb 06                	jmp    f0103025 <debuginfo_eip+0x19e>
f010301f:	83 e8 01             	sub    $0x1,%eax
f0103022:	83 ea 0c             	sub    $0xc,%edx
f0103025:	89 c6                	mov    %eax,%esi
f0103027:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f010302a:	7f 33                	jg     f010305f <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f010302c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103030:	80 f9 84             	cmp    $0x84,%cl
f0103033:	74 0b                	je     f0103040 <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103035:	80 f9 64             	cmp    $0x64,%cl
f0103038:	75 e5                	jne    f010301f <debuginfo_eip+0x198>
f010303a:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f010303e:	74 df                	je     f010301f <debuginfo_eip+0x198>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103040:	6b f6 0c             	imul   $0xc,%esi,%esi
f0103043:	8b 86 5c 4f 10 f0    	mov    -0xfefb0a4(%esi),%eax
f0103049:	ba 01 ca 10 f0       	mov    $0xf010ca01,%edx
f010304e:	81 ea 5d ac 10 f0    	sub    $0xf010ac5d,%edx
f0103054:	39 d0                	cmp    %edx,%eax
f0103056:	73 07                	jae    f010305f <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103058:	05 5d ac 10 f0       	add    $0xf010ac5d,%eax
f010305d:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010305f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103062:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103065:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010306a:	39 ca                	cmp    %ecx,%edx
f010306c:	7d 53                	jge    f01030c1 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f010306e:	8d 42 01             	lea    0x1(%edx),%eax
f0103071:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103074:	89 c2                	mov    %eax,%edx
f0103076:	6b c0 0c             	imul   $0xc,%eax,%eax
f0103079:	05 5c 4f 10 f0       	add    $0xf0104f5c,%eax
f010307e:	89 ce                	mov    %ecx,%esi
f0103080:	eb 04                	jmp    f0103086 <debuginfo_eip+0x1ff>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103082:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103086:	39 d6                	cmp    %edx,%esi
f0103088:	7e 32                	jle    f01030bc <debuginfo_eip+0x235>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010308a:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f010308e:	83 c2 01             	add    $0x1,%edx
f0103091:	83 c0 0c             	add    $0xc,%eax
f0103094:	80 f9 a0             	cmp    $0xa0,%cl
f0103097:	74 e9                	je     f0103082 <debuginfo_eip+0x1fb>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103099:	b8 00 00 00 00       	mov    $0x0,%eax
f010309e:	eb 21                	jmp    f01030c1 <debuginfo_eip+0x23a>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01030a0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01030a5:	eb 1a                	jmp    f01030c1 <debuginfo_eip+0x23a>
f01030a7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01030ac:	eb 13                	jmp    f01030c1 <debuginfo_eip+0x23a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01030ae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01030b3:	eb 0c                	jmp    f01030c1 <debuginfo_eip+0x23a>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	
	if(lline <= rline){
		info->eip_line = stabs[lline].n_desc;
	}else{
		return -1;
f01030b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01030ba:	eb 05                	jmp    f01030c1 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01030bc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01030c1:	83 c4 3c             	add    $0x3c,%esp
f01030c4:	5b                   	pop    %ebx
f01030c5:	5e                   	pop    %esi
f01030c6:	5f                   	pop    %edi
f01030c7:	5d                   	pop    %ebp
f01030c8:	c3                   	ret    
f01030c9:	66 90                	xchg   %ax,%ax
f01030cb:	66 90                	xchg   %ax,%ax
f01030cd:	66 90                	xchg   %ax,%ax
f01030cf:	90                   	nop

f01030d0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01030d0:	55                   	push   %ebp
f01030d1:	89 e5                	mov    %esp,%ebp
f01030d3:	57                   	push   %edi
f01030d4:	56                   	push   %esi
f01030d5:	53                   	push   %ebx
f01030d6:	83 ec 3c             	sub    $0x3c,%esp
f01030d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01030dc:	89 d7                	mov    %edx,%edi
f01030de:	8b 45 08             	mov    0x8(%ebp),%eax
f01030e1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01030e4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030e7:	89 c3                	mov    %eax,%ebx
f01030e9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01030ec:	8b 45 10             	mov    0x10(%ebp),%eax
f01030ef:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01030f2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01030f7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01030fa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01030fd:	39 d9                	cmp    %ebx,%ecx
f01030ff:	72 05                	jb     f0103106 <printnum+0x36>
f0103101:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103104:	77 69                	ja     f010316f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103106:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0103109:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010310d:	83 ee 01             	sub    $0x1,%esi
f0103110:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103114:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103118:	8b 44 24 08          	mov    0x8(%esp),%eax
f010311c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103120:	89 c3                	mov    %eax,%ebx
f0103122:	89 d6                	mov    %edx,%esi
f0103124:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103127:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010312a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010312e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103132:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103135:	89 04 24             	mov    %eax,(%esp)
f0103138:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010313b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010313f:	e8 bc 09 00 00       	call   f0103b00 <__udivdi3>
f0103144:	89 d9                	mov    %ebx,%ecx
f0103146:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010314a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010314e:	89 04 24             	mov    %eax,(%esp)
f0103151:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103155:	89 fa                	mov    %edi,%edx
f0103157:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010315a:	e8 71 ff ff ff       	call   f01030d0 <printnum>
f010315f:	eb 1b                	jmp    f010317c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103161:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103165:	8b 45 18             	mov    0x18(%ebp),%eax
f0103168:	89 04 24             	mov    %eax,(%esp)
f010316b:	ff d3                	call   *%ebx
f010316d:	eb 03                	jmp    f0103172 <printnum+0xa2>
f010316f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103172:	83 ee 01             	sub    $0x1,%esi
f0103175:	85 f6                	test   %esi,%esi
f0103177:	7f e8                	jg     f0103161 <printnum+0x91>
f0103179:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010317c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103180:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103184:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103187:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010318a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010318e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103192:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103195:	89 04 24             	mov    %eax,(%esp)
f0103198:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010319b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010319f:	e8 8c 0a 00 00       	call   f0103c30 <__umoddi3>
f01031a4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031a8:	0f be 80 4c 4d 10 f0 	movsbl -0xfefb2b4(%eax),%eax
f01031af:	89 04 24             	mov    %eax,(%esp)
f01031b2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031b5:	ff d0                	call   *%eax
}
f01031b7:	83 c4 3c             	add    $0x3c,%esp
f01031ba:	5b                   	pop    %ebx
f01031bb:	5e                   	pop    %esi
f01031bc:	5f                   	pop    %edi
f01031bd:	5d                   	pop    %ebp
f01031be:	c3                   	ret    

f01031bf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01031bf:	55                   	push   %ebp
f01031c0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01031c2:	83 fa 01             	cmp    $0x1,%edx
f01031c5:	7e 0e                	jle    f01031d5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01031c7:	8b 10                	mov    (%eax),%edx
f01031c9:	8d 4a 08             	lea    0x8(%edx),%ecx
f01031cc:	89 08                	mov    %ecx,(%eax)
f01031ce:	8b 02                	mov    (%edx),%eax
f01031d0:	8b 52 04             	mov    0x4(%edx),%edx
f01031d3:	eb 22                	jmp    f01031f7 <getuint+0x38>
	else if (lflag)
f01031d5:	85 d2                	test   %edx,%edx
f01031d7:	74 10                	je     f01031e9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01031d9:	8b 10                	mov    (%eax),%edx
f01031db:	8d 4a 04             	lea    0x4(%edx),%ecx
f01031de:	89 08                	mov    %ecx,(%eax)
f01031e0:	8b 02                	mov    (%edx),%eax
f01031e2:	ba 00 00 00 00       	mov    $0x0,%edx
f01031e7:	eb 0e                	jmp    f01031f7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01031e9:	8b 10                	mov    (%eax),%edx
f01031eb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01031ee:	89 08                	mov    %ecx,(%eax)
f01031f0:	8b 02                	mov    (%edx),%eax
f01031f2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01031f7:	5d                   	pop    %ebp
f01031f8:	c3                   	ret    

f01031f9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01031f9:	55                   	push   %ebp
f01031fa:	89 e5                	mov    %esp,%ebp
f01031fc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01031ff:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103203:	8b 10                	mov    (%eax),%edx
f0103205:	3b 50 04             	cmp    0x4(%eax),%edx
f0103208:	73 0a                	jae    f0103214 <sprintputch+0x1b>
		*b->buf++ = ch;
f010320a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010320d:	89 08                	mov    %ecx,(%eax)
f010320f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103212:	88 02                	mov    %al,(%edx)
}
f0103214:	5d                   	pop    %ebp
f0103215:	c3                   	ret    

f0103216 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103216:	55                   	push   %ebp
f0103217:	89 e5                	mov    %esp,%ebp
f0103219:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010321c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010321f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103223:	8b 45 10             	mov    0x10(%ebp),%eax
f0103226:	89 44 24 08          	mov    %eax,0x8(%esp)
f010322a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010322d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103231:	8b 45 08             	mov    0x8(%ebp),%eax
f0103234:	89 04 24             	mov    %eax,(%esp)
f0103237:	e8 02 00 00 00       	call   f010323e <vprintfmt>
	va_end(ap);
}
f010323c:	c9                   	leave  
f010323d:	c3                   	ret    

f010323e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010323e:	55                   	push   %ebp
f010323f:	89 e5                	mov    %esp,%ebp
f0103241:	57                   	push   %edi
f0103242:	56                   	push   %esi
f0103243:	53                   	push   %ebx
f0103244:	83 ec 3c             	sub    $0x3c,%esp
f0103247:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010324a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010324d:	eb 14                	jmp    f0103263 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010324f:	85 c0                	test   %eax,%eax
f0103251:	0f 84 b3 03 00 00    	je     f010360a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0103257:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010325b:	89 04 24             	mov    %eax,(%esp)
f010325e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103261:	89 f3                	mov    %esi,%ebx
f0103263:	8d 73 01             	lea    0x1(%ebx),%esi
f0103266:	0f b6 03             	movzbl (%ebx),%eax
f0103269:	83 f8 25             	cmp    $0x25,%eax
f010326c:	75 e1                	jne    f010324f <vprintfmt+0x11>
f010326e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0103272:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103279:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0103280:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0103287:	ba 00 00 00 00       	mov    $0x0,%edx
f010328c:	eb 1d                	jmp    f01032ab <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010328e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103290:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0103294:	eb 15                	jmp    f01032ab <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103296:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103298:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010329c:	eb 0d                	jmp    f01032ab <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010329e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032a1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01032a4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032ab:	8d 5e 01             	lea    0x1(%esi),%ebx
f01032ae:	0f b6 0e             	movzbl (%esi),%ecx
f01032b1:	0f b6 c1             	movzbl %cl,%eax
f01032b4:	83 e9 23             	sub    $0x23,%ecx
f01032b7:	80 f9 55             	cmp    $0x55,%cl
f01032ba:	0f 87 2a 03 00 00    	ja     f01035ea <vprintfmt+0x3ac>
f01032c0:	0f b6 c9             	movzbl %cl,%ecx
f01032c3:	ff 24 8d d8 4d 10 f0 	jmp    *-0xfefb228(,%ecx,4)
f01032ca:	89 de                	mov    %ebx,%esi
f01032cc:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01032d1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f01032d4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f01032d8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01032db:	8d 58 d0             	lea    -0x30(%eax),%ebx
f01032de:	83 fb 09             	cmp    $0x9,%ebx
f01032e1:	77 36                	ja     f0103319 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01032e3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01032e6:	eb e9                	jmp    f01032d1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01032e8:	8b 45 14             	mov    0x14(%ebp),%eax
f01032eb:	8d 48 04             	lea    0x4(%eax),%ecx
f01032ee:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01032f1:	8b 00                	mov    (%eax),%eax
f01032f3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032f6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01032f8:	eb 22                	jmp    f010331c <vprintfmt+0xde>
f01032fa:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01032fd:	85 c9                	test   %ecx,%ecx
f01032ff:	b8 00 00 00 00       	mov    $0x0,%eax
f0103304:	0f 49 c1             	cmovns %ecx,%eax
f0103307:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010330a:	89 de                	mov    %ebx,%esi
f010330c:	eb 9d                	jmp    f01032ab <vprintfmt+0x6d>
f010330e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103310:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0103317:	eb 92                	jmp    f01032ab <vprintfmt+0x6d>
f0103319:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010331c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103320:	79 89                	jns    f01032ab <vprintfmt+0x6d>
f0103322:	e9 77 ff ff ff       	jmp    f010329e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103327:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010332a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010332c:	e9 7a ff ff ff       	jmp    f01032ab <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103331:	8b 45 14             	mov    0x14(%ebp),%eax
f0103334:	8d 50 04             	lea    0x4(%eax),%edx
f0103337:	89 55 14             	mov    %edx,0x14(%ebp)
f010333a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010333e:	8b 00                	mov    (%eax),%eax
f0103340:	89 04 24             	mov    %eax,(%esp)
f0103343:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103346:	e9 18 ff ff ff       	jmp    f0103263 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010334b:	8b 45 14             	mov    0x14(%ebp),%eax
f010334e:	8d 50 04             	lea    0x4(%eax),%edx
f0103351:	89 55 14             	mov    %edx,0x14(%ebp)
f0103354:	8b 00                	mov    (%eax),%eax
f0103356:	99                   	cltd   
f0103357:	31 d0                	xor    %edx,%eax
f0103359:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010335b:	83 f8 06             	cmp    $0x6,%eax
f010335e:	7f 0b                	jg     f010336b <vprintfmt+0x12d>
f0103360:	8b 14 85 30 4f 10 f0 	mov    -0xfefb0d0(,%eax,4),%edx
f0103367:	85 d2                	test   %edx,%edx
f0103369:	75 20                	jne    f010338b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010336b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010336f:	c7 44 24 08 64 4d 10 	movl   $0xf0104d64,0x8(%esp)
f0103376:	f0 
f0103377:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010337b:	8b 45 08             	mov    0x8(%ebp),%eax
f010337e:	89 04 24             	mov    %eax,(%esp)
f0103381:	e8 90 fe ff ff       	call   f0103216 <printfmt>
f0103386:	e9 d8 fe ff ff       	jmp    f0103263 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010338b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010338f:	c7 44 24 08 7c 4a 10 	movl   $0xf0104a7c,0x8(%esp)
f0103396:	f0 
f0103397:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010339b:	8b 45 08             	mov    0x8(%ebp),%eax
f010339e:	89 04 24             	mov    %eax,(%esp)
f01033a1:	e8 70 fe ff ff       	call   f0103216 <printfmt>
f01033a6:	e9 b8 fe ff ff       	jmp    f0103263 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033ab:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01033ae:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01033b1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01033b4:	8b 45 14             	mov    0x14(%ebp),%eax
f01033b7:	8d 50 04             	lea    0x4(%eax),%edx
f01033ba:	89 55 14             	mov    %edx,0x14(%ebp)
f01033bd:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01033bf:	85 f6                	test   %esi,%esi
f01033c1:	b8 5d 4d 10 f0       	mov    $0xf0104d5d,%eax
f01033c6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f01033c9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01033cd:	0f 84 97 00 00 00    	je     f010346a <vprintfmt+0x22c>
f01033d3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01033d7:	0f 8e 9b 00 00 00    	jle    f0103478 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f01033dd:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01033e1:	89 34 24             	mov    %esi,(%esp)
f01033e4:	e8 9f 03 00 00       	call   f0103788 <strnlen>
f01033e9:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01033ec:	29 c2                	sub    %eax,%edx
f01033ee:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f01033f1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f01033f5:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01033f8:	89 75 d8             	mov    %esi,-0x28(%ebp)
f01033fb:	8b 75 08             	mov    0x8(%ebp),%esi
f01033fe:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103401:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103403:	eb 0f                	jmp    f0103414 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0103405:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103409:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010340c:	89 04 24             	mov    %eax,(%esp)
f010340f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103411:	83 eb 01             	sub    $0x1,%ebx
f0103414:	85 db                	test   %ebx,%ebx
f0103416:	7f ed                	jg     f0103405 <vprintfmt+0x1c7>
f0103418:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010341b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010341e:	85 d2                	test   %edx,%edx
f0103420:	b8 00 00 00 00       	mov    $0x0,%eax
f0103425:	0f 49 c2             	cmovns %edx,%eax
f0103428:	29 c2                	sub    %eax,%edx
f010342a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010342d:	89 d7                	mov    %edx,%edi
f010342f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103432:	eb 50                	jmp    f0103484 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103434:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103438:	74 1e                	je     f0103458 <vprintfmt+0x21a>
f010343a:	0f be d2             	movsbl %dl,%edx
f010343d:	83 ea 20             	sub    $0x20,%edx
f0103440:	83 fa 5e             	cmp    $0x5e,%edx
f0103443:	76 13                	jbe    f0103458 <vprintfmt+0x21a>
					putch('?', putdat);
f0103445:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103448:	89 44 24 04          	mov    %eax,0x4(%esp)
f010344c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103453:	ff 55 08             	call   *0x8(%ebp)
f0103456:	eb 0d                	jmp    f0103465 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0103458:	8b 55 0c             	mov    0xc(%ebp),%edx
f010345b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010345f:	89 04 24             	mov    %eax,(%esp)
f0103462:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103465:	83 ef 01             	sub    $0x1,%edi
f0103468:	eb 1a                	jmp    f0103484 <vprintfmt+0x246>
f010346a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010346d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0103470:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103473:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103476:	eb 0c                	jmp    f0103484 <vprintfmt+0x246>
f0103478:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010347b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010347e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103481:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103484:	83 c6 01             	add    $0x1,%esi
f0103487:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010348b:	0f be c2             	movsbl %dl,%eax
f010348e:	85 c0                	test   %eax,%eax
f0103490:	74 27                	je     f01034b9 <vprintfmt+0x27b>
f0103492:	85 db                	test   %ebx,%ebx
f0103494:	78 9e                	js     f0103434 <vprintfmt+0x1f6>
f0103496:	83 eb 01             	sub    $0x1,%ebx
f0103499:	79 99                	jns    f0103434 <vprintfmt+0x1f6>
f010349b:	89 f8                	mov    %edi,%eax
f010349d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01034a0:	8b 75 08             	mov    0x8(%ebp),%esi
f01034a3:	89 c3                	mov    %eax,%ebx
f01034a5:	eb 1a                	jmp    f01034c1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01034a7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01034ab:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01034b2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01034b4:	83 eb 01             	sub    $0x1,%ebx
f01034b7:	eb 08                	jmp    f01034c1 <vprintfmt+0x283>
f01034b9:	89 fb                	mov    %edi,%ebx
f01034bb:	8b 75 08             	mov    0x8(%ebp),%esi
f01034be:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01034c1:	85 db                	test   %ebx,%ebx
f01034c3:	7f e2                	jg     f01034a7 <vprintfmt+0x269>
f01034c5:	89 75 08             	mov    %esi,0x8(%ebp)
f01034c8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01034cb:	e9 93 fd ff ff       	jmp    f0103263 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01034d0:	83 fa 01             	cmp    $0x1,%edx
f01034d3:	7e 16                	jle    f01034eb <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f01034d5:	8b 45 14             	mov    0x14(%ebp),%eax
f01034d8:	8d 50 08             	lea    0x8(%eax),%edx
f01034db:	89 55 14             	mov    %edx,0x14(%ebp)
f01034de:	8b 50 04             	mov    0x4(%eax),%edx
f01034e1:	8b 00                	mov    (%eax),%eax
f01034e3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01034e6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01034e9:	eb 32                	jmp    f010351d <vprintfmt+0x2df>
	else if (lflag)
f01034eb:	85 d2                	test   %edx,%edx
f01034ed:	74 18                	je     f0103507 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f01034ef:	8b 45 14             	mov    0x14(%ebp),%eax
f01034f2:	8d 50 04             	lea    0x4(%eax),%edx
f01034f5:	89 55 14             	mov    %edx,0x14(%ebp)
f01034f8:	8b 30                	mov    (%eax),%esi
f01034fa:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01034fd:	89 f0                	mov    %esi,%eax
f01034ff:	c1 f8 1f             	sar    $0x1f,%eax
f0103502:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103505:	eb 16                	jmp    f010351d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0103507:	8b 45 14             	mov    0x14(%ebp),%eax
f010350a:	8d 50 04             	lea    0x4(%eax),%edx
f010350d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103510:	8b 30                	mov    (%eax),%esi
f0103512:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0103515:	89 f0                	mov    %esi,%eax
f0103517:	c1 f8 1f             	sar    $0x1f,%eax
f010351a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010351d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103520:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103523:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103528:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010352c:	0f 89 80 00 00 00    	jns    f01035b2 <vprintfmt+0x374>
				putch('-', putdat);
f0103532:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103536:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010353d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103540:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103543:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103546:	f7 d8                	neg    %eax
f0103548:	83 d2 00             	adc    $0x0,%edx
f010354b:	f7 da                	neg    %edx
			}
			base = 10;
f010354d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103552:	eb 5e                	jmp    f01035b2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103554:	8d 45 14             	lea    0x14(%ebp),%eax
f0103557:	e8 63 fc ff ff       	call   f01031bf <getuint>
			base = 10;
f010355c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103561:	eb 4f                	jmp    f01035b2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0103563:	8d 45 14             	lea    0x14(%ebp),%eax
f0103566:	e8 54 fc ff ff       	call   f01031bf <getuint>
			base = 8;
f010356b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103570:	eb 40                	jmp    f01035b2 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f0103572:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103576:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010357d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103580:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103584:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010358b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010358e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103591:	8d 50 04             	lea    0x4(%eax),%edx
f0103594:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103597:	8b 00                	mov    (%eax),%eax
f0103599:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010359e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01035a3:	eb 0d                	jmp    f01035b2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01035a5:	8d 45 14             	lea    0x14(%ebp),%eax
f01035a8:	e8 12 fc ff ff       	call   f01031bf <getuint>
			base = 16;
f01035ad:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01035b2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f01035b6:	89 74 24 10          	mov    %esi,0x10(%esp)
f01035ba:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01035bd:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01035c1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035c5:	89 04 24             	mov    %eax,(%esp)
f01035c8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01035cc:	89 fa                	mov    %edi,%edx
f01035ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01035d1:	e8 fa fa ff ff       	call   f01030d0 <printnum>
			break;
f01035d6:	e9 88 fc ff ff       	jmp    f0103263 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01035db:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035df:	89 04 24             	mov    %eax,(%esp)
f01035e2:	ff 55 08             	call   *0x8(%ebp)
			break;
f01035e5:	e9 79 fc ff ff       	jmp    f0103263 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01035ea:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035ee:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01035f5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01035f8:	89 f3                	mov    %esi,%ebx
f01035fa:	eb 03                	jmp    f01035ff <vprintfmt+0x3c1>
f01035fc:	83 eb 01             	sub    $0x1,%ebx
f01035ff:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0103603:	75 f7                	jne    f01035fc <vprintfmt+0x3be>
f0103605:	e9 59 fc ff ff       	jmp    f0103263 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010360a:	83 c4 3c             	add    $0x3c,%esp
f010360d:	5b                   	pop    %ebx
f010360e:	5e                   	pop    %esi
f010360f:	5f                   	pop    %edi
f0103610:	5d                   	pop    %ebp
f0103611:	c3                   	ret    

f0103612 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103612:	55                   	push   %ebp
f0103613:	89 e5                	mov    %esp,%ebp
f0103615:	83 ec 28             	sub    $0x28,%esp
f0103618:	8b 45 08             	mov    0x8(%ebp),%eax
f010361b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010361e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103621:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103625:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103628:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010362f:	85 c0                	test   %eax,%eax
f0103631:	74 30                	je     f0103663 <vsnprintf+0x51>
f0103633:	85 d2                	test   %edx,%edx
f0103635:	7e 2c                	jle    f0103663 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103637:	8b 45 14             	mov    0x14(%ebp),%eax
f010363a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010363e:	8b 45 10             	mov    0x10(%ebp),%eax
f0103641:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103645:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103648:	89 44 24 04          	mov    %eax,0x4(%esp)
f010364c:	c7 04 24 f9 31 10 f0 	movl   $0xf01031f9,(%esp)
f0103653:	e8 e6 fb ff ff       	call   f010323e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103658:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010365b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010365e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103661:	eb 05                	jmp    f0103668 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103663:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103668:	c9                   	leave  
f0103669:	c3                   	ret    

f010366a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010366a:	55                   	push   %ebp
f010366b:	89 e5                	mov    %esp,%ebp
f010366d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103670:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103673:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103677:	8b 45 10             	mov    0x10(%ebp),%eax
f010367a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010367e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103681:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103685:	8b 45 08             	mov    0x8(%ebp),%eax
f0103688:	89 04 24             	mov    %eax,(%esp)
f010368b:	e8 82 ff ff ff       	call   f0103612 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103690:	c9                   	leave  
f0103691:	c3                   	ret    
f0103692:	66 90                	xchg   %ax,%ax
f0103694:	66 90                	xchg   %ax,%ax
f0103696:	66 90                	xchg   %ax,%ax
f0103698:	66 90                	xchg   %ax,%ax
f010369a:	66 90                	xchg   %ax,%ax
f010369c:	66 90                	xchg   %ax,%ax
f010369e:	66 90                	xchg   %ax,%ax

f01036a0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01036a0:	55                   	push   %ebp
f01036a1:	89 e5                	mov    %esp,%ebp
f01036a3:	57                   	push   %edi
f01036a4:	56                   	push   %esi
f01036a5:	53                   	push   %ebx
f01036a6:	83 ec 1c             	sub    $0x1c,%esp
f01036a9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01036ac:	85 c0                	test   %eax,%eax
f01036ae:	74 10                	je     f01036c0 <readline+0x20>
		cprintf("%s", prompt);
f01036b0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036b4:	c7 04 24 7c 4a 10 f0 	movl   $0xf0104a7c,(%esp)
f01036bb:	e8 d0 f6 ff ff       	call   f0102d90 <cprintf>

	i = 0;
	echoing = iscons(0);
f01036c0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01036c7:	e8 56 cf ff ff       	call   f0100622 <iscons>
f01036cc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01036ce:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01036d3:	e8 39 cf ff ff       	call   f0100611 <getchar>
f01036d8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01036da:	85 c0                	test   %eax,%eax
f01036dc:	79 17                	jns    f01036f5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01036de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036e2:	c7 04 24 4c 4f 10 f0 	movl   $0xf0104f4c,(%esp)
f01036e9:	e8 a2 f6 ff ff       	call   f0102d90 <cprintf>
			return NULL;
f01036ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01036f3:	eb 6d                	jmp    f0103762 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01036f5:	83 f8 7f             	cmp    $0x7f,%eax
f01036f8:	74 05                	je     f01036ff <readline+0x5f>
f01036fa:	83 f8 08             	cmp    $0x8,%eax
f01036fd:	75 19                	jne    f0103718 <readline+0x78>
f01036ff:	85 f6                	test   %esi,%esi
f0103701:	7e 15                	jle    f0103718 <readline+0x78>
			if (echoing)
f0103703:	85 ff                	test   %edi,%edi
f0103705:	74 0c                	je     f0103713 <readline+0x73>
				cputchar('\b');
f0103707:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010370e:	e8 ee ce ff ff       	call   f0100601 <cputchar>
			i--;
f0103713:	83 ee 01             	sub    $0x1,%esi
f0103716:	eb bb                	jmp    f01036d3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103718:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010371e:	7f 1c                	jg     f010373c <readline+0x9c>
f0103720:	83 fb 1f             	cmp    $0x1f,%ebx
f0103723:	7e 17                	jle    f010373c <readline+0x9c>
			if (echoing)
f0103725:	85 ff                	test   %edi,%edi
f0103727:	74 08                	je     f0103731 <readline+0x91>
				cputchar(c);
f0103729:	89 1c 24             	mov    %ebx,(%esp)
f010372c:	e8 d0 ce ff ff       	call   f0100601 <cputchar>
			buf[i++] = c;
f0103731:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f0103737:	8d 76 01             	lea    0x1(%esi),%esi
f010373a:	eb 97                	jmp    f01036d3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010373c:	83 fb 0d             	cmp    $0xd,%ebx
f010373f:	74 05                	je     f0103746 <readline+0xa6>
f0103741:	83 fb 0a             	cmp    $0xa,%ebx
f0103744:	75 8d                	jne    f01036d3 <readline+0x33>
			if (echoing)
f0103746:	85 ff                	test   %edi,%edi
f0103748:	74 0c                	je     f0103756 <readline+0xb6>
				cputchar('\n');
f010374a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103751:	e8 ab ce ff ff       	call   f0100601 <cputchar>
			buf[i] = 0;
f0103756:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f010375d:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f0103762:	83 c4 1c             	add    $0x1c,%esp
f0103765:	5b                   	pop    %ebx
f0103766:	5e                   	pop    %esi
f0103767:	5f                   	pop    %edi
f0103768:	5d                   	pop    %ebp
f0103769:	c3                   	ret    
f010376a:	66 90                	xchg   %ax,%ax
f010376c:	66 90                	xchg   %ax,%ax
f010376e:	66 90                	xchg   %ax,%ax

f0103770 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103770:	55                   	push   %ebp
f0103771:	89 e5                	mov    %esp,%ebp
f0103773:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103776:	b8 00 00 00 00       	mov    $0x0,%eax
f010377b:	eb 03                	jmp    f0103780 <strlen+0x10>
		n++;
f010377d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103780:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103784:	75 f7                	jne    f010377d <strlen+0xd>
		n++;
	return n;
}
f0103786:	5d                   	pop    %ebp
f0103787:	c3                   	ret    

f0103788 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103788:	55                   	push   %ebp
f0103789:	89 e5                	mov    %esp,%ebp
f010378b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010378e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103791:	b8 00 00 00 00       	mov    $0x0,%eax
f0103796:	eb 03                	jmp    f010379b <strnlen+0x13>
		n++;
f0103798:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010379b:	39 d0                	cmp    %edx,%eax
f010379d:	74 06                	je     f01037a5 <strnlen+0x1d>
f010379f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01037a3:	75 f3                	jne    f0103798 <strnlen+0x10>
		n++;
	return n;
}
f01037a5:	5d                   	pop    %ebp
f01037a6:	c3                   	ret    

f01037a7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01037a7:	55                   	push   %ebp
f01037a8:	89 e5                	mov    %esp,%ebp
f01037aa:	53                   	push   %ebx
f01037ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01037ae:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01037b1:	89 c2                	mov    %eax,%edx
f01037b3:	83 c2 01             	add    $0x1,%edx
f01037b6:	83 c1 01             	add    $0x1,%ecx
f01037b9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01037bd:	88 5a ff             	mov    %bl,-0x1(%edx)
f01037c0:	84 db                	test   %bl,%bl
f01037c2:	75 ef                	jne    f01037b3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01037c4:	5b                   	pop    %ebx
f01037c5:	5d                   	pop    %ebp
f01037c6:	c3                   	ret    

f01037c7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01037c7:	55                   	push   %ebp
f01037c8:	89 e5                	mov    %esp,%ebp
f01037ca:	53                   	push   %ebx
f01037cb:	83 ec 08             	sub    $0x8,%esp
f01037ce:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01037d1:	89 1c 24             	mov    %ebx,(%esp)
f01037d4:	e8 97 ff ff ff       	call   f0103770 <strlen>
	strcpy(dst + len, src);
f01037d9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01037dc:	89 54 24 04          	mov    %edx,0x4(%esp)
f01037e0:	01 d8                	add    %ebx,%eax
f01037e2:	89 04 24             	mov    %eax,(%esp)
f01037e5:	e8 bd ff ff ff       	call   f01037a7 <strcpy>
	return dst;
}
f01037ea:	89 d8                	mov    %ebx,%eax
f01037ec:	83 c4 08             	add    $0x8,%esp
f01037ef:	5b                   	pop    %ebx
f01037f0:	5d                   	pop    %ebp
f01037f1:	c3                   	ret    

f01037f2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01037f2:	55                   	push   %ebp
f01037f3:	89 e5                	mov    %esp,%ebp
f01037f5:	56                   	push   %esi
f01037f6:	53                   	push   %ebx
f01037f7:	8b 75 08             	mov    0x8(%ebp),%esi
f01037fa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01037fd:	89 f3                	mov    %esi,%ebx
f01037ff:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103802:	89 f2                	mov    %esi,%edx
f0103804:	eb 0f                	jmp    f0103815 <strncpy+0x23>
		*dst++ = *src;
f0103806:	83 c2 01             	add    $0x1,%edx
f0103809:	0f b6 01             	movzbl (%ecx),%eax
f010380c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010380f:	80 39 01             	cmpb   $0x1,(%ecx)
f0103812:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103815:	39 da                	cmp    %ebx,%edx
f0103817:	75 ed                	jne    f0103806 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103819:	89 f0                	mov    %esi,%eax
f010381b:	5b                   	pop    %ebx
f010381c:	5e                   	pop    %esi
f010381d:	5d                   	pop    %ebp
f010381e:	c3                   	ret    

f010381f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010381f:	55                   	push   %ebp
f0103820:	89 e5                	mov    %esp,%ebp
f0103822:	56                   	push   %esi
f0103823:	53                   	push   %ebx
f0103824:	8b 75 08             	mov    0x8(%ebp),%esi
f0103827:	8b 55 0c             	mov    0xc(%ebp),%edx
f010382a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010382d:	89 f0                	mov    %esi,%eax
f010382f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103833:	85 c9                	test   %ecx,%ecx
f0103835:	75 0b                	jne    f0103842 <strlcpy+0x23>
f0103837:	eb 1d                	jmp    f0103856 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103839:	83 c0 01             	add    $0x1,%eax
f010383c:	83 c2 01             	add    $0x1,%edx
f010383f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103842:	39 d8                	cmp    %ebx,%eax
f0103844:	74 0b                	je     f0103851 <strlcpy+0x32>
f0103846:	0f b6 0a             	movzbl (%edx),%ecx
f0103849:	84 c9                	test   %cl,%cl
f010384b:	75 ec                	jne    f0103839 <strlcpy+0x1a>
f010384d:	89 c2                	mov    %eax,%edx
f010384f:	eb 02                	jmp    f0103853 <strlcpy+0x34>
f0103851:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0103853:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0103856:	29 f0                	sub    %esi,%eax
}
f0103858:	5b                   	pop    %ebx
f0103859:	5e                   	pop    %esi
f010385a:	5d                   	pop    %ebp
f010385b:	c3                   	ret    

f010385c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010385c:	55                   	push   %ebp
f010385d:	89 e5                	mov    %esp,%ebp
f010385f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103862:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103865:	eb 06                	jmp    f010386d <strcmp+0x11>
		p++, q++;
f0103867:	83 c1 01             	add    $0x1,%ecx
f010386a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010386d:	0f b6 01             	movzbl (%ecx),%eax
f0103870:	84 c0                	test   %al,%al
f0103872:	74 04                	je     f0103878 <strcmp+0x1c>
f0103874:	3a 02                	cmp    (%edx),%al
f0103876:	74 ef                	je     f0103867 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103878:	0f b6 c0             	movzbl %al,%eax
f010387b:	0f b6 12             	movzbl (%edx),%edx
f010387e:	29 d0                	sub    %edx,%eax
}
f0103880:	5d                   	pop    %ebp
f0103881:	c3                   	ret    

f0103882 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103882:	55                   	push   %ebp
f0103883:	89 e5                	mov    %esp,%ebp
f0103885:	53                   	push   %ebx
f0103886:	8b 45 08             	mov    0x8(%ebp),%eax
f0103889:	8b 55 0c             	mov    0xc(%ebp),%edx
f010388c:	89 c3                	mov    %eax,%ebx
f010388e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103891:	eb 06                	jmp    f0103899 <strncmp+0x17>
		n--, p++, q++;
f0103893:	83 c0 01             	add    $0x1,%eax
f0103896:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103899:	39 d8                	cmp    %ebx,%eax
f010389b:	74 15                	je     f01038b2 <strncmp+0x30>
f010389d:	0f b6 08             	movzbl (%eax),%ecx
f01038a0:	84 c9                	test   %cl,%cl
f01038a2:	74 04                	je     f01038a8 <strncmp+0x26>
f01038a4:	3a 0a                	cmp    (%edx),%cl
f01038a6:	74 eb                	je     f0103893 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01038a8:	0f b6 00             	movzbl (%eax),%eax
f01038ab:	0f b6 12             	movzbl (%edx),%edx
f01038ae:	29 d0                	sub    %edx,%eax
f01038b0:	eb 05                	jmp    f01038b7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01038b2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01038b7:	5b                   	pop    %ebx
f01038b8:	5d                   	pop    %ebp
f01038b9:	c3                   	ret    

f01038ba <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01038ba:	55                   	push   %ebp
f01038bb:	89 e5                	mov    %esp,%ebp
f01038bd:	8b 45 08             	mov    0x8(%ebp),%eax
f01038c0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01038c4:	eb 07                	jmp    f01038cd <strchr+0x13>
		if (*s == c)
f01038c6:	38 ca                	cmp    %cl,%dl
f01038c8:	74 0f                	je     f01038d9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01038ca:	83 c0 01             	add    $0x1,%eax
f01038cd:	0f b6 10             	movzbl (%eax),%edx
f01038d0:	84 d2                	test   %dl,%dl
f01038d2:	75 f2                	jne    f01038c6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01038d4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01038d9:	5d                   	pop    %ebp
f01038da:	c3                   	ret    

f01038db <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01038db:	55                   	push   %ebp
f01038dc:	89 e5                	mov    %esp,%ebp
f01038de:	8b 45 08             	mov    0x8(%ebp),%eax
f01038e1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01038e5:	eb 07                	jmp    f01038ee <strfind+0x13>
		if (*s == c)
f01038e7:	38 ca                	cmp    %cl,%dl
f01038e9:	74 0a                	je     f01038f5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01038eb:	83 c0 01             	add    $0x1,%eax
f01038ee:	0f b6 10             	movzbl (%eax),%edx
f01038f1:	84 d2                	test   %dl,%dl
f01038f3:	75 f2                	jne    f01038e7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f01038f5:	5d                   	pop    %ebp
f01038f6:	c3                   	ret    

f01038f7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01038f7:	55                   	push   %ebp
f01038f8:	89 e5                	mov    %esp,%ebp
f01038fa:	57                   	push   %edi
f01038fb:	56                   	push   %esi
f01038fc:	53                   	push   %ebx
f01038fd:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103900:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103903:	85 c9                	test   %ecx,%ecx
f0103905:	74 36                	je     f010393d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103907:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010390d:	75 28                	jne    f0103937 <memset+0x40>
f010390f:	f6 c1 03             	test   $0x3,%cl
f0103912:	75 23                	jne    f0103937 <memset+0x40>
		c &= 0xFF;
f0103914:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103918:	89 d3                	mov    %edx,%ebx
f010391a:	c1 e3 08             	shl    $0x8,%ebx
f010391d:	89 d6                	mov    %edx,%esi
f010391f:	c1 e6 18             	shl    $0x18,%esi
f0103922:	89 d0                	mov    %edx,%eax
f0103924:	c1 e0 10             	shl    $0x10,%eax
f0103927:	09 f0                	or     %esi,%eax
f0103929:	09 c2                	or     %eax,%edx
f010392b:	89 d0                	mov    %edx,%eax
f010392d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010392f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103932:	fc                   	cld    
f0103933:	f3 ab                	rep stos %eax,%es:(%edi)
f0103935:	eb 06                	jmp    f010393d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103937:	8b 45 0c             	mov    0xc(%ebp),%eax
f010393a:	fc                   	cld    
f010393b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010393d:	89 f8                	mov    %edi,%eax
f010393f:	5b                   	pop    %ebx
f0103940:	5e                   	pop    %esi
f0103941:	5f                   	pop    %edi
f0103942:	5d                   	pop    %ebp
f0103943:	c3                   	ret    

f0103944 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103944:	55                   	push   %ebp
f0103945:	89 e5                	mov    %esp,%ebp
f0103947:	57                   	push   %edi
f0103948:	56                   	push   %esi
f0103949:	8b 45 08             	mov    0x8(%ebp),%eax
f010394c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010394f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103952:	39 c6                	cmp    %eax,%esi
f0103954:	73 35                	jae    f010398b <memmove+0x47>
f0103956:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103959:	39 d0                	cmp    %edx,%eax
f010395b:	73 2e                	jae    f010398b <memmove+0x47>
		s += n;
		d += n;
f010395d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0103960:	89 d6                	mov    %edx,%esi
f0103962:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103964:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010396a:	75 13                	jne    f010397f <memmove+0x3b>
f010396c:	f6 c1 03             	test   $0x3,%cl
f010396f:	75 0e                	jne    f010397f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103971:	83 ef 04             	sub    $0x4,%edi
f0103974:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103977:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010397a:	fd                   	std    
f010397b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010397d:	eb 09                	jmp    f0103988 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010397f:	83 ef 01             	sub    $0x1,%edi
f0103982:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103985:	fd                   	std    
f0103986:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103988:	fc                   	cld    
f0103989:	eb 1d                	jmp    f01039a8 <memmove+0x64>
f010398b:	89 f2                	mov    %esi,%edx
f010398d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010398f:	f6 c2 03             	test   $0x3,%dl
f0103992:	75 0f                	jne    f01039a3 <memmove+0x5f>
f0103994:	f6 c1 03             	test   $0x3,%cl
f0103997:	75 0a                	jne    f01039a3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103999:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010399c:	89 c7                	mov    %eax,%edi
f010399e:	fc                   	cld    
f010399f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01039a1:	eb 05                	jmp    f01039a8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01039a3:	89 c7                	mov    %eax,%edi
f01039a5:	fc                   	cld    
f01039a6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01039a8:	5e                   	pop    %esi
f01039a9:	5f                   	pop    %edi
f01039aa:	5d                   	pop    %ebp
f01039ab:	c3                   	ret    

f01039ac <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01039ac:	55                   	push   %ebp
f01039ad:	89 e5                	mov    %esp,%ebp
f01039af:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01039b2:	8b 45 10             	mov    0x10(%ebp),%eax
f01039b5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01039b9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039bc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01039c3:	89 04 24             	mov    %eax,(%esp)
f01039c6:	e8 79 ff ff ff       	call   f0103944 <memmove>
}
f01039cb:	c9                   	leave  
f01039cc:	c3                   	ret    

f01039cd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01039cd:	55                   	push   %ebp
f01039ce:	89 e5                	mov    %esp,%ebp
f01039d0:	56                   	push   %esi
f01039d1:	53                   	push   %ebx
f01039d2:	8b 55 08             	mov    0x8(%ebp),%edx
f01039d5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01039d8:	89 d6                	mov    %edx,%esi
f01039da:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01039dd:	eb 1a                	jmp    f01039f9 <memcmp+0x2c>
		if (*s1 != *s2)
f01039df:	0f b6 02             	movzbl (%edx),%eax
f01039e2:	0f b6 19             	movzbl (%ecx),%ebx
f01039e5:	38 d8                	cmp    %bl,%al
f01039e7:	74 0a                	je     f01039f3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01039e9:	0f b6 c0             	movzbl %al,%eax
f01039ec:	0f b6 db             	movzbl %bl,%ebx
f01039ef:	29 d8                	sub    %ebx,%eax
f01039f1:	eb 0f                	jmp    f0103a02 <memcmp+0x35>
		s1++, s2++;
f01039f3:	83 c2 01             	add    $0x1,%edx
f01039f6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01039f9:	39 f2                	cmp    %esi,%edx
f01039fb:	75 e2                	jne    f01039df <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01039fd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a02:	5b                   	pop    %ebx
f0103a03:	5e                   	pop    %esi
f0103a04:	5d                   	pop    %ebp
f0103a05:	c3                   	ret    

f0103a06 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103a06:	55                   	push   %ebp
f0103a07:	89 e5                	mov    %esp,%ebp
f0103a09:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a0c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103a0f:	89 c2                	mov    %eax,%edx
f0103a11:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103a14:	eb 07                	jmp    f0103a1d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103a16:	38 08                	cmp    %cl,(%eax)
f0103a18:	74 07                	je     f0103a21 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103a1a:	83 c0 01             	add    $0x1,%eax
f0103a1d:	39 d0                	cmp    %edx,%eax
f0103a1f:	72 f5                	jb     f0103a16 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103a21:	5d                   	pop    %ebp
f0103a22:	c3                   	ret    

f0103a23 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103a23:	55                   	push   %ebp
f0103a24:	89 e5                	mov    %esp,%ebp
f0103a26:	57                   	push   %edi
f0103a27:	56                   	push   %esi
f0103a28:	53                   	push   %ebx
f0103a29:	8b 55 08             	mov    0x8(%ebp),%edx
f0103a2c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103a2f:	eb 03                	jmp    f0103a34 <strtol+0x11>
		s++;
f0103a31:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103a34:	0f b6 0a             	movzbl (%edx),%ecx
f0103a37:	80 f9 09             	cmp    $0x9,%cl
f0103a3a:	74 f5                	je     f0103a31 <strtol+0xe>
f0103a3c:	80 f9 20             	cmp    $0x20,%cl
f0103a3f:	74 f0                	je     f0103a31 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103a41:	80 f9 2b             	cmp    $0x2b,%cl
f0103a44:	75 0a                	jne    f0103a50 <strtol+0x2d>
		s++;
f0103a46:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103a49:	bf 00 00 00 00       	mov    $0x0,%edi
f0103a4e:	eb 11                	jmp    f0103a61 <strtol+0x3e>
f0103a50:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103a55:	80 f9 2d             	cmp    $0x2d,%cl
f0103a58:	75 07                	jne    f0103a61 <strtol+0x3e>
		s++, neg = 1;
f0103a5a:	8d 52 01             	lea    0x1(%edx),%edx
f0103a5d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103a61:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0103a66:	75 15                	jne    f0103a7d <strtol+0x5a>
f0103a68:	80 3a 30             	cmpb   $0x30,(%edx)
f0103a6b:	75 10                	jne    f0103a7d <strtol+0x5a>
f0103a6d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103a71:	75 0a                	jne    f0103a7d <strtol+0x5a>
		s += 2, base = 16;
f0103a73:	83 c2 02             	add    $0x2,%edx
f0103a76:	b8 10 00 00 00       	mov    $0x10,%eax
f0103a7b:	eb 10                	jmp    f0103a8d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0103a7d:	85 c0                	test   %eax,%eax
f0103a7f:	75 0c                	jne    f0103a8d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103a81:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103a83:	80 3a 30             	cmpb   $0x30,(%edx)
f0103a86:	75 05                	jne    f0103a8d <strtol+0x6a>
		s++, base = 8;
f0103a88:	83 c2 01             	add    $0x1,%edx
f0103a8b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0103a8d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103a92:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103a95:	0f b6 0a             	movzbl (%edx),%ecx
f0103a98:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103a9b:	89 f0                	mov    %esi,%eax
f0103a9d:	3c 09                	cmp    $0x9,%al
f0103a9f:	77 08                	ja     f0103aa9 <strtol+0x86>
			dig = *s - '0';
f0103aa1:	0f be c9             	movsbl %cl,%ecx
f0103aa4:	83 e9 30             	sub    $0x30,%ecx
f0103aa7:	eb 20                	jmp    f0103ac9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0103aa9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103aac:	89 f0                	mov    %esi,%eax
f0103aae:	3c 19                	cmp    $0x19,%al
f0103ab0:	77 08                	ja     f0103aba <strtol+0x97>
			dig = *s - 'a' + 10;
f0103ab2:	0f be c9             	movsbl %cl,%ecx
f0103ab5:	83 e9 57             	sub    $0x57,%ecx
f0103ab8:	eb 0f                	jmp    f0103ac9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0103aba:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0103abd:	89 f0                	mov    %esi,%eax
f0103abf:	3c 19                	cmp    $0x19,%al
f0103ac1:	77 16                	ja     f0103ad9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0103ac3:	0f be c9             	movsbl %cl,%ecx
f0103ac6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103ac9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0103acc:	7d 0f                	jge    f0103add <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0103ace:	83 c2 01             	add    $0x1,%edx
f0103ad1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0103ad5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0103ad7:	eb bc                	jmp    f0103a95 <strtol+0x72>
f0103ad9:	89 d8                	mov    %ebx,%eax
f0103adb:	eb 02                	jmp    f0103adf <strtol+0xbc>
f0103add:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0103adf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103ae3:	74 05                	je     f0103aea <strtol+0xc7>
		*endptr = (char *) s;
f0103ae5:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103ae8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0103aea:	f7 d8                	neg    %eax
f0103aec:	85 ff                	test   %edi,%edi
f0103aee:	0f 44 c3             	cmove  %ebx,%eax
}
f0103af1:	5b                   	pop    %ebx
f0103af2:	5e                   	pop    %esi
f0103af3:	5f                   	pop    %edi
f0103af4:	5d                   	pop    %ebp
f0103af5:	c3                   	ret    
f0103af6:	66 90                	xchg   %ax,%ax
f0103af8:	66 90                	xchg   %ax,%ax
f0103afa:	66 90                	xchg   %ax,%ax
f0103afc:	66 90                	xchg   %ax,%ax
f0103afe:	66 90                	xchg   %ax,%ax

f0103b00 <__udivdi3>:
f0103b00:	55                   	push   %ebp
f0103b01:	57                   	push   %edi
f0103b02:	56                   	push   %esi
f0103b03:	83 ec 0c             	sub    $0xc,%esp
f0103b06:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103b0a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0103b0e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0103b12:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103b16:	85 c0                	test   %eax,%eax
f0103b18:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103b1c:	89 ea                	mov    %ebp,%edx
f0103b1e:	89 0c 24             	mov    %ecx,(%esp)
f0103b21:	75 2d                	jne    f0103b50 <__udivdi3+0x50>
f0103b23:	39 e9                	cmp    %ebp,%ecx
f0103b25:	77 61                	ja     f0103b88 <__udivdi3+0x88>
f0103b27:	85 c9                	test   %ecx,%ecx
f0103b29:	89 ce                	mov    %ecx,%esi
f0103b2b:	75 0b                	jne    f0103b38 <__udivdi3+0x38>
f0103b2d:	b8 01 00 00 00       	mov    $0x1,%eax
f0103b32:	31 d2                	xor    %edx,%edx
f0103b34:	f7 f1                	div    %ecx
f0103b36:	89 c6                	mov    %eax,%esi
f0103b38:	31 d2                	xor    %edx,%edx
f0103b3a:	89 e8                	mov    %ebp,%eax
f0103b3c:	f7 f6                	div    %esi
f0103b3e:	89 c5                	mov    %eax,%ebp
f0103b40:	89 f8                	mov    %edi,%eax
f0103b42:	f7 f6                	div    %esi
f0103b44:	89 ea                	mov    %ebp,%edx
f0103b46:	83 c4 0c             	add    $0xc,%esp
f0103b49:	5e                   	pop    %esi
f0103b4a:	5f                   	pop    %edi
f0103b4b:	5d                   	pop    %ebp
f0103b4c:	c3                   	ret    
f0103b4d:	8d 76 00             	lea    0x0(%esi),%esi
f0103b50:	39 e8                	cmp    %ebp,%eax
f0103b52:	77 24                	ja     f0103b78 <__udivdi3+0x78>
f0103b54:	0f bd e8             	bsr    %eax,%ebp
f0103b57:	83 f5 1f             	xor    $0x1f,%ebp
f0103b5a:	75 3c                	jne    f0103b98 <__udivdi3+0x98>
f0103b5c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103b60:	39 34 24             	cmp    %esi,(%esp)
f0103b63:	0f 86 9f 00 00 00    	jbe    f0103c08 <__udivdi3+0x108>
f0103b69:	39 d0                	cmp    %edx,%eax
f0103b6b:	0f 82 97 00 00 00    	jb     f0103c08 <__udivdi3+0x108>
f0103b71:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103b78:	31 d2                	xor    %edx,%edx
f0103b7a:	31 c0                	xor    %eax,%eax
f0103b7c:	83 c4 0c             	add    $0xc,%esp
f0103b7f:	5e                   	pop    %esi
f0103b80:	5f                   	pop    %edi
f0103b81:	5d                   	pop    %ebp
f0103b82:	c3                   	ret    
f0103b83:	90                   	nop
f0103b84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103b88:	89 f8                	mov    %edi,%eax
f0103b8a:	f7 f1                	div    %ecx
f0103b8c:	31 d2                	xor    %edx,%edx
f0103b8e:	83 c4 0c             	add    $0xc,%esp
f0103b91:	5e                   	pop    %esi
f0103b92:	5f                   	pop    %edi
f0103b93:	5d                   	pop    %ebp
f0103b94:	c3                   	ret    
f0103b95:	8d 76 00             	lea    0x0(%esi),%esi
f0103b98:	89 e9                	mov    %ebp,%ecx
f0103b9a:	8b 3c 24             	mov    (%esp),%edi
f0103b9d:	d3 e0                	shl    %cl,%eax
f0103b9f:	89 c6                	mov    %eax,%esi
f0103ba1:	b8 20 00 00 00       	mov    $0x20,%eax
f0103ba6:	29 e8                	sub    %ebp,%eax
f0103ba8:	89 c1                	mov    %eax,%ecx
f0103baa:	d3 ef                	shr    %cl,%edi
f0103bac:	89 e9                	mov    %ebp,%ecx
f0103bae:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103bb2:	8b 3c 24             	mov    (%esp),%edi
f0103bb5:	09 74 24 08          	or     %esi,0x8(%esp)
f0103bb9:	89 d6                	mov    %edx,%esi
f0103bbb:	d3 e7                	shl    %cl,%edi
f0103bbd:	89 c1                	mov    %eax,%ecx
f0103bbf:	89 3c 24             	mov    %edi,(%esp)
f0103bc2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103bc6:	d3 ee                	shr    %cl,%esi
f0103bc8:	89 e9                	mov    %ebp,%ecx
f0103bca:	d3 e2                	shl    %cl,%edx
f0103bcc:	89 c1                	mov    %eax,%ecx
f0103bce:	d3 ef                	shr    %cl,%edi
f0103bd0:	09 d7                	or     %edx,%edi
f0103bd2:	89 f2                	mov    %esi,%edx
f0103bd4:	89 f8                	mov    %edi,%eax
f0103bd6:	f7 74 24 08          	divl   0x8(%esp)
f0103bda:	89 d6                	mov    %edx,%esi
f0103bdc:	89 c7                	mov    %eax,%edi
f0103bde:	f7 24 24             	mull   (%esp)
f0103be1:	39 d6                	cmp    %edx,%esi
f0103be3:	89 14 24             	mov    %edx,(%esp)
f0103be6:	72 30                	jb     f0103c18 <__udivdi3+0x118>
f0103be8:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103bec:	89 e9                	mov    %ebp,%ecx
f0103bee:	d3 e2                	shl    %cl,%edx
f0103bf0:	39 c2                	cmp    %eax,%edx
f0103bf2:	73 05                	jae    f0103bf9 <__udivdi3+0xf9>
f0103bf4:	3b 34 24             	cmp    (%esp),%esi
f0103bf7:	74 1f                	je     f0103c18 <__udivdi3+0x118>
f0103bf9:	89 f8                	mov    %edi,%eax
f0103bfb:	31 d2                	xor    %edx,%edx
f0103bfd:	e9 7a ff ff ff       	jmp    f0103b7c <__udivdi3+0x7c>
f0103c02:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103c08:	31 d2                	xor    %edx,%edx
f0103c0a:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c0f:	e9 68 ff ff ff       	jmp    f0103b7c <__udivdi3+0x7c>
f0103c14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103c18:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103c1b:	31 d2                	xor    %edx,%edx
f0103c1d:	83 c4 0c             	add    $0xc,%esp
f0103c20:	5e                   	pop    %esi
f0103c21:	5f                   	pop    %edi
f0103c22:	5d                   	pop    %ebp
f0103c23:	c3                   	ret    
f0103c24:	66 90                	xchg   %ax,%ax
f0103c26:	66 90                	xchg   %ax,%ax
f0103c28:	66 90                	xchg   %ax,%ax
f0103c2a:	66 90                	xchg   %ax,%ax
f0103c2c:	66 90                	xchg   %ax,%ax
f0103c2e:	66 90                	xchg   %ax,%ax

f0103c30 <__umoddi3>:
f0103c30:	55                   	push   %ebp
f0103c31:	57                   	push   %edi
f0103c32:	56                   	push   %esi
f0103c33:	83 ec 14             	sub    $0x14,%esp
f0103c36:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103c3a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103c3e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0103c42:	89 c7                	mov    %eax,%edi
f0103c44:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c48:	8b 44 24 30          	mov    0x30(%esp),%eax
f0103c4c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103c50:	89 34 24             	mov    %esi,(%esp)
f0103c53:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103c57:	85 c0                	test   %eax,%eax
f0103c59:	89 c2                	mov    %eax,%edx
f0103c5b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103c5f:	75 17                	jne    f0103c78 <__umoddi3+0x48>
f0103c61:	39 fe                	cmp    %edi,%esi
f0103c63:	76 4b                	jbe    f0103cb0 <__umoddi3+0x80>
f0103c65:	89 c8                	mov    %ecx,%eax
f0103c67:	89 fa                	mov    %edi,%edx
f0103c69:	f7 f6                	div    %esi
f0103c6b:	89 d0                	mov    %edx,%eax
f0103c6d:	31 d2                	xor    %edx,%edx
f0103c6f:	83 c4 14             	add    $0x14,%esp
f0103c72:	5e                   	pop    %esi
f0103c73:	5f                   	pop    %edi
f0103c74:	5d                   	pop    %ebp
f0103c75:	c3                   	ret    
f0103c76:	66 90                	xchg   %ax,%ax
f0103c78:	39 f8                	cmp    %edi,%eax
f0103c7a:	77 54                	ja     f0103cd0 <__umoddi3+0xa0>
f0103c7c:	0f bd e8             	bsr    %eax,%ebp
f0103c7f:	83 f5 1f             	xor    $0x1f,%ebp
f0103c82:	75 5c                	jne    f0103ce0 <__umoddi3+0xb0>
f0103c84:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103c88:	39 3c 24             	cmp    %edi,(%esp)
f0103c8b:	0f 87 e7 00 00 00    	ja     f0103d78 <__umoddi3+0x148>
f0103c91:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103c95:	29 f1                	sub    %esi,%ecx
f0103c97:	19 c7                	sbb    %eax,%edi
f0103c99:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103c9d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103ca1:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103ca5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103ca9:	83 c4 14             	add    $0x14,%esp
f0103cac:	5e                   	pop    %esi
f0103cad:	5f                   	pop    %edi
f0103cae:	5d                   	pop    %ebp
f0103caf:	c3                   	ret    
f0103cb0:	85 f6                	test   %esi,%esi
f0103cb2:	89 f5                	mov    %esi,%ebp
f0103cb4:	75 0b                	jne    f0103cc1 <__umoddi3+0x91>
f0103cb6:	b8 01 00 00 00       	mov    $0x1,%eax
f0103cbb:	31 d2                	xor    %edx,%edx
f0103cbd:	f7 f6                	div    %esi
f0103cbf:	89 c5                	mov    %eax,%ebp
f0103cc1:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103cc5:	31 d2                	xor    %edx,%edx
f0103cc7:	f7 f5                	div    %ebp
f0103cc9:	89 c8                	mov    %ecx,%eax
f0103ccb:	f7 f5                	div    %ebp
f0103ccd:	eb 9c                	jmp    f0103c6b <__umoddi3+0x3b>
f0103ccf:	90                   	nop
f0103cd0:	89 c8                	mov    %ecx,%eax
f0103cd2:	89 fa                	mov    %edi,%edx
f0103cd4:	83 c4 14             	add    $0x14,%esp
f0103cd7:	5e                   	pop    %esi
f0103cd8:	5f                   	pop    %edi
f0103cd9:	5d                   	pop    %ebp
f0103cda:	c3                   	ret    
f0103cdb:	90                   	nop
f0103cdc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103ce0:	8b 04 24             	mov    (%esp),%eax
f0103ce3:	be 20 00 00 00       	mov    $0x20,%esi
f0103ce8:	89 e9                	mov    %ebp,%ecx
f0103cea:	29 ee                	sub    %ebp,%esi
f0103cec:	d3 e2                	shl    %cl,%edx
f0103cee:	89 f1                	mov    %esi,%ecx
f0103cf0:	d3 e8                	shr    %cl,%eax
f0103cf2:	89 e9                	mov    %ebp,%ecx
f0103cf4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cf8:	8b 04 24             	mov    (%esp),%eax
f0103cfb:	09 54 24 04          	or     %edx,0x4(%esp)
f0103cff:	89 fa                	mov    %edi,%edx
f0103d01:	d3 e0                	shl    %cl,%eax
f0103d03:	89 f1                	mov    %esi,%ecx
f0103d05:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103d09:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103d0d:	d3 ea                	shr    %cl,%edx
f0103d0f:	89 e9                	mov    %ebp,%ecx
f0103d11:	d3 e7                	shl    %cl,%edi
f0103d13:	89 f1                	mov    %esi,%ecx
f0103d15:	d3 e8                	shr    %cl,%eax
f0103d17:	89 e9                	mov    %ebp,%ecx
f0103d19:	09 f8                	or     %edi,%eax
f0103d1b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0103d1f:	f7 74 24 04          	divl   0x4(%esp)
f0103d23:	d3 e7                	shl    %cl,%edi
f0103d25:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103d29:	89 d7                	mov    %edx,%edi
f0103d2b:	f7 64 24 08          	mull   0x8(%esp)
f0103d2f:	39 d7                	cmp    %edx,%edi
f0103d31:	89 c1                	mov    %eax,%ecx
f0103d33:	89 14 24             	mov    %edx,(%esp)
f0103d36:	72 2c                	jb     f0103d64 <__umoddi3+0x134>
f0103d38:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0103d3c:	72 22                	jb     f0103d60 <__umoddi3+0x130>
f0103d3e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103d42:	29 c8                	sub    %ecx,%eax
f0103d44:	19 d7                	sbb    %edx,%edi
f0103d46:	89 e9                	mov    %ebp,%ecx
f0103d48:	89 fa                	mov    %edi,%edx
f0103d4a:	d3 e8                	shr    %cl,%eax
f0103d4c:	89 f1                	mov    %esi,%ecx
f0103d4e:	d3 e2                	shl    %cl,%edx
f0103d50:	89 e9                	mov    %ebp,%ecx
f0103d52:	d3 ef                	shr    %cl,%edi
f0103d54:	09 d0                	or     %edx,%eax
f0103d56:	89 fa                	mov    %edi,%edx
f0103d58:	83 c4 14             	add    $0x14,%esp
f0103d5b:	5e                   	pop    %esi
f0103d5c:	5f                   	pop    %edi
f0103d5d:	5d                   	pop    %ebp
f0103d5e:	c3                   	ret    
f0103d5f:	90                   	nop
f0103d60:	39 d7                	cmp    %edx,%edi
f0103d62:	75 da                	jne    f0103d3e <__umoddi3+0x10e>
f0103d64:	8b 14 24             	mov    (%esp),%edx
f0103d67:	89 c1                	mov    %eax,%ecx
f0103d69:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0103d6d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0103d71:	eb cb                	jmp    f0103d3e <__umoddi3+0x10e>
f0103d73:	90                   	nop
f0103d74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d78:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0103d7c:	0f 82 0f ff ff ff    	jb     f0103c91 <__umoddi3+0x61>
f0103d82:	e9 1a ff ff ff       	jmp    f0103ca1 <__umoddi3+0x71>
