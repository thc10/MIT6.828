
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
f0100015:	b8 00 70 11 00       	mov    $0x117000,%eax
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
f0100034:	bc 00 70 11 f0       	mov    $0xf0117000,%esp

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
f0100046:	b8 70 99 11 f0       	mov    $0xf0119970,%eax
f010004b:	2d 00 93 11 f0       	sub    $0xf0119300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 93 11 f0 	movl   $0xf0119300,(%esp)
f0100063:	e8 9f 3e 00 00       	call   f0103f07 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 a2 04 00 00       	call   f010050f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 a0 43 10 f0 	movl   $0xf01043a0,(%esp)
f010007c:	e8 25 33 00 00       	call   f01033a6 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 7e 17 00 00       	call   f0101804 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 d2 0c 00 00       	call   f0100d64 <monitor>
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
f010009f:	83 3d 60 99 11 f0 00 	cmpl   $0x0,0xf0119960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 99 11 f0    	mov    %esi,0xf0119960

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
f01000c1:	c7 04 24 bb 43 10 f0 	movl   $0xf01043bb,(%esp)
f01000c8:	e8 d9 32 00 00       	call   f01033a6 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 9a 32 00 00       	call   f0103373 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 23 47 10 f0 	movl   $0xf0104723,(%esp)
f01000e0:	e8 c1 32 00 00       	call   f01033a6 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 73 0c 00 00       	call   f0100d64 <monitor>
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
f010010b:	c7 04 24 d3 43 10 f0 	movl   $0xf01043d3,(%esp)
f0100112:	e8 8f 32 00 00       	call   f01033a6 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 4d 32 00 00       	call   f0103373 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 23 47 10 f0 	movl   $0xf0104723,(%esp)
f010012d:	e8 74 32 00 00       	call   f01033a6 <cprintf>
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
f010016b:	a1 24 95 11 f0       	mov    0xf0119524,%eax
f0100170:	8d 48 01             	lea    0x1(%eax),%ecx
f0100173:	89 0d 24 95 11 f0    	mov    %ecx,0xf0119524
f0100179:	88 90 20 93 11 f0    	mov    %dl,-0xfee6ce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010017f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100185:	75 0a                	jne    f0100191 <cons_intr+0x35>
			cons.wpos = 0;
f0100187:	c7 05 24 95 11 f0 00 	movl   $0x0,0xf0119524
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
f01001bf:	83 0d 00 93 11 f0 40 	orl    $0x40,0xf0119300
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
f01001d7:	8b 0d 00 93 11 f0    	mov    0xf0119300,%ecx
f01001dd:	89 cb                	mov    %ecx,%ebx
f01001df:	83 e3 40             	and    $0x40,%ebx
f01001e2:	83 e0 7f             	and    $0x7f,%eax
f01001e5:	85 db                	test   %ebx,%ebx
f01001e7:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001ea:	0f b6 d2             	movzbl %dl,%edx
f01001ed:	0f b6 82 40 45 10 f0 	movzbl -0xfefbac0(%edx),%eax
f01001f4:	83 c8 40             	or     $0x40,%eax
f01001f7:	0f b6 c0             	movzbl %al,%eax
f01001fa:	f7 d0                	not    %eax
f01001fc:	21 c1                	and    %eax,%ecx
f01001fe:	89 0d 00 93 11 f0    	mov    %ecx,0xf0119300
		return 0;
f0100204:	b8 00 00 00 00       	mov    $0x0,%eax
f0100209:	e9 a3 00 00 00       	jmp    f01002b1 <kbd_proc_data+0x111>
	} else if (shift & E0ESC) {
f010020e:	8b 0d 00 93 11 f0    	mov    0xf0119300,%ecx
f0100214:	f6 c1 40             	test   $0x40,%cl
f0100217:	74 0e                	je     f0100227 <kbd_proc_data+0x87>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100219:	83 c8 80             	or     $0xffffff80,%eax
f010021c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010021e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100221:	89 0d 00 93 11 f0    	mov    %ecx,0xf0119300
	}

	shift |= shiftcode[data];
f0100227:	0f b6 d2             	movzbl %dl,%edx
f010022a:	0f b6 82 40 45 10 f0 	movzbl -0xfefbac0(%edx),%eax
f0100231:	0b 05 00 93 11 f0    	or     0xf0119300,%eax
	shift ^= togglecode[data];
f0100237:	0f b6 8a 40 44 10 f0 	movzbl -0xfefbbc0(%edx),%ecx
f010023e:	31 c8                	xor    %ecx,%eax
f0100240:	a3 00 93 11 f0       	mov    %eax,0xf0119300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100245:	89 c1                	mov    %eax,%ecx
f0100247:	83 e1 03             	and    $0x3,%ecx
f010024a:	8b 0c 8d 20 44 10 f0 	mov    -0xfefbbe0(,%ecx,4),%ecx
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
f010028a:	c7 04 24 ed 43 10 f0 	movl   $0xf01043ed,(%esp)
f0100291:	e8 10 31 00 00       	call   f01033a6 <cprintf>
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
f010036c:	0f b7 05 28 95 11 f0 	movzwl 0xf0119528,%eax
f0100373:	66 85 c0             	test   %ax,%ax
f0100376:	0f 84 e5 00 00 00    	je     f0100461 <cons_putc+0x1aa>
			crt_pos--;
f010037c:	83 e8 01             	sub    $0x1,%eax
f010037f:	66 a3 28 95 11 f0    	mov    %ax,0xf0119528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100385:	0f b7 c0             	movzwl %ax,%eax
f0100388:	66 81 e7 00 ff       	and    $0xff00,%di
f010038d:	83 cf 20             	or     $0x20,%edi
f0100390:	8b 15 2c 95 11 f0    	mov    0xf011952c,%edx
f0100396:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010039a:	eb 78                	jmp    f0100414 <cons_putc+0x15d>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010039c:	66 83 05 28 95 11 f0 	addw   $0x50,0xf0119528
f01003a3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a4:	0f b7 05 28 95 11 f0 	movzwl 0xf0119528,%eax
f01003ab:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003b1:	c1 e8 16             	shr    $0x16,%eax
f01003b4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b7:	c1 e0 04             	shl    $0x4,%eax
f01003ba:	66 a3 28 95 11 f0    	mov    %ax,0xf0119528
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
f01003f6:	0f b7 05 28 95 11 f0 	movzwl 0xf0119528,%eax
f01003fd:	8d 50 01             	lea    0x1(%eax),%edx
f0100400:	66 89 15 28 95 11 f0 	mov    %dx,0xf0119528
f0100407:	0f b7 c0             	movzwl %ax,%eax
f010040a:	8b 15 2c 95 11 f0    	mov    0xf011952c,%edx
f0100410:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100414:	66 81 3d 28 95 11 f0 	cmpw   $0x7cf,0xf0119528
f010041b:	cf 07 
f010041d:	76 42                	jbe    f0100461 <cons_putc+0x1aa>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041f:	a1 2c 95 11 f0       	mov    0xf011952c,%eax
f0100424:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010042b:	00 
f010042c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100432:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100436:	89 04 24             	mov    %eax,(%esp)
f0100439:	e8 16 3b 00 00       	call   f0103f54 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010043e:	8b 15 2c 95 11 f0    	mov    0xf011952c,%edx
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
f0100459:	66 83 2d 28 95 11 f0 	subw   $0x50,0xf0119528
f0100460:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100461:	8b 0d 30 95 11 f0    	mov    0xf0119530,%ecx
f0100467:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046c:	89 ca                	mov    %ecx,%edx
f010046e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046f:	0f b7 1d 28 95 11 f0 	movzwl 0xf0119528,%ebx
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
f0100497:	80 3d 34 95 11 f0 00 	cmpb   $0x0,0xf0119534
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
f01004d5:	a1 20 95 11 f0       	mov    0xf0119520,%eax
f01004da:	3b 05 24 95 11 f0    	cmp    0xf0119524,%eax
f01004e0:	74 26                	je     f0100508 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e2:	8d 50 01             	lea    0x1(%eax),%edx
f01004e5:	89 15 20 95 11 f0    	mov    %edx,0xf0119520
f01004eb:	0f b6 88 20 93 11 f0 	movzbl -0xfee6ce0(%eax),%ecx
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
f01004fc:	c7 05 20 95 11 f0 00 	movl   $0x0,0xf0119520
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
f0100535:	c7 05 30 95 11 f0 b4 	movl   $0x3b4,0xf0119530
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
f010054d:	c7 05 30 95 11 f0 d4 	movl   $0x3d4,0xf0119530
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
f010055c:	8b 0d 30 95 11 f0    	mov    0xf0119530,%ecx
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
f0100581:	89 3d 2c 95 11 f0    	mov    %edi,0xf011952c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100587:	0f b6 d8             	movzbl %al,%ebx
f010058a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010058c:	66 89 35 28 95 11 f0 	mov    %si,0xf0119528
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
f01005dd:	88 0d 34 95 11 f0    	mov    %cl,0xf0119534
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
f01005ed:	c7 04 24 f9 43 10 f0 	movl   $0xf01043f9,(%esp)
f01005f4:	e8 ad 2d 00 00       	call   f01033a6 <cprintf>
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
f0100633:	57                   	push   %edi
f0100634:	56                   	push   %esi
f0100635:	53                   	push   %ebx
f0100636:	83 ec 1c             	sub    $0x1c,%esp
f0100639:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010063c:	bb 44 4d 10 f0       	mov    $0xf0104d44,%ebx
f0100641:	be a4 4d 10 f0       	mov    $0xf0104da4,%esi
	int i;

	if(argc == 2){
f0100646:	83 7d 08 02          	cmpl   $0x2,0x8(%ebp)
f010064a:	75 2d                	jne    f0100679 <mon_help+0x49>
f010064c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100651:	89 d8                	mov    %ebx,%eax
f0100653:	c1 e0 04             	shl    $0x4,%eax
		for (i = 0; i < ARRAY_SIZE(commands); i++)
			if (strcmp(argv[1], commands[i].name) == 0)
f0100656:	8b 80 40 4d 10 f0    	mov    -0xfefb2c0(%eax),%eax
f010065c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100660:	8b 47 04             	mov    0x4(%edi),%eax
f0100663:	89 04 24             	mov    %eax,(%esp)
f0100666:	e8 01 38 00 00       	call   f0103e6c <strcmp>
f010066b:	85 c0                	test   %eax,%eax
f010066d:	74 41                	je     f01006b0 <mon_help+0x80>
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	if(argc == 2){
		for (i = 0; i < ARRAY_SIZE(commands); i++)
f010066f:	83 c3 01             	add    $0x1,%ebx
f0100672:	83 fb 06             	cmp    $0x6,%ebx
f0100675:	75 da                	jne    f0100651 <mon_help+0x21>
f0100677:	eb 22                	jmp    f010069b <mon_help+0x6b>
			cprintf("No command : %s !\n", argv[1]);
		else
			cprintf("%s\nUsage : %s\n", commands[i].desc, commands[i].usage);
	}else{
		for (i = 0; i < ARRAY_SIZE(commands); i++)
			cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100679:	8b 03                	mov    (%ebx),%eax
f010067b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010067f:	8b 43 fc             	mov    -0x4(%ebx),%eax
f0100682:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100686:	c7 04 24 40 46 10 f0 	movl   $0xf0104640,(%esp)
f010068d:	e8 14 2d 00 00       	call   f01033a6 <cprintf>
f0100692:	83 c3 10             	add    $0x10,%ebx
		if (i >= ARRAY_SIZE(commands))
			cprintf("No command : %s !\n", argv[1]);
		else
			cprintf("%s\nUsage : %s\n", commands[i].desc, commands[i].usage);
	}else{
		for (i = 0; i < ARRAY_SIZE(commands); i++)
f0100695:	39 f3                	cmp    %esi,%ebx
f0100697:	75 e0                	jne    f0100679 <mon_help+0x49>
f0100699:	eb 3c                	jmp    f01006d7 <mon_help+0xa7>
	if(argc == 2){
		for (i = 0; i < ARRAY_SIZE(commands); i++)
			if (strcmp(argv[1], commands[i].name) == 0)
				break;
		if (i >= ARRAY_SIZE(commands))
			cprintf("No command : %s !\n", argv[1]);
f010069b:	8b 47 04             	mov    0x4(%edi),%eax
f010069e:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006a2:	c7 04 24 49 46 10 f0 	movl   $0xf0104649,(%esp)
f01006a9:	e8 f8 2c 00 00       	call   f01033a6 <cprintf>
f01006ae:	eb 27                	jmp    f01006d7 <mon_help+0xa7>
		else
			cprintf("%s\nUsage : %s\n", commands[i].desc, commands[i].usage);
f01006b0:	89 d8                	mov    %ebx,%eax
f01006b2:	c1 e0 04             	shl    $0x4,%eax
f01006b5:	8b 90 48 4d 10 f0    	mov    -0xfefb2b8(%eax),%edx
f01006bb:	05 40 4d 10 f0       	add    $0xf0104d40,%eax
f01006c0:	89 54 24 08          	mov    %edx,0x8(%esp)
f01006c4:	8b 40 04             	mov    0x4(%eax),%eax
f01006c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006cb:	c7 04 24 5c 46 10 f0 	movl   $0xf010465c,(%esp)
f01006d2:	e8 cf 2c 00 00       	call   f01033a6 <cprintf>
	}else{
		for (i = 0; i < ARRAY_SIZE(commands); i++)
			cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	}
	return 0;
}
f01006d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01006dc:	83 c4 1c             	add    $0x1c,%esp
f01006df:	5b                   	pop    %ebx
f01006e0:	5e                   	pop    %esi
f01006e1:	5f                   	pop    %edi
f01006e2:	5d                   	pop    %ebp
f01006e3:	c3                   	ret    

f01006e4 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006e4:	55                   	push   %ebp
f01006e5:	89 e5                	mov    %esp,%ebp
f01006e7:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006ea:	c7 04 24 6b 46 10 f0 	movl   $0xf010466b,(%esp)
f01006f1:	e8 b0 2c 00 00       	call   f01033a6 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006f6:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006fd:	00 
f01006fe:	c7 04 24 d8 47 10 f0 	movl   $0xf01047d8,(%esp)
f0100705:	e8 9c 2c 00 00       	call   f01033a6 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010070a:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100711:	00 
f0100712:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100719:	f0 
f010071a:	c7 04 24 00 48 10 f0 	movl   $0xf0104800,(%esp)
f0100721:	e8 80 2c 00 00       	call   f01033a6 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100726:	c7 44 24 08 97 43 10 	movl   $0x104397,0x8(%esp)
f010072d:	00 
f010072e:	c7 44 24 04 97 43 10 	movl   $0xf0104397,0x4(%esp)
f0100735:	f0 
f0100736:	c7 04 24 24 48 10 f0 	movl   $0xf0104824,(%esp)
f010073d:	e8 64 2c 00 00       	call   f01033a6 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100742:	c7 44 24 08 00 93 11 	movl   $0x119300,0x8(%esp)
f0100749:	00 
f010074a:	c7 44 24 04 00 93 11 	movl   $0xf0119300,0x4(%esp)
f0100751:	f0 
f0100752:	c7 04 24 48 48 10 f0 	movl   $0xf0104848,(%esp)
f0100759:	e8 48 2c 00 00       	call   f01033a6 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010075e:	c7 44 24 08 70 99 11 	movl   $0x119970,0x8(%esp)
f0100765:	00 
f0100766:	c7 44 24 04 70 99 11 	movl   $0xf0119970,0x4(%esp)
f010076d:	f0 
f010076e:	c7 04 24 6c 48 10 f0 	movl   $0xf010486c,(%esp)
f0100775:	e8 2c 2c 00 00       	call   f01033a6 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010077a:	b8 6f 9d 11 f0       	mov    $0xf0119d6f,%eax
f010077f:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100784:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100789:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010078f:	85 c0                	test   %eax,%eax
f0100791:	0f 48 c2             	cmovs  %edx,%eax
f0100794:	c1 f8 0a             	sar    $0xa,%eax
f0100797:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079b:	c7 04 24 90 48 10 f0 	movl   $0xf0104890,(%esp)
f01007a2:	e8 ff 2b 00 00       	call   f01033a6 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01007a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ac:	c9                   	leave  
f01007ad:	c3                   	ret    

f01007ae <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007ae:	55                   	push   %ebp
f01007af:	89 e5                	mov    %esp,%ebp
f01007b1:	57                   	push   %edi
f01007b2:	56                   	push   %esi
f01007b3:	53                   	push   %ebx
f01007b4:	83 ec 4c             	sub    $0x4c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01007b7:	89 ee                	mov    %ebp,%esi
	// 每次压栈的顺序依次是：保存ebx、保存ebp、返回地址eip、五个参数
	uint32_t eip;
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f01007b9:	c7 04 24 84 46 10 f0 	movl   $0xf0104684,(%esp)
f01007c0:	e8 e1 2b 00 00       	call   f01033a6 <cprintf>
	while(ebp != 0){
f01007c5:	eb 77                	jmp    f010083e <mon_backtrace+0x90>
		eip = *((uint32_t *)ebp + 1);
f01007c7:	8b 7e 04             	mov    0x4(%esi),%edi
		debuginfo_eip(eip, &info);
f01007ca:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007cd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007d1:	89 3c 24             	mov    %edi,(%esp)
f01007d4:	e8 c4 2c 00 00       	call   f010349d <debuginfo_eip>
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
f01007d9:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01007dd:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007e1:	c7 04 24 96 46 10 f0 	movl   $0xf0104696,(%esp)
f01007e8:	e8 b9 2b 00 00       	call   f01033a6 <cprintf>
		for(int i = 2; i < 7; i++){
f01007ed:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x", *((uint32_t*)ebp + i));
f01007f2:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f01007f5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007f9:	c7 04 24 b1 46 10 f0 	movl   $0xf01046b1,(%esp)
f0100800:	e8 a1 2b 00 00       	call   f01033a6 <cprintf>
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
		eip = *((uint32_t *)ebp + 1);
		debuginfo_eip(eip, &info);
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
		for(int i = 2; i < 7; i++){
f0100805:	83 c3 01             	add    $0x1,%ebx
f0100808:	83 fb 07             	cmp    $0x7,%ebx
f010080b:	75 e5                	jne    f01007f2 <mon_backtrace+0x44>
			cprintf(" %08x", *((uint32_t*)ebp + i));
		}
		cprintf("\n         %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
f010080d:	2b 7d e0             	sub    -0x20(%ebp),%edi
f0100810:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0100814:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100817:	89 44 24 10          	mov    %eax,0x10(%esp)
f010081b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010081e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100822:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100825:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100829:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010082c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100830:	c7 04 24 b7 46 10 f0 	movl   $0xf01046b7,(%esp)
f0100837:	e8 6a 2b 00 00       	call   f01033a6 <cprintf>
		ebp = *((uint32_t *)ebp);
f010083c:	8b 36                	mov    (%esi),%esi
	// 每次压栈的顺序依次是：保存ebx、保存ebp、返回地址eip、五个参数
	uint32_t eip;
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f010083e:	85 f6                	test   %esi,%esi
f0100840:	75 85                	jne    f01007c7 <mon_backtrace+0x19>
		}
		cprintf("\n         %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
		ebp = *((uint32_t *)ebp);
	}
	return 0;
}
f0100842:	b8 00 00 00 00       	mov    $0x0,%eax
f0100847:	83 c4 4c             	add    $0x4c,%esp
f010084a:	5b                   	pop    %ebx
f010084b:	5e                   	pop    %esi
f010084c:	5f                   	pop    %edi
f010084d:	5d                   	pop    %ebp
f010084e:	c3                   	ret    

f010084f <mon_showmappings>:

int
mon_showmappings(int argc, char **argv, struct Trapframe *tf)
{
f010084f:	55                   	push   %ebp
f0100850:	89 e5                	mov    %esp,%ebp
f0100852:	57                   	push   %edi
f0100853:	56                   	push   %esi
f0100854:	53                   	push   %ebx
f0100855:	81 ec 8c 00 00 00    	sub    $0x8c,%esp
f010085b:	8b 75 08             	mov    0x8(%ebp),%esi
f010085e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// check arguments num
	if (argc != 3 && argc != 2){
f0100861:	8d 46 fe             	lea    -0x2(%esi),%eax
f0100864:	83 f8 01             	cmp    $0x1,%eax
f0100867:	76 11                	jbe    f010087a <mon_showmappings+0x2b>
		cprintf("Usage: showmappings start_addr (end_addr) \n");
f0100869:	c7 04 24 bc 48 10 f0 	movl   $0xf01048bc,(%esp)
f0100870:	e8 31 2b 00 00       	call   f01033a6 <cprintf>
		return 0;
f0100875:	e9 e7 01 00 00       	jmp    f0100a61 <mon_showmappings+0x212>
	 * nptr : the string who is to change to a interger
	 * endptr : if the nptr is invalid, write the first invalid char in endptr
	 * base : the type of number
	*/
	char *errStr;
	uintptr_t start_addr = strtol(argv[1], &errStr, 16);
f010087a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100881:	00 
f0100882:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100885:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100889:	8b 43 04             	mov    0x4(%ebx),%eax
f010088c:	89 04 24             	mov    %eax,(%esp)
f010088f:	e8 9f 37 00 00       	call   f0104033 <strtol>
	if (*errStr){
f0100894:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100897:	80 3a 00             	cmpb   $0x0,(%edx)
f010089a:	74 18                	je     f01008b4 <mon_showmappings+0x65>
		cprintf("error : invalid input : %s .\n", argv[1]);
f010089c:	8b 43 04             	mov    0x4(%ebx),%eax
f010089f:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008a3:	c7 04 24 d1 46 10 f0 	movl   $0xf01046d1,(%esp)
f01008aa:	e8 f7 2a 00 00       	call   f01033a6 <cprintf>
		return 0;
f01008af:	e9 ad 01 00 00       	jmp    f0100a61 <mon_showmappings+0x212>
	}
	start_addr = ROUNDDOWN(start_addr, PGSIZE);
f01008b4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008b9:	89 c7                	mov    %eax,%edi
	uintptr_t end_addr;
	if (argc == 2)
f01008bb:	83 fe 02             	cmp    $0x2,%esi
f01008be:	75 0e                	jne    f01008ce <mon_showmappings+0x7f>
		end_addr = start_addr + PGSIZE;
f01008c0:	8d 80 00 10 00 00    	lea    0x1000(%eax),%eax
f01008c6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01008c9:	e9 8a 01 00 00       	jmp    f0100a58 <mon_showmappings+0x209>
	else{
		end_addr = strtol(argv[2], &errStr, 16);
f01008ce:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f01008d5:	00 
f01008d6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01008d9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008dd:	8b 43 08             	mov    0x8(%ebx),%eax
f01008e0:	89 04 24             	mov    %eax,(%esp)
f01008e3:	e8 4b 37 00 00       	call   f0104033 <strtol>
		if (*errStr){
			cprintf("error : invalid input : %s .\n", argv[2]);
			return 0;
		}
		end_addr = ROUNDUP(end_addr, PGSIZE);
f01008e8:	05 ff 0f 00 00       	add    $0xfff,%eax
f01008ed:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008f2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	uintptr_t end_addr;
	if (argc == 2)
		end_addr = start_addr + PGSIZE;
	else{
		end_addr = strtol(argv[2], &errStr, 16);
		if (*errStr){
f01008f5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01008f8:	80 38 00             	cmpb   $0x0,(%eax)
f01008fb:	0f 84 57 01 00 00    	je     f0100a58 <mon_showmappings+0x209>
			cprintf("error : invalid input : %s .\n", argv[2]);
f0100901:	8b 43 08             	mov    0x8(%ebx),%eax
f0100904:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100908:	c7 04 24 d1 46 10 f0 	movl   $0xf01046d1,(%esp)
f010090f:	e8 92 2a 00 00       	call   f01033a6 <cprintf>
			return 0;
f0100914:	e9 48 01 00 00       	jmp    f0100a61 <mon_showmappings+0x212>
		}
		end_addr = ROUNDUP(end_addr, PGSIZE);
	}

	while(start_addr < end_addr){
		pte_t *cur_pte = pgdir_walk(kern_pgdir, (void *)start_addr, 0);
f0100919:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100920:	00 
f0100921:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100925:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f010092a:	89 04 24             	mov    %eax,(%esp)
f010092d:	e8 46 0c 00 00       	call   f0101578 <pgdir_walk>
f0100932:	89 c3                	mov    %eax,%ebx
		if(!cur_pte || !(*cur_pte & PTE_P)){
f0100934:	85 c0                	test   %eax,%eax
f0100936:	74 06                	je     f010093e <mon_showmappings+0xef>
f0100938:	8b 00                	mov    (%eax),%eax
f010093a:	a8 01                	test   $0x1,%al
f010093c:	75 15                	jne    f0100953 <mon_showmappings+0x104>
			cprintf("virtual address 0x%08x not mapped.\n", start_addr);
f010093e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100942:	c7 04 24 e8 48 10 f0 	movl   $0xf01048e8,(%esp)
f0100949:	e8 58 2a 00 00       	call   f01033a6 <cprintf>
f010094e:	e9 ff 00 00 00       	jmp    f0100a52 <mon_showmappings+0x203>
		}else{
			cprintf("virtual address 0x%08x physical address 0x%08x permission: ", 
f0100953:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100958:	89 44 24 08          	mov    %eax,0x8(%esp)
f010095c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100960:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0100967:	e8 3a 2a 00 00       	call   f01033a6 <cprintf>
				start_addr, PTE_ADDR(*cur_pte));
			char perm_Global = (*cur_pte & PTE_G) ? 'G' : '-';
f010096c:	8b 03                	mov    (%ebx),%eax
f010096e:	89 c2                	mov    %eax,%edx
f0100970:	81 e2 00 01 00 00    	and    $0x100,%edx
f0100976:	83 fa 01             	cmp    $0x1,%edx
f0100979:	19 c9                	sbb    %ecx,%ecx
f010097b:	89 4d b8             	mov    %ecx,-0x48(%ebp)
f010097e:	80 65 b8 e6          	andb   $0xe6,-0x48(%ebp)
f0100982:	80 45 b8 47          	addb   $0x47,-0x48(%ebp)
			char perm_PageSize = (*cur_pte & PTE_PS) ? 'S' : '-';
f0100986:	89 c2                	mov    %eax,%edx
f0100988:	81 e2 80 00 00 00    	and    $0x80,%edx
f010098e:	83 fa 01             	cmp    $0x1,%edx
f0100991:	19 d2                	sbb    %edx,%edx
f0100993:	83 e2 da             	and    $0xffffffda,%edx
f0100996:	83 c2 53             	add    $0x53,%edx
			char perm_Dirty = (*cur_pte & PTE_D) ? 'D' : '-';
f0100999:	89 c1                	mov    %eax,%ecx
f010099b:	83 e1 40             	and    $0x40,%ecx
f010099e:	83 f9 01             	cmp    $0x1,%ecx
f01009a1:	19 c9                	sbb    %ecx,%ecx
f01009a3:	83 e1 e9             	and    $0xffffffe9,%ecx
f01009a6:	83 c1 44             	add    $0x44,%ecx
			char perm_Accessed = (*cur_pte & PTE_A) ? 'A' : '-';
f01009a9:	89 c3                	mov    %eax,%ebx
f01009ab:	83 e3 20             	and    $0x20,%ebx
f01009ae:	83 fb 01             	cmp    $0x1,%ebx
f01009b1:	19 db                	sbb    %ebx,%ebx
f01009b3:	83 e3 ec             	and    $0xffffffec,%ebx
f01009b6:	83 c3 41             	add    $0x41,%ebx
			char perm_CacheDisable = (*cur_pte & PTE_PCD) ? 'C' : '-';
f01009b9:	89 c6                	mov    %eax,%esi
f01009bb:	83 e6 10             	and    $0x10,%esi
f01009be:	83 fe 01             	cmp    $0x1,%esi
f01009c1:	19 f6                	sbb    %esi,%esi
f01009c3:	89 75 a8             	mov    %esi,-0x58(%ebp)
f01009c6:	80 65 a8 ea          	andb   $0xea,-0x58(%ebp)
f01009ca:	80 45 a8 43          	addb   $0x43,-0x58(%ebp)
			char perm_Wirtethrough = (*cur_pte & PTE_PWT) ? 'T' : '-';
f01009ce:	89 c6                	mov    %eax,%esi
f01009d0:	83 e6 08             	and    $0x8,%esi
f01009d3:	83 fe 01             	cmp    $0x1,%esi
f01009d6:	19 f6                	sbb    %esi,%esi
f01009d8:	89 75 98             	mov    %esi,-0x68(%ebp)
f01009db:	80 65 98 d9          	andb   $0xd9,-0x68(%ebp)
f01009df:	80 45 98 54          	addb   $0x54,-0x68(%ebp)
			char perm_User = (*cur_pte & PTE_U) ? 'U' : '-';
f01009e3:	89 c6                	mov    %eax,%esi
f01009e5:	83 e6 04             	and    $0x4,%esi
f01009e8:	83 fe 01             	cmp    $0x1,%esi
f01009eb:	19 f6                	sbb    %esi,%esi
f01009ed:	83 e6 d8             	and    $0xffffffd8,%esi
f01009f0:	83 c6 55             	add    $0x55,%esi
			char perm_Writeable = (*cur_pte & PTE_W) ? 'W' : '-';
f01009f3:	83 e0 02             	and    $0x2,%eax
f01009f6:	83 f8 01             	cmp    $0x1,%eax
f01009f9:	19 c0                	sbb    %eax,%eax
f01009fb:	83 e0 d6             	and    $0xffffffd6,%eax
f01009fe:	83 c0 57             	add    $0x57,%eax
			char perm_Present = 'P';	// has been checked
			cprintf("%c%c%c%c%c%c%c%c%c\n", perm_Global, perm_PageSize, perm_Dirty, perm_Accessed, perm_CacheDisable, perm_Wirtethrough, perm_User, perm_Writeable,perm_Present);
f0100a01:	c7 44 24 24 50 00 00 	movl   $0x50,0x24(%esp)
f0100a08:	00 
f0100a09:	0f be c0             	movsbl %al,%eax
f0100a0c:	89 44 24 20          	mov    %eax,0x20(%esp)
f0100a10:	89 f0                	mov    %esi,%eax
f0100a12:	0f be f0             	movsbl %al,%esi
f0100a15:	89 74 24 1c          	mov    %esi,0x1c(%esp)
f0100a19:	0f be 45 98          	movsbl -0x68(%ebp),%eax
f0100a1d:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100a21:	0f be 45 a8          	movsbl -0x58(%ebp),%eax
f0100a25:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100a29:	0f be db             	movsbl %bl,%ebx
f0100a2c:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0100a30:	0f be c9             	movsbl %cl,%ecx
f0100a33:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100a37:	0f be d2             	movsbl %dl,%edx
f0100a3a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100a3e:	0f be 45 b8          	movsbl -0x48(%ebp),%eax
f0100a42:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a46:	c7 04 24 ef 46 10 f0 	movl   $0xf01046ef,(%esp)
f0100a4d:	e8 54 29 00 00       	call   f01033a6 <cprintf>
		}
		start_addr += PGSIZE;
f0100a52:	81 c7 00 10 00 00    	add    $0x1000,%edi
			return 0;
		}
		end_addr = ROUNDUP(end_addr, PGSIZE);
	}

	while(start_addr < end_addr){
f0100a58:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0100a5b:	0f 82 b8 fe ff ff    	jb     f0100919 <mon_showmappings+0xca>
			cprintf("%c%c%c%c%c%c%c%c%c\n", perm_Global, perm_PageSize, perm_Dirty, perm_Accessed, perm_CacheDisable, perm_Wirtethrough, perm_User, perm_Writeable,perm_Present);
		}
		start_addr += PGSIZE;
	}
	return 0;
}
f0100a61:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a66:	81 c4 8c 00 00 00    	add    $0x8c,%esp
f0100a6c:	5b                   	pop    %ebx
f0100a6d:	5e                   	pop    %esi
f0100a6e:	5f                   	pop    %edi
f0100a6f:	5d                   	pop    %ebp
f0100a70:	c3                   	ret    

f0100a71 <mon_dump>:
	return 0;
}

int
mon_dump(int argc, char **argv, struct Trapframe *tf)
{
f0100a71:	55                   	push   %ebp
f0100a72:	89 e5                	mov    %esp,%ebp
f0100a74:	57                   	push   %edi
f0100a75:	56                   	push   %esi
f0100a76:	53                   	push   %ebx
f0100a77:	83 ec 2c             	sub    $0x2c,%esp
f0100a7a:	8b 7d 0c             	mov    0xc(%ebp),%edi
	int is_phyaddr = 0;
	if (argc != 4 || *argv[1] != '-'){
f0100a7d:	83 7d 08 04          	cmpl   $0x4,0x8(%ebp)
f0100a81:	75 08                	jne    f0100a8b <mon_dump+0x1a>
f0100a83:	8b 47 04             	mov    0x4(%edi),%eax
f0100a86:	80 38 2d             	cmpb   $0x2d,(%eax)
f0100a89:	74 11                	je     f0100a9c <mon_dump+0x2b>
		cprintf("Usage : dump [-p|-v] start_addr end_addr\n");
f0100a8b:	c7 04 24 48 49 10 f0 	movl   $0xf0104948,(%esp)
f0100a92:	e8 0f 29 00 00       	call   f01033a6 <cprintf>
		return 0;
f0100a97:	e9 67 01 00 00       	jmp    f0100c03 <mon_dump+0x192>
	}
	if (argv[1][1] == 'p' || argv[1][1] == 'P')
f0100a9c:	0f b6 40 01          	movzbl 0x1(%eax),%eax
f0100aa0:	83 e0 df             	and    $0xffffffdf,%eax
f0100aa3:	3c 50                	cmp    $0x50,%al
f0100aa5:	74 1a                	je     f0100ac1 <mon_dump+0x50>
		is_phyaddr = 1;
	else if (argv[1][1] == 'v' || argv[1][1] == 'V')
		is_phyaddr = 0;
f0100aa7:	bb 00 00 00 00       	mov    $0x0,%ebx
		cprintf("Usage : dump [-p|-v] start_addr end_addr\n");
		return 0;
	}
	if (argv[1][1] == 'p' || argv[1][1] == 'P')
		is_phyaddr = 1;
	else if (argv[1][1] == 'v' || argv[1][1] == 'V')
f0100aac:	3c 56                	cmp    $0x56,%al
f0100aae:	74 16                	je     f0100ac6 <mon_dump+0x55>
		is_phyaddr = 0;
	else{
		cprintf("Usage : dump [-p|-v] start_addr end_addr\n");
f0100ab0:	c7 04 24 48 49 10 f0 	movl   $0xf0104948,(%esp)
f0100ab7:	e8 ea 28 00 00       	call   f01033a6 <cprintf>
		return 0;
f0100abc:	e9 42 01 00 00       	jmp    f0100c03 <mon_dump+0x192>
	if (argc != 4 || *argv[1] != '-'){
		cprintf("Usage : dump [-p|-v] start_addr end_addr\n");
		return 0;
	}
	if (argv[1][1] == 'p' || argv[1][1] == 'P')
		is_phyaddr = 1;
f0100ac1:	bb 01 00 00 00       	mov    $0x1,%ebx
		return 0;
	}

	// get start_addr and end_addr
	char *errStr;
	uintptr_t start_addr = strtol(argv[2], &errStr, 16);
f0100ac6:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100acd:	00 
f0100ace:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100ad1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ad5:	8b 47 08             	mov    0x8(%edi),%eax
f0100ad8:	89 04 24             	mov    %eax,(%esp)
f0100adb:	e8 53 35 00 00       	call   f0104033 <strtol>
	if (*errStr){
f0100ae0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100ae3:	80 3a 00             	cmpb   $0x0,(%edx)
f0100ae6:	74 18                	je     f0100b00 <mon_dump+0x8f>
		cprintf("error : invalid input : %s .\n", argv[1]);
f0100ae8:	8b 47 04             	mov    0x4(%edi),%eax
f0100aeb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100aef:	c7 04 24 d1 46 10 f0 	movl   $0xf01046d1,(%esp)
f0100af6:	e8 ab 28 00 00       	call   f01033a6 <cprintf>
		return 0;
f0100afb:	e9 03 01 00 00       	jmp    f0100c03 <mon_dump+0x192>
	}
	start_addr = ROUNDDOWN(start_addr, PGSIZE);
f0100b00:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b05:	89 c6                	mov    %eax,%esi
	uintptr_t end_addr = strtol(argv[3], &errStr, 16);
f0100b07:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100b0e:	00 
f0100b0f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100b12:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b16:	8b 47 0c             	mov    0xc(%edi),%eax
f0100b19:	89 04 24             	mov    %eax,(%esp)
f0100b1c:	e8 12 35 00 00       	call   f0104033 <strtol>
	if (*errStr){
f0100b21:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100b24:	80 3a 00             	cmpb   $0x0,(%edx)
f0100b27:	74 18                	je     f0100b41 <mon_dump+0xd0>
		cprintf("error : invalid input : %s .\n", argv[2]);
f0100b29:	8b 47 08             	mov    0x8(%edi),%eax
f0100b2c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b30:	c7 04 24 d1 46 10 f0 	movl   $0xf01046d1,(%esp)
f0100b37:	e8 6a 28 00 00       	call   f01033a6 <cprintf>
		return 0;
f0100b3c:	e9 c2 00 00 00       	jmp    f0100c03 <mon_dump+0x192>
	}
	end_addr = ROUNDUP(end_addr, PGSIZE);
f0100b41:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100b46:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b4b:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// if the addr is physical addr, change to vitual addr
	if (is_phyaddr){
f0100b4e:	85 db                	test   %ebx,%ebx
f0100b50:	74 33                	je     f0100b85 <mon_dump+0x114>
		if ((PGNUM(start_addr) >= npages) || (PGNUM(end_addr) >= npages)){
f0100b52:	a1 64 99 11 f0       	mov    0xf0119964,%eax
f0100b57:	89 f2                	mov    %esi,%edx
f0100b59:	c1 ea 0c             	shr    $0xc,%edx
f0100b5c:	39 c2                	cmp    %eax,%edx
f0100b5e:	73 17                	jae    f0100b77 <mon_dump+0x106>
f0100b60:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100b63:	c1 ea 0c             	shr    $0xc,%edx
static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f0100b66:	81 ee 00 00 00 10    	sub    $0x10000000,%esi
f0100b6c:	81 6d d4 00 00 00 10 	subl   $0x10000000,-0x2c(%ebp)
f0100b73:	39 d0                	cmp    %edx,%eax
f0100b75:	77 0e                	ja     f0100b85 <mon_dump+0x114>
			cprintf("error: the address overflow the max physical address\n");
f0100b77:	c7 04 24 74 49 10 f0 	movl   $0xf0104974,(%esp)
f0100b7e:	e8 23 28 00 00       	call   f01033a6 <cprintf>
			return 0;
f0100b83:	eb 7e                	jmp    f0100c03 <mon_dump+0x192>
		end_addr = (uint32_t)KADDR(end_addr);
	}

	while(start_addr < end_addr){
		pte_t *ppte;
		if (page_lookup(kern_pgdir, (void *)start_addr, &ppte) == NULL || *ppte == 0){
f0100b85:	8d 7d e0             	lea    -0x20(%ebp),%edi
f0100b88:	eb 74                	jmp    f0100bfe <mon_dump+0x18d>
f0100b8a:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0100b8e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b92:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0100b97:	89 04 24             	mov    %eax,(%esp)
f0100b9a:	e8 4b 0b 00 00       	call   f01016ea <page_lookup>
f0100b9f:	85 c0                	test   %eax,%eax
f0100ba1:	74 09                	je     f0100bac <mon_dump+0x13b>
f0100ba3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ba6:	8b 00                	mov    (%eax),%eax
f0100ba8:	85 c0                	test   %eax,%eax
f0100baa:	75 0e                	jne    f0100bba <mon_dump+0x149>
			cprintf("virtual addr 0x%08x not mapping\n");
f0100bac:	c7 04 24 ac 49 10 f0 	movl   $0xf01049ac,(%esp)
f0100bb3:	e8 ee 27 00 00       	call   f01033a6 <cprintf>
f0100bb8:	eb 3e                	jmp    f0100bf8 <mon_dump+0x187>
		}else{
			cprintf("virtual addr 0x%08x physical addr 0x%08x memory ", PTE_ADDR(*ppte) | PGOFF(start_addr));
f0100bba:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100bbf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bc3:	c7 04 24 d0 49 10 f0 	movl   $0xf01049d0,(%esp)
f0100bca:	e8 d7 27 00 00       	call   f01033a6 <cprintf>
f0100bcf:	bb 10 00 00 00       	mov    $0x10,%ebx
			for (int i = 0; i < 16; i++)
				cprintf("%02x ", *(unsigned char *)start_addr);
f0100bd4:	0f b6 06             	movzbl (%esi),%eax
f0100bd7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bdb:	c7 04 24 03 47 10 f0 	movl   $0xf0104703,(%esp)
f0100be2:	e8 bf 27 00 00       	call   f01033a6 <cprintf>
		pte_t *ppte;
		if (page_lookup(kern_pgdir, (void *)start_addr, &ppte) == NULL || *ppte == 0){
			cprintf("virtual addr 0x%08x not mapping\n");
		}else{
			cprintf("virtual addr 0x%08x physical addr 0x%08x memory ", PTE_ADDR(*ppte) | PGOFF(start_addr));
			for (int i = 0; i < 16; i++)
f0100be7:	83 eb 01             	sub    $0x1,%ebx
f0100bea:	75 e8                	jne    f0100bd4 <mon_dump+0x163>
				cprintf("%02x ", *(unsigned char *)start_addr);
			cprintf("\n");
f0100bec:	c7 04 24 23 47 10 f0 	movl   $0xf0104723,(%esp)
f0100bf3:	e8 ae 27 00 00       	call   f01033a6 <cprintf>
		}
		start_addr += PGSIZE;
f0100bf8:	81 c6 00 10 00 00    	add    $0x1000,%esi
		}
		start_addr = (uint32_t)KADDR(start_addr);
		end_addr = (uint32_t)KADDR(end_addr);
	}

	while(start_addr < end_addr){
f0100bfe:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0100c01:	72 87                	jb     f0100b8a <mon_dump+0x119>
			cprintf("\n");
		}
		start_addr += PGSIZE;
	}
	return 0;
}
f0100c03:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c08:	83 c4 2c             	add    $0x2c,%esp
f0100c0b:	5b                   	pop    %ebx
f0100c0c:	5e                   	pop    %esi
f0100c0d:	5f                   	pop    %edi
f0100c0e:	5d                   	pop    %ebp
f0100c0f:	c3                   	ret    

f0100c10 <mon_setpermission>:
	return 0;
}

int
mon_setpermission(int argc, char **argv, struct Trapframe *tf)
{
f0100c10:	55                   	push   %ebp
f0100c11:	89 e5                	mov    %esp,%ebp
f0100c13:	57                   	push   %edi
f0100c14:	56                   	push   %esi
f0100c15:	53                   	push   %ebx
f0100c16:	83 ec 2c             	sub    $0x2c,%esp
f0100c19:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if (argc != 3 || (*argv[2] != '+' && *argv[2] != '-')){
f0100c1c:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f0100c20:	75 0e                	jne    f0100c30 <mon_setpermission+0x20>
f0100c22:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c25:	0f b6 00             	movzbl (%eax),%eax
f0100c28:	3c 2d                	cmp    $0x2d,%al
f0100c2a:	74 15                	je     f0100c41 <mon_setpermission+0x31>
f0100c2c:	3c 2b                	cmp    $0x2b,%al
f0100c2e:	74 11                	je     f0100c41 <mon_setpermission+0x31>
		cprintf("Usage : setperm [+|-]perm \n");
f0100c30:	c7 04 24 09 47 10 f0 	movl   $0xf0104709,(%esp)
f0100c37:	e8 6a 27 00 00       	call   f01033a6 <cprintf>
		return 0;
f0100c3c:	e9 16 01 00 00       	jmp    f0100d57 <mon_setpermission+0x147>
	}
	char *errStr;
	uint32_t start_addr = strtol(argv[1], &errStr, 16);
f0100c41:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100c48:	00 
f0100c49:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100c4c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c50:	8b 43 04             	mov    0x4(%ebx),%eax
f0100c53:	89 04 24             	mov    %eax,(%esp)
f0100c56:	e8 d8 33 00 00       	call   f0104033 <strtol>
	start_addr = ROUNDDOWN(start_addr, PGSIZE);
f0100c5b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c60:	89 c6                	mov    %eax,%esi
	pte_t *ppte;
	struct PageInfo *pp = page_lookup(kern_pgdir, (void *)start_addr, &ppte);
f0100c62:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0100c65:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100c69:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c6d:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0100c72:	89 04 24             	mov    %eax,(%esp)
f0100c75:	e8 70 0a 00 00       	call   f01016ea <page_lookup>
	if (!pp || !*ppte){
f0100c7a:	85 c0                	test   %eax,%eax
f0100c7c:	74 09                	je     f0100c87 <mon_setpermission+0x77>
f0100c7e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100c81:	8b 39                	mov    (%ecx),%edi
f0100c83:	85 ff                	test   %edi,%edi
f0100c85:	75 15                	jne    f0100c9c <mon_setpermission+0x8c>
		cprintf("virtual address 0x%08x not mapped.\n", start_addr);
f0100c87:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c8b:	c7 04 24 e8 48 10 f0 	movl   $0xf01048e8,(%esp)
f0100c92:	e8 0f 27 00 00       	call   f01033a6 <cprintf>
		return 0;
f0100c97:	e9 bb 00 00 00       	jmp    f0100d57 <mon_setpermission+0x147>
	} 
	if (*argv[2] == '+'){
f0100c9c:	8b 53 08             	mov    0x8(%ebx),%edx
f0100c9f:	0f b6 02             	movzbl (%edx),%eax
f0100ca2:	3c 2b                	cmp    $0x2b,%al
f0100ca4:	75 56                	jne    f0100cfc <mon_setpermission+0xec>
		*ppte |= str2permision(argv[2] + 1);
f0100ca6:	83 c2 01             	add    $0x1,%edx

void	tlb_invalidate(pde_t *pgdir, void *va);

static inline int
str2permision(const char *buf){
	int perm = 0;
f0100ca9:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cae:	eb 3f                	jmp    f0100cef <mon_setpermission+0xdf>
	while(*buf != '\0'){
		switch(*buf++){
f0100cb0:	83 c2 01             	add    $0x1,%edx
f0100cb3:	83 e8 41             	sub    $0x41,%eax
f0100cb6:	3c 36                	cmp    $0x36,%al
f0100cb8:	77 35                	ja     f0100cef <mon_setpermission+0xdf>
f0100cba:	0f b6 c0             	movzbl %al,%eax
f0100cbd:	ff 24 85 80 4b 10 f0 	jmp    *-0xfefb480(,%eax,4)
			case 'p':
			case 'P':
				perm |= PTE_P;
f0100cc4:	83 cb 01             	or     $0x1,%ebx
f0100cc7:	eb 26                	jmp    f0100cef <mon_setpermission+0xdf>
				break;
			case 'w':
			case 'W':
				perm |= PTE_W;
f0100cc9:	83 cb 02             	or     $0x2,%ebx
f0100ccc:	eb 21                	jmp    f0100cef <mon_setpermission+0xdf>
				break;
			case 'u':
			case 'U':
				perm |= PTE_U;
f0100cce:	83 cb 04             	or     $0x4,%ebx
f0100cd1:	eb 1c                	jmp    f0100cef <mon_setpermission+0xdf>
				break;
			case 't':
			case 'T':
				perm |= PTE_PWT;
f0100cd3:	83 cb 08             	or     $0x8,%ebx
f0100cd6:	eb 17                	jmp    f0100cef <mon_setpermission+0xdf>
				break;
			case 'c':
			case 'C':
				perm |= PTE_PCD;
f0100cd8:	83 cb 10             	or     $0x10,%ebx
f0100cdb:	eb 12                	jmp    f0100cef <mon_setpermission+0xdf>
				break;
			case 'a':
			case 'A':
				perm |= PTE_A;
f0100cdd:	83 cb 20             	or     $0x20,%ebx
f0100ce0:	eb 0d                	jmp    f0100cef <mon_setpermission+0xdf>
				break;
			case 'd':
			case 'D':
				perm |= PTE_D;
f0100ce2:	83 cb 40             	or     $0x40,%ebx
f0100ce5:	eb 08                	jmp    f0100cef <mon_setpermission+0xdf>
				break;
			case 's':
			case 'S':
				perm |= PTE_PS;
f0100ce7:	80 cb 80             	or     $0x80,%bl
f0100cea:	eb 03                	jmp    f0100cef <mon_setpermission+0xdf>
				break;
			case 'g':
			case 'G':
				perm |= PTE_G;
f0100cec:	80 cf 01             	or     $0x1,%bh
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline int
str2permision(const char *buf){
	int perm = 0;
	while(*buf != '\0'){
f0100cef:	0f b6 02             	movzbl (%edx),%eax
f0100cf2:	84 c0                	test   %al,%al
f0100cf4:	75 ba                	jne    f0100cb0 <mon_setpermission+0xa0>
f0100cf6:	09 df                	or     %ebx,%edi
f0100cf8:	89 39                	mov    %edi,(%ecx)
f0100cfa:	eb 5b                	jmp    f0100d57 <mon_setpermission+0x147>
	}else if (*argv[2] == '-'){
		*ppte = *ppte & (~str2permision(argv[2] + 1));
f0100cfc:	83 c2 01             	add    $0x1,%edx

void	tlb_invalidate(pde_t *pgdir, void *va);

static inline int
str2permision(const char *buf){
	int perm = 0;
f0100cff:	bb 00 00 00 00       	mov    $0x0,%ebx
		cprintf("virtual address 0x%08x not mapped.\n", start_addr);
		return 0;
	} 
	if (*argv[2] == '+'){
		*ppte |= str2permision(argv[2] + 1);
	}else if (*argv[2] == '-'){
f0100d04:	3c 2d                	cmp    $0x2d,%al
f0100d06:	74 42                	je     f0100d4a <mon_setpermission+0x13a>
f0100d08:	eb 4d                	jmp    f0100d57 <mon_setpermission+0x147>
	while(*buf != '\0'){
		switch(*buf++){
f0100d0a:	83 c2 01             	add    $0x1,%edx
f0100d0d:	83 e8 41             	sub    $0x41,%eax
f0100d10:	3c 36                	cmp    $0x36,%al
f0100d12:	77 36                	ja     f0100d4a <mon_setpermission+0x13a>
f0100d14:	0f b6 c0             	movzbl %al,%eax
f0100d17:	ff 24 85 5c 4c 10 f0 	jmp    *-0xfefb3a4(,%eax,4)
			case 'p':
			case 'P':
				perm |= PTE_P;
f0100d1e:	83 cb 01             	or     $0x1,%ebx
f0100d21:	eb 27                	jmp    f0100d4a <mon_setpermission+0x13a>
				break;
			case 'w':
			case 'W':
				perm |= PTE_W;
f0100d23:	83 cb 02             	or     $0x2,%ebx
f0100d26:	eb 22                	jmp    f0100d4a <mon_setpermission+0x13a>
				break;
			case 'u':
			case 'U':
				perm |= PTE_U;
f0100d28:	83 cb 04             	or     $0x4,%ebx
f0100d2b:	eb 1d                	jmp    f0100d4a <mon_setpermission+0x13a>
				break;
			case 't':
			case 'T':
				perm |= PTE_PWT;
f0100d2d:	83 cb 08             	or     $0x8,%ebx
f0100d30:	eb 18                	jmp    f0100d4a <mon_setpermission+0x13a>
				break;
			case 'c':
			case 'C':
				perm |= PTE_PCD;
f0100d32:	83 cb 10             	or     $0x10,%ebx
f0100d35:	eb 13                	jmp    f0100d4a <mon_setpermission+0x13a>
				break;
			case 'a':
			case 'A':
				perm |= PTE_A;
f0100d37:	83 cb 20             	or     $0x20,%ebx
f0100d3a:	eb 0e                	jmp    f0100d4a <mon_setpermission+0x13a>
				break;
			case 'd':
			case 'D':
				perm |= PTE_D;
f0100d3c:	83 cb 40             	or     $0x40,%ebx
f0100d3f:	90                   	nop
f0100d40:	eb 08                	jmp    f0100d4a <mon_setpermission+0x13a>
				break;
			case 's':
			case 'S':
				perm |= PTE_PS;
f0100d42:	80 cb 80             	or     $0x80,%bl
f0100d45:	eb 03                	jmp    f0100d4a <mon_setpermission+0x13a>
				break;
			case 'g':
			case 'G':
				perm |= PTE_G;
f0100d47:	80 cf 01             	or     $0x1,%bh
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline int
str2permision(const char *buf){
	int perm = 0;
	while(*buf != '\0'){
f0100d4a:	0f b6 02             	movzbl (%edx),%eax
f0100d4d:	84 c0                	test   %al,%al
f0100d4f:	75 b9                	jne    f0100d0a <mon_setpermission+0xfa>
		*ppte = *ppte & (~str2permision(argv[2] + 1));
f0100d51:	f7 d3                	not    %ebx
f0100d53:	21 df                	and    %ebx,%edi
f0100d55:	89 39                	mov    %edi,(%ecx)
	}
	return 0;
}
f0100d57:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d5c:	83 c4 2c             	add    $0x2c,%esp
f0100d5f:	5b                   	pop    %ebx
f0100d60:	5e                   	pop    %esi
f0100d61:	5f                   	pop    %edi
f0100d62:	5d                   	pop    %ebp
f0100d63:	c3                   	ret    

f0100d64 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100d64:	55                   	push   %ebp
f0100d65:	89 e5                	mov    %esp,%ebp
f0100d67:	57                   	push   %edi
f0100d68:	56                   	push   %esi
f0100d69:	53                   	push   %ebx
f0100d6a:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100d6d:	c7 04 24 04 4a 10 f0 	movl   $0xf0104a04,(%esp)
f0100d74:	e8 2d 26 00 00       	call   f01033a6 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100d79:	c7 04 24 28 4a 10 f0 	movl   $0xf0104a28,(%esp)
f0100d80:	e8 21 26 00 00       	call   f01033a6 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100d85:	c7 04 24 25 47 10 f0 	movl   $0xf0104725,(%esp)
f0100d8c:	e8 1f 2f 00 00       	call   f0103cb0 <readline>
f0100d91:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100d93:	85 c0                	test   %eax,%eax
f0100d95:	74 ee                	je     f0100d85 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100d97:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100d9e:	be 00 00 00 00       	mov    $0x0,%esi
f0100da3:	eb 0a                	jmp    f0100daf <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100da5:	c6 03 00             	movb   $0x0,(%ebx)
f0100da8:	89 f7                	mov    %esi,%edi
f0100daa:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100dad:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100daf:	0f b6 03             	movzbl (%ebx),%eax
f0100db2:	84 c0                	test   %al,%al
f0100db4:	74 63                	je     f0100e19 <monitor+0xb5>
f0100db6:	0f be c0             	movsbl %al,%eax
f0100db9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dbd:	c7 04 24 29 47 10 f0 	movl   $0xf0104729,(%esp)
f0100dc4:	e8 01 31 00 00       	call   f0103eca <strchr>
f0100dc9:	85 c0                	test   %eax,%eax
f0100dcb:	75 d8                	jne    f0100da5 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100dcd:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100dd0:	74 47                	je     f0100e19 <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100dd2:	83 fe 0f             	cmp    $0xf,%esi
f0100dd5:	75 16                	jne    f0100ded <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100dd7:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100dde:	00 
f0100ddf:	c7 04 24 2e 47 10 f0 	movl   $0xf010472e,(%esp)
f0100de6:	e8 bb 25 00 00       	call   f01033a6 <cprintf>
f0100deb:	eb 98                	jmp    f0100d85 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100ded:	8d 7e 01             	lea    0x1(%esi),%edi
f0100df0:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100df4:	eb 03                	jmp    f0100df9 <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100df6:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100df9:	0f b6 03             	movzbl (%ebx),%eax
f0100dfc:	84 c0                	test   %al,%al
f0100dfe:	74 ad                	je     f0100dad <monitor+0x49>
f0100e00:	0f be c0             	movsbl %al,%eax
f0100e03:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e07:	c7 04 24 29 47 10 f0 	movl   $0xf0104729,(%esp)
f0100e0e:	e8 b7 30 00 00       	call   f0103eca <strchr>
f0100e13:	85 c0                	test   %eax,%eax
f0100e15:	74 df                	je     f0100df6 <monitor+0x92>
f0100e17:	eb 94                	jmp    f0100dad <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f0100e19:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100e20:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100e21:	85 f6                	test   %esi,%esi
f0100e23:	0f 84 5c ff ff ff    	je     f0100d85 <monitor+0x21>
f0100e29:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e2e:	89 d8                	mov    %ebx,%eax
f0100e30:	c1 e0 04             	shl    $0x4,%eax
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100e33:	8b 80 40 4d 10 f0    	mov    -0xfefb2c0(%eax),%eax
f0100e39:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e3d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100e40:	89 04 24             	mov    %eax,(%esp)
f0100e43:	e8 24 30 00 00       	call   f0103e6c <strcmp>
f0100e48:	85 c0                	test   %eax,%eax
f0100e4a:	75 23                	jne    f0100e6f <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f0100e4c:	c1 e3 04             	shl    $0x4,%ebx
f0100e4f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e52:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e56:	8d 45 a8             	lea    -0x58(%ebp),%eax
f0100e59:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e5d:	89 34 24             	mov    %esi,(%esp)
f0100e60:	ff 93 4c 4d 10 f0    	call   *-0xfefb2b4(%ebx)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100e66:	85 c0                	test   %eax,%eax
f0100e68:	78 25                	js     f0100e8f <monitor+0x12b>
f0100e6a:	e9 16 ff ff ff       	jmp    f0100d85 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100e6f:	83 c3 01             	add    $0x1,%ebx
f0100e72:	83 fb 06             	cmp    $0x6,%ebx
f0100e75:	75 b7                	jne    f0100e2e <monitor+0xca>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100e77:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100e7a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e7e:	c7 04 24 4b 47 10 f0 	movl   $0xf010474b,(%esp)
f0100e85:	e8 1c 25 00 00       	call   f01033a6 <cprintf>
f0100e8a:	e9 f6 fe ff ff       	jmp    f0100d85 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100e8f:	83 c4 5c             	add    $0x5c,%esp
f0100e92:	5b                   	pop    %ebx
f0100e93:	5e                   	pop    %esi
f0100e94:	5f                   	pop    %edi
f0100e95:	5d                   	pop    %ebp
f0100e96:	c3                   	ret    
f0100e97:	66 90                	xchg   %ax,%ax
f0100e99:	66 90                	xchg   %ax,%ax
f0100e9b:	66 90                	xchg   %ax,%ax
f0100e9d:	66 90                	xchg   %ax,%ax
f0100e9f:	90                   	nop

f0100ea0 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100ea0:	55                   	push   %ebp
f0100ea1:	89 e5                	mov    %esp,%ebp
f0100ea3:	56                   	push   %esi
f0100ea4:	53                   	push   %ebx
f0100ea5:	83 ec 10             	sub    $0x10,%esp
f0100ea8:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100eaa:	89 04 24             	mov    %eax,(%esp)
f0100ead:	e8 84 24 00 00       	call   f0103336 <mc146818_read>
f0100eb2:	89 c6                	mov    %eax,%esi
f0100eb4:	83 c3 01             	add    $0x1,%ebx
f0100eb7:	89 1c 24             	mov    %ebx,(%esp)
f0100eba:	e8 77 24 00 00       	call   f0103336 <mc146818_read>
f0100ebf:	c1 e0 08             	shl    $0x8,%eax
f0100ec2:	09 f0                	or     %esi,%eax
}
f0100ec4:	83 c4 10             	add    $0x10,%esp
f0100ec7:	5b                   	pop    %ebx
f0100ec8:	5e                   	pop    %esi
f0100ec9:	5d                   	pop    %ebp
f0100eca:	c3                   	ret    

f0100ecb <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100ecb:	55                   	push   %ebp
f0100ecc:	89 e5                	mov    %esp,%ebp
f0100ece:	83 ec 18             	sub    $0x18,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100ed1:	83 3d 38 95 11 f0 00 	cmpl   $0x0,0xf0119538
f0100ed8:	0f 85 8a 00 00 00    	jne    f0100f68 <boot_alloc+0x9d>
		extern char end[];	//end point to the end of segment bss
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100ede:	ba 6f a9 11 f0       	mov    $0xf011a96f,%edx
f0100ee3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ee9:	89 15 38 95 11 f0    	mov    %edx,0xf0119538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0)
f0100eef:	85 c0                	test   %eax,%eax
f0100ef1:	75 07                	jne    f0100efa <boot_alloc+0x2f>
		return nextfree;
f0100ef3:	a1 38 95 11 f0       	mov    0xf0119538,%eax
f0100ef8:	eb 78                	jmp    f0100f72 <boot_alloc+0xa7>
	else if (n > 0){
		result = nextfree;
f0100efa:	8b 15 38 95 11 f0    	mov    0xf0119538,%edx
		nextfree += n;
		nextfree = ROUNDUP((char *) nextfree, PGSIZE);
f0100f00:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100f07:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100f0c:	a3 38 95 11 f0       	mov    %eax,0xf0119538
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f11:	81 3d 64 99 11 f0 00 	cmpl   $0x400,0xf0119964
f0100f18:	04 00 00 
f0100f1b:	77 24                	ja     f0100f41 <boot_alloc+0x76>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f1d:	c7 44 24 0c 00 00 40 	movl   $0x400000,0xc(%esp)
f0100f24:	00 
f0100f25:	c7 44 24 08 a0 4d 10 	movl   $0xf0104da0,0x8(%esp)
f0100f2c:	f0 
f0100f2d:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
f0100f34:	00 
f0100f35:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0100f3c:	e8 53 f1 ff ff       	call   f0100094 <_panic>
		//nextfree should be less than the size of kernel virtual address: 4MB
		if(nextfree >= (char *)KADDR(0x400000))
f0100f41:	3d ff ff 3f f0       	cmp    $0xf03fffff,%eax
f0100f46:	76 1c                	jbe    f0100f64 <boot_alloc+0x99>
			panic("error: nextfree out of the size of kernel virtual address\n");
f0100f48:	c7 44 24 08 c4 4d 10 	movl   $0xf0104dc4,0x8(%esp)
f0100f4f:	f0 
f0100f50:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
f0100f57:	00 
f0100f58:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0100f5f:	e8 30 f1 ff ff       	call   f0100094 <_panic>
		return result;
f0100f64:	89 d0                	mov    %edx,%eax
f0100f66:	eb 0a                	jmp    f0100f72 <boot_alloc+0xa7>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0)
f0100f68:	85 c0                	test   %eax,%eax
f0100f6a:	75 8e                	jne    f0100efa <boot_alloc+0x2f>
f0100f6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100f70:	eb 81                	jmp    f0100ef3 <boot_alloc+0x28>
		if(nextfree >= (char *)KADDR(0x400000))
			panic("error: nextfree out of the size of kernel virtual address\n");
		return result;
	}
	return NULL;
}
f0100f72:	c9                   	leave  
f0100f73:	c3                   	ret    

f0100f74 <page2kva>:
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f74:	2b 05 6c 99 11 f0    	sub    0xf011996c,%eax
f0100f7a:	c1 f8 03             	sar    $0x3,%eax
f0100f7d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f80:	89 c2                	mov    %eax,%edx
f0100f82:	c1 ea 0c             	shr    $0xc,%edx
f0100f85:	3b 15 64 99 11 f0    	cmp    0xf0119964,%edx
f0100f8b:	72 26                	jb     f0100fb3 <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100f8d:	55                   	push   %ebp
f0100f8e:	89 e5                	mov    %esp,%ebp
f0100f90:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f93:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f97:	c7 44 24 08 a0 4d 10 	movl   $0xf0104da0,0x8(%esp)
f0100f9e:	f0 
f0100f9f:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
f0100fa6:	00 
f0100fa7:	c7 04 24 68 55 10 f0 	movl   $0xf0105568,(%esp)
f0100fae:	e8 e1 f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100fb3:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
f0100fb8:	c3                   	ret    

f0100fb9 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100fb9:	89 d1                	mov    %edx,%ecx
f0100fbb:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100fbe:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100fc1:	a8 01                	test   $0x1,%al
f0100fc3:	74 5d                	je     f0101022 <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100fc5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fca:	89 c1                	mov    %eax,%ecx
f0100fcc:	c1 e9 0c             	shr    $0xc,%ecx
f0100fcf:	3b 0d 64 99 11 f0    	cmp    0xf0119964,%ecx
f0100fd5:	72 26                	jb     f0100ffd <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100fd7:	55                   	push   %ebp
f0100fd8:	89 e5                	mov    %esp,%ebp
f0100fda:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fdd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fe1:	c7 44 24 08 a0 4d 10 	movl   $0xf0104da0,0x8(%esp)
f0100fe8:	f0 
f0100fe9:	c7 44 24 04 e3 02 00 	movl   $0x2e3,0x4(%esp)
f0100ff0:	00 
f0100ff1:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0100ff8:	e8 97 f0 ff ff       	call   f0100094 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100ffd:	c1 ea 0c             	shr    $0xc,%edx
f0101000:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0101006:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010100d:	89 c2                	mov    %eax,%edx
f010100f:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0101012:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101017:	85 d2                	test   %edx,%edx
f0101019:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010101e:	0f 44 c2             	cmove  %edx,%eax
f0101021:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0101022:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0101027:	c3                   	ret    

f0101028 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0101028:	55                   	push   %ebp
f0101029:	89 e5                	mov    %esp,%ebp
f010102b:	57                   	push   %edi
f010102c:	56                   	push   %esi
f010102d:	53                   	push   %ebx
f010102e:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0101031:	84 c0                	test   %al,%al
f0101033:	0f 85 07 03 00 00    	jne    f0101340 <check_page_free_list+0x318>
f0101039:	e9 14 03 00 00       	jmp    f0101352 <check_page_free_list+0x32a>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f010103e:	c7 44 24 08 00 4e 10 	movl   $0xf0104e00,0x8(%esp)
f0101045:	f0 
f0101046:	c7 44 24 04 26 02 00 	movl   $0x226,0x4(%esp)
f010104d:	00 
f010104e:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101055:	e8 3a f0 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f010105a:	8d 55 d8             	lea    -0x28(%ebp),%edx
f010105d:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101060:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101063:	89 55 e4             	mov    %edx,-0x1c(%ebp)
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101066:	89 c2                	mov    %eax,%edx
f0101068:	2b 15 6c 99 11 f0    	sub    0xf011996c,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f010106e:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0101074:	0f 95 c2             	setne  %dl
f0101077:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f010107a:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f010107e:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0101080:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101084:	8b 00                	mov    (%eax),%eax
f0101086:	85 c0                	test   %eax,%eax
f0101088:	75 dc                	jne    f0101066 <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f010108a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010108d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0101093:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101096:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101099:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f010109b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010109e:	a3 3c 95 11 f0       	mov    %eax,0xf011953c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01010a3:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01010a8:	8b 1d 3c 95 11 f0    	mov    0xf011953c,%ebx
f01010ae:	eb 63                	jmp    f0101113 <check_page_free_list+0xeb>
f01010b0:	89 d8                	mov    %ebx,%eax
f01010b2:	2b 05 6c 99 11 f0    	sub    0xf011996c,%eax
f01010b8:	c1 f8 03             	sar    $0x3,%eax
f01010bb:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f01010be:	89 c2                	mov    %eax,%edx
f01010c0:	c1 ea 16             	shr    $0x16,%edx
f01010c3:	39 f2                	cmp    %esi,%edx
f01010c5:	73 4a                	jae    f0101111 <check_page_free_list+0xe9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010c7:	89 c2                	mov    %eax,%edx
f01010c9:	c1 ea 0c             	shr    $0xc,%edx
f01010cc:	3b 15 64 99 11 f0    	cmp    0xf0119964,%edx
f01010d2:	72 20                	jb     f01010f4 <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010d4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01010d8:	c7 44 24 08 a0 4d 10 	movl   $0xf0104da0,0x8(%esp)
f01010df:	f0 
f01010e0:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
f01010e7:	00 
f01010e8:	c7 04 24 68 55 10 f0 	movl   $0xf0105568,(%esp)
f01010ef:	e8 a0 ef ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f01010f4:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f01010fb:	00 
f01010fc:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0101103:	00 
	return (void *)(pa + KERNBASE);
f0101104:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101109:	89 04 24             	mov    %eax,(%esp)
f010110c:	e8 f6 2d 00 00       	call   f0103f07 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101111:	8b 1b                	mov    (%ebx),%ebx
f0101113:	85 db                	test   %ebx,%ebx
f0101115:	75 99                	jne    f01010b0 <check_page_free_list+0x88>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0101117:	b8 00 00 00 00       	mov    $0x0,%eax
f010111c:	e8 aa fd ff ff       	call   f0100ecb <boot_alloc>
f0101121:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101124:	8b 15 3c 95 11 f0    	mov    0xf011953c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f010112a:	8b 0d 6c 99 11 f0    	mov    0xf011996c,%ecx
		assert(pp < pages + npages);
f0101130:	a1 64 99 11 f0       	mov    0xf0119964,%eax
f0101135:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0101138:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f010113b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f010113e:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0101141:	bf 00 00 00 00       	mov    $0x0,%edi
f0101146:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101149:	e9 97 01 00 00       	jmp    f01012e5 <check_page_free_list+0x2bd>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f010114e:	39 ca                	cmp    %ecx,%edx
f0101150:	73 24                	jae    f0101176 <check_page_free_list+0x14e>
f0101152:	c7 44 24 0c 76 55 10 	movl   $0xf0105576,0xc(%esp)
f0101159:	f0 
f010115a:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101161:	f0 
f0101162:	c7 44 24 04 40 02 00 	movl   $0x240,0x4(%esp)
f0101169:	00 
f010116a:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101171:	e8 1e ef ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0101176:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0101179:	72 24                	jb     f010119f <check_page_free_list+0x177>
f010117b:	c7 44 24 0c 97 55 10 	movl   $0xf0105597,0xc(%esp)
f0101182:	f0 
f0101183:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f010118a:	f0 
f010118b:	c7 44 24 04 41 02 00 	movl   $0x241,0x4(%esp)
f0101192:	00 
f0101193:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f010119a:	e8 f5 ee ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f010119f:	89 d0                	mov    %edx,%eax
f01011a1:	2b 45 d0             	sub    -0x30(%ebp),%eax
f01011a4:	a8 07                	test   $0x7,%al
f01011a6:	74 24                	je     f01011cc <check_page_free_list+0x1a4>
f01011a8:	c7 44 24 0c 24 4e 10 	movl   $0xf0104e24,0xc(%esp)
f01011af:	f0 
f01011b0:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01011b7:	f0 
f01011b8:	c7 44 24 04 42 02 00 	movl   $0x242,0x4(%esp)
f01011bf:	00 
f01011c0:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01011c7:	e8 c8 ee ff ff       	call   f0100094 <_panic>
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01011cc:	c1 f8 03             	sar    $0x3,%eax
f01011cf:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f01011d2:	85 c0                	test   %eax,%eax
f01011d4:	75 24                	jne    f01011fa <check_page_free_list+0x1d2>
f01011d6:	c7 44 24 0c ab 55 10 	movl   $0xf01055ab,0xc(%esp)
f01011dd:	f0 
f01011de:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01011e5:	f0 
f01011e6:	c7 44 24 04 45 02 00 	movl   $0x245,0x4(%esp)
f01011ed:	00 
f01011ee:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01011f5:	e8 9a ee ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f01011fa:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f01011ff:	75 24                	jne    f0101225 <check_page_free_list+0x1fd>
f0101201:	c7 44 24 0c bc 55 10 	movl   $0xf01055bc,0xc(%esp)
f0101208:	f0 
f0101209:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101210:	f0 
f0101211:	c7 44 24 04 46 02 00 	movl   $0x246,0x4(%esp)
f0101218:	00 
f0101219:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101220:	e8 6f ee ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0101225:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f010122a:	75 24                	jne    f0101250 <check_page_free_list+0x228>
f010122c:	c7 44 24 0c 58 4e 10 	movl   $0xf0104e58,0xc(%esp)
f0101233:	f0 
f0101234:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f010123b:	f0 
f010123c:	c7 44 24 04 47 02 00 	movl   $0x247,0x4(%esp)
f0101243:	00 
f0101244:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f010124b:	e8 44 ee ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0101250:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0101255:	75 24                	jne    f010127b <check_page_free_list+0x253>
f0101257:	c7 44 24 0c d5 55 10 	movl   $0xf01055d5,0xc(%esp)
f010125e:	f0 
f010125f:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101266:	f0 
f0101267:	c7 44 24 04 48 02 00 	movl   $0x248,0x4(%esp)
f010126e:	00 
f010126f:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101276:	e8 19 ee ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f010127b:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0101280:	76 58                	jbe    f01012da <check_page_free_list+0x2b2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101282:	89 c3                	mov    %eax,%ebx
f0101284:	c1 eb 0c             	shr    $0xc,%ebx
f0101287:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f010128a:	77 20                	ja     f01012ac <check_page_free_list+0x284>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010128c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101290:	c7 44 24 08 a0 4d 10 	movl   $0xf0104da0,0x8(%esp)
f0101297:	f0 
f0101298:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
f010129f:	00 
f01012a0:	c7 04 24 68 55 10 f0 	movl   $0xf0105568,(%esp)
f01012a7:	e8 e8 ed ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01012ac:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01012b1:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f01012b4:	76 2a                	jbe    f01012e0 <check_page_free_list+0x2b8>
f01012b6:	c7 44 24 0c 7c 4e 10 	movl   $0xf0104e7c,0xc(%esp)
f01012bd:	f0 
f01012be:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01012c5:	f0 
f01012c6:	c7 44 24 04 49 02 00 	movl   $0x249,0x4(%esp)
f01012cd:	00 
f01012ce:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01012d5:	e8 ba ed ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f01012da:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f01012de:	eb 03                	jmp    f01012e3 <check_page_free_list+0x2bb>
		else
			++nfree_extmem;
f01012e0:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01012e3:	8b 12                	mov    (%edx),%edx
f01012e5:	85 d2                	test   %edx,%edx
f01012e7:	0f 85 61 fe ff ff    	jne    f010114e <check_page_free_list+0x126>
f01012ed:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f01012f0:	85 db                	test   %ebx,%ebx
f01012f2:	7f 24                	jg     f0101318 <check_page_free_list+0x2f0>
f01012f4:	c7 44 24 0c ef 55 10 	movl   $0xf01055ef,0xc(%esp)
f01012fb:	f0 
f01012fc:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101303:	f0 
f0101304:	c7 44 24 04 51 02 00 	movl   $0x251,0x4(%esp)
f010130b:	00 
f010130c:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101313:	e8 7c ed ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0101318:	85 ff                	test   %edi,%edi
f010131a:	7f 4d                	jg     f0101369 <check_page_free_list+0x341>
f010131c:	c7 44 24 0c 01 56 10 	movl   $0xf0105601,0xc(%esp)
f0101323:	f0 
f0101324:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f010132b:	f0 
f010132c:	c7 44 24 04 52 02 00 	movl   $0x252,0x4(%esp)
f0101333:	00 
f0101334:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f010133b:	e8 54 ed ff ff       	call   f0100094 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0101340:	a1 3c 95 11 f0       	mov    0xf011953c,%eax
f0101345:	85 c0                	test   %eax,%eax
f0101347:	0f 85 0d fd ff ff    	jne    f010105a <check_page_free_list+0x32>
f010134d:	e9 ec fc ff ff       	jmp    f010103e <check_page_free_list+0x16>
f0101352:	83 3d 3c 95 11 f0 00 	cmpl   $0x0,0xf011953c
f0101359:	0f 84 df fc ff ff    	je     f010103e <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010135f:	be 00 04 00 00       	mov    $0x400,%esi
f0101364:	e9 3f fd ff ff       	jmp    f01010a8 <check_page_free_list+0x80>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0101369:	83 c4 4c             	add    $0x4c,%esp
f010136c:	5b                   	pop    %ebx
f010136d:	5e                   	pop    %esi
f010136e:	5f                   	pop    %edi
f010136f:	5d                   	pop    %ebp
f0101370:	c3                   	ret    

f0101371 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0101371:	55                   	push   %ebp
f0101372:	89 e5                	mov    %esp,%ebp
f0101374:	56                   	push   %esi
f0101375:	53                   	push   %ebx
f0101376:	83 ec 10             	sub    $0x10,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0101379:	be 00 00 00 00       	mov    $0x0,%esi
f010137e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101383:	e9 ef 00 00 00       	jmp    f0101477 <page_init+0x106>
		if (i == 0){
f0101388:	85 db                	test   %ebx,%ebx
f010138a:	75 16                	jne    f01013a2 <page_init+0x31>
			//Mark physical page 0 as in use
			pages[i].pp_ref = 1;
f010138c:	a1 6c 99 11 f0       	mov    0xf011996c,%eax
f0101391:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;	//pp_link = NULL means this page has been alloced
f0101397:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f010139d:	e9 cf 00 00 00       	jmp    f0101471 <page_init+0x100>
		}else if (i >= 1 && i < npages_basemem){
f01013a2:	3b 1d 40 95 11 f0    	cmp    0xf0119540,%ebx
f01013a8:	73 28                	jae    f01013d2 <page_init+0x61>
			//The rest of base memory [PGSIZE, npages_basemen * PGSIZE]
			pages[i].pp_ref = 0;
f01013aa:	89 f0                	mov    %esi,%eax
f01013ac:	03 05 6c 99 11 f0    	add    0xf011996c,%eax
f01013b2:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f01013b8:	8b 15 3c 95 11 f0    	mov    0xf011953c,%edx
f01013be:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f01013c0:	89 f0                	mov    %esi,%eax
f01013c2:	03 05 6c 99 11 f0    	add    0xf011996c,%eax
f01013c8:	a3 3c 95 11 f0       	mov    %eax,0xf011953c
f01013cd:	e9 9f 00 00 00       	jmp    f0101471 <page_init+0x100>
f01013d2:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
		}else if (i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE){
f01013d8:	83 f8 5f             	cmp    $0x5f,%eax
f01013db:	77 16                	ja     f01013f3 <page_init+0x82>
			//The IO hole [IOPHYSMEM, EXTPHYSMEM)
			pages[i].pp_ref = 1;
f01013dd:	89 f0                	mov    %esi,%eax
f01013df:	03 05 6c 99 11 f0    	add    0xf011996c,%eax
f01013e5:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f01013eb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f01013f1:	eb 7e                	jmp    f0101471 <page_init+0x100>
		}else if (i >= EXTPHYSMEM/PGSIZE && i < PADDR(boot_alloc(0))/PGSIZE){	//use PADDR() to change the kernel virtual addresss to physical address
f01013f3:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f01013f9:	76 53                	jbe    f010144e <page_init+0xdd>
f01013fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0101400:	e8 c6 fa ff ff       	call   f0100ecb <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101405:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010140a:	77 20                	ja     f010142c <page_init+0xbb>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010140c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101410:	c7 44 24 08 c4 4e 10 	movl   $0xf0104ec4,0x8(%esp)
f0101417:	f0 
f0101418:	c7 44 24 04 1b 01 00 	movl   $0x11b,0x4(%esp)
f010141f:	00 
f0101420:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101427:	e8 68 ec ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010142c:	05 00 00 00 10       	add    $0x10000000,%eax
f0101431:	c1 e8 0c             	shr    $0xc,%eax
f0101434:	39 c3                	cmp    %eax,%ebx
f0101436:	73 16                	jae    f010144e <page_init+0xdd>
			//The extended memory [EXTPHYSMEM, ...)
			pages[i].pp_ref = 1;
f0101438:	89 f0                	mov    %esi,%eax
f010143a:	03 05 6c 99 11 f0    	add    0xf011996c,%eax
f0101440:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0101446:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f010144c:	eb 23                	jmp    f0101471 <page_init+0x100>
		}else{
			pages[i].pp_ref = 0;
f010144e:	89 f0                	mov    %esi,%eax
f0101450:	03 05 6c 99 11 f0    	add    0xf011996c,%eax
f0101456:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f010145c:	8b 15 3c 95 11 f0    	mov    0xf011953c,%edx
f0101462:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0101464:	89 f0                	mov    %esi,%eax
f0101466:	03 05 6c 99 11 f0    	add    0xf011996c,%eax
f010146c:	a3 3c 95 11 f0       	mov    %eax,0xf011953c
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0101471:	83 c3 01             	add    $0x1,%ebx
f0101474:	83 c6 08             	add    $0x8,%esi
f0101477:	3b 1d 64 99 11 f0    	cmp    0xf0119964,%ebx
f010147d:	0f 82 05 ff ff ff    	jb     f0101388 <page_init+0x17>
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0101483:	83 c4 10             	add    $0x10,%esp
f0101486:	5b                   	pop    %ebx
f0101487:	5e                   	pop    %esi
f0101488:	5d                   	pop    %ebp
f0101489:	c3                   	ret    

f010148a <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f010148a:	55                   	push   %ebp
f010148b:	89 e5                	mov    %esp,%ebp
f010148d:	53                   	push   %ebx
f010148e:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if (page_free_list == NULL)	//out of free memory
f0101491:	8b 1d 3c 95 11 f0    	mov    0xf011953c,%ebx
f0101497:	85 db                	test   %ebx,%ebx
f0101499:	74 6f                	je     f010150a <page_alloc+0x80>
		return NULL;

	struct PageInfo *page = page_free_list;
	page_free_list = page_free_list->pp_link;
f010149b:	8b 03                	mov    (%ebx),%eax
f010149d:	a3 3c 95 11 f0       	mov    %eax,0xf011953c
	page->pp_link = NULL;
f01014a2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO)
		memset(page2kva(page), '\0', PGSIZE);	//page2kva():get kernel virtual address by pageNum 
	return page;
f01014a8:	89 d8                	mov    %ebx,%eax
		return NULL;

	struct PageInfo *page = page_free_list;
	page_free_list = page_free_list->pp_link;
	page->pp_link = NULL;
	if (alloc_flags & ALLOC_ZERO)
f01014aa:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f01014ae:	74 5f                	je     f010150f <page_alloc+0x85>
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014b0:	2b 05 6c 99 11 f0    	sub    0xf011996c,%eax
f01014b6:	c1 f8 03             	sar    $0x3,%eax
f01014b9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014bc:	89 c2                	mov    %eax,%edx
f01014be:	c1 ea 0c             	shr    $0xc,%edx
f01014c1:	3b 15 64 99 11 f0    	cmp    0xf0119964,%edx
f01014c7:	72 20                	jb     f01014e9 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014c9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01014cd:	c7 44 24 08 a0 4d 10 	movl   $0xf0104da0,0x8(%esp)
f01014d4:	f0 
f01014d5:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
f01014dc:	00 
f01014dd:	c7 04 24 68 55 10 f0 	movl   $0xf0105568,(%esp)
f01014e4:	e8 ab eb ff ff       	call   f0100094 <_panic>
		memset(page2kva(page), '\0', PGSIZE);	//page2kva():get kernel virtual address by pageNum 
f01014e9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01014f0:	00 
f01014f1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01014f8:	00 
	return (void *)(pa + KERNBASE);
f01014f9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014fe:	89 04 24             	mov    %eax,(%esp)
f0101501:	e8 01 2a 00 00       	call   f0103f07 <memset>
	return page;
f0101506:	89 d8                	mov    %ebx,%eax
f0101508:	eb 05                	jmp    f010150f <page_alloc+0x85>
struct PageInfo *
page_alloc(int alloc_flags)
{
	// Fill this function in
	if (page_free_list == NULL)	//out of free memory
		return NULL;
f010150a:	b8 00 00 00 00       	mov    $0x0,%eax
	page_free_list = page_free_list->pp_link;
	page->pp_link = NULL;
	if (alloc_flags & ALLOC_ZERO)
		memset(page2kva(page), '\0', PGSIZE);	//page2kva():get kernel virtual address by pageNum 
	return page;
}
f010150f:	83 c4 14             	add    $0x14,%esp
f0101512:	5b                   	pop    %ebx
f0101513:	5d                   	pop    %ebp
f0101514:	c3                   	ret    

f0101515 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101515:	55                   	push   %ebp
f0101516:	89 e5                	mov    %esp,%ebp
f0101518:	83 ec 18             	sub    $0x18,%esp
f010151b:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref  != 0 || pp->pp_link != NULL){
f010151e:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101523:	75 05                	jne    f010152a <page_free+0x15>
f0101525:	83 38 00             	cmpl   $0x0,(%eax)
f0101528:	74 1c                	je     f0101546 <page_free+0x31>
		panic("error(page_free):check before free a page\n");
f010152a:	c7 44 24 08 e8 4e 10 	movl   $0xf0104ee8,0x8(%esp)
f0101531:	f0 
f0101532:	c7 44 24 04 4d 01 00 	movl   $0x14d,0x4(%esp)
f0101539:	00 
f010153a:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101541:	e8 4e eb ff ff       	call   f0100094 <_panic>
		return;
	}
	pp->pp_link = page_free_list;
f0101546:	8b 15 3c 95 11 f0    	mov    0xf011953c,%edx
f010154c:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f010154e:	a3 3c 95 11 f0       	mov    %eax,0xf011953c
	return;
}
f0101553:	c9                   	leave  
f0101554:	c3                   	ret    

f0101555 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101555:	55                   	push   %ebp
f0101556:	89 e5                	mov    %esp,%ebp
f0101558:	83 ec 18             	sub    $0x18,%esp
f010155b:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f010155e:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0101562:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0101565:	66 89 50 04          	mov    %dx,0x4(%eax)
f0101569:	66 85 d2             	test   %dx,%dx
f010156c:	75 08                	jne    f0101576 <page_decref+0x21>
		page_free(pp);
f010156e:	89 04 24             	mov    %eax,(%esp)
f0101571:	e8 9f ff ff ff       	call   f0101515 <page_free>
}
f0101576:	c9                   	leave  
f0101577:	c3                   	ret    

f0101578 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101578:	55                   	push   %ebp
f0101579:	89 e5                	mov    %esp,%ebp
f010157b:	56                   	push   %esi
f010157c:	53                   	push   %ebx
f010157d:	83 ec 10             	sub    $0x10,%esp
f0101580:	8b 45 0c             	mov    0xc(%ebp),%eax
	uint32_t page_dir_index = PDX(va);
	uint32_t page_table_index = PTX(va);
f0101583:	89 c3                	mov    %eax,%ebx
f0101585:	c1 eb 0c             	shr    $0xc,%ebx
f0101588:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
	uint32_t page_dir_index = PDX(va);
f010158e:	c1 e8 16             	shr    $0x16,%eax
	uint32_t page_table_index = PTX(va);
	pte_t *page_tab;
	if (pgdir[page_dir_index] & PTE_P){		//test is exist or not
f0101591:	8d 34 85 00 00 00 00 	lea    0x0(,%eax,4),%esi
f0101598:	03 75 08             	add    0x8(%ebp),%esi
f010159b:	8b 16                	mov    (%esi),%edx
f010159d:	f6 c2 01             	test   $0x1,%dl
f01015a0:	74 3e                	je     f01015e0 <pgdir_walk+0x68>
		page_tab = KADDR(PTE_ADDR(pgdir[page_dir_index]));
f01015a2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01015a8:	89 d0                	mov    %edx,%eax
f01015aa:	c1 e8 0c             	shr    $0xc,%eax
f01015ad:	3b 05 64 99 11 f0    	cmp    0xf0119964,%eax
f01015b3:	72 20                	jb     f01015d5 <pgdir_walk+0x5d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01015b5:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01015b9:	c7 44 24 08 a0 4d 10 	movl   $0xf0104da0,0x8(%esp)
f01015c0:	f0 
f01015c1:	c7 44 24 04 7d 01 00 	movl   $0x17d,0x4(%esp)
f01015c8:	00 
f01015c9:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01015d0:	e8 bf ea ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01015d5:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01015db:	e9 8d 00 00 00       	jmp    f010166d <pgdir_walk+0xf5>
	}else{
		if (create){
f01015e0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01015e4:	0f 84 88 00 00 00    	je     f0101672 <pgdir_walk+0xfa>
			struct PageInfo *newPage = page_alloc(ALLOC_ZERO);
f01015ea:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01015f1:	e8 94 fe ff ff       	call   f010148a <page_alloc>
			if (!newPage)
f01015f6:	85 c0                	test   %eax,%eax
f01015f8:	74 7f                	je     f0101679 <pgdir_walk+0x101>
				return NULL;
			newPage->pp_ref++;
f01015fa:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01015ff:	2b 05 6c 99 11 f0    	sub    0xf011996c,%eax
f0101605:	c1 f8 03             	sar    $0x3,%eax
f0101608:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010160b:	89 c2                	mov    %eax,%edx
f010160d:	c1 ea 0c             	shr    $0xc,%edx
f0101610:	3b 15 64 99 11 f0    	cmp    0xf0119964,%edx
f0101616:	72 20                	jb     f0101638 <pgdir_walk+0xc0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101618:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010161c:	c7 44 24 08 a0 4d 10 	movl   $0xf0104da0,0x8(%esp)
f0101623:	f0 
f0101624:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
f010162b:	00 
f010162c:	c7 04 24 68 55 10 f0 	movl   $0xf0105568,(%esp)
f0101633:	e8 5c ea ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101638:	8d 88 00 00 00 f0    	lea    -0x10000000(%eax),%ecx
f010163e:	89 ca                	mov    %ecx,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101640:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0101646:	77 20                	ja     f0101668 <pgdir_walk+0xf0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101648:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010164c:	c7 44 24 08 c4 4e 10 	movl   $0xf0104ec4,0x8(%esp)
f0101653:	f0 
f0101654:	c7 44 24 04 85 01 00 	movl   $0x185,0x4(%esp)
f010165b:	00 
f010165c:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101663:	e8 2c ea ff ff       	call   f0100094 <_panic>
			page_tab = (pte_t *)page2kva(newPage);
			pgdir[page_dir_index] = PADDR(page_tab) | PTE_P | PTE_W | PTE_U;
f0101668:	83 c8 07             	or     $0x7,%eax
f010166b:	89 06                	mov    %eax,(%esi)
		}else{
			return NULL;
		}
	}
	return &page_tab[page_table_index];
f010166d:	8d 04 9a             	lea    (%edx,%ebx,4),%eax
f0101670:	eb 0c                	jmp    f010167e <pgdir_walk+0x106>
				return NULL;
			newPage->pp_ref++;
			page_tab = (pte_t *)page2kva(newPage);
			pgdir[page_dir_index] = PADDR(page_tab) | PTE_P | PTE_W | PTE_U;
		}else{
			return NULL;
f0101672:	b8 00 00 00 00       	mov    $0x0,%eax
f0101677:	eb 05                	jmp    f010167e <pgdir_walk+0x106>
		page_tab = KADDR(PTE_ADDR(pgdir[page_dir_index]));
	}else{
		if (create){
			struct PageInfo *newPage = page_alloc(ALLOC_ZERO);
			if (!newPage)
				return NULL;
f0101679:	b8 00 00 00 00       	mov    $0x0,%eax
		}else{
			return NULL;
		}
	}
	return &page_tab[page_table_index];
}
f010167e:	83 c4 10             	add    $0x10,%esp
f0101681:	5b                   	pop    %ebx
f0101682:	5e                   	pop    %esi
f0101683:	5d                   	pop    %ebp
f0101684:	c3                   	ret    

f0101685 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101685:	55                   	push   %ebp
f0101686:	89 e5                	mov    %esp,%ebp
f0101688:	57                   	push   %edi
f0101689:	56                   	push   %esi
f010168a:	53                   	push   %ebx
f010168b:	83 ec 2c             	sub    $0x2c,%esp
f010168e:	89 c7                	mov    %eax,%edi
f0101690:	8b 45 08             	mov    0x8(%ebp),%eax
	pte_t *page_tab;
	// use the code below, when va = 0xf0000000(kernelbase) and size = 0x10000000,
	// en_addr will overflow, so va > end_addr, will not run the code in while(){}
	// size_t end_addr = va + size;
	// insted, we can use page_num to avoid overflow
	size_t page_num = PGNUM(size);
f0101693:	c1 e9 0c             	shr    $0xc,%ecx
f0101696:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for(size_t i = 0; i < page_num; i++){
f0101699:	89 c3                	mov    %eax,%ebx
f010169b:	be 00 00 00 00       	mov    $0x0,%esi
f01016a0:	29 c2                	sub    %eax,%edx
f01016a2:	89 55 e0             	mov    %edx,-0x20(%ebp)
		// in this function, va's type is uintptr_t
		// when call pgdir_walk(), should change its type to void *
		page_tab = pgdir_walk(pgdir, (void *)va, 1);
		if (!page_tab)
			return;
		*page_tab = pa | perm | PTE_P;
f01016a5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016a8:	83 c8 01             	or     $0x1,%eax
f01016ab:	89 45 dc             	mov    %eax,-0x24(%ebp)
	// use the code below, when va = 0xf0000000(kernelbase) and size = 0x10000000,
	// en_addr will overflow, so va > end_addr, will not run the code in while(){}
	// size_t end_addr = va + size;
	// insted, we can use page_num to avoid overflow
	size_t page_num = PGNUM(size);
	for(size_t i = 0; i < page_num; i++){
f01016ae:	eb 2d                	jmp    f01016dd <boot_map_region+0x58>
		// in this function, va's type is uintptr_t
		// when call pgdir_walk(), should change its type to void *
		page_tab = pgdir_walk(pgdir, (void *)va, 1);
f01016b0:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01016b7:	00 
f01016b8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01016bb:	01 d8                	add    %ebx,%eax
f01016bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016c1:	89 3c 24             	mov    %edi,(%esp)
f01016c4:	e8 af fe ff ff       	call   f0101578 <pgdir_walk>
		if (!page_tab)
f01016c9:	85 c0                	test   %eax,%eax
f01016cb:	74 15                	je     f01016e2 <boot_map_region+0x5d>
			return;
		*page_tab = pa | perm | PTE_P;
f01016cd:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01016d0:	09 da                	or     %ebx,%edx
f01016d2:	89 10                	mov    %edx,(%eax)
		pa += PGSIZE;
f01016d4:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// use the code below, when va = 0xf0000000(kernelbase) and size = 0x10000000,
	// en_addr will overflow, so va > end_addr, will not run the code in while(){}
	// size_t end_addr = va + size;
	// insted, we can use page_num to avoid overflow
	size_t page_num = PGNUM(size);
	for(size_t i = 0; i < page_num; i++){
f01016da:	83 c6 01             	add    $0x1,%esi
f01016dd:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f01016e0:	75 ce                	jne    f01016b0 <boot_map_region+0x2b>
			return;
		*page_tab = pa | perm | PTE_P;
		pa += PGSIZE;
		va += PGSIZE;
	}
}
f01016e2:	83 c4 2c             	add    $0x2c,%esp
f01016e5:	5b                   	pop    %ebx
f01016e6:	5e                   	pop    %esi
f01016e7:	5f                   	pop    %edi
f01016e8:	5d                   	pop    %ebp
f01016e9:	c3                   	ret    

f01016ea <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01016ea:	55                   	push   %ebp
f01016eb:	89 e5                	mov    %esp,%ebp
f01016ed:	53                   	push   %ebx
f01016ee:	83 ec 14             	sub    $0x14,%esp
f01016f1:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// search without create, so the third parameter is 0
	pte_t *page_tab = pgdir_walk(pgdir, va, 0);
f01016f4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01016fb:	00 
f01016fc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016ff:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101703:	8b 45 08             	mov    0x8(%ebp),%eax
f0101706:	89 04 24             	mov    %eax,(%esp)
f0101709:	e8 6a fe ff ff       	call   f0101578 <pgdir_walk>
	if (!page_tab)
f010170e:	85 c0                	test   %eax,%eax
f0101710:	74 3a                	je     f010174c <page_lookup+0x62>
		return NULL;	//fail to find
	if (pte_store){
f0101712:	85 db                	test   %ebx,%ebx
f0101714:	74 02                	je     f0101718 <page_lookup+0x2e>
		*pte_store = page_tab;
f0101716:	89 03                	mov    %eax,(%ebx)
	}
	return pa2page(PTE_ADDR(*page_tab));
f0101718:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010171a:	c1 e8 0c             	shr    $0xc,%eax
f010171d:	3b 05 64 99 11 f0    	cmp    0xf0119964,%eax
f0101723:	72 1c                	jb     f0101741 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f0101725:	c7 44 24 08 14 4f 10 	movl   $0xf0104f14,0x8(%esp)
f010172c:	f0 
f010172d:	c7 44 24 04 7b 00 00 	movl   $0x7b,0x4(%esp)
f0101734:	00 
f0101735:	c7 04 24 68 55 10 f0 	movl   $0xf0105568,(%esp)
f010173c:	e8 53 e9 ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0101741:	8b 15 6c 99 11 f0    	mov    0xf011996c,%edx
f0101747:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010174a:	eb 05                	jmp    f0101751 <page_lookup+0x67>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// search without create, so the third parameter is 0
	pte_t *page_tab = pgdir_walk(pgdir, va, 0);
	if (!page_tab)
		return NULL;	//fail to find
f010174c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store){
		*pte_store = page_tab;
	}
	return pa2page(PTE_ADDR(*page_tab));
}
f0101751:	83 c4 14             	add    $0x14,%esp
f0101754:	5b                   	pop    %ebx
f0101755:	5d                   	pop    %ebp
f0101756:	c3                   	ret    

f0101757 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101757:	55                   	push   %ebp
f0101758:	89 e5                	mov    %esp,%ebp
f010175a:	53                   	push   %ebx
f010175b:	83 ec 24             	sub    $0x24,%esp
f010175e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *page_tab;
	pte_t **pte_store = &page_tab;
	struct PageInfo *pageInfo = page_lookup(pgdir, va, pte_store);
f0101761:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101764:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101768:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010176c:	8b 45 08             	mov    0x8(%ebp),%eax
f010176f:	89 04 24             	mov    %eax,(%esp)
f0101772:	e8 73 ff ff ff       	call   f01016ea <page_lookup>
	if (!pageInfo){
f0101777:	85 c0                	test   %eax,%eax
f0101779:	74 14                	je     f010178f <page_remove+0x38>
		return;
	}
	page_decref(pageInfo);
f010177b:	89 04 24             	mov    %eax,(%esp)
f010177e:	e8 d2 fd ff ff       	call   f0101555 <page_decref>
	*page_tab = 0;	//remove
f0101783:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101786:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010178c:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);
}
f010178f:	83 c4 24             	add    $0x24,%esp
f0101792:	5b                   	pop    %ebx
f0101793:	5d                   	pop    %ebp
f0101794:	c3                   	ret    

f0101795 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101795:	55                   	push   %ebp
f0101796:	89 e5                	mov    %esp,%ebp
f0101798:	57                   	push   %edi
f0101799:	56                   	push   %esi
f010179a:	53                   	push   %ebx
f010179b:	83 ec 1c             	sub    $0x1c,%esp
f010179e:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017a1:	8b 7d 10             	mov    0x10(%ebp),%edi
	// search with create, if not find, create page
	pte_t *page_tab = pgdir_walk(pgdir, va, 1);
f01017a4:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01017ab:	00 
f01017ac:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01017b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01017b3:	89 04 24             	mov    %eax,(%esp)
f01017b6:	e8 bd fd ff ff       	call   f0101578 <pgdir_walk>
f01017bb:	89 c3                	mov    %eax,%ebx
	if (!page_tab)
f01017bd:	85 c0                	test   %eax,%eax
f01017bf:	74 36                	je     f01017f7 <page_insert+0x62>
		return -E_NO_MEM;	// lack of memory
	pp->pp_ref++;
f01017c1:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	if (*page_tab & PTE_P)	// test is exist or not
f01017c6:	f6 00 01             	testb  $0x1,(%eax)
f01017c9:	74 0f                	je     f01017da <page_insert+0x45>
		page_remove(pgdir, va);
f01017cb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01017cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01017d2:	89 04 24             	mov    %eax,(%esp)
f01017d5:	e8 7d ff ff ff       	call   f0101757 <page_remove>
	*page_tab = page2pa(pp) | perm | PTE_P;
f01017da:	8b 45 14             	mov    0x14(%ebp),%eax
f01017dd:	83 c8 01             	or     $0x1,%eax
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017e0:	2b 35 6c 99 11 f0    	sub    0xf011996c,%esi
f01017e6:	c1 fe 03             	sar    $0x3,%esi
f01017e9:	c1 e6 0c             	shl    $0xc,%esi
f01017ec:	09 c6                	or     %eax,%esi
f01017ee:	89 33                	mov    %esi,(%ebx)
	return 0;
f01017f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01017f5:	eb 05                	jmp    f01017fc <page_insert+0x67>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// search with create, if not find, create page
	pte_t *page_tab = pgdir_walk(pgdir, va, 1);
	if (!page_tab)
		return -E_NO_MEM;	// lack of memory
f01017f7:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	pp->pp_ref++;
	if (*page_tab & PTE_P)	// test is exist or not
		page_remove(pgdir, va);
	*page_tab = page2pa(pp) | perm | PTE_P;
	return 0;
}
f01017fc:	83 c4 1c             	add    $0x1c,%esp
f01017ff:	5b                   	pop    %ebx
f0101800:	5e                   	pop    %esi
f0101801:	5f                   	pop    %edi
f0101802:	5d                   	pop    %ebp
f0101803:	c3                   	ret    

f0101804 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101804:	55                   	push   %ebp
f0101805:	89 e5                	mov    %esp,%ebp
f0101807:	57                   	push   %edi
f0101808:	56                   	push   %esi
f0101809:	53                   	push   %ebx
f010180a:	83 ec 4c             	sub    $0x4c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f010180d:	b8 15 00 00 00       	mov    $0x15,%eax
f0101812:	e8 89 f6 ff ff       	call   f0100ea0 <nvram_read>
f0101817:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101819:	b8 17 00 00 00       	mov    $0x17,%eax
f010181e:	e8 7d f6 ff ff       	call   f0100ea0 <nvram_read>
f0101823:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101825:	b8 34 00 00 00       	mov    $0x34,%eax
f010182a:	e8 71 f6 ff ff       	call   f0100ea0 <nvram_read>
f010182f:	c1 e0 06             	shl    $0x6,%eax
f0101832:	89 c2                	mov    %eax,%edx

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
		totalmem = 16 * 1024 + ext16mem;
f0101834:	8d 80 00 40 00 00    	lea    0x4000(%eax),%eax
	extmem = nvram_read(NVRAM_EXTLO);
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f010183a:	85 d2                	test   %edx,%edx
f010183c:	75 0b                	jne    f0101849 <mem_init+0x45>
		totalmem = 16 * 1024 + ext16mem;
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f010183e:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101844:	85 f6                	test   %esi,%esi
f0101846:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0101849:	89 c2                	mov    %eax,%edx
f010184b:	c1 ea 02             	shr    $0x2,%edx
f010184e:	89 15 64 99 11 f0    	mov    %edx,0xf0119964
	npages_basemem = basemem / (PGSIZE / 1024);
f0101854:	89 da                	mov    %ebx,%edx
f0101856:	c1 ea 02             	shr    $0x2,%edx
f0101859:	89 15 40 95 11 f0    	mov    %edx,0xf0119540

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010185f:	89 c2                	mov    %eax,%edx
f0101861:	29 da                	sub    %ebx,%edx
f0101863:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101867:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010186b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010186f:	c7 04 24 34 4f 10 f0 	movl   $0xf0104f34,(%esp)
f0101876:	e8 2b 1b 00 00       	call   f01033a6 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010187b:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101880:	e8 46 f6 ff ff       	call   f0100ecb <boot_alloc>
f0101885:	a3 68 99 11 f0       	mov    %eax,0xf0119968
	memset(kern_pgdir, 0, PGSIZE);
f010188a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101891:	00 
f0101892:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101899:	00 
f010189a:	89 04 24             	mov    %eax,(%esp)
f010189d:	e8 65 26 00 00       	call   f0103f07 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01018a2:	a1 68 99 11 f0       	mov    0xf0119968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01018a7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01018ac:	77 20                	ja     f01018ce <mem_init+0xca>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01018ae:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01018b2:	c7 44 24 08 c4 4e 10 	movl   $0xf0104ec4,0x8(%esp)
f01018b9:	f0 
f01018ba:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f01018c1:	00 
f01018c2:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01018c9:	e8 c6 e7 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01018ce:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01018d4:	83 ca 05             	or     $0x5,%edx
f01018d7:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(sizeof(struct PageInfo) * npages);
f01018dd:	a1 64 99 11 f0       	mov    0xf0119964,%eax
f01018e2:	c1 e0 03             	shl    $0x3,%eax
f01018e5:	e8 e1 f5 ff ff       	call   f0100ecb <boot_alloc>
f01018ea:	a3 6c 99 11 f0       	mov    %eax,0xf011996c
	memset(pages, 0, sizeof(struct PageInfo) * npages);
f01018ef:	8b 0d 64 99 11 f0    	mov    0xf0119964,%ecx
f01018f5:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01018fc:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101900:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101907:	00 
f0101908:	89 04 24             	mov    %eax,(%esp)
f010190b:	e8 f7 25 00 00       	call   f0103f07 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101910:	e8 5c fa ff ff       	call   f0101371 <page_init>

	check_page_free_list(1);
f0101915:	b8 01 00 00 00       	mov    $0x1,%eax
f010191a:	e8 09 f7 ff ff       	call   f0101028 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010191f:	83 3d 6c 99 11 f0 00 	cmpl   $0x0,0xf011996c
f0101926:	75 1c                	jne    f0101944 <mem_init+0x140>
		panic("'pages' is a null pointer!");
f0101928:	c7 44 24 08 12 56 10 	movl   $0xf0105612,0x8(%esp)
f010192f:	f0 
f0101930:	c7 44 24 04 63 02 00 	movl   $0x263,0x4(%esp)
f0101937:	00 
f0101938:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f010193f:	e8 50 e7 ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101944:	a1 3c 95 11 f0       	mov    0xf011953c,%eax
f0101949:	bb 00 00 00 00       	mov    $0x0,%ebx
f010194e:	eb 05                	jmp    f0101955 <mem_init+0x151>
		++nfree;
f0101950:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101953:	8b 00                	mov    (%eax),%eax
f0101955:	85 c0                	test   %eax,%eax
f0101957:	75 f7                	jne    f0101950 <mem_init+0x14c>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101959:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101960:	e8 25 fb ff ff       	call   f010148a <page_alloc>
f0101965:	89 c7                	mov    %eax,%edi
f0101967:	85 c0                	test   %eax,%eax
f0101969:	75 24                	jne    f010198f <mem_init+0x18b>
f010196b:	c7 44 24 0c 2d 56 10 	movl   $0xf010562d,0xc(%esp)
f0101972:	f0 
f0101973:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f010197a:	f0 
f010197b:	c7 44 24 04 6b 02 00 	movl   $0x26b,0x4(%esp)
f0101982:	00 
f0101983:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f010198a:	e8 05 e7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010198f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101996:	e8 ef fa ff ff       	call   f010148a <page_alloc>
f010199b:	89 c6                	mov    %eax,%esi
f010199d:	85 c0                	test   %eax,%eax
f010199f:	75 24                	jne    f01019c5 <mem_init+0x1c1>
f01019a1:	c7 44 24 0c 43 56 10 	movl   $0xf0105643,0xc(%esp)
f01019a8:	f0 
f01019a9:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01019b0:	f0 
f01019b1:	c7 44 24 04 6c 02 00 	movl   $0x26c,0x4(%esp)
f01019b8:	00 
f01019b9:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01019c0:	e8 cf e6 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01019c5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019cc:	e8 b9 fa ff ff       	call   f010148a <page_alloc>
f01019d1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01019d4:	85 c0                	test   %eax,%eax
f01019d6:	75 24                	jne    f01019fc <mem_init+0x1f8>
f01019d8:	c7 44 24 0c 59 56 10 	movl   $0xf0105659,0xc(%esp)
f01019df:	f0 
f01019e0:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01019e7:	f0 
f01019e8:	c7 44 24 04 6d 02 00 	movl   $0x26d,0x4(%esp)
f01019ef:	00 
f01019f0:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01019f7:	e8 98 e6 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019fc:	39 f7                	cmp    %esi,%edi
f01019fe:	75 24                	jne    f0101a24 <mem_init+0x220>
f0101a00:	c7 44 24 0c 6f 56 10 	movl   $0xf010566f,0xc(%esp)
f0101a07:	f0 
f0101a08:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101a0f:	f0 
f0101a10:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f0101a17:	00 
f0101a18:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101a1f:	e8 70 e6 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a24:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a27:	39 c6                	cmp    %eax,%esi
f0101a29:	74 04                	je     f0101a2f <mem_init+0x22b>
f0101a2b:	39 c7                	cmp    %eax,%edi
f0101a2d:	75 24                	jne    f0101a53 <mem_init+0x24f>
f0101a2f:	c7 44 24 0c 70 4f 10 	movl   $0xf0104f70,0xc(%esp)
f0101a36:	f0 
f0101a37:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101a3e:	f0 
f0101a3f:	c7 44 24 04 71 02 00 	movl   $0x271,0x4(%esp)
f0101a46:	00 
f0101a47:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101a4e:	e8 41 e6 ff ff       	call   f0100094 <_panic>
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a53:	8b 15 6c 99 11 f0    	mov    0xf011996c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101a59:	a1 64 99 11 f0       	mov    0xf0119964,%eax
f0101a5e:	c1 e0 0c             	shl    $0xc,%eax
f0101a61:	89 f9                	mov    %edi,%ecx
f0101a63:	29 d1                	sub    %edx,%ecx
f0101a65:	c1 f9 03             	sar    $0x3,%ecx
f0101a68:	c1 e1 0c             	shl    $0xc,%ecx
f0101a6b:	39 c1                	cmp    %eax,%ecx
f0101a6d:	72 24                	jb     f0101a93 <mem_init+0x28f>
f0101a6f:	c7 44 24 0c 81 56 10 	movl   $0xf0105681,0xc(%esp)
f0101a76:	f0 
f0101a77:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101a7e:	f0 
f0101a7f:	c7 44 24 04 72 02 00 	movl   $0x272,0x4(%esp)
f0101a86:	00 
f0101a87:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101a8e:	e8 01 e6 ff ff       	call   f0100094 <_panic>
f0101a93:	89 f1                	mov    %esi,%ecx
f0101a95:	29 d1                	sub    %edx,%ecx
f0101a97:	c1 f9 03             	sar    $0x3,%ecx
f0101a9a:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101a9d:	39 c8                	cmp    %ecx,%eax
f0101a9f:	77 24                	ja     f0101ac5 <mem_init+0x2c1>
f0101aa1:	c7 44 24 0c 9e 56 10 	movl   $0xf010569e,0xc(%esp)
f0101aa8:	f0 
f0101aa9:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101ab0:	f0 
f0101ab1:	c7 44 24 04 73 02 00 	movl   $0x273,0x4(%esp)
f0101ab8:	00 
f0101ab9:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101ac0:	e8 cf e5 ff ff       	call   f0100094 <_panic>
f0101ac5:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ac8:	29 d1                	sub    %edx,%ecx
f0101aca:	89 ca                	mov    %ecx,%edx
f0101acc:	c1 fa 03             	sar    $0x3,%edx
f0101acf:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101ad2:	39 d0                	cmp    %edx,%eax
f0101ad4:	77 24                	ja     f0101afa <mem_init+0x2f6>
f0101ad6:	c7 44 24 0c bb 56 10 	movl   $0xf01056bb,0xc(%esp)
f0101add:	f0 
f0101ade:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101ae5:	f0 
f0101ae6:	c7 44 24 04 74 02 00 	movl   $0x274,0x4(%esp)
f0101aed:	00 
f0101aee:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101af5:	e8 9a e5 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101afa:	a1 3c 95 11 f0       	mov    0xf011953c,%eax
f0101aff:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101b02:	c7 05 3c 95 11 f0 00 	movl   $0x0,0xf011953c
f0101b09:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101b0c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b13:	e8 72 f9 ff ff       	call   f010148a <page_alloc>
f0101b18:	85 c0                	test   %eax,%eax
f0101b1a:	74 24                	je     f0101b40 <mem_init+0x33c>
f0101b1c:	c7 44 24 0c d8 56 10 	movl   $0xf01056d8,0xc(%esp)
f0101b23:	f0 
f0101b24:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101b2b:	f0 
f0101b2c:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
f0101b33:	00 
f0101b34:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101b3b:	e8 54 e5 ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101b40:	89 3c 24             	mov    %edi,(%esp)
f0101b43:	e8 cd f9 ff ff       	call   f0101515 <page_free>
	page_free(pp1);
f0101b48:	89 34 24             	mov    %esi,(%esp)
f0101b4b:	e8 c5 f9 ff ff       	call   f0101515 <page_free>
	page_free(pp2);
f0101b50:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b53:	89 04 24             	mov    %eax,(%esp)
f0101b56:	e8 ba f9 ff ff       	call   f0101515 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101b5b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b62:	e8 23 f9 ff ff       	call   f010148a <page_alloc>
f0101b67:	89 c6                	mov    %eax,%esi
f0101b69:	85 c0                	test   %eax,%eax
f0101b6b:	75 24                	jne    f0101b91 <mem_init+0x38d>
f0101b6d:	c7 44 24 0c 2d 56 10 	movl   $0xf010562d,0xc(%esp)
f0101b74:	f0 
f0101b75:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101b7c:	f0 
f0101b7d:	c7 44 24 04 82 02 00 	movl   $0x282,0x4(%esp)
f0101b84:	00 
f0101b85:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101b8c:	e8 03 e5 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101b91:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b98:	e8 ed f8 ff ff       	call   f010148a <page_alloc>
f0101b9d:	89 c7                	mov    %eax,%edi
f0101b9f:	85 c0                	test   %eax,%eax
f0101ba1:	75 24                	jne    f0101bc7 <mem_init+0x3c3>
f0101ba3:	c7 44 24 0c 43 56 10 	movl   $0xf0105643,0xc(%esp)
f0101baa:	f0 
f0101bab:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101bb2:	f0 
f0101bb3:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
f0101bba:	00 
f0101bbb:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101bc2:	e8 cd e4 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101bc7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bce:	e8 b7 f8 ff ff       	call   f010148a <page_alloc>
f0101bd3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101bd6:	85 c0                	test   %eax,%eax
f0101bd8:	75 24                	jne    f0101bfe <mem_init+0x3fa>
f0101bda:	c7 44 24 0c 59 56 10 	movl   $0xf0105659,0xc(%esp)
f0101be1:	f0 
f0101be2:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101be9:	f0 
f0101bea:	c7 44 24 04 84 02 00 	movl   $0x284,0x4(%esp)
f0101bf1:	00 
f0101bf2:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101bf9:	e8 96 e4 ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101bfe:	39 fe                	cmp    %edi,%esi
f0101c00:	75 24                	jne    f0101c26 <mem_init+0x422>
f0101c02:	c7 44 24 0c 6f 56 10 	movl   $0xf010566f,0xc(%esp)
f0101c09:	f0 
f0101c0a:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101c11:	f0 
f0101c12:	c7 44 24 04 86 02 00 	movl   $0x286,0x4(%esp)
f0101c19:	00 
f0101c1a:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101c21:	e8 6e e4 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101c26:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c29:	39 c7                	cmp    %eax,%edi
f0101c2b:	74 04                	je     f0101c31 <mem_init+0x42d>
f0101c2d:	39 c6                	cmp    %eax,%esi
f0101c2f:	75 24                	jne    f0101c55 <mem_init+0x451>
f0101c31:	c7 44 24 0c 70 4f 10 	movl   $0xf0104f70,0xc(%esp)
f0101c38:	f0 
f0101c39:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101c40:	f0 
f0101c41:	c7 44 24 04 87 02 00 	movl   $0x287,0x4(%esp)
f0101c48:	00 
f0101c49:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101c50:	e8 3f e4 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101c55:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c5c:	e8 29 f8 ff ff       	call   f010148a <page_alloc>
f0101c61:	85 c0                	test   %eax,%eax
f0101c63:	74 24                	je     f0101c89 <mem_init+0x485>
f0101c65:	c7 44 24 0c d8 56 10 	movl   $0xf01056d8,0xc(%esp)
f0101c6c:	f0 
f0101c6d:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101c74:	f0 
f0101c75:	c7 44 24 04 88 02 00 	movl   $0x288,0x4(%esp)
f0101c7c:	00 
f0101c7d:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101c84:	e8 0b e4 ff ff       	call   f0100094 <_panic>
f0101c89:	89 f0                	mov    %esi,%eax
f0101c8b:	2b 05 6c 99 11 f0    	sub    0xf011996c,%eax
f0101c91:	c1 f8 03             	sar    $0x3,%eax
f0101c94:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c97:	89 c2                	mov    %eax,%edx
f0101c99:	c1 ea 0c             	shr    $0xc,%edx
f0101c9c:	3b 15 64 99 11 f0    	cmp    0xf0119964,%edx
f0101ca2:	72 20                	jb     f0101cc4 <mem_init+0x4c0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ca4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101ca8:	c7 44 24 08 a0 4d 10 	movl   $0xf0104da0,0x8(%esp)
f0101caf:	f0 
f0101cb0:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
f0101cb7:	00 
f0101cb8:	c7 04 24 68 55 10 f0 	movl   $0xf0105568,(%esp)
f0101cbf:	e8 d0 e3 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101cc4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ccb:	00 
f0101ccc:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101cd3:	00 
	return (void *)(pa + KERNBASE);
f0101cd4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101cd9:	89 04 24             	mov    %eax,(%esp)
f0101cdc:	e8 26 22 00 00       	call   f0103f07 <memset>
	page_free(pp0);
f0101ce1:	89 34 24             	mov    %esi,(%esp)
f0101ce4:	e8 2c f8 ff ff       	call   f0101515 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101ce9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101cf0:	e8 95 f7 ff ff       	call   f010148a <page_alloc>
f0101cf5:	85 c0                	test   %eax,%eax
f0101cf7:	75 24                	jne    f0101d1d <mem_init+0x519>
f0101cf9:	c7 44 24 0c e7 56 10 	movl   $0xf01056e7,0xc(%esp)
f0101d00:	f0 
f0101d01:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101d08:	f0 
f0101d09:	c7 44 24 04 8d 02 00 	movl   $0x28d,0x4(%esp)
f0101d10:	00 
f0101d11:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101d18:	e8 77 e3 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101d1d:	39 c6                	cmp    %eax,%esi
f0101d1f:	74 24                	je     f0101d45 <mem_init+0x541>
f0101d21:	c7 44 24 0c 05 57 10 	movl   $0xf0105705,0xc(%esp)
f0101d28:	f0 
f0101d29:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101d30:	f0 
f0101d31:	c7 44 24 04 8e 02 00 	movl   $0x28e,0x4(%esp)
f0101d38:	00 
f0101d39:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101d40:	e8 4f e3 ff ff       	call   f0100094 <_panic>
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101d45:	89 f0                	mov    %esi,%eax
f0101d47:	2b 05 6c 99 11 f0    	sub    0xf011996c,%eax
f0101d4d:	c1 f8 03             	sar    $0x3,%eax
f0101d50:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d53:	89 c2                	mov    %eax,%edx
f0101d55:	c1 ea 0c             	shr    $0xc,%edx
f0101d58:	3b 15 64 99 11 f0    	cmp    0xf0119964,%edx
f0101d5e:	72 20                	jb     f0101d80 <mem_init+0x57c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d60:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d64:	c7 44 24 08 a0 4d 10 	movl   $0xf0104da0,0x8(%esp)
f0101d6b:	f0 
f0101d6c:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
f0101d73:	00 
f0101d74:	c7 04 24 68 55 10 f0 	movl   $0xf0105568,(%esp)
f0101d7b:	e8 14 e3 ff ff       	call   f0100094 <_panic>
f0101d80:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101d86:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101d8c:	80 38 00             	cmpb   $0x0,(%eax)
f0101d8f:	74 24                	je     f0101db5 <mem_init+0x5b1>
f0101d91:	c7 44 24 0c 15 57 10 	movl   $0xf0105715,0xc(%esp)
f0101d98:	f0 
f0101d99:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101da0:	f0 
f0101da1:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
f0101da8:	00 
f0101da9:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101db0:	e8 df e2 ff ff       	call   f0100094 <_panic>
f0101db5:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101db8:	39 d0                	cmp    %edx,%eax
f0101dba:	75 d0                	jne    f0101d8c <mem_init+0x588>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101dbc:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101dbf:	a3 3c 95 11 f0       	mov    %eax,0xf011953c

	// free the pages we took
	page_free(pp0);
f0101dc4:	89 34 24             	mov    %esi,(%esp)
f0101dc7:	e8 49 f7 ff ff       	call   f0101515 <page_free>
	page_free(pp1);
f0101dcc:	89 3c 24             	mov    %edi,(%esp)
f0101dcf:	e8 41 f7 ff ff       	call   f0101515 <page_free>
	page_free(pp2);
f0101dd4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dd7:	89 04 24             	mov    %eax,(%esp)
f0101dda:	e8 36 f7 ff ff       	call   f0101515 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101ddf:	a1 3c 95 11 f0       	mov    0xf011953c,%eax
f0101de4:	eb 05                	jmp    f0101deb <mem_init+0x5e7>
		--nfree;
f0101de6:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101de9:	8b 00                	mov    (%eax),%eax
f0101deb:	85 c0                	test   %eax,%eax
f0101ded:	75 f7                	jne    f0101de6 <mem_init+0x5e2>
		--nfree;
	assert(nfree == 0);
f0101def:	85 db                	test   %ebx,%ebx
f0101df1:	74 24                	je     f0101e17 <mem_init+0x613>
f0101df3:	c7 44 24 0c 1f 57 10 	movl   $0xf010571f,0xc(%esp)
f0101dfa:	f0 
f0101dfb:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101e02:	f0 
f0101e03:	c7 44 24 04 9e 02 00 	movl   $0x29e,0x4(%esp)
f0101e0a:	00 
f0101e0b:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101e12:	e8 7d e2 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101e17:	c7 04 24 90 4f 10 f0 	movl   $0xf0104f90,(%esp)
f0101e1e:	e8 83 15 00 00       	call   f01033a6 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101e23:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e2a:	e8 5b f6 ff ff       	call   f010148a <page_alloc>
f0101e2f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101e32:	85 c0                	test   %eax,%eax
f0101e34:	75 24                	jne    f0101e5a <mem_init+0x656>
f0101e36:	c7 44 24 0c 2d 56 10 	movl   $0xf010562d,0xc(%esp)
f0101e3d:	f0 
f0101e3e:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101e45:	f0 
f0101e46:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f0101e4d:	00 
f0101e4e:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101e55:	e8 3a e2 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101e5a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e61:	e8 24 f6 ff ff       	call   f010148a <page_alloc>
f0101e66:	89 c3                	mov    %eax,%ebx
f0101e68:	85 c0                	test   %eax,%eax
f0101e6a:	75 24                	jne    f0101e90 <mem_init+0x68c>
f0101e6c:	c7 44 24 0c 43 56 10 	movl   $0xf0105643,0xc(%esp)
f0101e73:	f0 
f0101e74:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101e7b:	f0 
f0101e7c:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f0101e83:	00 
f0101e84:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101e8b:	e8 04 e2 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101e90:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e97:	e8 ee f5 ff ff       	call   f010148a <page_alloc>
f0101e9c:	89 c6                	mov    %eax,%esi
f0101e9e:	85 c0                	test   %eax,%eax
f0101ea0:	75 24                	jne    f0101ec6 <mem_init+0x6c2>
f0101ea2:	c7 44 24 0c 59 56 10 	movl   $0xf0105659,0xc(%esp)
f0101ea9:	f0 
f0101eaa:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101eb1:	f0 
f0101eb2:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f0101eb9:	00 
f0101eba:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101ec1:	e8 ce e1 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101ec6:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101ec9:	75 24                	jne    f0101eef <mem_init+0x6eb>
f0101ecb:	c7 44 24 0c 6f 56 10 	movl   $0xf010566f,0xc(%esp)
f0101ed2:	f0 
f0101ed3:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101eda:	f0 
f0101edb:	c7 44 24 04 fc 02 00 	movl   $0x2fc,0x4(%esp)
f0101ee2:	00 
f0101ee3:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101eea:	e8 a5 e1 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101eef:	39 c3                	cmp    %eax,%ebx
f0101ef1:	74 05                	je     f0101ef8 <mem_init+0x6f4>
f0101ef3:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101ef6:	75 24                	jne    f0101f1c <mem_init+0x718>
f0101ef8:	c7 44 24 0c 70 4f 10 	movl   $0xf0104f70,0xc(%esp)
f0101eff:	f0 
f0101f00:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101f07:	f0 
f0101f08:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f0101f0f:	00 
f0101f10:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101f17:	e8 78 e1 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101f1c:	a1 3c 95 11 f0       	mov    0xf011953c,%eax
f0101f21:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101f24:	c7 05 3c 95 11 f0 00 	movl   $0x0,0xf011953c
f0101f2b:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101f2e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f35:	e8 50 f5 ff ff       	call   f010148a <page_alloc>
f0101f3a:	85 c0                	test   %eax,%eax
f0101f3c:	74 24                	je     f0101f62 <mem_init+0x75e>
f0101f3e:	c7 44 24 0c d8 56 10 	movl   $0xf01056d8,0xc(%esp)
f0101f45:	f0 
f0101f46:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101f4d:	f0 
f0101f4e:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f0101f55:	00 
f0101f56:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101f5d:	e8 32 e1 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101f62:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101f65:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101f69:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101f70:	00 
f0101f71:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0101f76:	89 04 24             	mov    %eax,(%esp)
f0101f79:	e8 6c f7 ff ff       	call   f01016ea <page_lookup>
f0101f7e:	85 c0                	test   %eax,%eax
f0101f80:	74 24                	je     f0101fa6 <mem_init+0x7a2>
f0101f82:	c7 44 24 0c b0 4f 10 	movl   $0xf0104fb0,0xc(%esp)
f0101f89:	f0 
f0101f8a:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101f91:	f0 
f0101f92:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f0101f99:	00 
f0101f9a:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101fa1:	e8 ee e0 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101fa6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fad:	00 
f0101fae:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fb5:	00 
f0101fb6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101fba:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0101fbf:	89 04 24             	mov    %eax,(%esp)
f0101fc2:	e8 ce f7 ff ff       	call   f0101795 <page_insert>
f0101fc7:	85 c0                	test   %eax,%eax
f0101fc9:	78 24                	js     f0101fef <mem_init+0x7eb>
f0101fcb:	c7 44 24 0c e8 4f 10 	movl   $0xf0104fe8,0xc(%esp)
f0101fd2:	f0 
f0101fd3:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0101fda:	f0 
f0101fdb:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0101fe2:	00 
f0101fe3:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0101fea:	e8 a5 e0 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101fef:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ff2:	89 04 24             	mov    %eax,(%esp)
f0101ff5:	e8 1b f5 ff ff       	call   f0101515 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101ffa:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102001:	00 
f0102002:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102009:	00 
f010200a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010200e:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102013:	89 04 24             	mov    %eax,(%esp)
f0102016:	e8 7a f7 ff ff       	call   f0101795 <page_insert>
f010201b:	85 c0                	test   %eax,%eax
f010201d:	74 24                	je     f0102043 <mem_init+0x83f>
f010201f:	c7 44 24 0c 18 50 10 	movl   $0xf0105018,0xc(%esp)
f0102026:	f0 
f0102027:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f010202e:	f0 
f010202f:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0102036:	00 
f0102037:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f010203e:	e8 51 e0 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102043:	8b 3d 68 99 11 f0    	mov    0xf0119968,%edi
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102049:	a1 6c 99 11 f0       	mov    0xf011996c,%eax
f010204e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102051:	8b 17                	mov    (%edi),%edx
f0102053:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102059:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010205c:	29 c1                	sub    %eax,%ecx
f010205e:	89 c8                	mov    %ecx,%eax
f0102060:	c1 f8 03             	sar    $0x3,%eax
f0102063:	c1 e0 0c             	shl    $0xc,%eax
f0102066:	39 c2                	cmp    %eax,%edx
f0102068:	74 24                	je     f010208e <mem_init+0x88a>
f010206a:	c7 44 24 0c 48 50 10 	movl   $0xf0105048,0xc(%esp)
f0102071:	f0 
f0102072:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102079:	f0 
f010207a:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f0102081:	00 
f0102082:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102089:	e8 06 e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010208e:	ba 00 00 00 00       	mov    $0x0,%edx
f0102093:	89 f8                	mov    %edi,%eax
f0102095:	e8 1f ef ff ff       	call   f0100fb9 <check_va2pa>
f010209a:	89 da                	mov    %ebx,%edx
f010209c:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010209f:	c1 fa 03             	sar    $0x3,%edx
f01020a2:	c1 e2 0c             	shl    $0xc,%edx
f01020a5:	39 d0                	cmp    %edx,%eax
f01020a7:	74 24                	je     f01020cd <mem_init+0x8c9>
f01020a9:	c7 44 24 0c 70 50 10 	movl   $0xf0105070,0xc(%esp)
f01020b0:	f0 
f01020b1:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01020b8:	f0 
f01020b9:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f01020c0:	00 
f01020c1:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01020c8:	e8 c7 df ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01020cd:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01020d2:	74 24                	je     f01020f8 <mem_init+0x8f4>
f01020d4:	c7 44 24 0c 2a 57 10 	movl   $0xf010572a,0xc(%esp)
f01020db:	f0 
f01020dc:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01020e3:	f0 
f01020e4:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
f01020eb:	00 
f01020ec:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01020f3:	e8 9c df ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f01020f8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020fb:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102100:	74 24                	je     f0102126 <mem_init+0x922>
f0102102:	c7 44 24 0c 3b 57 10 	movl   $0xf010573b,0xc(%esp)
f0102109:	f0 
f010210a:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102111:	f0 
f0102112:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0102119:	00 
f010211a:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102121:	e8 6e df ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102126:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010212d:	00 
f010212e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102135:	00 
f0102136:	89 74 24 04          	mov    %esi,0x4(%esp)
f010213a:	89 3c 24             	mov    %edi,(%esp)
f010213d:	e8 53 f6 ff ff       	call   f0101795 <page_insert>
f0102142:	85 c0                	test   %eax,%eax
f0102144:	74 24                	je     f010216a <mem_init+0x966>
f0102146:	c7 44 24 0c a0 50 10 	movl   $0xf01050a0,0xc(%esp)
f010214d:	f0 
f010214e:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102155:	f0 
f0102156:	c7 44 24 04 15 03 00 	movl   $0x315,0x4(%esp)
f010215d:	00 
f010215e:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102165:	e8 2a df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010216a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010216f:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102174:	e8 40 ee ff ff       	call   f0100fb9 <check_va2pa>
f0102179:	89 f2                	mov    %esi,%edx
f010217b:	2b 15 6c 99 11 f0    	sub    0xf011996c,%edx
f0102181:	c1 fa 03             	sar    $0x3,%edx
f0102184:	c1 e2 0c             	shl    $0xc,%edx
f0102187:	39 d0                	cmp    %edx,%eax
f0102189:	74 24                	je     f01021af <mem_init+0x9ab>
f010218b:	c7 44 24 0c dc 50 10 	movl   $0xf01050dc,0xc(%esp)
f0102192:	f0 
f0102193:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f010219a:	f0 
f010219b:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
f01021a2:	00 
f01021a3:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01021aa:	e8 e5 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f01021af:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01021b4:	74 24                	je     f01021da <mem_init+0x9d6>
f01021b6:	c7 44 24 0c 4c 57 10 	movl   $0xf010574c,0xc(%esp)
f01021bd:	f0 
f01021be:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01021c5:	f0 
f01021c6:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f01021cd:	00 
f01021ce:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01021d5:	e8 ba de ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01021da:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01021e1:	e8 a4 f2 ff ff       	call   f010148a <page_alloc>
f01021e6:	85 c0                	test   %eax,%eax
f01021e8:	74 24                	je     f010220e <mem_init+0xa0a>
f01021ea:	c7 44 24 0c d8 56 10 	movl   $0xf01056d8,0xc(%esp)
f01021f1:	f0 
f01021f2:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01021f9:	f0 
f01021fa:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
f0102201:	00 
f0102202:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102209:	e8 86 de ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010220e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102215:	00 
f0102216:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010221d:	00 
f010221e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102222:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102227:	89 04 24             	mov    %eax,(%esp)
f010222a:	e8 66 f5 ff ff       	call   f0101795 <page_insert>
f010222f:	85 c0                	test   %eax,%eax
f0102231:	74 24                	je     f0102257 <mem_init+0xa53>
f0102233:	c7 44 24 0c a0 50 10 	movl   $0xf01050a0,0xc(%esp)
f010223a:	f0 
f010223b:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102242:	f0 
f0102243:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f010224a:	00 
f010224b:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102252:	e8 3d de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102257:	ba 00 10 00 00       	mov    $0x1000,%edx
f010225c:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102261:	e8 53 ed ff ff       	call   f0100fb9 <check_va2pa>
f0102266:	89 f2                	mov    %esi,%edx
f0102268:	2b 15 6c 99 11 f0    	sub    0xf011996c,%edx
f010226e:	c1 fa 03             	sar    $0x3,%edx
f0102271:	c1 e2 0c             	shl    $0xc,%edx
f0102274:	39 d0                	cmp    %edx,%eax
f0102276:	74 24                	je     f010229c <mem_init+0xa98>
f0102278:	c7 44 24 0c dc 50 10 	movl   $0xf01050dc,0xc(%esp)
f010227f:	f0 
f0102280:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102287:	f0 
f0102288:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f010228f:	00 
f0102290:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102297:	e8 f8 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f010229c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01022a1:	74 24                	je     f01022c7 <mem_init+0xac3>
f01022a3:	c7 44 24 0c 4c 57 10 	movl   $0xf010574c,0xc(%esp)
f01022aa:	f0 
f01022ab:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01022b2:	f0 
f01022b3:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f01022ba:	00 
f01022bb:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01022c2:	e8 cd dd ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01022c7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01022ce:	e8 b7 f1 ff ff       	call   f010148a <page_alloc>
f01022d3:	85 c0                	test   %eax,%eax
f01022d5:	74 24                	je     f01022fb <mem_init+0xaf7>
f01022d7:	c7 44 24 0c d8 56 10 	movl   $0xf01056d8,0xc(%esp)
f01022de:	f0 
f01022df:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01022e6:	f0 
f01022e7:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f01022ee:	00 
f01022ef:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01022f6:	e8 99 dd ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01022fb:	8b 15 68 99 11 f0    	mov    0xf0119968,%edx
f0102301:	8b 02                	mov    (%edx),%eax
f0102303:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102308:	89 c1                	mov    %eax,%ecx
f010230a:	c1 e9 0c             	shr    $0xc,%ecx
f010230d:	3b 0d 64 99 11 f0    	cmp    0xf0119964,%ecx
f0102313:	72 20                	jb     f0102335 <mem_init+0xb31>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102315:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102319:	c7 44 24 08 a0 4d 10 	movl   $0xf0104da0,0x8(%esp)
f0102320:	f0 
f0102321:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0102328:	00 
f0102329:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102330:	e8 5f dd ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102335:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010233a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010233d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102344:	00 
f0102345:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010234c:	00 
f010234d:	89 14 24             	mov    %edx,(%esp)
f0102350:	e8 23 f2 ff ff       	call   f0101578 <pgdir_walk>
f0102355:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102358:	8d 57 04             	lea    0x4(%edi),%edx
f010235b:	39 d0                	cmp    %edx,%eax
f010235d:	74 24                	je     f0102383 <mem_init+0xb7f>
f010235f:	c7 44 24 0c 0c 51 10 	movl   $0xf010510c,0xc(%esp)
f0102366:	f0 
f0102367:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f010236e:	f0 
f010236f:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0102376:	00 
f0102377:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f010237e:	e8 11 dd ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102383:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f010238a:	00 
f010238b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102392:	00 
f0102393:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102397:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f010239c:	89 04 24             	mov    %eax,(%esp)
f010239f:	e8 f1 f3 ff ff       	call   f0101795 <page_insert>
f01023a4:	85 c0                	test   %eax,%eax
f01023a6:	74 24                	je     f01023cc <mem_init+0xbc8>
f01023a8:	c7 44 24 0c 4c 51 10 	movl   $0xf010514c,0xc(%esp)
f01023af:	f0 
f01023b0:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01023b7:	f0 
f01023b8:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f01023bf:	00 
f01023c0:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01023c7:	e8 c8 dc ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023cc:	8b 3d 68 99 11 f0    	mov    0xf0119968,%edi
f01023d2:	ba 00 10 00 00       	mov    $0x1000,%edx
f01023d7:	89 f8                	mov    %edi,%eax
f01023d9:	e8 db eb ff ff       	call   f0100fb9 <check_va2pa>
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01023de:	89 f2                	mov    %esi,%edx
f01023e0:	2b 15 6c 99 11 f0    	sub    0xf011996c,%edx
f01023e6:	c1 fa 03             	sar    $0x3,%edx
f01023e9:	c1 e2 0c             	shl    $0xc,%edx
f01023ec:	39 d0                	cmp    %edx,%eax
f01023ee:	74 24                	je     f0102414 <mem_init+0xc10>
f01023f0:	c7 44 24 0c dc 50 10 	movl   $0xf01050dc,0xc(%esp)
f01023f7:	f0 
f01023f8:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01023ff:	f0 
f0102400:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0102407:	00 
f0102408:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f010240f:	e8 80 dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102414:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102419:	74 24                	je     f010243f <mem_init+0xc3b>
f010241b:	c7 44 24 0c 4c 57 10 	movl   $0xf010574c,0xc(%esp)
f0102422:	f0 
f0102423:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f010242a:	f0 
f010242b:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0102432:	00 
f0102433:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f010243a:	e8 55 dc ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f010243f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102446:	00 
f0102447:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010244e:	00 
f010244f:	89 3c 24             	mov    %edi,(%esp)
f0102452:	e8 21 f1 ff ff       	call   f0101578 <pgdir_walk>
f0102457:	f6 00 04             	testb  $0x4,(%eax)
f010245a:	75 24                	jne    f0102480 <mem_init+0xc7c>
f010245c:	c7 44 24 0c 8c 51 10 	movl   $0xf010518c,0xc(%esp)
f0102463:	f0 
f0102464:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f010246b:	f0 
f010246c:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0102473:	00 
f0102474:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f010247b:	e8 14 dc ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102480:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102485:	f6 00 04             	testb  $0x4,(%eax)
f0102488:	75 24                	jne    f01024ae <mem_init+0xcaa>
f010248a:	c7 44 24 0c 5d 57 10 	movl   $0xf010575d,0xc(%esp)
f0102491:	f0 
f0102492:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102499:	f0 
f010249a:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f01024a1:	00 
f01024a2:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01024a9:	e8 e6 db ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01024ae:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01024b5:	00 
f01024b6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01024bd:	00 
f01024be:	89 74 24 04          	mov    %esi,0x4(%esp)
f01024c2:	89 04 24             	mov    %eax,(%esp)
f01024c5:	e8 cb f2 ff ff       	call   f0101795 <page_insert>
f01024ca:	85 c0                	test   %eax,%eax
f01024cc:	74 24                	je     f01024f2 <mem_init+0xcee>
f01024ce:	c7 44 24 0c a0 50 10 	movl   $0xf01050a0,0xc(%esp)
f01024d5:	f0 
f01024d6:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01024dd:	f0 
f01024de:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f01024e5:	00 
f01024e6:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01024ed:	e8 a2 db ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01024f2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01024f9:	00 
f01024fa:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102501:	00 
f0102502:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102507:	89 04 24             	mov    %eax,(%esp)
f010250a:	e8 69 f0 ff ff       	call   f0101578 <pgdir_walk>
f010250f:	f6 00 02             	testb  $0x2,(%eax)
f0102512:	75 24                	jne    f0102538 <mem_init+0xd34>
f0102514:	c7 44 24 0c c0 51 10 	movl   $0xf01051c0,0xc(%esp)
f010251b:	f0 
f010251c:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102523:	f0 
f0102524:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f010252b:	00 
f010252c:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102533:	e8 5c db ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102538:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010253f:	00 
f0102540:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102547:	00 
f0102548:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f010254d:	89 04 24             	mov    %eax,(%esp)
f0102550:	e8 23 f0 ff ff       	call   f0101578 <pgdir_walk>
f0102555:	f6 00 04             	testb  $0x4,(%eax)
f0102558:	74 24                	je     f010257e <mem_init+0xd7a>
f010255a:	c7 44 24 0c f4 51 10 	movl   $0xf01051f4,0xc(%esp)
f0102561:	f0 
f0102562:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102569:	f0 
f010256a:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0102571:	00 
f0102572:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102579:	e8 16 db ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010257e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102585:	00 
f0102586:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f010258d:	00 
f010258e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102591:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102595:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f010259a:	89 04 24             	mov    %eax,(%esp)
f010259d:	e8 f3 f1 ff ff       	call   f0101795 <page_insert>
f01025a2:	85 c0                	test   %eax,%eax
f01025a4:	78 24                	js     f01025ca <mem_init+0xdc6>
f01025a6:	c7 44 24 0c 2c 52 10 	movl   $0xf010522c,0xc(%esp)
f01025ad:	f0 
f01025ae:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01025b5:	f0 
f01025b6:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f01025bd:	00 
f01025be:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01025c5:	e8 ca da ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01025ca:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01025d1:	00 
f01025d2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01025d9:	00 
f01025da:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01025de:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f01025e3:	89 04 24             	mov    %eax,(%esp)
f01025e6:	e8 aa f1 ff ff       	call   f0101795 <page_insert>
f01025eb:	85 c0                	test   %eax,%eax
f01025ed:	74 24                	je     f0102613 <mem_init+0xe0f>
f01025ef:	c7 44 24 0c 64 52 10 	movl   $0xf0105264,0xc(%esp)
f01025f6:	f0 
f01025f7:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01025fe:	f0 
f01025ff:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0102606:	00 
f0102607:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f010260e:	e8 81 da ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102613:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010261a:	00 
f010261b:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102622:	00 
f0102623:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102628:	89 04 24             	mov    %eax,(%esp)
f010262b:	e8 48 ef ff ff       	call   f0101578 <pgdir_walk>
f0102630:	f6 00 04             	testb  $0x4,(%eax)
f0102633:	74 24                	je     f0102659 <mem_init+0xe55>
f0102635:	c7 44 24 0c f4 51 10 	movl   $0xf01051f4,0xc(%esp)
f010263c:	f0 
f010263d:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102644:	f0 
f0102645:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f010264c:	00 
f010264d:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102654:	e8 3b da ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102659:	8b 3d 68 99 11 f0    	mov    0xf0119968,%edi
f010265f:	ba 00 00 00 00       	mov    $0x0,%edx
f0102664:	89 f8                	mov    %edi,%eax
f0102666:	e8 4e e9 ff ff       	call   f0100fb9 <check_va2pa>
f010266b:	89 c1                	mov    %eax,%ecx
f010266d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102670:	89 d8                	mov    %ebx,%eax
f0102672:	2b 05 6c 99 11 f0    	sub    0xf011996c,%eax
f0102678:	c1 f8 03             	sar    $0x3,%eax
f010267b:	c1 e0 0c             	shl    $0xc,%eax
f010267e:	39 c1                	cmp    %eax,%ecx
f0102680:	74 24                	je     f01026a6 <mem_init+0xea2>
f0102682:	c7 44 24 0c a0 52 10 	movl   $0xf01052a0,0xc(%esp)
f0102689:	f0 
f010268a:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102691:	f0 
f0102692:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0102699:	00 
f010269a:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01026a1:	e8 ee d9 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01026a6:	ba 00 10 00 00       	mov    $0x1000,%edx
f01026ab:	89 f8                	mov    %edi,%eax
f01026ad:	e8 07 e9 ff ff       	call   f0100fb9 <check_va2pa>
f01026b2:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01026b5:	74 24                	je     f01026db <mem_init+0xed7>
f01026b7:	c7 44 24 0c cc 52 10 	movl   $0xf01052cc,0xc(%esp)
f01026be:	f0 
f01026bf:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01026c6:	f0 
f01026c7:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f01026ce:	00 
f01026cf:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01026d6:	e8 b9 d9 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01026db:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01026e0:	74 24                	je     f0102706 <mem_init+0xf02>
f01026e2:	c7 44 24 0c 73 57 10 	movl   $0xf0105773,0xc(%esp)
f01026e9:	f0 
f01026ea:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01026f1:	f0 
f01026f2:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f01026f9:	00 
f01026fa:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102701:	e8 8e d9 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102706:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010270b:	74 24                	je     f0102731 <mem_init+0xf2d>
f010270d:	c7 44 24 0c 84 57 10 	movl   $0xf0105784,0xc(%esp)
f0102714:	f0 
f0102715:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f010271c:	f0 
f010271d:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0102724:	00 
f0102725:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f010272c:	e8 63 d9 ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102731:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102738:	e8 4d ed ff ff       	call   f010148a <page_alloc>
f010273d:	85 c0                	test   %eax,%eax
f010273f:	74 04                	je     f0102745 <mem_init+0xf41>
f0102741:	39 c6                	cmp    %eax,%esi
f0102743:	74 24                	je     f0102769 <mem_init+0xf65>
f0102745:	c7 44 24 0c fc 52 10 	movl   $0xf01052fc,0xc(%esp)
f010274c:	f0 
f010274d:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102754:	f0 
f0102755:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f010275c:	00 
f010275d:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102764:	e8 2b d9 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102769:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102770:	00 
f0102771:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102776:	89 04 24             	mov    %eax,(%esp)
f0102779:	e8 d9 ef ff ff       	call   f0101757 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010277e:	8b 3d 68 99 11 f0    	mov    0xf0119968,%edi
f0102784:	ba 00 00 00 00       	mov    $0x0,%edx
f0102789:	89 f8                	mov    %edi,%eax
f010278b:	e8 29 e8 ff ff       	call   f0100fb9 <check_va2pa>
f0102790:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102793:	74 24                	je     f01027b9 <mem_init+0xfb5>
f0102795:	c7 44 24 0c 20 53 10 	movl   $0xf0105320,0xc(%esp)
f010279c:	f0 
f010279d:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01027a4:	f0 
f01027a5:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f01027ac:	00 
f01027ad:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01027b4:	e8 db d8 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01027b9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01027be:	89 f8                	mov    %edi,%eax
f01027c0:	e8 f4 e7 ff ff       	call   f0100fb9 <check_va2pa>
f01027c5:	89 da                	mov    %ebx,%edx
f01027c7:	2b 15 6c 99 11 f0    	sub    0xf011996c,%edx
f01027cd:	c1 fa 03             	sar    $0x3,%edx
f01027d0:	c1 e2 0c             	shl    $0xc,%edx
f01027d3:	39 d0                	cmp    %edx,%eax
f01027d5:	74 24                	je     f01027fb <mem_init+0xff7>
f01027d7:	c7 44 24 0c cc 52 10 	movl   $0xf01052cc,0xc(%esp)
f01027de:	f0 
f01027df:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01027e6:	f0 
f01027e7:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f01027ee:	00 
f01027ef:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01027f6:	e8 99 d8 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01027fb:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102800:	74 24                	je     f0102826 <mem_init+0x1022>
f0102802:	c7 44 24 0c 2a 57 10 	movl   $0xf010572a,0xc(%esp)
f0102809:	f0 
f010280a:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102811:	f0 
f0102812:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0102819:	00 
f010281a:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102821:	e8 6e d8 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102826:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010282b:	74 24                	je     f0102851 <mem_init+0x104d>
f010282d:	c7 44 24 0c 84 57 10 	movl   $0xf0105784,0xc(%esp)
f0102834:	f0 
f0102835:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f010283c:	f0 
f010283d:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0102844:	00 
f0102845:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f010284c:	e8 43 d8 ff ff       	call   f0100094 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102851:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102858:	00 
f0102859:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102860:	00 
f0102861:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102865:	89 3c 24             	mov    %edi,(%esp)
f0102868:	e8 28 ef ff ff       	call   f0101795 <page_insert>
f010286d:	85 c0                	test   %eax,%eax
f010286f:	74 24                	je     f0102895 <mem_init+0x1091>
f0102871:	c7 44 24 0c 44 53 10 	movl   $0xf0105344,0xc(%esp)
f0102878:	f0 
f0102879:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102880:	f0 
f0102881:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0102888:	00 
f0102889:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102890:	e8 ff d7 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref);
f0102895:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010289a:	75 24                	jne    f01028c0 <mem_init+0x10bc>
f010289c:	c7 44 24 0c 95 57 10 	movl   $0xf0105795,0xc(%esp)
f01028a3:	f0 
f01028a4:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01028ab:	f0 
f01028ac:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f01028b3:	00 
f01028b4:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01028bb:	e8 d4 d7 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_link == NULL);
f01028c0:	83 3b 00             	cmpl   $0x0,(%ebx)
f01028c3:	74 24                	je     f01028e9 <mem_init+0x10e5>
f01028c5:	c7 44 24 0c a1 57 10 	movl   $0xf01057a1,0xc(%esp)
f01028cc:	f0 
f01028cd:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01028d4:	f0 
f01028d5:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f01028dc:	00 
f01028dd:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01028e4:	e8 ab d7 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01028e9:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01028f0:	00 
f01028f1:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f01028f6:	89 04 24             	mov    %eax,(%esp)
f01028f9:	e8 59 ee ff ff       	call   f0101757 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01028fe:	8b 3d 68 99 11 f0    	mov    0xf0119968,%edi
f0102904:	ba 00 00 00 00       	mov    $0x0,%edx
f0102909:	89 f8                	mov    %edi,%eax
f010290b:	e8 a9 e6 ff ff       	call   f0100fb9 <check_va2pa>
f0102910:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102913:	74 24                	je     f0102939 <mem_init+0x1135>
f0102915:	c7 44 24 0c 20 53 10 	movl   $0xf0105320,0xc(%esp)
f010291c:	f0 
f010291d:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102924:	f0 
f0102925:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f010292c:	00 
f010292d:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102934:	e8 5b d7 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102939:	ba 00 10 00 00       	mov    $0x1000,%edx
f010293e:	89 f8                	mov    %edi,%eax
f0102940:	e8 74 e6 ff ff       	call   f0100fb9 <check_va2pa>
f0102945:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102948:	74 24                	je     f010296e <mem_init+0x116a>
f010294a:	c7 44 24 0c 7c 53 10 	movl   $0xf010537c,0xc(%esp)
f0102951:	f0 
f0102952:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102959:	f0 
f010295a:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f0102961:	00 
f0102962:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102969:	e8 26 d7 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f010296e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102973:	74 24                	je     f0102999 <mem_init+0x1195>
f0102975:	c7 44 24 0c b6 57 10 	movl   $0xf01057b6,0xc(%esp)
f010297c:	f0 
f010297d:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102984:	f0 
f0102985:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f010298c:	00 
f010298d:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102994:	e8 fb d6 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102999:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010299e:	74 24                	je     f01029c4 <mem_init+0x11c0>
f01029a0:	c7 44 24 0c 84 57 10 	movl   $0xf0105784,0xc(%esp)
f01029a7:	f0 
f01029a8:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01029af:	f0 
f01029b0:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f01029b7:	00 
f01029b8:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01029bf:	e8 d0 d6 ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01029c4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01029cb:	e8 ba ea ff ff       	call   f010148a <page_alloc>
f01029d0:	85 c0                	test   %eax,%eax
f01029d2:	74 04                	je     f01029d8 <mem_init+0x11d4>
f01029d4:	39 c3                	cmp    %eax,%ebx
f01029d6:	74 24                	je     f01029fc <mem_init+0x11f8>
f01029d8:	c7 44 24 0c a4 53 10 	movl   $0xf01053a4,0xc(%esp)
f01029df:	f0 
f01029e0:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01029e7:	f0 
f01029e8:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f01029ef:	00 
f01029f0:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01029f7:	e8 98 d6 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01029fc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a03:	e8 82 ea ff ff       	call   f010148a <page_alloc>
f0102a08:	85 c0                	test   %eax,%eax
f0102a0a:	74 24                	je     f0102a30 <mem_init+0x122c>
f0102a0c:	c7 44 24 0c d8 56 10 	movl   $0xf01056d8,0xc(%esp)
f0102a13:	f0 
f0102a14:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102a1b:	f0 
f0102a1c:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f0102a23:	00 
f0102a24:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102a2b:	e8 64 d6 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102a30:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102a35:	8b 08                	mov    (%eax),%ecx
f0102a37:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102a3d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102a40:	2b 15 6c 99 11 f0    	sub    0xf011996c,%edx
f0102a46:	c1 fa 03             	sar    $0x3,%edx
f0102a49:	c1 e2 0c             	shl    $0xc,%edx
f0102a4c:	39 d1                	cmp    %edx,%ecx
f0102a4e:	74 24                	je     f0102a74 <mem_init+0x1270>
f0102a50:	c7 44 24 0c 48 50 10 	movl   $0xf0105048,0xc(%esp)
f0102a57:	f0 
f0102a58:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102a5f:	f0 
f0102a60:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f0102a67:	00 
f0102a68:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102a6f:	e8 20 d6 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102a74:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102a7a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a7d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102a82:	74 24                	je     f0102aa8 <mem_init+0x12a4>
f0102a84:	c7 44 24 0c 3b 57 10 	movl   $0xf010573b,0xc(%esp)
f0102a8b:	f0 
f0102a8c:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102a93:	f0 
f0102a94:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f0102a9b:	00 
f0102a9c:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102aa3:	e8 ec d5 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102aa8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102aab:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102ab1:	89 04 24             	mov    %eax,(%esp)
f0102ab4:	e8 5c ea ff ff       	call   f0101515 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102ab9:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102ac0:	00 
f0102ac1:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102ac8:	00 
f0102ac9:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102ace:	89 04 24             	mov    %eax,(%esp)
f0102ad1:	e8 a2 ea ff ff       	call   f0101578 <pgdir_walk>
f0102ad6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102ad9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102adc:	8b 15 68 99 11 f0    	mov    0xf0119968,%edx
f0102ae2:	8b 7a 04             	mov    0x4(%edx),%edi
f0102ae5:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102aeb:	8b 0d 64 99 11 f0    	mov    0xf0119964,%ecx
f0102af1:	89 f8                	mov    %edi,%eax
f0102af3:	c1 e8 0c             	shr    $0xc,%eax
f0102af6:	39 c8                	cmp    %ecx,%eax
f0102af8:	72 20                	jb     f0102b1a <mem_init+0x1316>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102afa:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102afe:	c7 44 24 08 a0 4d 10 	movl   $0xf0104da0,0x8(%esp)
f0102b05:	f0 
f0102b06:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0102b0d:	00 
f0102b0e:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102b15:	e8 7a d5 ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102b1a:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102b20:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102b23:	74 24                	je     f0102b49 <mem_init+0x1345>
f0102b25:	c7 44 24 0c c7 57 10 	movl   $0xf01057c7,0xc(%esp)
f0102b2c:	f0 
f0102b2d:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102b34:	f0 
f0102b35:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f0102b3c:	00 
f0102b3d:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102b44:	e8 4b d5 ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102b49:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102b50:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b53:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b59:	2b 05 6c 99 11 f0    	sub    0xf011996c,%eax
f0102b5f:	c1 f8 03             	sar    $0x3,%eax
f0102b62:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b65:	89 c2                	mov    %eax,%edx
f0102b67:	c1 ea 0c             	shr    $0xc,%edx
f0102b6a:	39 d1                	cmp    %edx,%ecx
f0102b6c:	77 20                	ja     f0102b8e <mem_init+0x138a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b6e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b72:	c7 44 24 08 a0 4d 10 	movl   $0xf0104da0,0x8(%esp)
f0102b79:	f0 
f0102b7a:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
f0102b81:	00 
f0102b82:	c7 04 24 68 55 10 f0 	movl   $0xf0105568,(%esp)
f0102b89:	e8 06 d5 ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102b8e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b95:	00 
f0102b96:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102b9d:	00 
	return (void *)(pa + KERNBASE);
f0102b9e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102ba3:	89 04 24             	mov    %eax,(%esp)
f0102ba6:	e8 5c 13 00 00       	call   f0103f07 <memset>
	page_free(pp0);
f0102bab:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102bae:	89 3c 24             	mov    %edi,(%esp)
f0102bb1:	e8 5f e9 ff ff       	call   f0101515 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102bb6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102bbd:	00 
f0102bbe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102bc5:	00 
f0102bc6:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102bcb:	89 04 24             	mov    %eax,(%esp)
f0102bce:	e8 a5 e9 ff ff       	call   f0101578 <pgdir_walk>
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bd3:	89 fa                	mov    %edi,%edx
f0102bd5:	2b 15 6c 99 11 f0    	sub    0xf011996c,%edx
f0102bdb:	c1 fa 03             	sar    $0x3,%edx
f0102bde:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102be1:	89 d0                	mov    %edx,%eax
f0102be3:	c1 e8 0c             	shr    $0xc,%eax
f0102be6:	3b 05 64 99 11 f0    	cmp    0xf0119964,%eax
f0102bec:	72 20                	jb     f0102c0e <mem_init+0x140a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bee:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102bf2:	c7 44 24 08 a0 4d 10 	movl   $0xf0104da0,0x8(%esp)
f0102bf9:	f0 
f0102bfa:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
f0102c01:	00 
f0102c02:	c7 04 24 68 55 10 f0 	movl   $0xf0105568,(%esp)
f0102c09:	e8 86 d4 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102c0e:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102c14:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102c17:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102c1d:	f6 00 01             	testb  $0x1,(%eax)
f0102c20:	74 24                	je     f0102c46 <mem_init+0x1442>
f0102c22:	c7 44 24 0c df 57 10 	movl   $0xf01057df,0xc(%esp)
f0102c29:	f0 
f0102c2a:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102c31:	f0 
f0102c32:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f0102c39:	00 
f0102c3a:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102c41:	e8 4e d4 ff ff       	call   f0100094 <_panic>
f0102c46:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102c49:	39 d0                	cmp    %edx,%eax
f0102c4b:	75 d0                	jne    f0102c1d <mem_init+0x1419>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102c4d:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102c52:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102c58:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c5b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102c61:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102c64:	89 0d 3c 95 11 f0    	mov    %ecx,0xf011953c

	// free the pages we took
	page_free(pp0);
f0102c6a:	89 04 24             	mov    %eax,(%esp)
f0102c6d:	e8 a3 e8 ff ff       	call   f0101515 <page_free>
	page_free(pp1);
f0102c72:	89 1c 24             	mov    %ebx,(%esp)
f0102c75:	e8 9b e8 ff ff       	call   f0101515 <page_free>
	page_free(pp2);
f0102c7a:	89 34 24             	mov    %esi,(%esp)
f0102c7d:	e8 93 e8 ff ff       	call   f0101515 <page_free>

	cprintf("check_page() succeeded!\n");
f0102c82:	c7 04 24 f6 57 10 f0 	movl   $0xf01057f6,(%esp)
f0102c89:	e8 18 07 00 00       	call   f01033a6 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, (uintptr_t)UPAGES, npages * sizeof(struct PageInfo), PADDR(pages), PTE_U | PTE_P);
f0102c8e:	a1 6c 99 11 f0       	mov    0xf011996c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c93:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c98:	77 20                	ja     f0102cba <mem_init+0x14b6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c9a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c9e:	c7 44 24 08 c4 4e 10 	movl   $0xf0104ec4,0x8(%esp)
f0102ca5:	f0 
f0102ca6:	c7 44 24 04 ba 00 00 	movl   $0xba,0x4(%esp)
f0102cad:	00 
f0102cae:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102cb5:	e8 da d3 ff ff       	call   f0100094 <_panic>
f0102cba:	8b 3d 64 99 11 f0    	mov    0xf0119964,%edi
f0102cc0:	8d 0c fd 00 00 00 00 	lea    0x0(,%edi,8),%ecx
f0102cc7:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102cce:	00 
	return (physaddr_t)kva - KERNBASE;
f0102ccf:	05 00 00 00 10       	add    $0x10000000,%eax
f0102cd4:	89 04 24             	mov    %eax,(%esp)
f0102cd7:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102cdc:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102ce1:	e8 9f e9 ff ff       	call   f0101685 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ce6:	bb 00 f0 10 f0       	mov    $0xf010f000,%ebx
f0102ceb:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102cf1:	77 20                	ja     f0102d13 <mem_init+0x150f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102cf3:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102cf7:	c7 44 24 08 c4 4e 10 	movl   $0xf0104ec4,0x8(%esp)
f0102cfe:	f0 
f0102cff:	c7 44 24 04 c7 00 00 	movl   $0xc7,0x4(%esp)
f0102d06:	00 
f0102d07:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102d0e:	e8 81 d3 ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, (uintptr_t)(KSTACKTOP - KSTKSIZE), KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f0102d13:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102d1a:	00 
f0102d1b:	c7 04 24 00 f0 10 00 	movl   $0x10f000,(%esp)
f0102d22:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102d27:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102d2c:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102d31:	e8 4f e9 ff ff       	call   f0101685 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, (uintptr_t)KERNBASE, ROUNDUP(0xffffffff - KERNBASE, PGSIZE), 0, PTE_W | PTE_P);
f0102d36:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102d3d:	00 
f0102d3e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102d45:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102d4a:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102d4f:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0102d54:	e8 2c e9 ff ff       	call   f0101685 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102d59:	8b 3d 68 99 11 f0    	mov    0xf0119968,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102d5f:	a1 64 99 11 f0       	mov    0xf0119964,%eax
f0102d64:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102d67:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102d6e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102d73:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102d76:	a1 6c 99 11 f0       	mov    0xf011996c,%eax
f0102d7b:	89 45 cc             	mov    %eax,-0x34(%ebp)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d7e:	89 45 c8             	mov    %eax,-0x38(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102d81:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d86:	89 45 c4             	mov    %eax,-0x3c(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102d89:	be 00 00 00 00       	mov    $0x0,%esi
f0102d8e:	eb 6d                	jmp    f0102dfd <mem_init+0x15f9>
f0102d90:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102d96:	89 f8                	mov    %edi,%eax
f0102d98:	e8 1c e2 ff ff       	call   f0100fb9 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d9d:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f0102da4:	77 23                	ja     f0102dc9 <mem_init+0x15c5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102da6:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102da9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102dad:	c7 44 24 08 c4 4e 10 	movl   $0xf0104ec4,0x8(%esp)
f0102db4:	f0 
f0102db5:	c7 44 24 04 b6 02 00 	movl   $0x2b6,0x4(%esp)
f0102dbc:	00 
f0102dbd:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102dc4:	e8 cb d2 ff ff       	call   f0100094 <_panic>
f0102dc9:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102dcc:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102dcf:	39 c2                	cmp    %eax,%edx
f0102dd1:	74 24                	je     f0102df7 <mem_init+0x15f3>
f0102dd3:	c7 44 24 0c c8 53 10 	movl   $0xf01053c8,0xc(%esp)
f0102dda:	f0 
f0102ddb:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102de2:	f0 
f0102de3:	c7 44 24 04 b6 02 00 	movl   $0x2b6,0x4(%esp)
f0102dea:	00 
f0102deb:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102df2:	e8 9d d2 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102df7:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102dfd:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f0102e00:	77 8e                	ja     f0102d90 <mem_init+0x158c>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102e02:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e05:	c1 e0 0c             	shl    $0xc,%eax
f0102e08:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102e0b:	be 00 00 00 00       	mov    $0x0,%esi
f0102e10:	eb 3b                	jmp    f0102e4d <mem_init+0x1649>
f0102e12:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102e18:	89 f8                	mov    %edi,%eax
f0102e1a:	e8 9a e1 ff ff       	call   f0100fb9 <check_va2pa>
f0102e1f:	39 c6                	cmp    %eax,%esi
f0102e21:	74 24                	je     f0102e47 <mem_init+0x1643>
f0102e23:	c7 44 24 0c fc 53 10 	movl   $0xf01053fc,0xc(%esp)
f0102e2a:	f0 
f0102e2b:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102e32:	f0 
f0102e33:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f0102e3a:	00 
f0102e3b:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102e42:	e8 4d d2 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102e47:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102e4d:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0102e50:	72 c0                	jb     f0102e12 <mem_init+0x160e>
f0102e52:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102e57:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102e5d:	89 f2                	mov    %esi,%edx
f0102e5f:	89 f8                	mov    %edi,%eax
f0102e61:	e8 53 e1 ff ff       	call   f0100fb9 <check_va2pa>
f0102e66:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f0102e69:	39 d0                	cmp    %edx,%eax
f0102e6b:	74 24                	je     f0102e91 <mem_init+0x168d>
f0102e6d:	c7 44 24 0c 24 54 10 	movl   $0xf0105424,0xc(%esp)
f0102e74:	f0 
f0102e75:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102e7c:	f0 
f0102e7d:	c7 44 24 04 bf 02 00 	movl   $0x2bf,0x4(%esp)
f0102e84:	00 
f0102e85:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102e8c:	e8 03 d2 ff ff       	call   f0100094 <_panic>
f0102e91:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102e97:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102e9d:	75 be                	jne    f0102e5d <mem_init+0x1659>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102e9f:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102ea4:	89 f8                	mov    %edi,%eax
f0102ea6:	e8 0e e1 ff ff       	call   f0100fb9 <check_va2pa>
f0102eab:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102eae:	75 0a                	jne    f0102eba <mem_init+0x16b6>
f0102eb0:	b8 00 00 00 00       	mov    $0x0,%eax
f0102eb5:	e9 f0 00 00 00       	jmp    f0102faa <mem_init+0x17a6>
f0102eba:	c7 44 24 0c 6c 54 10 	movl   $0xf010546c,0xc(%esp)
f0102ec1:	f0 
f0102ec2:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102ec9:	f0 
f0102eca:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f0102ed1:	00 
f0102ed2:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102ed9:	e8 b6 d1 ff ff       	call   f0100094 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102ede:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102ee3:	72 3c                	jb     f0102f21 <mem_init+0x171d>
f0102ee5:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102eea:	76 07                	jbe    f0102ef3 <mem_init+0x16ef>
f0102eec:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102ef1:	75 2e                	jne    f0102f21 <mem_init+0x171d>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102ef3:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102ef7:	0f 85 aa 00 00 00    	jne    f0102fa7 <mem_init+0x17a3>
f0102efd:	c7 44 24 0c 0f 58 10 	movl   $0xf010580f,0xc(%esp)
f0102f04:	f0 
f0102f05:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102f0c:	f0 
f0102f0d:	c7 44 24 04 c8 02 00 	movl   $0x2c8,0x4(%esp)
f0102f14:	00 
f0102f15:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102f1c:	e8 73 d1 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102f21:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102f26:	76 55                	jbe    f0102f7d <mem_init+0x1779>
				assert(pgdir[i] & PTE_P);
f0102f28:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102f2b:	f6 c2 01             	test   $0x1,%dl
f0102f2e:	75 24                	jne    f0102f54 <mem_init+0x1750>
f0102f30:	c7 44 24 0c 0f 58 10 	movl   $0xf010580f,0xc(%esp)
f0102f37:	f0 
f0102f38:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102f3f:	f0 
f0102f40:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
f0102f47:	00 
f0102f48:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102f4f:	e8 40 d1 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102f54:	f6 c2 02             	test   $0x2,%dl
f0102f57:	75 4e                	jne    f0102fa7 <mem_init+0x17a3>
f0102f59:	c7 44 24 0c 20 58 10 	movl   $0xf0105820,0xc(%esp)
f0102f60:	f0 
f0102f61:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102f68:	f0 
f0102f69:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
f0102f70:	00 
f0102f71:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102f78:	e8 17 d1 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102f7d:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102f81:	74 24                	je     f0102fa7 <mem_init+0x17a3>
f0102f83:	c7 44 24 0c 31 58 10 	movl   $0xf0105831,0xc(%esp)
f0102f8a:	f0 
f0102f8b:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0102f92:	f0 
f0102f93:	c7 44 24 04 cf 02 00 	movl   $0x2cf,0x4(%esp)
f0102f9a:	00 
f0102f9b:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102fa2:	e8 ed d0 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102fa7:	83 c0 01             	add    $0x1,%eax
f0102faa:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102faf:	0f 85 29 ff ff ff    	jne    f0102ede <mem_init+0x16da>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102fb5:	c7 04 24 9c 54 10 f0 	movl   $0xf010549c,(%esp)
f0102fbc:	e8 e5 03 00 00       	call   f01033a6 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102fc1:	a1 68 99 11 f0       	mov    0xf0119968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102fc6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102fcb:	77 20                	ja     f0102fed <mem_init+0x17e9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102fcd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102fd1:	c7 44 24 08 c4 4e 10 	movl   $0xf0104ec4,0x8(%esp)
f0102fd8:	f0 
f0102fd9:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
f0102fe0:	00 
f0102fe1:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0102fe8:	e8 a7 d0 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102fed:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102ff2:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102ff5:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ffa:	e8 29 e0 ff ff       	call   f0101028 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102fff:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0103002:	83 e0 f3             	and    $0xfffffff3,%eax
f0103005:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f010300a:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010300d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103014:	e8 71 e4 ff ff       	call   f010148a <page_alloc>
f0103019:	89 c3                	mov    %eax,%ebx
f010301b:	85 c0                	test   %eax,%eax
f010301d:	75 24                	jne    f0103043 <mem_init+0x183f>
f010301f:	c7 44 24 0c 2d 56 10 	movl   $0xf010562d,0xc(%esp)
f0103026:	f0 
f0103027:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f010302e:	f0 
f010302f:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f0103036:	00 
f0103037:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f010303e:	e8 51 d0 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0103043:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010304a:	e8 3b e4 ff ff       	call   f010148a <page_alloc>
f010304f:	89 c7                	mov    %eax,%edi
f0103051:	85 c0                	test   %eax,%eax
f0103053:	75 24                	jne    f0103079 <mem_init+0x1875>
f0103055:	c7 44 24 0c 43 56 10 	movl   $0xf0105643,0xc(%esp)
f010305c:	f0 
f010305d:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0103064:	f0 
f0103065:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f010306c:	00 
f010306d:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0103074:	e8 1b d0 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0103079:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103080:	e8 05 e4 ff ff       	call   f010148a <page_alloc>
f0103085:	89 c6                	mov    %eax,%esi
f0103087:	85 c0                	test   %eax,%eax
f0103089:	75 24                	jne    f01030af <mem_init+0x18ab>
f010308b:	c7 44 24 0c 59 56 10 	movl   $0xf0105659,0xc(%esp)
f0103092:	f0 
f0103093:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f010309a:	f0 
f010309b:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f01030a2:	00 
f01030a3:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01030aa:	e8 e5 cf ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f01030af:	89 1c 24             	mov    %ebx,(%esp)
f01030b2:	e8 5e e4 ff ff       	call   f0101515 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f01030b7:	89 f8                	mov    %edi,%eax
f01030b9:	e8 b6 de ff ff       	call   f0100f74 <page2kva>
f01030be:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01030c5:	00 
f01030c6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01030cd:	00 
f01030ce:	89 04 24             	mov    %eax,(%esp)
f01030d1:	e8 31 0e 00 00       	call   f0103f07 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01030d6:	89 f0                	mov    %esi,%eax
f01030d8:	e8 97 de ff ff       	call   f0100f74 <page2kva>
f01030dd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01030e4:	00 
f01030e5:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01030ec:	00 
f01030ed:	89 04 24             	mov    %eax,(%esp)
f01030f0:	e8 12 0e 00 00       	call   f0103f07 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01030f5:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01030fc:	00 
f01030fd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103104:	00 
f0103105:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103109:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f010310e:	89 04 24             	mov    %eax,(%esp)
f0103111:	e8 7f e6 ff ff       	call   f0101795 <page_insert>
	assert(pp1->pp_ref == 1);
f0103116:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010311b:	74 24                	je     f0103141 <mem_init+0x193d>
f010311d:	c7 44 24 0c 2a 57 10 	movl   $0xf010572a,0xc(%esp)
f0103124:	f0 
f0103125:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f010312c:	f0 
f010312d:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0103134:	00 
f0103135:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f010313c:	e8 53 cf ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103141:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0103148:	01 01 01 
f010314b:	74 24                	je     f0103171 <mem_init+0x196d>
f010314d:	c7 44 24 0c bc 54 10 	movl   $0xf01054bc,0xc(%esp)
f0103154:	f0 
f0103155:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f010315c:	f0 
f010315d:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0103164:	00 
f0103165:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f010316c:	e8 23 cf ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0103171:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103178:	00 
f0103179:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103180:	00 
f0103181:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103185:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f010318a:	89 04 24             	mov    %eax,(%esp)
f010318d:	e8 03 e6 ff ff       	call   f0101795 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0103192:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0103199:	02 02 02 
f010319c:	74 24                	je     f01031c2 <mem_init+0x19be>
f010319e:	c7 44 24 0c e0 54 10 	movl   $0xf01054e0,0xc(%esp)
f01031a5:	f0 
f01031a6:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01031ad:	f0 
f01031ae:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f01031b5:	00 
f01031b6:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01031bd:	e8 d2 ce ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f01031c2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01031c7:	74 24                	je     f01031ed <mem_init+0x19e9>
f01031c9:	c7 44 24 0c 4c 57 10 	movl   $0xf010574c,0xc(%esp)
f01031d0:	f0 
f01031d1:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01031d8:	f0 
f01031d9:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f01031e0:	00 
f01031e1:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01031e8:	e8 a7 ce ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f01031ed:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01031f2:	74 24                	je     f0103218 <mem_init+0x1a14>
f01031f4:	c7 44 24 0c b6 57 10 	movl   $0xf01057b6,0xc(%esp)
f01031fb:	f0 
f01031fc:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0103203:	f0 
f0103204:	c7 44 24 04 9b 03 00 	movl   $0x39b,0x4(%esp)
f010320b:	00 
f010320c:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0103213:	e8 7c ce ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0103218:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010321f:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0103222:	89 f0                	mov    %esi,%eax
f0103224:	e8 4b dd ff ff       	call   f0100f74 <page2kva>
f0103229:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f010322f:	74 24                	je     f0103255 <mem_init+0x1a51>
f0103231:	c7 44 24 0c 04 55 10 	movl   $0xf0105504,0xc(%esp)
f0103238:	f0 
f0103239:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0103240:	f0 
f0103241:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f0103248:	00 
f0103249:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0103250:	e8 3f ce ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0103255:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010325c:	00 
f010325d:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f0103262:	89 04 24             	mov    %eax,(%esp)
f0103265:	e8 ed e4 ff ff       	call   f0101757 <page_remove>
	assert(pp2->pp_ref == 0);
f010326a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010326f:	74 24                	je     f0103295 <mem_init+0x1a91>
f0103271:	c7 44 24 0c 84 57 10 	movl   $0xf0105784,0xc(%esp)
f0103278:	f0 
f0103279:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f0103280:	f0 
f0103281:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f0103288:	00 
f0103289:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0103290:	e8 ff cd ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103295:	a1 68 99 11 f0       	mov    0xf0119968,%eax
f010329a:	8b 08                	mov    (%eax),%ecx
f010329c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01032a2:	89 da                	mov    %ebx,%edx
f01032a4:	2b 15 6c 99 11 f0    	sub    0xf011996c,%edx
f01032aa:	c1 fa 03             	sar    $0x3,%edx
f01032ad:	c1 e2 0c             	shl    $0xc,%edx
f01032b0:	39 d1                	cmp    %edx,%ecx
f01032b2:	74 24                	je     f01032d8 <mem_init+0x1ad4>
f01032b4:	c7 44 24 0c 48 50 10 	movl   $0xf0105048,0xc(%esp)
f01032bb:	f0 
f01032bc:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01032c3:	f0 
f01032c4:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f01032cb:	00 
f01032cc:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f01032d3:	e8 bc cd ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f01032d8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01032de:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01032e3:	74 24                	je     f0103309 <mem_init+0x1b05>
f01032e5:	c7 44 24 0c 3b 57 10 	movl   $0xf010573b,0xc(%esp)
f01032ec:	f0 
f01032ed:	c7 44 24 08 82 55 10 	movl   $0xf0105582,0x8(%esp)
f01032f4:	f0 
f01032f5:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f01032fc:	00 
f01032fd:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f0103304:	e8 8b cd ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0103309:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f010330f:	89 1c 24             	mov    %ebx,(%esp)
f0103312:	e8 fe e1 ff ff       	call   f0101515 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0103317:	c7 04 24 30 55 10 f0 	movl   $0xf0105530,(%esp)
f010331e:	e8 83 00 00 00       	call   f01033a6 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0103323:	83 c4 4c             	add    $0x4c,%esp
f0103326:	5b                   	pop    %ebx
f0103327:	5e                   	pop    %esi
f0103328:	5f                   	pop    %edi
f0103329:	5d                   	pop    %ebp
f010332a:	c3                   	ret    

f010332b <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010332b:	55                   	push   %ebp
f010332c:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010332e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103331:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0103334:	5d                   	pop    %ebp
f0103335:	c3                   	ret    

f0103336 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103336:	55                   	push   %ebp
f0103337:	89 e5                	mov    %esp,%ebp
f0103339:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010333d:	ba 70 00 00 00       	mov    $0x70,%edx
f0103342:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103343:	b2 71                	mov    $0x71,%dl
f0103345:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103346:	0f b6 c0             	movzbl %al,%eax
}
f0103349:	5d                   	pop    %ebp
f010334a:	c3                   	ret    

f010334b <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010334b:	55                   	push   %ebp
f010334c:	89 e5                	mov    %esp,%ebp
f010334e:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103352:	ba 70 00 00 00       	mov    $0x70,%edx
f0103357:	ee                   	out    %al,(%dx)
f0103358:	b2 71                	mov    $0x71,%dl
f010335a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010335d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010335e:	5d                   	pop    %ebp
f010335f:	c3                   	ret    

f0103360 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103360:	55                   	push   %ebp
f0103361:	89 e5                	mov    %esp,%ebp
f0103363:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0103366:	8b 45 08             	mov    0x8(%ebp),%eax
f0103369:	89 04 24             	mov    %eax,(%esp)
f010336c:	e8 90 d2 ff ff       	call   f0100601 <cputchar>
	*cnt++;
}
f0103371:	c9                   	leave  
f0103372:	c3                   	ret    

f0103373 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103373:	55                   	push   %ebp
f0103374:	89 e5                	mov    %esp,%ebp
f0103376:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0103379:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103380:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103383:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103387:	8b 45 08             	mov    0x8(%ebp),%eax
f010338a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010338e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103391:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103395:	c7 04 24 60 33 10 f0 	movl   $0xf0103360,(%esp)
f010339c:	e8 ad 04 00 00       	call   f010384e <vprintfmt>
	return cnt;
}
f01033a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01033a4:	c9                   	leave  
f01033a5:	c3                   	ret    

f01033a6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01033a6:	55                   	push   %ebp
f01033a7:	89 e5                	mov    %esp,%ebp
f01033a9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01033ac:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01033af:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033b3:	8b 45 08             	mov    0x8(%ebp),%eax
f01033b6:	89 04 24             	mov    %eax,(%esp)
f01033b9:	e8 b5 ff ff ff       	call   f0103373 <vcprintf>
	va_end(ap);

	return cnt;
}
f01033be:	c9                   	leave  
f01033bf:	c3                   	ret    

f01033c0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01033c0:	55                   	push   %ebp
f01033c1:	89 e5                	mov    %esp,%ebp
f01033c3:	57                   	push   %edi
f01033c4:	56                   	push   %esi
f01033c5:	53                   	push   %ebx
f01033c6:	83 ec 10             	sub    $0x10,%esp
f01033c9:	89 c6                	mov    %eax,%esi
f01033cb:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01033ce:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01033d1:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01033d4:	8b 1a                	mov    (%edx),%ebx
f01033d6:	8b 01                	mov    (%ecx),%eax
f01033d8:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01033db:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f01033e2:	eb 77                	jmp    f010345b <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f01033e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01033e7:	01 d8                	add    %ebx,%eax
f01033e9:	b9 02 00 00 00       	mov    $0x2,%ecx
f01033ee:	99                   	cltd   
f01033ef:	f7 f9                	idiv   %ecx
f01033f1:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01033f3:	eb 01                	jmp    f01033f6 <stab_binsearch+0x36>
			m--;
f01033f5:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01033f6:	39 d9                	cmp    %ebx,%ecx
f01033f8:	7c 1d                	jl     f0103417 <stab_binsearch+0x57>
f01033fa:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01033fd:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0103402:	39 fa                	cmp    %edi,%edx
f0103404:	75 ef                	jne    f01033f5 <stab_binsearch+0x35>
f0103406:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103409:	6b d1 0c             	imul   $0xc,%ecx,%edx
f010340c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0103410:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103413:	73 18                	jae    f010342d <stab_binsearch+0x6d>
f0103415:	eb 05                	jmp    f010341c <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103417:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f010341a:	eb 3f                	jmp    f010345b <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f010341c:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f010341f:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0103421:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103424:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f010342b:	eb 2e                	jmp    f010345b <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010342d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103430:	73 15                	jae    f0103447 <stab_binsearch+0x87>
			*region_right = m - 1;
f0103432:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103435:	48                   	dec    %eax
f0103436:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103439:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010343c:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010343e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0103445:	eb 14                	jmp    f010345b <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103447:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010344a:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f010344d:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f010344f:	ff 45 0c             	incl   0xc(%ebp)
f0103452:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103454:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010345b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010345e:	7e 84                	jle    f01033e4 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103460:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0103464:	75 0d                	jne    f0103473 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0103466:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103469:	8b 00                	mov    (%eax),%eax
f010346b:	48                   	dec    %eax
f010346c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010346f:	89 07                	mov    %eax,(%edi)
f0103471:	eb 22                	jmp    f0103495 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103473:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103476:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103478:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f010347b:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010347d:	eb 01                	jmp    f0103480 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010347f:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103480:	39 c1                	cmp    %eax,%ecx
f0103482:	7d 0c                	jge    f0103490 <stab_binsearch+0xd0>
f0103484:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0103487:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f010348c:	39 fa                	cmp    %edi,%edx
f010348e:	75 ef                	jne    f010347f <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103490:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0103493:	89 07                	mov    %eax,(%edi)
	}
}
f0103495:	83 c4 10             	add    $0x10,%esp
f0103498:	5b                   	pop    %ebx
f0103499:	5e                   	pop    %esi
f010349a:	5f                   	pop    %edi
f010349b:	5d                   	pop    %ebp
f010349c:	c3                   	ret    

f010349d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010349d:	55                   	push   %ebp
f010349e:	89 e5                	mov    %esp,%ebp
f01034a0:	57                   	push   %edi
f01034a1:	56                   	push   %esi
f01034a2:	53                   	push   %ebx
f01034a3:	83 ec 3c             	sub    $0x3c,%esp
f01034a6:	8b 75 08             	mov    0x8(%ebp),%esi
f01034a9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01034ac:	c7 03 3f 58 10 f0    	movl   $0xf010583f,(%ebx)
	info->eip_line = 0;
f01034b2:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01034b9:	c7 43 08 3f 58 10 f0 	movl   $0xf010583f,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01034c0:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01034c7:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01034ca:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01034d1:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01034d7:	76 12                	jbe    f01034eb <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01034d9:	b8 60 e1 10 f0       	mov    $0xf010e160,%eax
f01034de:	3d 01 c2 10 f0       	cmp    $0xf010c201,%eax
f01034e3:	0f 86 cd 01 00 00    	jbe    f01036b6 <debuginfo_eip+0x219>
f01034e9:	eb 1c                	jmp    f0103507 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01034eb:	c7 44 24 08 49 58 10 	movl   $0xf0105849,0x8(%esp)
f01034f2:	f0 
f01034f3:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f01034fa:	00 
f01034fb:	c7 04 24 56 58 10 f0 	movl   $0xf0105856,(%esp)
f0103502:	e8 8d cb ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103507:	80 3d 5f e1 10 f0 00 	cmpb   $0x0,0xf010e15f
f010350e:	0f 85 a9 01 00 00    	jne    f01036bd <debuginfo_eip+0x220>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103514:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010351b:	b8 00 c2 10 f0       	mov    $0xf010c200,%eax
f0103520:	2d 74 5a 10 f0       	sub    $0xf0105a74,%eax
f0103525:	c1 f8 02             	sar    $0x2,%eax
f0103528:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010352e:	83 e8 01             	sub    $0x1,%eax
f0103531:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103534:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103538:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f010353f:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103542:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103545:	b8 74 5a 10 f0       	mov    $0xf0105a74,%eax
f010354a:	e8 71 fe ff ff       	call   f01033c0 <stab_binsearch>
	if (lfile == 0)
f010354f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103552:	85 c0                	test   %eax,%eax
f0103554:	0f 84 6a 01 00 00    	je     f01036c4 <debuginfo_eip+0x227>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010355a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010355d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103560:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103563:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103567:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f010356e:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103571:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103574:	b8 74 5a 10 f0       	mov    $0xf0105a74,%eax
f0103579:	e8 42 fe ff ff       	call   f01033c0 <stab_binsearch>

	if (lfun <= rfun) {
f010357e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103581:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103584:	39 d0                	cmp    %edx,%eax
f0103586:	7f 3d                	jg     f01035c5 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103588:	6b c8 0c             	imul   $0xc,%eax,%ecx
f010358b:	8d b9 74 5a 10 f0    	lea    -0xfefa58c(%ecx),%edi
f0103591:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0103594:	8b 89 74 5a 10 f0    	mov    -0xfefa58c(%ecx),%ecx
f010359a:	bf 60 e1 10 f0       	mov    $0xf010e160,%edi
f010359f:	81 ef 01 c2 10 f0    	sub    $0xf010c201,%edi
f01035a5:	39 f9                	cmp    %edi,%ecx
f01035a7:	73 09                	jae    f01035b2 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01035a9:	81 c1 01 c2 10 f0    	add    $0xf010c201,%ecx
f01035af:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01035b2:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01035b5:	8b 4f 08             	mov    0x8(%edi),%ecx
f01035b8:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01035bb:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01035bd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01035c0:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01035c3:	eb 0f                	jmp    f01035d4 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01035c5:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01035c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01035cb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01035ce:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01035d1:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01035d4:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f01035db:	00 
f01035dc:	8b 43 08             	mov    0x8(%ebx),%eax
f01035df:	89 04 24             	mov    %eax,(%esp)
f01035e2:	e8 04 09 00 00       	call   f0103eeb <strfind>
f01035e7:	2b 43 08             	sub    0x8(%ebx),%eax
f01035ea:	89 43 0c             	mov    %eax,0xc(%ebx)
	//
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01035ed:	89 74 24 04          	mov    %esi,0x4(%esp)
f01035f1:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f01035f8:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01035fb:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01035fe:	b8 74 5a 10 f0       	mov    $0xf0105a74,%eax
f0103603:	e8 b8 fd ff ff       	call   f01033c0 <stab_binsearch>
	
	if(lline <= rline){
f0103608:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010360b:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f010360e:	0f 8f b7 00 00 00    	jg     f01036cb <debuginfo_eip+0x22e>
		info->eip_line = stabs[lline].n_desc;
f0103614:	6b c0 0c             	imul   $0xc,%eax,%eax
f0103617:	0f b7 80 7a 5a 10 f0 	movzwl -0xfefa586(%eax),%eax
f010361e:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103621:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103624:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0103627:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010362a:	6b d0 0c             	imul   $0xc,%eax,%edx
f010362d:	81 c2 74 5a 10 f0    	add    $0xf0105a74,%edx
f0103633:	eb 06                	jmp    f010363b <debuginfo_eip+0x19e>
f0103635:	83 e8 01             	sub    $0x1,%eax
f0103638:	83 ea 0c             	sub    $0xc,%edx
f010363b:	89 c6                	mov    %eax,%esi
f010363d:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0103640:	7f 33                	jg     f0103675 <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f0103642:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103646:	80 f9 84             	cmp    $0x84,%cl
f0103649:	74 0b                	je     f0103656 <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010364b:	80 f9 64             	cmp    $0x64,%cl
f010364e:	75 e5                	jne    f0103635 <debuginfo_eip+0x198>
f0103650:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103654:	74 df                	je     f0103635 <debuginfo_eip+0x198>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103656:	6b f6 0c             	imul   $0xc,%esi,%esi
f0103659:	8b 86 74 5a 10 f0    	mov    -0xfefa58c(%esi),%eax
f010365f:	ba 60 e1 10 f0       	mov    $0xf010e160,%edx
f0103664:	81 ea 01 c2 10 f0    	sub    $0xf010c201,%edx
f010366a:	39 d0                	cmp    %edx,%eax
f010366c:	73 07                	jae    f0103675 <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010366e:	05 01 c2 10 f0       	add    $0xf010c201,%eax
f0103673:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103675:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103678:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010367b:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103680:	39 ca                	cmp    %ecx,%edx
f0103682:	7d 53                	jge    f01036d7 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f0103684:	8d 42 01             	lea    0x1(%edx),%eax
f0103687:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010368a:	89 c2                	mov    %eax,%edx
f010368c:	6b c0 0c             	imul   $0xc,%eax,%eax
f010368f:	05 74 5a 10 f0       	add    $0xf0105a74,%eax
f0103694:	89 ce                	mov    %ecx,%esi
f0103696:	eb 04                	jmp    f010369c <debuginfo_eip+0x1ff>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103698:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010369c:	39 d6                	cmp    %edx,%esi
f010369e:	7e 32                	jle    f01036d2 <debuginfo_eip+0x235>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01036a0:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01036a4:	83 c2 01             	add    $0x1,%edx
f01036a7:	83 c0 0c             	add    $0xc,%eax
f01036aa:	80 f9 a0             	cmp    $0xa0,%cl
f01036ad:	74 e9                	je     f0103698 <debuginfo_eip+0x1fb>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01036af:	b8 00 00 00 00       	mov    $0x0,%eax
f01036b4:	eb 21                	jmp    f01036d7 <debuginfo_eip+0x23a>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01036b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01036bb:	eb 1a                	jmp    f01036d7 <debuginfo_eip+0x23a>
f01036bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01036c2:	eb 13                	jmp    f01036d7 <debuginfo_eip+0x23a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01036c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01036c9:	eb 0c                	jmp    f01036d7 <debuginfo_eip+0x23a>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	
	if(lline <= rline){
		info->eip_line = stabs[lline].n_desc;
	}else{
		return -1;
f01036cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01036d0:	eb 05                	jmp    f01036d7 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01036d2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01036d7:	83 c4 3c             	add    $0x3c,%esp
f01036da:	5b                   	pop    %ebx
f01036db:	5e                   	pop    %esi
f01036dc:	5f                   	pop    %edi
f01036dd:	5d                   	pop    %ebp
f01036de:	c3                   	ret    
f01036df:	90                   	nop

f01036e0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01036e0:	55                   	push   %ebp
f01036e1:	89 e5                	mov    %esp,%ebp
f01036e3:	57                   	push   %edi
f01036e4:	56                   	push   %esi
f01036e5:	53                   	push   %ebx
f01036e6:	83 ec 3c             	sub    $0x3c,%esp
f01036e9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01036ec:	89 d7                	mov    %edx,%edi
f01036ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01036f1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01036f4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036f7:	89 c3                	mov    %eax,%ebx
f01036f9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01036fc:	8b 45 10             	mov    0x10(%ebp),%eax
f01036ff:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103702:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103707:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010370a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010370d:	39 d9                	cmp    %ebx,%ecx
f010370f:	72 05                	jb     f0103716 <printnum+0x36>
f0103711:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103714:	77 69                	ja     f010377f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103716:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0103719:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010371d:	83 ee 01             	sub    $0x1,%esi
f0103720:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103724:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103728:	8b 44 24 08          	mov    0x8(%esp),%eax
f010372c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103730:	89 c3                	mov    %eax,%ebx
f0103732:	89 d6                	mov    %edx,%esi
f0103734:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103737:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010373a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010373e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103742:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103745:	89 04 24             	mov    %eax,(%esp)
f0103748:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010374b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010374f:	e8 bc 09 00 00       	call   f0104110 <__udivdi3>
f0103754:	89 d9                	mov    %ebx,%ecx
f0103756:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010375a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010375e:	89 04 24             	mov    %eax,(%esp)
f0103761:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103765:	89 fa                	mov    %edi,%edx
f0103767:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010376a:	e8 71 ff ff ff       	call   f01036e0 <printnum>
f010376f:	eb 1b                	jmp    f010378c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103771:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103775:	8b 45 18             	mov    0x18(%ebp),%eax
f0103778:	89 04 24             	mov    %eax,(%esp)
f010377b:	ff d3                	call   *%ebx
f010377d:	eb 03                	jmp    f0103782 <printnum+0xa2>
f010377f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103782:	83 ee 01             	sub    $0x1,%esi
f0103785:	85 f6                	test   %esi,%esi
f0103787:	7f e8                	jg     f0103771 <printnum+0x91>
f0103789:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010378c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103790:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103794:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103797:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010379a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010379e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01037a2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01037a5:	89 04 24             	mov    %eax,(%esp)
f01037a8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01037ab:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037af:	e8 8c 0a 00 00       	call   f0104240 <__umoddi3>
f01037b4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01037b8:	0f be 80 64 58 10 f0 	movsbl -0xfefa79c(%eax),%eax
f01037bf:	89 04 24             	mov    %eax,(%esp)
f01037c2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01037c5:	ff d0                	call   *%eax
}
f01037c7:	83 c4 3c             	add    $0x3c,%esp
f01037ca:	5b                   	pop    %ebx
f01037cb:	5e                   	pop    %esi
f01037cc:	5f                   	pop    %edi
f01037cd:	5d                   	pop    %ebp
f01037ce:	c3                   	ret    

f01037cf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01037cf:	55                   	push   %ebp
f01037d0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01037d2:	83 fa 01             	cmp    $0x1,%edx
f01037d5:	7e 0e                	jle    f01037e5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01037d7:	8b 10                	mov    (%eax),%edx
f01037d9:	8d 4a 08             	lea    0x8(%edx),%ecx
f01037dc:	89 08                	mov    %ecx,(%eax)
f01037de:	8b 02                	mov    (%edx),%eax
f01037e0:	8b 52 04             	mov    0x4(%edx),%edx
f01037e3:	eb 22                	jmp    f0103807 <getuint+0x38>
	else if (lflag)
f01037e5:	85 d2                	test   %edx,%edx
f01037e7:	74 10                	je     f01037f9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01037e9:	8b 10                	mov    (%eax),%edx
f01037eb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01037ee:	89 08                	mov    %ecx,(%eax)
f01037f0:	8b 02                	mov    (%edx),%eax
f01037f2:	ba 00 00 00 00       	mov    $0x0,%edx
f01037f7:	eb 0e                	jmp    f0103807 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01037f9:	8b 10                	mov    (%eax),%edx
f01037fb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01037fe:	89 08                	mov    %ecx,(%eax)
f0103800:	8b 02                	mov    (%edx),%eax
f0103802:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103807:	5d                   	pop    %ebp
f0103808:	c3                   	ret    

f0103809 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103809:	55                   	push   %ebp
f010380a:	89 e5                	mov    %esp,%ebp
f010380c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010380f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103813:	8b 10                	mov    (%eax),%edx
f0103815:	3b 50 04             	cmp    0x4(%eax),%edx
f0103818:	73 0a                	jae    f0103824 <sprintputch+0x1b>
		*b->buf++ = ch;
f010381a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010381d:	89 08                	mov    %ecx,(%eax)
f010381f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103822:	88 02                	mov    %al,(%edx)
}
f0103824:	5d                   	pop    %ebp
f0103825:	c3                   	ret    

f0103826 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103826:	55                   	push   %ebp
f0103827:	89 e5                	mov    %esp,%ebp
f0103829:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010382c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010382f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103833:	8b 45 10             	mov    0x10(%ebp),%eax
f0103836:	89 44 24 08          	mov    %eax,0x8(%esp)
f010383a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010383d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103841:	8b 45 08             	mov    0x8(%ebp),%eax
f0103844:	89 04 24             	mov    %eax,(%esp)
f0103847:	e8 02 00 00 00       	call   f010384e <vprintfmt>
	va_end(ap);
}
f010384c:	c9                   	leave  
f010384d:	c3                   	ret    

f010384e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010384e:	55                   	push   %ebp
f010384f:	89 e5                	mov    %esp,%ebp
f0103851:	57                   	push   %edi
f0103852:	56                   	push   %esi
f0103853:	53                   	push   %ebx
f0103854:	83 ec 3c             	sub    $0x3c,%esp
f0103857:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010385a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010385d:	eb 14                	jmp    f0103873 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010385f:	85 c0                	test   %eax,%eax
f0103861:	0f 84 b3 03 00 00    	je     f0103c1a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0103867:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010386b:	89 04 24             	mov    %eax,(%esp)
f010386e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103871:	89 f3                	mov    %esi,%ebx
f0103873:	8d 73 01             	lea    0x1(%ebx),%esi
f0103876:	0f b6 03             	movzbl (%ebx),%eax
f0103879:	83 f8 25             	cmp    $0x25,%eax
f010387c:	75 e1                	jne    f010385f <vprintfmt+0x11>
f010387e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0103882:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103889:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0103890:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0103897:	ba 00 00 00 00       	mov    $0x0,%edx
f010389c:	eb 1d                	jmp    f01038bb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010389e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01038a0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01038a4:	eb 15                	jmp    f01038bb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01038a6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01038a8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01038ac:	eb 0d                	jmp    f01038bb <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01038ae:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01038b1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01038b4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01038bb:	8d 5e 01             	lea    0x1(%esi),%ebx
f01038be:	0f b6 0e             	movzbl (%esi),%ecx
f01038c1:	0f b6 c1             	movzbl %cl,%eax
f01038c4:	83 e9 23             	sub    $0x23,%ecx
f01038c7:	80 f9 55             	cmp    $0x55,%cl
f01038ca:	0f 87 2a 03 00 00    	ja     f0103bfa <vprintfmt+0x3ac>
f01038d0:	0f b6 c9             	movzbl %cl,%ecx
f01038d3:	ff 24 8d f0 58 10 f0 	jmp    *-0xfefa710(,%ecx,4)
f01038da:	89 de                	mov    %ebx,%esi
f01038dc:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01038e1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f01038e4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f01038e8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01038eb:	8d 58 d0             	lea    -0x30(%eax),%ebx
f01038ee:	83 fb 09             	cmp    $0x9,%ebx
f01038f1:	77 36                	ja     f0103929 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01038f3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01038f6:	eb e9                	jmp    f01038e1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01038f8:	8b 45 14             	mov    0x14(%ebp),%eax
f01038fb:	8d 48 04             	lea    0x4(%eax),%ecx
f01038fe:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103901:	8b 00                	mov    (%eax),%eax
f0103903:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103906:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103908:	eb 22                	jmp    f010392c <vprintfmt+0xde>
f010390a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010390d:	85 c9                	test   %ecx,%ecx
f010390f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103914:	0f 49 c1             	cmovns %ecx,%eax
f0103917:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010391a:	89 de                	mov    %ebx,%esi
f010391c:	eb 9d                	jmp    f01038bb <vprintfmt+0x6d>
f010391e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103920:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0103927:	eb 92                	jmp    f01038bb <vprintfmt+0x6d>
f0103929:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010392c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103930:	79 89                	jns    f01038bb <vprintfmt+0x6d>
f0103932:	e9 77 ff ff ff       	jmp    f01038ae <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103937:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010393a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010393c:	e9 7a ff ff ff       	jmp    f01038bb <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103941:	8b 45 14             	mov    0x14(%ebp),%eax
f0103944:	8d 50 04             	lea    0x4(%eax),%edx
f0103947:	89 55 14             	mov    %edx,0x14(%ebp)
f010394a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010394e:	8b 00                	mov    (%eax),%eax
f0103950:	89 04 24             	mov    %eax,(%esp)
f0103953:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103956:	e9 18 ff ff ff       	jmp    f0103873 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010395b:	8b 45 14             	mov    0x14(%ebp),%eax
f010395e:	8d 50 04             	lea    0x4(%eax),%edx
f0103961:	89 55 14             	mov    %edx,0x14(%ebp)
f0103964:	8b 00                	mov    (%eax),%eax
f0103966:	99                   	cltd   
f0103967:	31 d0                	xor    %edx,%eax
f0103969:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010396b:	83 f8 06             	cmp    $0x6,%eax
f010396e:	7f 0b                	jg     f010397b <vprintfmt+0x12d>
f0103970:	8b 14 85 48 5a 10 f0 	mov    -0xfefa5b8(,%eax,4),%edx
f0103977:	85 d2                	test   %edx,%edx
f0103979:	75 20                	jne    f010399b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010397b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010397f:	c7 44 24 08 7c 58 10 	movl   $0xf010587c,0x8(%esp)
f0103986:	f0 
f0103987:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010398b:	8b 45 08             	mov    0x8(%ebp),%eax
f010398e:	89 04 24             	mov    %eax,(%esp)
f0103991:	e8 90 fe ff ff       	call   f0103826 <printfmt>
f0103996:	e9 d8 fe ff ff       	jmp    f0103873 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010399b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010399f:	c7 44 24 08 94 55 10 	movl   $0xf0105594,0x8(%esp)
f01039a6:	f0 
f01039a7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01039ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01039ae:	89 04 24             	mov    %eax,(%esp)
f01039b1:	e8 70 fe ff ff       	call   f0103826 <printfmt>
f01039b6:	e9 b8 fe ff ff       	jmp    f0103873 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01039bb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01039be:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01039c1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01039c4:	8b 45 14             	mov    0x14(%ebp),%eax
f01039c7:	8d 50 04             	lea    0x4(%eax),%edx
f01039ca:	89 55 14             	mov    %edx,0x14(%ebp)
f01039cd:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01039cf:	85 f6                	test   %esi,%esi
f01039d1:	b8 75 58 10 f0       	mov    $0xf0105875,%eax
f01039d6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f01039d9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01039dd:	0f 84 97 00 00 00    	je     f0103a7a <vprintfmt+0x22c>
f01039e3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01039e7:	0f 8e 9b 00 00 00    	jle    f0103a88 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f01039ed:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01039f1:	89 34 24             	mov    %esi,(%esp)
f01039f4:	e8 9f 03 00 00       	call   f0103d98 <strnlen>
f01039f9:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01039fc:	29 c2                	sub    %eax,%edx
f01039fe:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0103a01:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103a05:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103a08:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0103a0b:	8b 75 08             	mov    0x8(%ebp),%esi
f0103a0e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103a11:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103a13:	eb 0f                	jmp    f0103a24 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0103a15:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103a19:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103a1c:	89 04 24             	mov    %eax,(%esp)
f0103a1f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103a21:	83 eb 01             	sub    $0x1,%ebx
f0103a24:	85 db                	test   %ebx,%ebx
f0103a26:	7f ed                	jg     f0103a15 <vprintfmt+0x1c7>
f0103a28:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0103a2b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0103a2e:	85 d2                	test   %edx,%edx
f0103a30:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a35:	0f 49 c2             	cmovns %edx,%eax
f0103a38:	29 c2                	sub    %eax,%edx
f0103a3a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0103a3d:	89 d7                	mov    %edx,%edi
f0103a3f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103a42:	eb 50                	jmp    f0103a94 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103a44:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103a48:	74 1e                	je     f0103a68 <vprintfmt+0x21a>
f0103a4a:	0f be d2             	movsbl %dl,%edx
f0103a4d:	83 ea 20             	sub    $0x20,%edx
f0103a50:	83 fa 5e             	cmp    $0x5e,%edx
f0103a53:	76 13                	jbe    f0103a68 <vprintfmt+0x21a>
					putch('?', putdat);
f0103a55:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a58:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a5c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103a63:	ff 55 08             	call   *0x8(%ebp)
f0103a66:	eb 0d                	jmp    f0103a75 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0103a68:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a6b:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103a6f:	89 04 24             	mov    %eax,(%esp)
f0103a72:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103a75:	83 ef 01             	sub    $0x1,%edi
f0103a78:	eb 1a                	jmp    f0103a94 <vprintfmt+0x246>
f0103a7a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0103a7d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0103a80:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103a83:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103a86:	eb 0c                	jmp    f0103a94 <vprintfmt+0x246>
f0103a88:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0103a8b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0103a8e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103a91:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103a94:	83 c6 01             	add    $0x1,%esi
f0103a97:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0103a9b:	0f be c2             	movsbl %dl,%eax
f0103a9e:	85 c0                	test   %eax,%eax
f0103aa0:	74 27                	je     f0103ac9 <vprintfmt+0x27b>
f0103aa2:	85 db                	test   %ebx,%ebx
f0103aa4:	78 9e                	js     f0103a44 <vprintfmt+0x1f6>
f0103aa6:	83 eb 01             	sub    $0x1,%ebx
f0103aa9:	79 99                	jns    f0103a44 <vprintfmt+0x1f6>
f0103aab:	89 f8                	mov    %edi,%eax
f0103aad:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103ab0:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ab3:	89 c3                	mov    %eax,%ebx
f0103ab5:	eb 1a                	jmp    f0103ad1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103ab7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103abb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103ac2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103ac4:	83 eb 01             	sub    $0x1,%ebx
f0103ac7:	eb 08                	jmp    f0103ad1 <vprintfmt+0x283>
f0103ac9:	89 fb                	mov    %edi,%ebx
f0103acb:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ace:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103ad1:	85 db                	test   %ebx,%ebx
f0103ad3:	7f e2                	jg     f0103ab7 <vprintfmt+0x269>
f0103ad5:	89 75 08             	mov    %esi,0x8(%ebp)
f0103ad8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0103adb:	e9 93 fd ff ff       	jmp    f0103873 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103ae0:	83 fa 01             	cmp    $0x1,%edx
f0103ae3:	7e 16                	jle    f0103afb <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0103ae5:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ae8:	8d 50 08             	lea    0x8(%eax),%edx
f0103aeb:	89 55 14             	mov    %edx,0x14(%ebp)
f0103aee:	8b 50 04             	mov    0x4(%eax),%edx
f0103af1:	8b 00                	mov    (%eax),%eax
f0103af3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103af6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103af9:	eb 32                	jmp    f0103b2d <vprintfmt+0x2df>
	else if (lflag)
f0103afb:	85 d2                	test   %edx,%edx
f0103afd:	74 18                	je     f0103b17 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f0103aff:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b02:	8d 50 04             	lea    0x4(%eax),%edx
f0103b05:	89 55 14             	mov    %edx,0x14(%ebp)
f0103b08:	8b 30                	mov    (%eax),%esi
f0103b0a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0103b0d:	89 f0                	mov    %esi,%eax
f0103b0f:	c1 f8 1f             	sar    $0x1f,%eax
f0103b12:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103b15:	eb 16                	jmp    f0103b2d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0103b17:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b1a:	8d 50 04             	lea    0x4(%eax),%edx
f0103b1d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103b20:	8b 30                	mov    (%eax),%esi
f0103b22:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0103b25:	89 f0                	mov    %esi,%eax
f0103b27:	c1 f8 1f             	sar    $0x1f,%eax
f0103b2a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103b2d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103b30:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103b33:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103b38:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b3c:	0f 89 80 00 00 00    	jns    f0103bc2 <vprintfmt+0x374>
				putch('-', putdat);
f0103b42:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103b46:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103b4d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103b50:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103b53:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103b56:	f7 d8                	neg    %eax
f0103b58:	83 d2 00             	adc    $0x0,%edx
f0103b5b:	f7 da                	neg    %edx
			}
			base = 10;
f0103b5d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103b62:	eb 5e                	jmp    f0103bc2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103b64:	8d 45 14             	lea    0x14(%ebp),%eax
f0103b67:	e8 63 fc ff ff       	call   f01037cf <getuint>
			base = 10;
f0103b6c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103b71:	eb 4f                	jmp    f0103bc2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0103b73:	8d 45 14             	lea    0x14(%ebp),%eax
f0103b76:	e8 54 fc ff ff       	call   f01037cf <getuint>
			base = 8;
f0103b7b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103b80:	eb 40                	jmp    f0103bc2 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f0103b82:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103b86:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0103b8d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103b90:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103b94:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103b9b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103b9e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ba1:	8d 50 04             	lea    0x4(%eax),%edx
f0103ba4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103ba7:	8b 00                	mov    (%eax),%eax
f0103ba9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103bae:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103bb3:	eb 0d                	jmp    f0103bc2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103bb5:	8d 45 14             	lea    0x14(%ebp),%eax
f0103bb8:	e8 12 fc ff ff       	call   f01037cf <getuint>
			base = 16;
f0103bbd:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103bc2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0103bc6:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103bca:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0103bcd:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103bd1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103bd5:	89 04 24             	mov    %eax,(%esp)
f0103bd8:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103bdc:	89 fa                	mov    %edi,%edx
f0103bde:	8b 45 08             	mov    0x8(%ebp),%eax
f0103be1:	e8 fa fa ff ff       	call   f01036e0 <printnum>
			break;
f0103be6:	e9 88 fc ff ff       	jmp    f0103873 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103beb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103bef:	89 04 24             	mov    %eax,(%esp)
f0103bf2:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103bf5:	e9 79 fc ff ff       	jmp    f0103873 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103bfa:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103bfe:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103c05:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103c08:	89 f3                	mov    %esi,%ebx
f0103c0a:	eb 03                	jmp    f0103c0f <vprintfmt+0x3c1>
f0103c0c:	83 eb 01             	sub    $0x1,%ebx
f0103c0f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0103c13:	75 f7                	jne    f0103c0c <vprintfmt+0x3be>
f0103c15:	e9 59 fc ff ff       	jmp    f0103873 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0103c1a:	83 c4 3c             	add    $0x3c,%esp
f0103c1d:	5b                   	pop    %ebx
f0103c1e:	5e                   	pop    %esi
f0103c1f:	5f                   	pop    %edi
f0103c20:	5d                   	pop    %ebp
f0103c21:	c3                   	ret    

f0103c22 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103c22:	55                   	push   %ebp
f0103c23:	89 e5                	mov    %esp,%ebp
f0103c25:	83 ec 28             	sub    $0x28,%esp
f0103c28:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c2b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103c2e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103c31:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103c35:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103c38:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103c3f:	85 c0                	test   %eax,%eax
f0103c41:	74 30                	je     f0103c73 <vsnprintf+0x51>
f0103c43:	85 d2                	test   %edx,%edx
f0103c45:	7e 2c                	jle    f0103c73 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103c47:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c4a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103c4e:	8b 45 10             	mov    0x10(%ebp),%eax
f0103c51:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c55:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103c58:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c5c:	c7 04 24 09 38 10 f0 	movl   $0xf0103809,(%esp)
f0103c63:	e8 e6 fb ff ff       	call   f010384e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103c68:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103c6b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103c6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103c71:	eb 05                	jmp    f0103c78 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103c73:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103c78:	c9                   	leave  
f0103c79:	c3                   	ret    

f0103c7a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103c7a:	55                   	push   %ebp
f0103c7b:	89 e5                	mov    %esp,%ebp
f0103c7d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103c80:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103c83:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103c87:	8b 45 10             	mov    0x10(%ebp),%eax
f0103c8a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c8e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103c91:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c95:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c98:	89 04 24             	mov    %eax,(%esp)
f0103c9b:	e8 82 ff ff ff       	call   f0103c22 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103ca0:	c9                   	leave  
f0103ca1:	c3                   	ret    
f0103ca2:	66 90                	xchg   %ax,%ax
f0103ca4:	66 90                	xchg   %ax,%ax
f0103ca6:	66 90                	xchg   %ax,%ax
f0103ca8:	66 90                	xchg   %ax,%ax
f0103caa:	66 90                	xchg   %ax,%ax
f0103cac:	66 90                	xchg   %ax,%ax
f0103cae:	66 90                	xchg   %ax,%ax

f0103cb0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103cb0:	55                   	push   %ebp
f0103cb1:	89 e5                	mov    %esp,%ebp
f0103cb3:	57                   	push   %edi
f0103cb4:	56                   	push   %esi
f0103cb5:	53                   	push   %ebx
f0103cb6:	83 ec 1c             	sub    $0x1c,%esp
f0103cb9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103cbc:	85 c0                	test   %eax,%eax
f0103cbe:	74 10                	je     f0103cd0 <readline+0x20>
		cprintf("%s", prompt);
f0103cc0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cc4:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0103ccb:	e8 d6 f6 ff ff       	call   f01033a6 <cprintf>

	i = 0;
	echoing = iscons(0);
f0103cd0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103cd7:	e8 46 c9 ff ff       	call   f0100622 <iscons>
f0103cdc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103cde:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103ce3:	e8 29 c9 ff ff       	call   f0100611 <getchar>
f0103ce8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103cea:	85 c0                	test   %eax,%eax
f0103cec:	79 17                	jns    f0103d05 <readline+0x55>
			cprintf("read error: %e\n", c);
f0103cee:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cf2:	c7 04 24 64 5a 10 f0 	movl   $0xf0105a64,(%esp)
f0103cf9:	e8 a8 f6 ff ff       	call   f01033a6 <cprintf>
			return NULL;
f0103cfe:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d03:	eb 6d                	jmp    f0103d72 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103d05:	83 f8 7f             	cmp    $0x7f,%eax
f0103d08:	74 05                	je     f0103d0f <readline+0x5f>
f0103d0a:	83 f8 08             	cmp    $0x8,%eax
f0103d0d:	75 19                	jne    f0103d28 <readline+0x78>
f0103d0f:	85 f6                	test   %esi,%esi
f0103d11:	7e 15                	jle    f0103d28 <readline+0x78>
			if (echoing)
f0103d13:	85 ff                	test   %edi,%edi
f0103d15:	74 0c                	je     f0103d23 <readline+0x73>
				cputchar('\b');
f0103d17:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0103d1e:	e8 de c8 ff ff       	call   f0100601 <cputchar>
			i--;
f0103d23:	83 ee 01             	sub    $0x1,%esi
f0103d26:	eb bb                	jmp    f0103ce3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103d28:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103d2e:	7f 1c                	jg     f0103d4c <readline+0x9c>
f0103d30:	83 fb 1f             	cmp    $0x1f,%ebx
f0103d33:	7e 17                	jle    f0103d4c <readline+0x9c>
			if (echoing)
f0103d35:	85 ff                	test   %edi,%edi
f0103d37:	74 08                	je     f0103d41 <readline+0x91>
				cputchar(c);
f0103d39:	89 1c 24             	mov    %ebx,(%esp)
f0103d3c:	e8 c0 c8 ff ff       	call   f0100601 <cputchar>
			buf[i++] = c;
f0103d41:	88 9e 60 95 11 f0    	mov    %bl,-0xfee6aa0(%esi)
f0103d47:	8d 76 01             	lea    0x1(%esi),%esi
f0103d4a:	eb 97                	jmp    f0103ce3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0103d4c:	83 fb 0d             	cmp    $0xd,%ebx
f0103d4f:	74 05                	je     f0103d56 <readline+0xa6>
f0103d51:	83 fb 0a             	cmp    $0xa,%ebx
f0103d54:	75 8d                	jne    f0103ce3 <readline+0x33>
			if (echoing)
f0103d56:	85 ff                	test   %edi,%edi
f0103d58:	74 0c                	je     f0103d66 <readline+0xb6>
				cputchar('\n');
f0103d5a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103d61:	e8 9b c8 ff ff       	call   f0100601 <cputchar>
			buf[i] = 0;
f0103d66:	c6 86 60 95 11 f0 00 	movb   $0x0,-0xfee6aa0(%esi)
			return buf;
f0103d6d:	b8 60 95 11 f0       	mov    $0xf0119560,%eax
		}
	}
}
f0103d72:	83 c4 1c             	add    $0x1c,%esp
f0103d75:	5b                   	pop    %ebx
f0103d76:	5e                   	pop    %esi
f0103d77:	5f                   	pop    %edi
f0103d78:	5d                   	pop    %ebp
f0103d79:	c3                   	ret    
f0103d7a:	66 90                	xchg   %ax,%ax
f0103d7c:	66 90                	xchg   %ax,%ax
f0103d7e:	66 90                	xchg   %ax,%ax

f0103d80 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103d80:	55                   	push   %ebp
f0103d81:	89 e5                	mov    %esp,%ebp
f0103d83:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103d86:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d8b:	eb 03                	jmp    f0103d90 <strlen+0x10>
		n++;
f0103d8d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103d90:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103d94:	75 f7                	jne    f0103d8d <strlen+0xd>
		n++;
	return n;
}
f0103d96:	5d                   	pop    %ebp
f0103d97:	c3                   	ret    

f0103d98 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103d98:	55                   	push   %ebp
f0103d99:	89 e5                	mov    %esp,%ebp
f0103d9b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103d9e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103da1:	b8 00 00 00 00       	mov    $0x0,%eax
f0103da6:	eb 03                	jmp    f0103dab <strnlen+0x13>
		n++;
f0103da8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103dab:	39 d0                	cmp    %edx,%eax
f0103dad:	74 06                	je     f0103db5 <strnlen+0x1d>
f0103daf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103db3:	75 f3                	jne    f0103da8 <strnlen+0x10>
		n++;
	return n;
}
f0103db5:	5d                   	pop    %ebp
f0103db6:	c3                   	ret    

f0103db7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103db7:	55                   	push   %ebp
f0103db8:	89 e5                	mov    %esp,%ebp
f0103dba:	53                   	push   %ebx
f0103dbb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103dbe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103dc1:	89 c2                	mov    %eax,%edx
f0103dc3:	83 c2 01             	add    $0x1,%edx
f0103dc6:	83 c1 01             	add    $0x1,%ecx
f0103dc9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103dcd:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103dd0:	84 db                	test   %bl,%bl
f0103dd2:	75 ef                	jne    f0103dc3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103dd4:	5b                   	pop    %ebx
f0103dd5:	5d                   	pop    %ebp
f0103dd6:	c3                   	ret    

f0103dd7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103dd7:	55                   	push   %ebp
f0103dd8:	89 e5                	mov    %esp,%ebp
f0103dda:	53                   	push   %ebx
f0103ddb:	83 ec 08             	sub    $0x8,%esp
f0103dde:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103de1:	89 1c 24             	mov    %ebx,(%esp)
f0103de4:	e8 97 ff ff ff       	call   f0103d80 <strlen>
	strcpy(dst + len, src);
f0103de9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103dec:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103df0:	01 d8                	add    %ebx,%eax
f0103df2:	89 04 24             	mov    %eax,(%esp)
f0103df5:	e8 bd ff ff ff       	call   f0103db7 <strcpy>
	return dst;
}
f0103dfa:	89 d8                	mov    %ebx,%eax
f0103dfc:	83 c4 08             	add    $0x8,%esp
f0103dff:	5b                   	pop    %ebx
f0103e00:	5d                   	pop    %ebp
f0103e01:	c3                   	ret    

f0103e02 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103e02:	55                   	push   %ebp
f0103e03:	89 e5                	mov    %esp,%ebp
f0103e05:	56                   	push   %esi
f0103e06:	53                   	push   %ebx
f0103e07:	8b 75 08             	mov    0x8(%ebp),%esi
f0103e0a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103e0d:	89 f3                	mov    %esi,%ebx
f0103e0f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103e12:	89 f2                	mov    %esi,%edx
f0103e14:	eb 0f                	jmp    f0103e25 <strncpy+0x23>
		*dst++ = *src;
f0103e16:	83 c2 01             	add    $0x1,%edx
f0103e19:	0f b6 01             	movzbl (%ecx),%eax
f0103e1c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103e1f:	80 39 01             	cmpb   $0x1,(%ecx)
f0103e22:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103e25:	39 da                	cmp    %ebx,%edx
f0103e27:	75 ed                	jne    f0103e16 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103e29:	89 f0                	mov    %esi,%eax
f0103e2b:	5b                   	pop    %ebx
f0103e2c:	5e                   	pop    %esi
f0103e2d:	5d                   	pop    %ebp
f0103e2e:	c3                   	ret    

f0103e2f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103e2f:	55                   	push   %ebp
f0103e30:	89 e5                	mov    %esp,%ebp
f0103e32:	56                   	push   %esi
f0103e33:	53                   	push   %ebx
f0103e34:	8b 75 08             	mov    0x8(%ebp),%esi
f0103e37:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103e3a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103e3d:	89 f0                	mov    %esi,%eax
f0103e3f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103e43:	85 c9                	test   %ecx,%ecx
f0103e45:	75 0b                	jne    f0103e52 <strlcpy+0x23>
f0103e47:	eb 1d                	jmp    f0103e66 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103e49:	83 c0 01             	add    $0x1,%eax
f0103e4c:	83 c2 01             	add    $0x1,%edx
f0103e4f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103e52:	39 d8                	cmp    %ebx,%eax
f0103e54:	74 0b                	je     f0103e61 <strlcpy+0x32>
f0103e56:	0f b6 0a             	movzbl (%edx),%ecx
f0103e59:	84 c9                	test   %cl,%cl
f0103e5b:	75 ec                	jne    f0103e49 <strlcpy+0x1a>
f0103e5d:	89 c2                	mov    %eax,%edx
f0103e5f:	eb 02                	jmp    f0103e63 <strlcpy+0x34>
f0103e61:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0103e63:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0103e66:	29 f0                	sub    %esi,%eax
}
f0103e68:	5b                   	pop    %ebx
f0103e69:	5e                   	pop    %esi
f0103e6a:	5d                   	pop    %ebp
f0103e6b:	c3                   	ret    

f0103e6c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103e6c:	55                   	push   %ebp
f0103e6d:	89 e5                	mov    %esp,%ebp
f0103e6f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103e72:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103e75:	eb 06                	jmp    f0103e7d <strcmp+0x11>
		p++, q++;
f0103e77:	83 c1 01             	add    $0x1,%ecx
f0103e7a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103e7d:	0f b6 01             	movzbl (%ecx),%eax
f0103e80:	84 c0                	test   %al,%al
f0103e82:	74 04                	je     f0103e88 <strcmp+0x1c>
f0103e84:	3a 02                	cmp    (%edx),%al
f0103e86:	74 ef                	je     f0103e77 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103e88:	0f b6 c0             	movzbl %al,%eax
f0103e8b:	0f b6 12             	movzbl (%edx),%edx
f0103e8e:	29 d0                	sub    %edx,%eax
}
f0103e90:	5d                   	pop    %ebp
f0103e91:	c3                   	ret    

f0103e92 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103e92:	55                   	push   %ebp
f0103e93:	89 e5                	mov    %esp,%ebp
f0103e95:	53                   	push   %ebx
f0103e96:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e99:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103e9c:	89 c3                	mov    %eax,%ebx
f0103e9e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103ea1:	eb 06                	jmp    f0103ea9 <strncmp+0x17>
		n--, p++, q++;
f0103ea3:	83 c0 01             	add    $0x1,%eax
f0103ea6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103ea9:	39 d8                	cmp    %ebx,%eax
f0103eab:	74 15                	je     f0103ec2 <strncmp+0x30>
f0103ead:	0f b6 08             	movzbl (%eax),%ecx
f0103eb0:	84 c9                	test   %cl,%cl
f0103eb2:	74 04                	je     f0103eb8 <strncmp+0x26>
f0103eb4:	3a 0a                	cmp    (%edx),%cl
f0103eb6:	74 eb                	je     f0103ea3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103eb8:	0f b6 00             	movzbl (%eax),%eax
f0103ebb:	0f b6 12             	movzbl (%edx),%edx
f0103ebe:	29 d0                	sub    %edx,%eax
f0103ec0:	eb 05                	jmp    f0103ec7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103ec2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103ec7:	5b                   	pop    %ebx
f0103ec8:	5d                   	pop    %ebp
f0103ec9:	c3                   	ret    

f0103eca <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103eca:	55                   	push   %ebp
f0103ecb:	89 e5                	mov    %esp,%ebp
f0103ecd:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ed0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103ed4:	eb 07                	jmp    f0103edd <strchr+0x13>
		if (*s == c)
f0103ed6:	38 ca                	cmp    %cl,%dl
f0103ed8:	74 0f                	je     f0103ee9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103eda:	83 c0 01             	add    $0x1,%eax
f0103edd:	0f b6 10             	movzbl (%eax),%edx
f0103ee0:	84 d2                	test   %dl,%dl
f0103ee2:	75 f2                	jne    f0103ed6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103ee4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103ee9:	5d                   	pop    %ebp
f0103eea:	c3                   	ret    

f0103eeb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103eeb:	55                   	push   %ebp
f0103eec:	89 e5                	mov    %esp,%ebp
f0103eee:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ef1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103ef5:	eb 07                	jmp    f0103efe <strfind+0x13>
		if (*s == c)
f0103ef7:	38 ca                	cmp    %cl,%dl
f0103ef9:	74 0a                	je     f0103f05 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103efb:	83 c0 01             	add    $0x1,%eax
f0103efe:	0f b6 10             	movzbl (%eax),%edx
f0103f01:	84 d2                	test   %dl,%dl
f0103f03:	75 f2                	jne    f0103ef7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0103f05:	5d                   	pop    %ebp
f0103f06:	c3                   	ret    

f0103f07 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103f07:	55                   	push   %ebp
f0103f08:	89 e5                	mov    %esp,%ebp
f0103f0a:	57                   	push   %edi
f0103f0b:	56                   	push   %esi
f0103f0c:	53                   	push   %ebx
f0103f0d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103f10:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103f13:	85 c9                	test   %ecx,%ecx
f0103f15:	74 36                	je     f0103f4d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103f17:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103f1d:	75 28                	jne    f0103f47 <memset+0x40>
f0103f1f:	f6 c1 03             	test   $0x3,%cl
f0103f22:	75 23                	jne    f0103f47 <memset+0x40>
		c &= 0xFF;
f0103f24:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103f28:	89 d3                	mov    %edx,%ebx
f0103f2a:	c1 e3 08             	shl    $0x8,%ebx
f0103f2d:	89 d6                	mov    %edx,%esi
f0103f2f:	c1 e6 18             	shl    $0x18,%esi
f0103f32:	89 d0                	mov    %edx,%eax
f0103f34:	c1 e0 10             	shl    $0x10,%eax
f0103f37:	09 f0                	or     %esi,%eax
f0103f39:	09 c2                	or     %eax,%edx
f0103f3b:	89 d0                	mov    %edx,%eax
f0103f3d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103f3f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103f42:	fc                   	cld    
f0103f43:	f3 ab                	rep stos %eax,%es:(%edi)
f0103f45:	eb 06                	jmp    f0103f4d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103f47:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f4a:	fc                   	cld    
f0103f4b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103f4d:	89 f8                	mov    %edi,%eax
f0103f4f:	5b                   	pop    %ebx
f0103f50:	5e                   	pop    %esi
f0103f51:	5f                   	pop    %edi
f0103f52:	5d                   	pop    %ebp
f0103f53:	c3                   	ret    

f0103f54 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103f54:	55                   	push   %ebp
f0103f55:	89 e5                	mov    %esp,%ebp
f0103f57:	57                   	push   %edi
f0103f58:	56                   	push   %esi
f0103f59:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f5c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103f5f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103f62:	39 c6                	cmp    %eax,%esi
f0103f64:	73 35                	jae    f0103f9b <memmove+0x47>
f0103f66:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103f69:	39 d0                	cmp    %edx,%eax
f0103f6b:	73 2e                	jae    f0103f9b <memmove+0x47>
		s += n;
		d += n;
f0103f6d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0103f70:	89 d6                	mov    %edx,%esi
f0103f72:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103f74:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103f7a:	75 13                	jne    f0103f8f <memmove+0x3b>
f0103f7c:	f6 c1 03             	test   $0x3,%cl
f0103f7f:	75 0e                	jne    f0103f8f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103f81:	83 ef 04             	sub    $0x4,%edi
f0103f84:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103f87:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0103f8a:	fd                   	std    
f0103f8b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103f8d:	eb 09                	jmp    f0103f98 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103f8f:	83 ef 01             	sub    $0x1,%edi
f0103f92:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103f95:	fd                   	std    
f0103f96:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103f98:	fc                   	cld    
f0103f99:	eb 1d                	jmp    f0103fb8 <memmove+0x64>
f0103f9b:	89 f2                	mov    %esi,%edx
f0103f9d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103f9f:	f6 c2 03             	test   $0x3,%dl
f0103fa2:	75 0f                	jne    f0103fb3 <memmove+0x5f>
f0103fa4:	f6 c1 03             	test   $0x3,%cl
f0103fa7:	75 0a                	jne    f0103fb3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103fa9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103fac:	89 c7                	mov    %eax,%edi
f0103fae:	fc                   	cld    
f0103faf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103fb1:	eb 05                	jmp    f0103fb8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103fb3:	89 c7                	mov    %eax,%edi
f0103fb5:	fc                   	cld    
f0103fb6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103fb8:	5e                   	pop    %esi
f0103fb9:	5f                   	pop    %edi
f0103fba:	5d                   	pop    %ebp
f0103fbb:	c3                   	ret    

f0103fbc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103fbc:	55                   	push   %ebp
f0103fbd:	89 e5                	mov    %esp,%ebp
f0103fbf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103fc2:	8b 45 10             	mov    0x10(%ebp),%eax
f0103fc5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103fc9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103fcc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103fd0:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fd3:	89 04 24             	mov    %eax,(%esp)
f0103fd6:	e8 79 ff ff ff       	call   f0103f54 <memmove>
}
f0103fdb:	c9                   	leave  
f0103fdc:	c3                   	ret    

f0103fdd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103fdd:	55                   	push   %ebp
f0103fde:	89 e5                	mov    %esp,%ebp
f0103fe0:	56                   	push   %esi
f0103fe1:	53                   	push   %ebx
f0103fe2:	8b 55 08             	mov    0x8(%ebp),%edx
f0103fe5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103fe8:	89 d6                	mov    %edx,%esi
f0103fea:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103fed:	eb 1a                	jmp    f0104009 <memcmp+0x2c>
		if (*s1 != *s2)
f0103fef:	0f b6 02             	movzbl (%edx),%eax
f0103ff2:	0f b6 19             	movzbl (%ecx),%ebx
f0103ff5:	38 d8                	cmp    %bl,%al
f0103ff7:	74 0a                	je     f0104003 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103ff9:	0f b6 c0             	movzbl %al,%eax
f0103ffc:	0f b6 db             	movzbl %bl,%ebx
f0103fff:	29 d8                	sub    %ebx,%eax
f0104001:	eb 0f                	jmp    f0104012 <memcmp+0x35>
		s1++, s2++;
f0104003:	83 c2 01             	add    $0x1,%edx
f0104006:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104009:	39 f2                	cmp    %esi,%edx
f010400b:	75 e2                	jne    f0103fef <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010400d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104012:	5b                   	pop    %ebx
f0104013:	5e                   	pop    %esi
f0104014:	5d                   	pop    %ebp
f0104015:	c3                   	ret    

f0104016 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104016:	55                   	push   %ebp
f0104017:	89 e5                	mov    %esp,%ebp
f0104019:	8b 45 08             	mov    0x8(%ebp),%eax
f010401c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010401f:	89 c2                	mov    %eax,%edx
f0104021:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104024:	eb 07                	jmp    f010402d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104026:	38 08                	cmp    %cl,(%eax)
f0104028:	74 07                	je     f0104031 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010402a:	83 c0 01             	add    $0x1,%eax
f010402d:	39 d0                	cmp    %edx,%eax
f010402f:	72 f5                	jb     f0104026 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104031:	5d                   	pop    %ebp
f0104032:	c3                   	ret    

f0104033 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104033:	55                   	push   %ebp
f0104034:	89 e5                	mov    %esp,%ebp
f0104036:	57                   	push   %edi
f0104037:	56                   	push   %esi
f0104038:	53                   	push   %ebx
f0104039:	8b 55 08             	mov    0x8(%ebp),%edx
f010403c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010403f:	eb 03                	jmp    f0104044 <strtol+0x11>
		s++;
f0104041:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104044:	0f b6 0a             	movzbl (%edx),%ecx
f0104047:	80 f9 09             	cmp    $0x9,%cl
f010404a:	74 f5                	je     f0104041 <strtol+0xe>
f010404c:	80 f9 20             	cmp    $0x20,%cl
f010404f:	74 f0                	je     f0104041 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104051:	80 f9 2b             	cmp    $0x2b,%cl
f0104054:	75 0a                	jne    f0104060 <strtol+0x2d>
		s++;
f0104056:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104059:	bf 00 00 00 00       	mov    $0x0,%edi
f010405e:	eb 11                	jmp    f0104071 <strtol+0x3e>
f0104060:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104065:	80 f9 2d             	cmp    $0x2d,%cl
f0104068:	75 07                	jne    f0104071 <strtol+0x3e>
		s++, neg = 1;
f010406a:	8d 52 01             	lea    0x1(%edx),%edx
f010406d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104071:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0104076:	75 15                	jne    f010408d <strtol+0x5a>
f0104078:	80 3a 30             	cmpb   $0x30,(%edx)
f010407b:	75 10                	jne    f010408d <strtol+0x5a>
f010407d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104081:	75 0a                	jne    f010408d <strtol+0x5a>
		s += 2, base = 16;
f0104083:	83 c2 02             	add    $0x2,%edx
f0104086:	b8 10 00 00 00       	mov    $0x10,%eax
f010408b:	eb 10                	jmp    f010409d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010408d:	85 c0                	test   %eax,%eax
f010408f:	75 0c                	jne    f010409d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104091:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104093:	80 3a 30             	cmpb   $0x30,(%edx)
f0104096:	75 05                	jne    f010409d <strtol+0x6a>
		s++, base = 8;
f0104098:	83 c2 01             	add    $0x1,%edx
f010409b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010409d:	bb 00 00 00 00       	mov    $0x0,%ebx
f01040a2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01040a5:	0f b6 0a             	movzbl (%edx),%ecx
f01040a8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01040ab:	89 f0                	mov    %esi,%eax
f01040ad:	3c 09                	cmp    $0x9,%al
f01040af:	77 08                	ja     f01040b9 <strtol+0x86>
			dig = *s - '0';
f01040b1:	0f be c9             	movsbl %cl,%ecx
f01040b4:	83 e9 30             	sub    $0x30,%ecx
f01040b7:	eb 20                	jmp    f01040d9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f01040b9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01040bc:	89 f0                	mov    %esi,%eax
f01040be:	3c 19                	cmp    $0x19,%al
f01040c0:	77 08                	ja     f01040ca <strtol+0x97>
			dig = *s - 'a' + 10;
f01040c2:	0f be c9             	movsbl %cl,%ecx
f01040c5:	83 e9 57             	sub    $0x57,%ecx
f01040c8:	eb 0f                	jmp    f01040d9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f01040ca:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01040cd:	89 f0                	mov    %esi,%eax
f01040cf:	3c 19                	cmp    $0x19,%al
f01040d1:	77 16                	ja     f01040e9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f01040d3:	0f be c9             	movsbl %cl,%ecx
f01040d6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01040d9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01040dc:	7d 0f                	jge    f01040ed <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f01040de:	83 c2 01             	add    $0x1,%edx
f01040e1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01040e5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01040e7:	eb bc                	jmp    f01040a5 <strtol+0x72>
f01040e9:	89 d8                	mov    %ebx,%eax
f01040eb:	eb 02                	jmp    f01040ef <strtol+0xbc>
f01040ed:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01040ef:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01040f3:	74 05                	je     f01040fa <strtol+0xc7>
		*endptr = (char *) s;
f01040f5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01040f8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01040fa:	f7 d8                	neg    %eax
f01040fc:	85 ff                	test   %edi,%edi
f01040fe:	0f 44 c3             	cmove  %ebx,%eax
}
f0104101:	5b                   	pop    %ebx
f0104102:	5e                   	pop    %esi
f0104103:	5f                   	pop    %edi
f0104104:	5d                   	pop    %ebp
f0104105:	c3                   	ret    
f0104106:	66 90                	xchg   %ax,%ax
f0104108:	66 90                	xchg   %ax,%ax
f010410a:	66 90                	xchg   %ax,%ax
f010410c:	66 90                	xchg   %ax,%ax
f010410e:	66 90                	xchg   %ax,%ax

f0104110 <__udivdi3>:
f0104110:	55                   	push   %ebp
f0104111:	57                   	push   %edi
f0104112:	56                   	push   %esi
f0104113:	83 ec 0c             	sub    $0xc,%esp
f0104116:	8b 44 24 28          	mov    0x28(%esp),%eax
f010411a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010411e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0104122:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104126:	85 c0                	test   %eax,%eax
f0104128:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010412c:	89 ea                	mov    %ebp,%edx
f010412e:	89 0c 24             	mov    %ecx,(%esp)
f0104131:	75 2d                	jne    f0104160 <__udivdi3+0x50>
f0104133:	39 e9                	cmp    %ebp,%ecx
f0104135:	77 61                	ja     f0104198 <__udivdi3+0x88>
f0104137:	85 c9                	test   %ecx,%ecx
f0104139:	89 ce                	mov    %ecx,%esi
f010413b:	75 0b                	jne    f0104148 <__udivdi3+0x38>
f010413d:	b8 01 00 00 00       	mov    $0x1,%eax
f0104142:	31 d2                	xor    %edx,%edx
f0104144:	f7 f1                	div    %ecx
f0104146:	89 c6                	mov    %eax,%esi
f0104148:	31 d2                	xor    %edx,%edx
f010414a:	89 e8                	mov    %ebp,%eax
f010414c:	f7 f6                	div    %esi
f010414e:	89 c5                	mov    %eax,%ebp
f0104150:	89 f8                	mov    %edi,%eax
f0104152:	f7 f6                	div    %esi
f0104154:	89 ea                	mov    %ebp,%edx
f0104156:	83 c4 0c             	add    $0xc,%esp
f0104159:	5e                   	pop    %esi
f010415a:	5f                   	pop    %edi
f010415b:	5d                   	pop    %ebp
f010415c:	c3                   	ret    
f010415d:	8d 76 00             	lea    0x0(%esi),%esi
f0104160:	39 e8                	cmp    %ebp,%eax
f0104162:	77 24                	ja     f0104188 <__udivdi3+0x78>
f0104164:	0f bd e8             	bsr    %eax,%ebp
f0104167:	83 f5 1f             	xor    $0x1f,%ebp
f010416a:	75 3c                	jne    f01041a8 <__udivdi3+0x98>
f010416c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0104170:	39 34 24             	cmp    %esi,(%esp)
f0104173:	0f 86 9f 00 00 00    	jbe    f0104218 <__udivdi3+0x108>
f0104179:	39 d0                	cmp    %edx,%eax
f010417b:	0f 82 97 00 00 00    	jb     f0104218 <__udivdi3+0x108>
f0104181:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104188:	31 d2                	xor    %edx,%edx
f010418a:	31 c0                	xor    %eax,%eax
f010418c:	83 c4 0c             	add    $0xc,%esp
f010418f:	5e                   	pop    %esi
f0104190:	5f                   	pop    %edi
f0104191:	5d                   	pop    %ebp
f0104192:	c3                   	ret    
f0104193:	90                   	nop
f0104194:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104198:	89 f8                	mov    %edi,%eax
f010419a:	f7 f1                	div    %ecx
f010419c:	31 d2                	xor    %edx,%edx
f010419e:	83 c4 0c             	add    $0xc,%esp
f01041a1:	5e                   	pop    %esi
f01041a2:	5f                   	pop    %edi
f01041a3:	5d                   	pop    %ebp
f01041a4:	c3                   	ret    
f01041a5:	8d 76 00             	lea    0x0(%esi),%esi
f01041a8:	89 e9                	mov    %ebp,%ecx
f01041aa:	8b 3c 24             	mov    (%esp),%edi
f01041ad:	d3 e0                	shl    %cl,%eax
f01041af:	89 c6                	mov    %eax,%esi
f01041b1:	b8 20 00 00 00       	mov    $0x20,%eax
f01041b6:	29 e8                	sub    %ebp,%eax
f01041b8:	89 c1                	mov    %eax,%ecx
f01041ba:	d3 ef                	shr    %cl,%edi
f01041bc:	89 e9                	mov    %ebp,%ecx
f01041be:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01041c2:	8b 3c 24             	mov    (%esp),%edi
f01041c5:	09 74 24 08          	or     %esi,0x8(%esp)
f01041c9:	89 d6                	mov    %edx,%esi
f01041cb:	d3 e7                	shl    %cl,%edi
f01041cd:	89 c1                	mov    %eax,%ecx
f01041cf:	89 3c 24             	mov    %edi,(%esp)
f01041d2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01041d6:	d3 ee                	shr    %cl,%esi
f01041d8:	89 e9                	mov    %ebp,%ecx
f01041da:	d3 e2                	shl    %cl,%edx
f01041dc:	89 c1                	mov    %eax,%ecx
f01041de:	d3 ef                	shr    %cl,%edi
f01041e0:	09 d7                	or     %edx,%edi
f01041e2:	89 f2                	mov    %esi,%edx
f01041e4:	89 f8                	mov    %edi,%eax
f01041e6:	f7 74 24 08          	divl   0x8(%esp)
f01041ea:	89 d6                	mov    %edx,%esi
f01041ec:	89 c7                	mov    %eax,%edi
f01041ee:	f7 24 24             	mull   (%esp)
f01041f1:	39 d6                	cmp    %edx,%esi
f01041f3:	89 14 24             	mov    %edx,(%esp)
f01041f6:	72 30                	jb     f0104228 <__udivdi3+0x118>
f01041f8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01041fc:	89 e9                	mov    %ebp,%ecx
f01041fe:	d3 e2                	shl    %cl,%edx
f0104200:	39 c2                	cmp    %eax,%edx
f0104202:	73 05                	jae    f0104209 <__udivdi3+0xf9>
f0104204:	3b 34 24             	cmp    (%esp),%esi
f0104207:	74 1f                	je     f0104228 <__udivdi3+0x118>
f0104209:	89 f8                	mov    %edi,%eax
f010420b:	31 d2                	xor    %edx,%edx
f010420d:	e9 7a ff ff ff       	jmp    f010418c <__udivdi3+0x7c>
f0104212:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104218:	31 d2                	xor    %edx,%edx
f010421a:	b8 01 00 00 00       	mov    $0x1,%eax
f010421f:	e9 68 ff ff ff       	jmp    f010418c <__udivdi3+0x7c>
f0104224:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104228:	8d 47 ff             	lea    -0x1(%edi),%eax
f010422b:	31 d2                	xor    %edx,%edx
f010422d:	83 c4 0c             	add    $0xc,%esp
f0104230:	5e                   	pop    %esi
f0104231:	5f                   	pop    %edi
f0104232:	5d                   	pop    %ebp
f0104233:	c3                   	ret    
f0104234:	66 90                	xchg   %ax,%ax
f0104236:	66 90                	xchg   %ax,%ax
f0104238:	66 90                	xchg   %ax,%ax
f010423a:	66 90                	xchg   %ax,%ax
f010423c:	66 90                	xchg   %ax,%ax
f010423e:	66 90                	xchg   %ax,%ax

f0104240 <__umoddi3>:
f0104240:	55                   	push   %ebp
f0104241:	57                   	push   %edi
f0104242:	56                   	push   %esi
f0104243:	83 ec 14             	sub    $0x14,%esp
f0104246:	8b 44 24 28          	mov    0x28(%esp),%eax
f010424a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010424e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0104252:	89 c7                	mov    %eax,%edi
f0104254:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104258:	8b 44 24 30          	mov    0x30(%esp),%eax
f010425c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0104260:	89 34 24             	mov    %esi,(%esp)
f0104263:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104267:	85 c0                	test   %eax,%eax
f0104269:	89 c2                	mov    %eax,%edx
f010426b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010426f:	75 17                	jne    f0104288 <__umoddi3+0x48>
f0104271:	39 fe                	cmp    %edi,%esi
f0104273:	76 4b                	jbe    f01042c0 <__umoddi3+0x80>
f0104275:	89 c8                	mov    %ecx,%eax
f0104277:	89 fa                	mov    %edi,%edx
f0104279:	f7 f6                	div    %esi
f010427b:	89 d0                	mov    %edx,%eax
f010427d:	31 d2                	xor    %edx,%edx
f010427f:	83 c4 14             	add    $0x14,%esp
f0104282:	5e                   	pop    %esi
f0104283:	5f                   	pop    %edi
f0104284:	5d                   	pop    %ebp
f0104285:	c3                   	ret    
f0104286:	66 90                	xchg   %ax,%ax
f0104288:	39 f8                	cmp    %edi,%eax
f010428a:	77 54                	ja     f01042e0 <__umoddi3+0xa0>
f010428c:	0f bd e8             	bsr    %eax,%ebp
f010428f:	83 f5 1f             	xor    $0x1f,%ebp
f0104292:	75 5c                	jne    f01042f0 <__umoddi3+0xb0>
f0104294:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0104298:	39 3c 24             	cmp    %edi,(%esp)
f010429b:	0f 87 e7 00 00 00    	ja     f0104388 <__umoddi3+0x148>
f01042a1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01042a5:	29 f1                	sub    %esi,%ecx
f01042a7:	19 c7                	sbb    %eax,%edi
f01042a9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01042ad:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01042b1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01042b5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01042b9:	83 c4 14             	add    $0x14,%esp
f01042bc:	5e                   	pop    %esi
f01042bd:	5f                   	pop    %edi
f01042be:	5d                   	pop    %ebp
f01042bf:	c3                   	ret    
f01042c0:	85 f6                	test   %esi,%esi
f01042c2:	89 f5                	mov    %esi,%ebp
f01042c4:	75 0b                	jne    f01042d1 <__umoddi3+0x91>
f01042c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01042cb:	31 d2                	xor    %edx,%edx
f01042cd:	f7 f6                	div    %esi
f01042cf:	89 c5                	mov    %eax,%ebp
f01042d1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01042d5:	31 d2                	xor    %edx,%edx
f01042d7:	f7 f5                	div    %ebp
f01042d9:	89 c8                	mov    %ecx,%eax
f01042db:	f7 f5                	div    %ebp
f01042dd:	eb 9c                	jmp    f010427b <__umoddi3+0x3b>
f01042df:	90                   	nop
f01042e0:	89 c8                	mov    %ecx,%eax
f01042e2:	89 fa                	mov    %edi,%edx
f01042e4:	83 c4 14             	add    $0x14,%esp
f01042e7:	5e                   	pop    %esi
f01042e8:	5f                   	pop    %edi
f01042e9:	5d                   	pop    %ebp
f01042ea:	c3                   	ret    
f01042eb:	90                   	nop
f01042ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01042f0:	8b 04 24             	mov    (%esp),%eax
f01042f3:	be 20 00 00 00       	mov    $0x20,%esi
f01042f8:	89 e9                	mov    %ebp,%ecx
f01042fa:	29 ee                	sub    %ebp,%esi
f01042fc:	d3 e2                	shl    %cl,%edx
f01042fe:	89 f1                	mov    %esi,%ecx
f0104300:	d3 e8                	shr    %cl,%eax
f0104302:	89 e9                	mov    %ebp,%ecx
f0104304:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104308:	8b 04 24             	mov    (%esp),%eax
f010430b:	09 54 24 04          	or     %edx,0x4(%esp)
f010430f:	89 fa                	mov    %edi,%edx
f0104311:	d3 e0                	shl    %cl,%eax
f0104313:	89 f1                	mov    %esi,%ecx
f0104315:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104319:	8b 44 24 10          	mov    0x10(%esp),%eax
f010431d:	d3 ea                	shr    %cl,%edx
f010431f:	89 e9                	mov    %ebp,%ecx
f0104321:	d3 e7                	shl    %cl,%edi
f0104323:	89 f1                	mov    %esi,%ecx
f0104325:	d3 e8                	shr    %cl,%eax
f0104327:	89 e9                	mov    %ebp,%ecx
f0104329:	09 f8                	or     %edi,%eax
f010432b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010432f:	f7 74 24 04          	divl   0x4(%esp)
f0104333:	d3 e7                	shl    %cl,%edi
f0104335:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104339:	89 d7                	mov    %edx,%edi
f010433b:	f7 64 24 08          	mull   0x8(%esp)
f010433f:	39 d7                	cmp    %edx,%edi
f0104341:	89 c1                	mov    %eax,%ecx
f0104343:	89 14 24             	mov    %edx,(%esp)
f0104346:	72 2c                	jb     f0104374 <__umoddi3+0x134>
f0104348:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010434c:	72 22                	jb     f0104370 <__umoddi3+0x130>
f010434e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0104352:	29 c8                	sub    %ecx,%eax
f0104354:	19 d7                	sbb    %edx,%edi
f0104356:	89 e9                	mov    %ebp,%ecx
f0104358:	89 fa                	mov    %edi,%edx
f010435a:	d3 e8                	shr    %cl,%eax
f010435c:	89 f1                	mov    %esi,%ecx
f010435e:	d3 e2                	shl    %cl,%edx
f0104360:	89 e9                	mov    %ebp,%ecx
f0104362:	d3 ef                	shr    %cl,%edi
f0104364:	09 d0                	or     %edx,%eax
f0104366:	89 fa                	mov    %edi,%edx
f0104368:	83 c4 14             	add    $0x14,%esp
f010436b:	5e                   	pop    %esi
f010436c:	5f                   	pop    %edi
f010436d:	5d                   	pop    %ebp
f010436e:	c3                   	ret    
f010436f:	90                   	nop
f0104370:	39 d7                	cmp    %edx,%edi
f0104372:	75 da                	jne    f010434e <__umoddi3+0x10e>
f0104374:	8b 14 24             	mov    (%esp),%edx
f0104377:	89 c1                	mov    %eax,%ecx
f0104379:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010437d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0104381:	eb cb                	jmp    f010434e <__umoddi3+0x10e>
f0104383:	90                   	nop
f0104384:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104388:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010438c:	0f 82 0f ff ff ff    	jb     f01042a1 <__umoddi3+0x61>
f0104392:	e9 1a ff ff ff       	jmp    f01042b1 <__umoddi3+0x71>
