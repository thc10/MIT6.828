
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
f0100015:	b8 00 b0 11 00       	mov    $0x11b000,%eax
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
f0100034:	bc 00 b0 11 f0       	mov    $0xf011b000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


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
f0100046:	b8 b0 fe 17 f0       	mov    $0xf017feb0,%eax
f010004b:	2d 9d ef 17 f0       	sub    $0xf017ef9d,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 9d ef 17 f0 	movl   $0xf017ef9d,(%esp)
f0100063:	e8 3f 52 00 00       	call   f01052a7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 c2 04 00 00       	call   f010052f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 40 57 10 f0 	movl   $0xf0105740,(%esp)
f010007c:	e8 e2 3c 00 00       	call   f0103d63 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 b1 17 00 00       	call   f0101837 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100086:	e8 42 36 00 00       	call   f01036cd <env_init>
	trap_init();
f010008b:	90                   	nop
f010008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100090:	e8 48 3d 00 00       	call   f0103ddd <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100095:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010009c:	00 
f010009d:	c7 04 24 59 3c 13 f0 	movl   $0xf0133c59,(%esp)
f01000a4:	e8 1b 38 00 00       	call   f01038c4 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a9:	a1 ec f1 17 f0       	mov    0xf017f1ec,%eax
f01000ae:	89 04 24             	mov    %eax,(%esp)
f01000b1:	e8 d1 3b 00 00       	call   f0103c87 <env_run>

f01000b6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000b6:	55                   	push   %ebp
f01000b7:	89 e5                	mov    %esp,%ebp
f01000b9:	56                   	push   %esi
f01000ba:	53                   	push   %ebx
f01000bb:	83 ec 10             	sub    $0x10,%esp
f01000be:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000c1:	83 3d a0 fe 17 f0 00 	cmpl   $0x0,0xf017fea0
f01000c8:	75 3d                	jne    f0100107 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000ca:	89 35 a0 fe 17 f0    	mov    %esi,0xf017fea0

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000d0:	fa                   	cli    
f01000d1:	fc                   	cld    

	va_start(ap, fmt);
f01000d2:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000d8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01000df:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000e3:	c7 04 24 5b 57 10 f0 	movl   $0xf010575b,(%esp)
f01000ea:	e8 74 3c 00 00       	call   f0103d63 <cprintf>
	vcprintf(fmt, ap);
f01000ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000f3:	89 34 24             	mov    %esi,(%esp)
f01000f6:	e8 35 3c 00 00       	call   f0103d30 <vcprintf>
	cprintf("\n");
f01000fb:	c7 04 24 c3 5a 10 f0 	movl   $0xf0105ac3,(%esp)
f0100102:	e8 5c 3c 00 00       	call   f0103d63 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100107:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010010e:	e8 71 0c 00 00       	call   f0100d84 <monitor>
f0100113:	eb f2                	jmp    f0100107 <_panic+0x51>

f0100115 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100115:	55                   	push   %ebp
f0100116:	89 e5                	mov    %esp,%ebp
f0100118:	53                   	push   %ebx
f0100119:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010011c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010011f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100122:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100126:	8b 45 08             	mov    0x8(%ebp),%eax
f0100129:	89 44 24 04          	mov    %eax,0x4(%esp)
f010012d:	c7 04 24 73 57 10 f0 	movl   $0xf0105773,(%esp)
f0100134:	e8 2a 3c 00 00       	call   f0103d63 <cprintf>
	vcprintf(fmt, ap);
f0100139:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010013d:	8b 45 10             	mov    0x10(%ebp),%eax
f0100140:	89 04 24             	mov    %eax,(%esp)
f0100143:	e8 e8 3b 00 00       	call   f0103d30 <vcprintf>
	cprintf("\n");
f0100148:	c7 04 24 c3 5a 10 f0 	movl   $0xf0105ac3,(%esp)
f010014f:	e8 0f 3c 00 00       	call   f0103d63 <cprintf>
	va_end(ap);
}
f0100154:	83 c4 14             	add    $0x14,%esp
f0100157:	5b                   	pop    %ebx
f0100158:	5d                   	pop    %ebp
f0100159:	c3                   	ret    
f010015a:	66 90                	xchg   %ax,%ax
f010015c:	66 90                	xchg   %ax,%ax
f010015e:	66 90                	xchg   %ax,%ax

f0100160 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100160:	55                   	push   %ebp
f0100161:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100163:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100168:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100169:	a8 01                	test   $0x1,%al
f010016b:	74 08                	je     f0100175 <serial_proc_data+0x15>
f010016d:	b2 f8                	mov    $0xf8,%dl
f010016f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100170:	0f b6 c0             	movzbl %al,%eax
f0100173:	eb 05                	jmp    f010017a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100175:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010017a:	5d                   	pop    %ebp
f010017b:	c3                   	ret    

f010017c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010017c:	55                   	push   %ebp
f010017d:	89 e5                	mov    %esp,%ebp
f010017f:	53                   	push   %ebx
f0100180:	83 ec 04             	sub    $0x4,%esp
f0100183:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100185:	eb 2a                	jmp    f01001b1 <cons_intr+0x35>
		if (c == 0)
f0100187:	85 d2                	test   %edx,%edx
f0100189:	74 26                	je     f01001b1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010018b:	a1 c4 f1 17 f0       	mov    0xf017f1c4,%eax
f0100190:	8d 48 01             	lea    0x1(%eax),%ecx
f0100193:	89 0d c4 f1 17 f0    	mov    %ecx,0xf017f1c4
f0100199:	88 90 c0 ef 17 f0    	mov    %dl,-0xfe81040(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010019f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001a5:	75 0a                	jne    f01001b1 <cons_intr+0x35>
			cons.wpos = 0;
f01001a7:	c7 05 c4 f1 17 f0 00 	movl   $0x0,0xf017f1c4
f01001ae:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001b1:	ff d3                	call   *%ebx
f01001b3:	89 c2                	mov    %eax,%edx
f01001b5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001b8:	75 cd                	jne    f0100187 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001ba:	83 c4 04             	add    $0x4,%esp
f01001bd:	5b                   	pop    %ebx
f01001be:	5d                   	pop    %ebp
f01001bf:	c3                   	ret    

f01001c0 <kbd_proc_data>:
f01001c0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001c5:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001c6:	a8 01                	test   $0x1,%al
f01001c8:	0f 84 f7 00 00 00    	je     f01002c5 <kbd_proc_data+0x105>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001ce:	a8 20                	test   $0x20,%al
f01001d0:	0f 85 f5 00 00 00    	jne    f01002cb <kbd_proc_data+0x10b>
f01001d6:	b2 60                	mov    $0x60,%dl
f01001d8:	ec                   	in     (%dx),%al
f01001d9:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001db:	3c e0                	cmp    $0xe0,%al
f01001dd:	75 0d                	jne    f01001ec <kbd_proc_data+0x2c>
		// E0 escape character
		shift |= E0ESC;
f01001df:	83 0d a0 ef 17 f0 40 	orl    $0x40,0xf017efa0
		return 0;
f01001e6:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001eb:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ec:	55                   	push   %ebp
f01001ed:	89 e5                	mov    %esp,%ebp
f01001ef:	53                   	push   %ebx
f01001f0:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001f3:	84 c0                	test   %al,%al
f01001f5:	79 37                	jns    f010022e <kbd_proc_data+0x6e>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001f7:	8b 0d a0 ef 17 f0    	mov    0xf017efa0,%ecx
f01001fd:	89 cb                	mov    %ecx,%ebx
f01001ff:	83 e3 40             	and    $0x40,%ebx
f0100202:	83 e0 7f             	and    $0x7f,%eax
f0100205:	85 db                	test   %ebx,%ebx
f0100207:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010020a:	0f b6 d2             	movzbl %dl,%edx
f010020d:	0f b6 82 e0 58 10 f0 	movzbl -0xfefa720(%edx),%eax
f0100214:	83 c8 40             	or     $0x40,%eax
f0100217:	0f b6 c0             	movzbl %al,%eax
f010021a:	f7 d0                	not    %eax
f010021c:	21 c1                	and    %eax,%ecx
f010021e:	89 0d a0 ef 17 f0    	mov    %ecx,0xf017efa0
		return 0;
f0100224:	b8 00 00 00 00       	mov    $0x0,%eax
f0100229:	e9 a3 00 00 00       	jmp    f01002d1 <kbd_proc_data+0x111>
	} else if (shift & E0ESC) {
f010022e:	8b 0d a0 ef 17 f0    	mov    0xf017efa0,%ecx
f0100234:	f6 c1 40             	test   $0x40,%cl
f0100237:	74 0e                	je     f0100247 <kbd_proc_data+0x87>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100239:	83 c8 80             	or     $0xffffff80,%eax
f010023c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010023e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100241:	89 0d a0 ef 17 f0    	mov    %ecx,0xf017efa0
	}

	shift |= shiftcode[data];
f0100247:	0f b6 d2             	movzbl %dl,%edx
f010024a:	0f b6 82 e0 58 10 f0 	movzbl -0xfefa720(%edx),%eax
f0100251:	0b 05 a0 ef 17 f0    	or     0xf017efa0,%eax
	shift ^= togglecode[data];
f0100257:	0f b6 8a e0 57 10 f0 	movzbl -0xfefa820(%edx),%ecx
f010025e:	31 c8                	xor    %ecx,%eax
f0100260:	a3 a0 ef 17 f0       	mov    %eax,0xf017efa0

	c = charcode[shift & (CTL | SHIFT)][data];
f0100265:	89 c1                	mov    %eax,%ecx
f0100267:	83 e1 03             	and    $0x3,%ecx
f010026a:	8b 0c 8d c0 57 10 f0 	mov    -0xfefa840(,%ecx,4),%ecx
f0100271:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100275:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100278:	a8 08                	test   $0x8,%al
f010027a:	74 1b                	je     f0100297 <kbd_proc_data+0xd7>
		if ('a' <= c && c <= 'z')
f010027c:	89 da                	mov    %ebx,%edx
f010027e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100281:	83 f9 19             	cmp    $0x19,%ecx
f0100284:	77 05                	ja     f010028b <kbd_proc_data+0xcb>
			c += 'A' - 'a';
f0100286:	83 eb 20             	sub    $0x20,%ebx
f0100289:	eb 0c                	jmp    f0100297 <kbd_proc_data+0xd7>
		else if ('A' <= c && c <= 'Z')
f010028b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010028e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100291:	83 fa 19             	cmp    $0x19,%edx
f0100294:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100297:	f7 d0                	not    %eax
f0100299:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010029b:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010029d:	f6 c2 06             	test   $0x6,%dl
f01002a0:	75 2f                	jne    f01002d1 <kbd_proc_data+0x111>
f01002a2:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002a8:	75 27                	jne    f01002d1 <kbd_proc_data+0x111>
		cprintf("Rebooting!\n");
f01002aa:	c7 04 24 8d 57 10 f0 	movl   $0xf010578d,(%esp)
f01002b1:	e8 ad 3a 00 00       	call   f0103d63 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002b6:	ba 92 00 00 00       	mov    $0x92,%edx
f01002bb:	b8 03 00 00 00       	mov    $0x3,%eax
f01002c0:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002c1:	89 d8                	mov    %ebx,%eax
f01002c3:	eb 0c                	jmp    f01002d1 <kbd_proc_data+0x111>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002ca:	c3                   	ret    
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002d0:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002d1:	83 c4 14             	add    $0x14,%esp
f01002d4:	5b                   	pop    %ebx
f01002d5:	5d                   	pop    %ebp
f01002d6:	c3                   	ret    

f01002d7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002d7:	55                   	push   %ebp
f01002d8:	89 e5                	mov    %esp,%ebp
f01002da:	57                   	push   %edi
f01002db:	56                   	push   %esi
f01002dc:	53                   	push   %ebx
f01002dd:	83 ec 1c             	sub    $0x1c,%esp
f01002e0:	89 c7                	mov    %eax,%edi
f01002e2:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ec:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002f1:	eb 06                	jmp    f01002f9 <cons_putc+0x22>
f01002f3:	89 ca                	mov    %ecx,%edx
f01002f5:	ec                   	in     (%dx),%al
f01002f6:	ec                   	in     (%dx),%al
f01002f7:	ec                   	in     (%dx),%al
f01002f8:	ec                   	in     (%dx),%al
f01002f9:	89 f2                	mov    %esi,%edx
f01002fb:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002fc:	a8 20                	test   $0x20,%al
f01002fe:	75 05                	jne    f0100305 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100300:	83 eb 01             	sub    $0x1,%ebx
f0100303:	75 ee                	jne    f01002f3 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100305:	89 f8                	mov    %edi,%eax
f0100307:	0f b6 c0             	movzbl %al,%eax
f010030a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010030d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100312:	ee                   	out    %al,(%dx)
f0100313:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100318:	be 79 03 00 00       	mov    $0x379,%esi
f010031d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100322:	eb 06                	jmp    f010032a <cons_putc+0x53>
f0100324:	89 ca                	mov    %ecx,%edx
f0100326:	ec                   	in     (%dx),%al
f0100327:	ec                   	in     (%dx),%al
f0100328:	ec                   	in     (%dx),%al
f0100329:	ec                   	in     (%dx),%al
f010032a:	89 f2                	mov    %esi,%edx
f010032c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010032d:	84 c0                	test   %al,%al
f010032f:	78 05                	js     f0100336 <cons_putc+0x5f>
f0100331:	83 eb 01             	sub    $0x1,%ebx
f0100334:	75 ee                	jne    f0100324 <cons_putc+0x4d>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100336:	ba 78 03 00 00       	mov    $0x378,%edx
f010033b:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010033f:	ee                   	out    %al,(%dx)
f0100340:	b2 7a                	mov    $0x7a,%dl
f0100342:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100347:	ee                   	out    %al,(%dx)
f0100348:	b8 08 00 00 00       	mov    $0x8,%eax
f010034d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010034e:	89 fa                	mov    %edi,%edx
f0100350:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100356:	89 f8                	mov    %edi,%eax
f0100358:	80 cc 07             	or     $0x7,%ah
f010035b:	85 d2                	test   %edx,%edx
f010035d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100360:	89 f8                	mov    %edi,%eax
f0100362:	0f b6 c0             	movzbl %al,%eax
f0100365:	83 f8 09             	cmp    $0x9,%eax
f0100368:	74 78                	je     f01003e2 <cons_putc+0x10b>
f010036a:	83 f8 09             	cmp    $0x9,%eax
f010036d:	7f 0a                	jg     f0100379 <cons_putc+0xa2>
f010036f:	83 f8 08             	cmp    $0x8,%eax
f0100372:	74 18                	je     f010038c <cons_putc+0xb5>
f0100374:	e9 9d 00 00 00       	jmp    f0100416 <cons_putc+0x13f>
f0100379:	83 f8 0a             	cmp    $0xa,%eax
f010037c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100380:	74 3a                	je     f01003bc <cons_putc+0xe5>
f0100382:	83 f8 0d             	cmp    $0xd,%eax
f0100385:	74 3d                	je     f01003c4 <cons_putc+0xed>
f0100387:	e9 8a 00 00 00       	jmp    f0100416 <cons_putc+0x13f>
	case '\b':
		if (crt_pos > 0) {
f010038c:	0f b7 05 c8 f1 17 f0 	movzwl 0xf017f1c8,%eax
f0100393:	66 85 c0             	test   %ax,%ax
f0100396:	0f 84 e5 00 00 00    	je     f0100481 <cons_putc+0x1aa>
			crt_pos--;
f010039c:	83 e8 01             	sub    $0x1,%eax
f010039f:	66 a3 c8 f1 17 f0    	mov    %ax,0xf017f1c8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003a5:	0f b7 c0             	movzwl %ax,%eax
f01003a8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003ad:	83 cf 20             	or     $0x20,%edi
f01003b0:	8b 15 cc f1 17 f0    	mov    0xf017f1cc,%edx
f01003b6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003ba:	eb 78                	jmp    f0100434 <cons_putc+0x15d>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003bc:	66 83 05 c8 f1 17 f0 	addw   $0x50,0xf017f1c8
f01003c3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003c4:	0f b7 05 c8 f1 17 f0 	movzwl 0xf017f1c8,%eax
f01003cb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003d1:	c1 e8 16             	shr    $0x16,%eax
f01003d4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003d7:	c1 e0 04             	shl    $0x4,%eax
f01003da:	66 a3 c8 f1 17 f0    	mov    %ax,0xf017f1c8
f01003e0:	eb 52                	jmp    f0100434 <cons_putc+0x15d>
		break;
	case '\t':
		cons_putc(' ');
f01003e2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e7:	e8 eb fe ff ff       	call   f01002d7 <cons_putc>
		cons_putc(' ');
f01003ec:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f1:	e8 e1 fe ff ff       	call   f01002d7 <cons_putc>
		cons_putc(' ');
f01003f6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fb:	e8 d7 fe ff ff       	call   f01002d7 <cons_putc>
		cons_putc(' ');
f0100400:	b8 20 00 00 00       	mov    $0x20,%eax
f0100405:	e8 cd fe ff ff       	call   f01002d7 <cons_putc>
		cons_putc(' ');
f010040a:	b8 20 00 00 00       	mov    $0x20,%eax
f010040f:	e8 c3 fe ff ff       	call   f01002d7 <cons_putc>
f0100414:	eb 1e                	jmp    f0100434 <cons_putc+0x15d>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100416:	0f b7 05 c8 f1 17 f0 	movzwl 0xf017f1c8,%eax
f010041d:	8d 50 01             	lea    0x1(%eax),%edx
f0100420:	66 89 15 c8 f1 17 f0 	mov    %dx,0xf017f1c8
f0100427:	0f b7 c0             	movzwl %ax,%eax
f010042a:	8b 15 cc f1 17 f0    	mov    0xf017f1cc,%edx
f0100430:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100434:	66 81 3d c8 f1 17 f0 	cmpw   $0x7cf,0xf017f1c8
f010043b:	cf 07 
f010043d:	76 42                	jbe    f0100481 <cons_putc+0x1aa>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010043f:	a1 cc f1 17 f0       	mov    0xf017f1cc,%eax
f0100444:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010044b:	00 
f010044c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100452:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100456:	89 04 24             	mov    %eax,(%esp)
f0100459:	e8 96 4e 00 00       	call   f01052f4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010045e:	8b 15 cc f1 17 f0    	mov    0xf017f1cc,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100464:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100469:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010046f:	83 c0 01             	add    $0x1,%eax
f0100472:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100477:	75 f0                	jne    f0100469 <cons_putc+0x192>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100479:	66 83 2d c8 f1 17 f0 	subw   $0x50,0xf017f1c8
f0100480:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100481:	8b 0d d0 f1 17 f0    	mov    0xf017f1d0,%ecx
f0100487:	b8 0e 00 00 00       	mov    $0xe,%eax
f010048c:	89 ca                	mov    %ecx,%edx
f010048e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010048f:	0f b7 1d c8 f1 17 f0 	movzwl 0xf017f1c8,%ebx
f0100496:	8d 71 01             	lea    0x1(%ecx),%esi
f0100499:	89 d8                	mov    %ebx,%eax
f010049b:	66 c1 e8 08          	shr    $0x8,%ax
f010049f:	89 f2                	mov    %esi,%edx
f01004a1:	ee                   	out    %al,(%dx)
f01004a2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004a7:	89 ca                	mov    %ecx,%edx
f01004a9:	ee                   	out    %al,(%dx)
f01004aa:	89 d8                	mov    %ebx,%eax
f01004ac:	89 f2                	mov    %esi,%edx
f01004ae:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004af:	83 c4 1c             	add    $0x1c,%esp
f01004b2:	5b                   	pop    %ebx
f01004b3:	5e                   	pop    %esi
f01004b4:	5f                   	pop    %edi
f01004b5:	5d                   	pop    %ebp
f01004b6:	c3                   	ret    

f01004b7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004b7:	80 3d d4 f1 17 f0 00 	cmpb   $0x0,0xf017f1d4
f01004be:	74 11                	je     f01004d1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004c0:	55                   	push   %ebp
f01004c1:	89 e5                	mov    %esp,%ebp
f01004c3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004c6:	b8 60 01 10 f0       	mov    $0xf0100160,%eax
f01004cb:	e8 ac fc ff ff       	call   f010017c <cons_intr>
}
f01004d0:	c9                   	leave  
f01004d1:	f3 c3                	repz ret 

f01004d3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004d3:	55                   	push   %ebp
f01004d4:	89 e5                	mov    %esp,%ebp
f01004d6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004d9:	b8 c0 01 10 f0       	mov    $0xf01001c0,%eax
f01004de:	e8 99 fc ff ff       	call   f010017c <cons_intr>
}
f01004e3:	c9                   	leave  
f01004e4:	c3                   	ret    

f01004e5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004e5:	55                   	push   %ebp
f01004e6:	89 e5                	mov    %esp,%ebp
f01004e8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004eb:	e8 c7 ff ff ff       	call   f01004b7 <serial_intr>
	kbd_intr();
f01004f0:	e8 de ff ff ff       	call   f01004d3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004f5:	a1 c0 f1 17 f0       	mov    0xf017f1c0,%eax
f01004fa:	3b 05 c4 f1 17 f0    	cmp    0xf017f1c4,%eax
f0100500:	74 26                	je     f0100528 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100502:	8d 50 01             	lea    0x1(%eax),%edx
f0100505:	89 15 c0 f1 17 f0    	mov    %edx,0xf017f1c0
f010050b:	0f b6 88 c0 ef 17 f0 	movzbl -0xfe81040(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100512:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100514:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010051a:	75 11                	jne    f010052d <cons_getc+0x48>
			cons.rpos = 0;
f010051c:	c7 05 c0 f1 17 f0 00 	movl   $0x0,0xf017f1c0
f0100523:	00 00 00 
f0100526:	eb 05                	jmp    f010052d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100528:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010052d:	c9                   	leave  
f010052e:	c3                   	ret    

f010052f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010052f:	55                   	push   %ebp
f0100530:	89 e5                	mov    %esp,%ebp
f0100532:	57                   	push   %edi
f0100533:	56                   	push   %esi
f0100534:	53                   	push   %ebx
f0100535:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100538:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010053f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100546:	5a a5 
	if (*cp != 0xA55A) {
f0100548:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010054f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100553:	74 11                	je     f0100566 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100555:	c7 05 d0 f1 17 f0 b4 	movl   $0x3b4,0xf017f1d0
f010055c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010055f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100564:	eb 16                	jmp    f010057c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100566:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010056d:	c7 05 d0 f1 17 f0 d4 	movl   $0x3d4,0xf017f1d0
f0100574:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100577:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010057c:	8b 0d d0 f1 17 f0    	mov    0xf017f1d0,%ecx
f0100582:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100587:	89 ca                	mov    %ecx,%edx
f0100589:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010058a:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010058d:	89 da                	mov    %ebx,%edx
f010058f:	ec                   	in     (%dx),%al
f0100590:	0f b6 f0             	movzbl %al,%esi
f0100593:	c1 e6 08             	shl    $0x8,%esi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100596:	b8 0f 00 00 00       	mov    $0xf,%eax
f010059b:	89 ca                	mov    %ecx,%edx
f010059d:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010059e:	89 da                	mov    %ebx,%edx
f01005a0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005a1:	89 3d cc f1 17 f0    	mov    %edi,0xf017f1cc

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005a7:	0f b6 d8             	movzbl %al,%ebx
f01005aa:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005ac:	66 89 35 c8 f1 17 f0 	mov    %si,0xf017f1c8
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005b3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005b8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bd:	89 f2                	mov    %esi,%edx
f01005bf:	ee                   	out    %al,(%dx)
f01005c0:	b2 fb                	mov    $0xfb,%dl
f01005c2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005c7:	ee                   	out    %al,(%dx)
f01005c8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005cd:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005d2:	89 da                	mov    %ebx,%edx
f01005d4:	ee                   	out    %al,(%dx)
f01005d5:	b2 f9                	mov    $0xf9,%dl
f01005d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005dc:	ee                   	out    %al,(%dx)
f01005dd:	b2 fb                	mov    $0xfb,%dl
f01005df:	b8 03 00 00 00       	mov    $0x3,%eax
f01005e4:	ee                   	out    %al,(%dx)
f01005e5:	b2 fc                	mov    $0xfc,%dl
f01005e7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ec:	ee                   	out    %al,(%dx)
f01005ed:	b2 f9                	mov    $0xf9,%dl
f01005ef:	b8 01 00 00 00       	mov    $0x1,%eax
f01005f4:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005f5:	b2 fd                	mov    $0xfd,%dl
f01005f7:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005f8:	3c ff                	cmp    $0xff,%al
f01005fa:	0f 95 c1             	setne  %cl
f01005fd:	88 0d d4 f1 17 f0    	mov    %cl,0xf017f1d4
f0100603:	89 f2                	mov    %esi,%edx
f0100605:	ec                   	in     (%dx),%al
f0100606:	89 da                	mov    %ebx,%edx
f0100608:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100609:	84 c9                	test   %cl,%cl
f010060b:	75 0c                	jne    f0100619 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010060d:	c7 04 24 99 57 10 f0 	movl   $0xf0105799,(%esp)
f0100614:	e8 4a 37 00 00       	call   f0103d63 <cprintf>
}
f0100619:	83 c4 1c             	add    $0x1c,%esp
f010061c:	5b                   	pop    %ebx
f010061d:	5e                   	pop    %esi
f010061e:	5f                   	pop    %edi
f010061f:	5d                   	pop    %ebp
f0100620:	c3                   	ret    

f0100621 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
f0100624:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100627:	8b 45 08             	mov    0x8(%ebp),%eax
f010062a:	e8 a8 fc ff ff       	call   f01002d7 <cons_putc>
}
f010062f:	c9                   	leave  
f0100630:	c3                   	ret    

f0100631 <getchar>:

int
getchar(void)
{
f0100631:	55                   	push   %ebp
f0100632:	89 e5                	mov    %esp,%ebp
f0100634:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100637:	e8 a9 fe ff ff       	call   f01004e5 <cons_getc>
f010063c:	85 c0                	test   %eax,%eax
f010063e:	74 f7                	je     f0100637 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100640:	c9                   	leave  
f0100641:	c3                   	ret    

f0100642 <iscons>:

int
iscons(int fdnum)
{
f0100642:	55                   	push   %ebp
f0100643:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100645:	b8 01 00 00 00       	mov    $0x1,%eax
f010064a:	5d                   	pop    %ebp
f010064b:	c3                   	ret    
f010064c:	66 90                	xchg   %ax,%ax
f010064e:	66 90                	xchg   %ax,%ax

f0100650 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100650:	55                   	push   %ebp
f0100651:	89 e5                	mov    %esp,%ebp
f0100653:	57                   	push   %edi
f0100654:	56                   	push   %esi
f0100655:	53                   	push   %ebx
f0100656:	83 ec 1c             	sub    $0x1c,%esp
f0100659:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010065c:	bb e4 60 10 f0       	mov    $0xf01060e4,%ebx
f0100661:	be 44 61 10 f0       	mov    $0xf0106144,%esi
	int i;

	if(argc == 2){
f0100666:	83 7d 08 02          	cmpl   $0x2,0x8(%ebp)
f010066a:	75 2d                	jne    f0100699 <mon_help+0x49>
f010066c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100671:	89 d8                	mov    %ebx,%eax
f0100673:	c1 e0 04             	shl    $0x4,%eax
		for (i = 0; i < ARRAY_SIZE(commands); i++)
			if (strcmp(argv[1], commands[i].name) == 0)
f0100676:	8b 80 e0 60 10 f0    	mov    -0xfef9f20(%eax),%eax
f010067c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100680:	8b 47 04             	mov    0x4(%edi),%eax
f0100683:	89 04 24             	mov    %eax,(%esp)
f0100686:	e8 81 4b 00 00       	call   f010520c <strcmp>
f010068b:	85 c0                	test   %eax,%eax
f010068d:	74 41                	je     f01006d0 <mon_help+0x80>
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	if(argc == 2){
		for (i = 0; i < ARRAY_SIZE(commands); i++)
f010068f:	83 c3 01             	add    $0x1,%ebx
f0100692:	83 fb 06             	cmp    $0x6,%ebx
f0100695:	75 da                	jne    f0100671 <mon_help+0x21>
f0100697:	eb 22                	jmp    f01006bb <mon_help+0x6b>
			cprintf("No command : %s !\n", argv[1]);
		else
			cprintf("%s\nUsage : %s\n", commands[i].desc, commands[i].usage);
	}else{
		for (i = 0; i < ARRAY_SIZE(commands); i++)
			cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100699:	8b 03                	mov    (%ebx),%eax
f010069b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010069f:	8b 43 fc             	mov    -0x4(%ebx),%eax
f01006a2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006a6:	c7 04 24 e0 59 10 f0 	movl   $0xf01059e0,(%esp)
f01006ad:	e8 b1 36 00 00       	call   f0103d63 <cprintf>
f01006b2:	83 c3 10             	add    $0x10,%ebx
		if (i >= ARRAY_SIZE(commands))
			cprintf("No command : %s !\n", argv[1]);
		else
			cprintf("%s\nUsage : %s\n", commands[i].desc, commands[i].usage);
	}else{
		for (i = 0; i < ARRAY_SIZE(commands); i++)
f01006b5:	39 f3                	cmp    %esi,%ebx
f01006b7:	75 e0                	jne    f0100699 <mon_help+0x49>
f01006b9:	eb 3c                	jmp    f01006f7 <mon_help+0xa7>
	if(argc == 2){
		for (i = 0; i < ARRAY_SIZE(commands); i++)
			if (strcmp(argv[1], commands[i].name) == 0)
				break;
		if (i >= ARRAY_SIZE(commands))
			cprintf("No command : %s !\n", argv[1]);
f01006bb:	8b 47 04             	mov    0x4(%edi),%eax
f01006be:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006c2:	c7 04 24 e9 59 10 f0 	movl   $0xf01059e9,(%esp)
f01006c9:	e8 95 36 00 00       	call   f0103d63 <cprintf>
f01006ce:	eb 27                	jmp    f01006f7 <mon_help+0xa7>
		else
			cprintf("%s\nUsage : %s\n", commands[i].desc, commands[i].usage);
f01006d0:	89 d8                	mov    %ebx,%eax
f01006d2:	c1 e0 04             	shl    $0x4,%eax
f01006d5:	8b 90 e8 60 10 f0    	mov    -0xfef9f18(%eax),%edx
f01006db:	05 e0 60 10 f0       	add    $0xf01060e0,%eax
f01006e0:	89 54 24 08          	mov    %edx,0x8(%esp)
f01006e4:	8b 40 04             	mov    0x4(%eax),%eax
f01006e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006eb:	c7 04 24 fc 59 10 f0 	movl   $0xf01059fc,(%esp)
f01006f2:	e8 6c 36 00 00       	call   f0103d63 <cprintf>
	}else{
		for (i = 0; i < ARRAY_SIZE(commands); i++)
			cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	}
	return 0;
}
f01006f7:	b8 00 00 00 00       	mov    $0x0,%eax
f01006fc:	83 c4 1c             	add    $0x1c,%esp
f01006ff:	5b                   	pop    %ebx
f0100700:	5e                   	pop    %esi
f0100701:	5f                   	pop    %edi
f0100702:	5d                   	pop    %ebp
f0100703:	c3                   	ret    

f0100704 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100704:	55                   	push   %ebp
f0100705:	89 e5                	mov    %esp,%ebp
f0100707:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010070a:	c7 04 24 0b 5a 10 f0 	movl   $0xf0105a0b,(%esp)
f0100711:	e8 4d 36 00 00       	call   f0103d63 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100716:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010071d:	00 
f010071e:	c7 04 24 78 5b 10 f0 	movl   $0xf0105b78,(%esp)
f0100725:	e8 39 36 00 00       	call   f0103d63 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010072a:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100731:	00 
f0100732:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100739:	f0 
f010073a:	c7 04 24 a0 5b 10 f0 	movl   $0xf0105ba0,(%esp)
f0100741:	e8 1d 36 00 00       	call   f0103d63 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100746:	c7 44 24 08 37 57 10 	movl   $0x105737,0x8(%esp)
f010074d:	00 
f010074e:	c7 44 24 04 37 57 10 	movl   $0xf0105737,0x4(%esp)
f0100755:	f0 
f0100756:	c7 04 24 c4 5b 10 f0 	movl   $0xf0105bc4,(%esp)
f010075d:	e8 01 36 00 00       	call   f0103d63 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100762:	c7 44 24 08 9d ef 17 	movl   $0x17ef9d,0x8(%esp)
f0100769:	00 
f010076a:	c7 44 24 04 9d ef 17 	movl   $0xf017ef9d,0x4(%esp)
f0100771:	f0 
f0100772:	c7 04 24 e8 5b 10 f0 	movl   $0xf0105be8,(%esp)
f0100779:	e8 e5 35 00 00       	call   f0103d63 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010077e:	c7 44 24 08 b0 fe 17 	movl   $0x17feb0,0x8(%esp)
f0100785:	00 
f0100786:	c7 44 24 04 b0 fe 17 	movl   $0xf017feb0,0x4(%esp)
f010078d:	f0 
f010078e:	c7 04 24 0c 5c 10 f0 	movl   $0xf0105c0c,(%esp)
f0100795:	e8 c9 35 00 00       	call   f0103d63 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010079a:	b8 af 02 18 f0       	mov    $0xf01802af,%eax
f010079f:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01007a4:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007a9:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01007af:	85 c0                	test   %eax,%eax
f01007b1:	0f 48 c2             	cmovs  %edx,%eax
f01007b4:	c1 f8 0a             	sar    $0xa,%eax
f01007b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007bb:	c7 04 24 30 5c 10 f0 	movl   $0xf0105c30,(%esp)
f01007c2:	e8 9c 35 00 00       	call   f0103d63 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01007c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01007cc:	c9                   	leave  
f01007cd:	c3                   	ret    

f01007ce <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007ce:	55                   	push   %ebp
f01007cf:	89 e5                	mov    %esp,%ebp
f01007d1:	57                   	push   %edi
f01007d2:	56                   	push   %esi
f01007d3:	53                   	push   %ebx
f01007d4:	83 ec 4c             	sub    $0x4c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01007d7:	89 ee                	mov    %ebp,%esi
	// 每次压栈的顺序依次是：保存ebx、保存ebp、返回地址eip、五个参数
	uint32_t eip;
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f01007d9:	c7 04 24 24 5a 10 f0 	movl   $0xf0105a24,(%esp)
f01007e0:	e8 7e 35 00 00       	call   f0103d63 <cprintf>
	while(ebp != 0){
f01007e5:	eb 77                	jmp    f010085e <mon_backtrace+0x90>
		eip = *((uint32_t *)ebp + 1);
f01007e7:	8b 7e 04             	mov    0x4(%esi),%edi
		debuginfo_eip(eip, &info);
f01007ea:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007f1:	89 3c 24             	mov    %edi,(%esp)
f01007f4:	e8 8b 3f 00 00       	call   f0104784 <debuginfo_eip>
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
f01007f9:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01007fd:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100801:	c7 04 24 36 5a 10 f0 	movl   $0xf0105a36,(%esp)
f0100808:	e8 56 35 00 00       	call   f0103d63 <cprintf>
		for(int i = 2; i < 7; i++){
f010080d:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x", *((uint32_t*)ebp + i));
f0100812:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f0100815:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100819:	c7 04 24 51 5a 10 f0 	movl   $0xf0105a51,(%esp)
f0100820:	e8 3e 35 00 00       	call   f0103d63 <cprintf>
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
		eip = *((uint32_t *)ebp + 1);
		debuginfo_eip(eip, &info);
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
		for(int i = 2; i < 7; i++){
f0100825:	83 c3 01             	add    $0x1,%ebx
f0100828:	83 fb 07             	cmp    $0x7,%ebx
f010082b:	75 e5                	jne    f0100812 <mon_backtrace+0x44>
			cprintf(" %08x", *((uint32_t*)ebp + i));
		}
		cprintf("\n         %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
f010082d:	2b 7d e0             	sub    -0x20(%ebp),%edi
f0100830:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0100834:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100837:	89 44 24 10          	mov    %eax,0x10(%esp)
f010083b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010083e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100842:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100845:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100849:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010084c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100850:	c7 04 24 57 5a 10 f0 	movl   $0xf0105a57,(%esp)
f0100857:	e8 07 35 00 00       	call   f0103d63 <cprintf>
		ebp = *((uint32_t *)ebp);
f010085c:	8b 36                	mov    (%esi),%esi
	// 每次压栈的顺序依次是：保存ebx、保存ebp、返回地址eip、五个参数
	uint32_t eip;
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f010085e:	85 f6                	test   %esi,%esi
f0100860:	75 85                	jne    f01007e7 <mon_backtrace+0x19>
		}
		cprintf("\n         %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
		ebp = *((uint32_t *)ebp);
	}
	return 0;
}
f0100862:	b8 00 00 00 00       	mov    $0x0,%eax
f0100867:	83 c4 4c             	add    $0x4c,%esp
f010086a:	5b                   	pop    %ebx
f010086b:	5e                   	pop    %esi
f010086c:	5f                   	pop    %edi
f010086d:	5d                   	pop    %ebp
f010086e:	c3                   	ret    

f010086f <mon_showmappings>:

int
mon_showmappings(int argc, char **argv, struct Trapframe *tf)
{
f010086f:	55                   	push   %ebp
f0100870:	89 e5                	mov    %esp,%ebp
f0100872:	57                   	push   %edi
f0100873:	56                   	push   %esi
f0100874:	53                   	push   %ebx
f0100875:	81 ec 8c 00 00 00    	sub    $0x8c,%esp
f010087b:	8b 75 08             	mov    0x8(%ebp),%esi
f010087e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// check arguments num
	if (argc != 3 && argc != 2){
f0100881:	8d 46 fe             	lea    -0x2(%esi),%eax
f0100884:	83 f8 01             	cmp    $0x1,%eax
f0100887:	76 11                	jbe    f010089a <mon_showmappings+0x2b>
		cprintf("Usage: showmappings start_addr (end_addr) \n");
f0100889:	c7 04 24 5c 5c 10 f0 	movl   $0xf0105c5c,(%esp)
f0100890:	e8 ce 34 00 00       	call   f0103d63 <cprintf>
		return 0;
f0100895:	e9 e7 01 00 00       	jmp    f0100a81 <mon_showmappings+0x212>
	 * nptr : the string who is to change to a interger
	 * endptr : if the nptr is invalid, write the first invalid char in endptr
	 * base : the type of number
	*/
	char *errStr;
	uintptr_t start_addr = strtol(argv[1], &errStr, 16);
f010089a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f01008a1:	00 
f01008a2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01008a5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008a9:	8b 43 04             	mov    0x4(%ebx),%eax
f01008ac:	89 04 24             	mov    %eax,(%esp)
f01008af:	e8 1f 4b 00 00       	call   f01053d3 <strtol>
	if (*errStr){
f01008b4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01008b7:	80 3a 00             	cmpb   $0x0,(%edx)
f01008ba:	74 18                	je     f01008d4 <mon_showmappings+0x65>
		cprintf("error : invalid input : %s .\n", argv[1]);
f01008bc:	8b 43 04             	mov    0x4(%ebx),%eax
f01008bf:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008c3:	c7 04 24 71 5a 10 f0 	movl   $0xf0105a71,(%esp)
f01008ca:	e8 94 34 00 00       	call   f0103d63 <cprintf>
		return 0;
f01008cf:	e9 ad 01 00 00       	jmp    f0100a81 <mon_showmappings+0x212>
	}
	start_addr = ROUNDDOWN(start_addr, PGSIZE);
f01008d4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008d9:	89 c7                	mov    %eax,%edi
	uintptr_t end_addr;
	if (argc == 2)
f01008db:	83 fe 02             	cmp    $0x2,%esi
f01008de:	75 0e                	jne    f01008ee <mon_showmappings+0x7f>
		end_addr = start_addr + PGSIZE;
f01008e0:	8d 80 00 10 00 00    	lea    0x1000(%eax),%eax
f01008e6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01008e9:	e9 8a 01 00 00       	jmp    f0100a78 <mon_showmappings+0x209>
	else{
		end_addr = strtol(argv[2], &errStr, 16);
f01008ee:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f01008f5:	00 
f01008f6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01008f9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008fd:	8b 43 08             	mov    0x8(%ebx),%eax
f0100900:	89 04 24             	mov    %eax,(%esp)
f0100903:	e8 cb 4a 00 00       	call   f01053d3 <strtol>
		if (*errStr){
			cprintf("error : invalid input : %s .\n", argv[2]);
			return 0;
		}
		end_addr = ROUNDUP(end_addr, PGSIZE);
f0100908:	05 ff 0f 00 00       	add    $0xfff,%eax
f010090d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100912:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	uintptr_t end_addr;
	if (argc == 2)
		end_addr = start_addr + PGSIZE;
	else{
		end_addr = strtol(argv[2], &errStr, 16);
		if (*errStr){
f0100915:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100918:	80 38 00             	cmpb   $0x0,(%eax)
f010091b:	0f 84 57 01 00 00    	je     f0100a78 <mon_showmappings+0x209>
			cprintf("error : invalid input : %s .\n", argv[2]);
f0100921:	8b 43 08             	mov    0x8(%ebx),%eax
f0100924:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100928:	c7 04 24 71 5a 10 f0 	movl   $0xf0105a71,(%esp)
f010092f:	e8 2f 34 00 00       	call   f0103d63 <cprintf>
			return 0;
f0100934:	e9 48 01 00 00       	jmp    f0100a81 <mon_showmappings+0x212>
		}
		end_addr = ROUNDUP(end_addr, PGSIZE);
	}

	while(start_addr < end_addr){
		pte_t *cur_pte = pgdir_walk(kern_pgdir, (void *)start_addr, 0);
f0100939:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100940:	00 
f0100941:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100945:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f010094a:	89 04 24             	mov    %eax,(%esp)
f010094d:	e8 56 0c 00 00       	call   f01015a8 <pgdir_walk>
f0100952:	89 c3                	mov    %eax,%ebx
		if(!cur_pte || !(*cur_pte & PTE_P)){
f0100954:	85 c0                	test   %eax,%eax
f0100956:	74 06                	je     f010095e <mon_showmappings+0xef>
f0100958:	8b 00                	mov    (%eax),%eax
f010095a:	a8 01                	test   $0x1,%al
f010095c:	75 15                	jne    f0100973 <mon_showmappings+0x104>
			cprintf("virtual address 0x%08x not mapped.\n", start_addr);
f010095e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100962:	c7 04 24 88 5c 10 f0 	movl   $0xf0105c88,(%esp)
f0100969:	e8 f5 33 00 00       	call   f0103d63 <cprintf>
f010096e:	e9 ff 00 00 00       	jmp    f0100a72 <mon_showmappings+0x203>
		}else{
			cprintf("virtual address 0x%08x physical address 0x%08x permission: ", 
f0100973:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100978:	89 44 24 08          	mov    %eax,0x8(%esp)
f010097c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100980:	c7 04 24 ac 5c 10 f0 	movl   $0xf0105cac,(%esp)
f0100987:	e8 d7 33 00 00       	call   f0103d63 <cprintf>
				start_addr, PTE_ADDR(*cur_pte));
			char perm_Global = (*cur_pte & PTE_G) ? 'G' : '-';
f010098c:	8b 03                	mov    (%ebx),%eax
f010098e:	89 c2                	mov    %eax,%edx
f0100990:	81 e2 00 01 00 00    	and    $0x100,%edx
f0100996:	83 fa 01             	cmp    $0x1,%edx
f0100999:	19 c9                	sbb    %ecx,%ecx
f010099b:	89 4d b8             	mov    %ecx,-0x48(%ebp)
f010099e:	80 65 b8 e6          	andb   $0xe6,-0x48(%ebp)
f01009a2:	80 45 b8 47          	addb   $0x47,-0x48(%ebp)
			char perm_PageSize = (*cur_pte & PTE_PS) ? 'S' : '-';
f01009a6:	89 c2                	mov    %eax,%edx
f01009a8:	81 e2 80 00 00 00    	and    $0x80,%edx
f01009ae:	83 fa 01             	cmp    $0x1,%edx
f01009b1:	19 d2                	sbb    %edx,%edx
f01009b3:	83 e2 da             	and    $0xffffffda,%edx
f01009b6:	83 c2 53             	add    $0x53,%edx
			char perm_Dirty = (*cur_pte & PTE_D) ? 'D' : '-';
f01009b9:	89 c1                	mov    %eax,%ecx
f01009bb:	83 e1 40             	and    $0x40,%ecx
f01009be:	83 f9 01             	cmp    $0x1,%ecx
f01009c1:	19 c9                	sbb    %ecx,%ecx
f01009c3:	83 e1 e9             	and    $0xffffffe9,%ecx
f01009c6:	83 c1 44             	add    $0x44,%ecx
			char perm_Accessed = (*cur_pte & PTE_A) ? 'A' : '-';
f01009c9:	89 c3                	mov    %eax,%ebx
f01009cb:	83 e3 20             	and    $0x20,%ebx
f01009ce:	83 fb 01             	cmp    $0x1,%ebx
f01009d1:	19 db                	sbb    %ebx,%ebx
f01009d3:	83 e3 ec             	and    $0xffffffec,%ebx
f01009d6:	83 c3 41             	add    $0x41,%ebx
			char perm_CacheDisable = (*cur_pte & PTE_PCD) ? 'C' : '-';
f01009d9:	89 c6                	mov    %eax,%esi
f01009db:	83 e6 10             	and    $0x10,%esi
f01009de:	83 fe 01             	cmp    $0x1,%esi
f01009e1:	19 f6                	sbb    %esi,%esi
f01009e3:	89 75 a8             	mov    %esi,-0x58(%ebp)
f01009e6:	80 65 a8 ea          	andb   $0xea,-0x58(%ebp)
f01009ea:	80 45 a8 43          	addb   $0x43,-0x58(%ebp)
			char perm_Wirtethrough = (*cur_pte & PTE_PWT) ? 'T' : '-';
f01009ee:	89 c6                	mov    %eax,%esi
f01009f0:	83 e6 08             	and    $0x8,%esi
f01009f3:	83 fe 01             	cmp    $0x1,%esi
f01009f6:	19 f6                	sbb    %esi,%esi
f01009f8:	89 75 98             	mov    %esi,-0x68(%ebp)
f01009fb:	80 65 98 d9          	andb   $0xd9,-0x68(%ebp)
f01009ff:	80 45 98 54          	addb   $0x54,-0x68(%ebp)
			char perm_User = (*cur_pte & PTE_U) ? 'U' : '-';
f0100a03:	89 c6                	mov    %eax,%esi
f0100a05:	83 e6 04             	and    $0x4,%esi
f0100a08:	83 fe 01             	cmp    $0x1,%esi
f0100a0b:	19 f6                	sbb    %esi,%esi
f0100a0d:	83 e6 d8             	and    $0xffffffd8,%esi
f0100a10:	83 c6 55             	add    $0x55,%esi
			char perm_Writeable = (*cur_pte & PTE_W) ? 'W' : '-';
f0100a13:	83 e0 02             	and    $0x2,%eax
f0100a16:	83 f8 01             	cmp    $0x1,%eax
f0100a19:	19 c0                	sbb    %eax,%eax
f0100a1b:	83 e0 d6             	and    $0xffffffd6,%eax
f0100a1e:	83 c0 57             	add    $0x57,%eax
			char perm_Present = 'P';	// has been checked
			cprintf("%c%c%c%c%c%c%c%c%c\n", perm_Global, perm_PageSize, perm_Dirty, perm_Accessed, perm_CacheDisable, perm_Wirtethrough, perm_User, perm_Writeable,perm_Present);
f0100a21:	c7 44 24 24 50 00 00 	movl   $0x50,0x24(%esp)
f0100a28:	00 
f0100a29:	0f be c0             	movsbl %al,%eax
f0100a2c:	89 44 24 20          	mov    %eax,0x20(%esp)
f0100a30:	89 f0                	mov    %esi,%eax
f0100a32:	0f be f0             	movsbl %al,%esi
f0100a35:	89 74 24 1c          	mov    %esi,0x1c(%esp)
f0100a39:	0f be 45 98          	movsbl -0x68(%ebp),%eax
f0100a3d:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100a41:	0f be 45 a8          	movsbl -0x58(%ebp),%eax
f0100a45:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100a49:	0f be db             	movsbl %bl,%ebx
f0100a4c:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0100a50:	0f be c9             	movsbl %cl,%ecx
f0100a53:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100a57:	0f be d2             	movsbl %dl,%edx
f0100a5a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100a5e:	0f be 45 b8          	movsbl -0x48(%ebp),%eax
f0100a62:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a66:	c7 04 24 8f 5a 10 f0 	movl   $0xf0105a8f,(%esp)
f0100a6d:	e8 f1 32 00 00       	call   f0103d63 <cprintf>
		}
		start_addr += PGSIZE;
f0100a72:	81 c7 00 10 00 00    	add    $0x1000,%edi
			return 0;
		}
		end_addr = ROUNDUP(end_addr, PGSIZE);
	}

	while(start_addr < end_addr){
f0100a78:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0100a7b:	0f 82 b8 fe ff ff    	jb     f0100939 <mon_showmappings+0xca>
			cprintf("%c%c%c%c%c%c%c%c%c\n", perm_Global, perm_PageSize, perm_Dirty, perm_Accessed, perm_CacheDisable, perm_Wirtethrough, perm_User, perm_Writeable,perm_Present);
		}
		start_addr += PGSIZE;
	}
	return 0;
}
f0100a81:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a86:	81 c4 8c 00 00 00    	add    $0x8c,%esp
f0100a8c:	5b                   	pop    %ebx
f0100a8d:	5e                   	pop    %esi
f0100a8e:	5f                   	pop    %edi
f0100a8f:	5d                   	pop    %ebp
f0100a90:	c3                   	ret    

f0100a91 <mon_dump>:
	return 0;
}

int
mon_dump(int argc, char **argv, struct Trapframe *tf)
{
f0100a91:	55                   	push   %ebp
f0100a92:	89 e5                	mov    %esp,%ebp
f0100a94:	57                   	push   %edi
f0100a95:	56                   	push   %esi
f0100a96:	53                   	push   %ebx
f0100a97:	83 ec 2c             	sub    $0x2c,%esp
f0100a9a:	8b 7d 0c             	mov    0xc(%ebp),%edi
	int is_phyaddr = 0;
	if (argc != 4 || *argv[1] != '-'){
f0100a9d:	83 7d 08 04          	cmpl   $0x4,0x8(%ebp)
f0100aa1:	75 08                	jne    f0100aab <mon_dump+0x1a>
f0100aa3:	8b 47 04             	mov    0x4(%edi),%eax
f0100aa6:	80 38 2d             	cmpb   $0x2d,(%eax)
f0100aa9:	74 11                	je     f0100abc <mon_dump+0x2b>
		cprintf("Usage : dump [-p|-v] start_addr end_addr\n");
f0100aab:	c7 04 24 e8 5c 10 f0 	movl   $0xf0105ce8,(%esp)
f0100ab2:	e8 ac 32 00 00       	call   f0103d63 <cprintf>
		return 0;
f0100ab7:	e9 67 01 00 00       	jmp    f0100c23 <mon_dump+0x192>
	}
	if (argv[1][1] == 'p' || argv[1][1] == 'P')
f0100abc:	0f b6 40 01          	movzbl 0x1(%eax),%eax
f0100ac0:	83 e0 df             	and    $0xffffffdf,%eax
f0100ac3:	3c 50                	cmp    $0x50,%al
f0100ac5:	74 1a                	je     f0100ae1 <mon_dump+0x50>
		is_phyaddr = 1;
	else if (argv[1][1] == 'v' || argv[1][1] == 'V')
		is_phyaddr = 0;
f0100ac7:	bb 00 00 00 00       	mov    $0x0,%ebx
		cprintf("Usage : dump [-p|-v] start_addr end_addr\n");
		return 0;
	}
	if (argv[1][1] == 'p' || argv[1][1] == 'P')
		is_phyaddr = 1;
	else if (argv[1][1] == 'v' || argv[1][1] == 'V')
f0100acc:	3c 56                	cmp    $0x56,%al
f0100ace:	74 16                	je     f0100ae6 <mon_dump+0x55>
		is_phyaddr = 0;
	else{
		cprintf("Usage : dump [-p|-v] start_addr end_addr\n");
f0100ad0:	c7 04 24 e8 5c 10 f0 	movl   $0xf0105ce8,(%esp)
f0100ad7:	e8 87 32 00 00       	call   f0103d63 <cprintf>
		return 0;
f0100adc:	e9 42 01 00 00       	jmp    f0100c23 <mon_dump+0x192>
	if (argc != 4 || *argv[1] != '-'){
		cprintf("Usage : dump [-p|-v] start_addr end_addr\n");
		return 0;
	}
	if (argv[1][1] == 'p' || argv[1][1] == 'P')
		is_phyaddr = 1;
f0100ae1:	bb 01 00 00 00       	mov    $0x1,%ebx
		return 0;
	}

	// get start_addr and end_addr
	char *errStr;
	uintptr_t start_addr = strtol(argv[2], &errStr, 16);
f0100ae6:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100aed:	00 
f0100aee:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100af1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100af5:	8b 47 08             	mov    0x8(%edi),%eax
f0100af8:	89 04 24             	mov    %eax,(%esp)
f0100afb:	e8 d3 48 00 00       	call   f01053d3 <strtol>
	if (*errStr){
f0100b00:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100b03:	80 3a 00             	cmpb   $0x0,(%edx)
f0100b06:	74 18                	je     f0100b20 <mon_dump+0x8f>
		cprintf("error : invalid input : %s .\n", argv[1]);
f0100b08:	8b 47 04             	mov    0x4(%edi),%eax
f0100b0b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b0f:	c7 04 24 71 5a 10 f0 	movl   $0xf0105a71,(%esp)
f0100b16:	e8 48 32 00 00       	call   f0103d63 <cprintf>
		return 0;
f0100b1b:	e9 03 01 00 00       	jmp    f0100c23 <mon_dump+0x192>
	}
	start_addr = ROUNDDOWN(start_addr, PGSIZE);
f0100b20:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b25:	89 c6                	mov    %eax,%esi
	uintptr_t end_addr = strtol(argv[3], &errStr, 16);
f0100b27:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100b2e:	00 
f0100b2f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100b32:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b36:	8b 47 0c             	mov    0xc(%edi),%eax
f0100b39:	89 04 24             	mov    %eax,(%esp)
f0100b3c:	e8 92 48 00 00       	call   f01053d3 <strtol>
	if (*errStr){
f0100b41:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100b44:	80 3a 00             	cmpb   $0x0,(%edx)
f0100b47:	74 18                	je     f0100b61 <mon_dump+0xd0>
		cprintf("error : invalid input : %s .\n", argv[2]);
f0100b49:	8b 47 08             	mov    0x8(%edi),%eax
f0100b4c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b50:	c7 04 24 71 5a 10 f0 	movl   $0xf0105a71,(%esp)
f0100b57:	e8 07 32 00 00       	call   f0103d63 <cprintf>
		return 0;
f0100b5c:	e9 c2 00 00 00       	jmp    f0100c23 <mon_dump+0x192>
	}
	end_addr = ROUNDUP(end_addr, PGSIZE);
f0100b61:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100b66:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b6b:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// if the addr is physical addr, change to vitual addr
	if (is_phyaddr){
f0100b6e:	85 db                	test   %ebx,%ebx
f0100b70:	74 33                	je     f0100ba5 <mon_dump+0x114>
		if ((PGNUM(start_addr) >= npages) || (PGNUM(end_addr) >= npages)){
f0100b72:	a1 a4 fe 17 f0       	mov    0xf017fea4,%eax
f0100b77:	89 f2                	mov    %esi,%edx
f0100b79:	c1 ea 0c             	shr    $0xc,%edx
f0100b7c:	39 c2                	cmp    %eax,%edx
f0100b7e:	73 17                	jae    f0100b97 <mon_dump+0x106>
f0100b80:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100b83:	c1 ea 0c             	shr    $0xc,%edx
static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f0100b86:	81 ee 00 00 00 10    	sub    $0x10000000,%esi
f0100b8c:	81 6d d4 00 00 00 10 	subl   $0x10000000,-0x2c(%ebp)
f0100b93:	39 d0                	cmp    %edx,%eax
f0100b95:	77 0e                	ja     f0100ba5 <mon_dump+0x114>
			cprintf("error: the address overflow the max physical address\n");
f0100b97:	c7 04 24 14 5d 10 f0 	movl   $0xf0105d14,(%esp)
f0100b9e:	e8 c0 31 00 00       	call   f0103d63 <cprintf>
			return 0;
f0100ba3:	eb 7e                	jmp    f0100c23 <mon_dump+0x192>
		end_addr = (uint32_t)KADDR(end_addr);
	}

	while(start_addr < end_addr){
		pte_t *ppte;
		if (page_lookup(kern_pgdir, (void *)start_addr, &ppte) == NULL || *ppte == 0){
f0100ba5:	8d 7d e0             	lea    -0x20(%ebp),%edi
f0100ba8:	eb 74                	jmp    f0100c1e <mon_dump+0x18d>
f0100baa:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0100bae:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bb2:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0100bb7:	89 04 24             	mov    %eax,(%esp)
f0100bba:	e8 5b 0b 00 00       	call   f010171a <page_lookup>
f0100bbf:	85 c0                	test   %eax,%eax
f0100bc1:	74 09                	je     f0100bcc <mon_dump+0x13b>
f0100bc3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bc6:	8b 00                	mov    (%eax),%eax
f0100bc8:	85 c0                	test   %eax,%eax
f0100bca:	75 0e                	jne    f0100bda <mon_dump+0x149>
			cprintf("virtual addr 0x%08x not mapping\n");
f0100bcc:	c7 04 24 4c 5d 10 f0 	movl   $0xf0105d4c,(%esp)
f0100bd3:	e8 8b 31 00 00       	call   f0103d63 <cprintf>
f0100bd8:	eb 3e                	jmp    f0100c18 <mon_dump+0x187>
		}else{
			cprintf("virtual addr 0x%08x physical addr 0x%08x memory ", PTE_ADDR(*ppte) | PGOFF(start_addr));
f0100bda:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100bdf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100be3:	c7 04 24 70 5d 10 f0 	movl   $0xf0105d70,(%esp)
f0100bea:	e8 74 31 00 00       	call   f0103d63 <cprintf>
f0100bef:	bb 10 00 00 00       	mov    $0x10,%ebx
			for (int i = 0; i < 16; i++)
				cprintf("%02x ", *(unsigned char *)start_addr);
f0100bf4:	0f b6 06             	movzbl (%esi),%eax
f0100bf7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bfb:	c7 04 24 a3 5a 10 f0 	movl   $0xf0105aa3,(%esp)
f0100c02:	e8 5c 31 00 00       	call   f0103d63 <cprintf>
		pte_t *ppte;
		if (page_lookup(kern_pgdir, (void *)start_addr, &ppte) == NULL || *ppte == 0){
			cprintf("virtual addr 0x%08x not mapping\n");
		}else{
			cprintf("virtual addr 0x%08x physical addr 0x%08x memory ", PTE_ADDR(*ppte) | PGOFF(start_addr));
			for (int i = 0; i < 16; i++)
f0100c07:	83 eb 01             	sub    $0x1,%ebx
f0100c0a:	75 e8                	jne    f0100bf4 <mon_dump+0x163>
				cprintf("%02x ", *(unsigned char *)start_addr);
			cprintf("\n");
f0100c0c:	c7 04 24 c3 5a 10 f0 	movl   $0xf0105ac3,(%esp)
f0100c13:	e8 4b 31 00 00       	call   f0103d63 <cprintf>
		}
		start_addr += PGSIZE;
f0100c18:	81 c6 00 10 00 00    	add    $0x1000,%esi
		}
		start_addr = (uint32_t)KADDR(start_addr);
		end_addr = (uint32_t)KADDR(end_addr);
	}

	while(start_addr < end_addr){
f0100c1e:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0100c21:	72 87                	jb     f0100baa <mon_dump+0x119>
			cprintf("\n");
		}
		start_addr += PGSIZE;
	}
	return 0;
}
f0100c23:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c28:	83 c4 2c             	add    $0x2c,%esp
f0100c2b:	5b                   	pop    %ebx
f0100c2c:	5e                   	pop    %esi
f0100c2d:	5f                   	pop    %edi
f0100c2e:	5d                   	pop    %ebp
f0100c2f:	c3                   	ret    

f0100c30 <mon_setpermission>:
	return 0;
}

int
mon_setpermission(int argc, char **argv, struct Trapframe *tf)
{
f0100c30:	55                   	push   %ebp
f0100c31:	89 e5                	mov    %esp,%ebp
f0100c33:	57                   	push   %edi
f0100c34:	56                   	push   %esi
f0100c35:	53                   	push   %ebx
f0100c36:	83 ec 2c             	sub    $0x2c,%esp
f0100c39:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if (argc != 3 || (*argv[2] != '+' && *argv[2] != '-')){
f0100c3c:	83 7d 08 03          	cmpl   $0x3,0x8(%ebp)
f0100c40:	75 0e                	jne    f0100c50 <mon_setpermission+0x20>
f0100c42:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c45:	0f b6 00             	movzbl (%eax),%eax
f0100c48:	3c 2d                	cmp    $0x2d,%al
f0100c4a:	74 15                	je     f0100c61 <mon_setpermission+0x31>
f0100c4c:	3c 2b                	cmp    $0x2b,%al
f0100c4e:	74 11                	je     f0100c61 <mon_setpermission+0x31>
		cprintf("Usage : setperm [+|-]perm \n");
f0100c50:	c7 04 24 a9 5a 10 f0 	movl   $0xf0105aa9,(%esp)
f0100c57:	e8 07 31 00 00       	call   f0103d63 <cprintf>
		return 0;
f0100c5c:	e9 16 01 00 00       	jmp    f0100d77 <mon_setpermission+0x147>
	}
	char *errStr;
	uint32_t start_addr = strtol(argv[1], &errStr, 16);
f0100c61:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0100c68:	00 
f0100c69:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100c6c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c70:	8b 43 04             	mov    0x4(%ebx),%eax
f0100c73:	89 04 24             	mov    %eax,(%esp)
f0100c76:	e8 58 47 00 00       	call   f01053d3 <strtol>
	start_addr = ROUNDDOWN(start_addr, PGSIZE);
f0100c7b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c80:	89 c6                	mov    %eax,%esi
	pte_t *ppte;
	struct PageInfo *pp = page_lookup(kern_pgdir, (void *)start_addr, &ppte);
f0100c82:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0100c85:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100c89:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c8d:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0100c92:	89 04 24             	mov    %eax,(%esp)
f0100c95:	e8 80 0a 00 00       	call   f010171a <page_lookup>
	if (!pp || !*ppte){
f0100c9a:	85 c0                	test   %eax,%eax
f0100c9c:	74 09                	je     f0100ca7 <mon_setpermission+0x77>
f0100c9e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100ca1:	8b 39                	mov    (%ecx),%edi
f0100ca3:	85 ff                	test   %edi,%edi
f0100ca5:	75 15                	jne    f0100cbc <mon_setpermission+0x8c>
		cprintf("virtual address 0x%08x not mapped.\n", start_addr);
f0100ca7:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100cab:	c7 04 24 88 5c 10 f0 	movl   $0xf0105c88,(%esp)
f0100cb2:	e8 ac 30 00 00       	call   f0103d63 <cprintf>
		return 0;
f0100cb7:	e9 bb 00 00 00       	jmp    f0100d77 <mon_setpermission+0x147>
	} 
	if (*argv[2] == '+'){
f0100cbc:	8b 53 08             	mov    0x8(%ebx),%edx
f0100cbf:	0f b6 02             	movzbl (%edx),%eax
f0100cc2:	3c 2b                	cmp    $0x2b,%al
f0100cc4:	75 56                	jne    f0100d1c <mon_setpermission+0xec>
		*ppte |= str2permision(argv[2] + 1);
f0100cc6:	83 c2 01             	add    $0x1,%edx
int	user_mem_check(struct Env *env, const void *va, size_t len, int perm);
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline int
str2permision(const char *buf){
	int perm = 0;
f0100cc9:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cce:	eb 3f                	jmp    f0100d0f <mon_setpermission+0xdf>
	while(*buf != '\0'){
		switch(*buf++){
f0100cd0:	83 c2 01             	add    $0x1,%edx
f0100cd3:	83 e8 41             	sub    $0x41,%eax
f0100cd6:	3c 36                	cmp    $0x36,%al
f0100cd8:	77 35                	ja     f0100d0f <mon_setpermission+0xdf>
f0100cda:	0f b6 c0             	movzbl %al,%eax
f0100cdd:	ff 24 85 20 5f 10 f0 	jmp    *-0xfefa0e0(,%eax,4)
			case 'p':
			case 'P':
				perm |= PTE_P;
f0100ce4:	83 cb 01             	or     $0x1,%ebx
f0100ce7:	eb 26                	jmp    f0100d0f <mon_setpermission+0xdf>
				break;
			case 'w':
			case 'W':
				perm |= PTE_W;
f0100ce9:	83 cb 02             	or     $0x2,%ebx
f0100cec:	eb 21                	jmp    f0100d0f <mon_setpermission+0xdf>
				break;
			case 'u':
			case 'U':
				perm |= PTE_U;
f0100cee:	83 cb 04             	or     $0x4,%ebx
f0100cf1:	eb 1c                	jmp    f0100d0f <mon_setpermission+0xdf>
				break;
			case 't':
			case 'T':
				perm |= PTE_PWT;
f0100cf3:	83 cb 08             	or     $0x8,%ebx
f0100cf6:	eb 17                	jmp    f0100d0f <mon_setpermission+0xdf>
				break;
			case 'c':
			case 'C':
				perm |= PTE_PCD;
f0100cf8:	83 cb 10             	or     $0x10,%ebx
f0100cfb:	eb 12                	jmp    f0100d0f <mon_setpermission+0xdf>
				break;
			case 'a':
			case 'A':
				perm |= PTE_A;
f0100cfd:	83 cb 20             	or     $0x20,%ebx
f0100d00:	eb 0d                	jmp    f0100d0f <mon_setpermission+0xdf>
				break;
			case 'd':
			case 'D':
				perm |= PTE_D;
f0100d02:	83 cb 40             	or     $0x40,%ebx
f0100d05:	eb 08                	jmp    f0100d0f <mon_setpermission+0xdf>
				break;
			case 's':
			case 'S':
				perm |= PTE_PS;
f0100d07:	80 cb 80             	or     $0x80,%bl
f0100d0a:	eb 03                	jmp    f0100d0f <mon_setpermission+0xdf>
				break;
			case 'g':
			case 'G':
				perm |= PTE_G;
f0100d0c:	80 cf 01             	or     $0x1,%bh
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline int
str2permision(const char *buf){
	int perm = 0;
	while(*buf != '\0'){
f0100d0f:	0f b6 02             	movzbl (%edx),%eax
f0100d12:	84 c0                	test   %al,%al
f0100d14:	75 ba                	jne    f0100cd0 <mon_setpermission+0xa0>
f0100d16:	09 df                	or     %ebx,%edi
f0100d18:	89 39                	mov    %edi,(%ecx)
f0100d1a:	eb 5b                	jmp    f0100d77 <mon_setpermission+0x147>
	}else if (*argv[2] == '-'){
		*ppte = *ppte & (~str2permision(argv[2] + 1));
f0100d1c:	83 c2 01             	add    $0x1,%edx
int	user_mem_check(struct Env *env, const void *va, size_t len, int perm);
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline int
str2permision(const char *buf){
	int perm = 0;
f0100d1f:	bb 00 00 00 00       	mov    $0x0,%ebx
		cprintf("virtual address 0x%08x not mapped.\n", start_addr);
		return 0;
	} 
	if (*argv[2] == '+'){
		*ppte |= str2permision(argv[2] + 1);
	}else if (*argv[2] == '-'){
f0100d24:	3c 2d                	cmp    $0x2d,%al
f0100d26:	74 42                	je     f0100d6a <mon_setpermission+0x13a>
f0100d28:	eb 4d                	jmp    f0100d77 <mon_setpermission+0x147>
	while(*buf != '\0'){
		switch(*buf++){
f0100d2a:	83 c2 01             	add    $0x1,%edx
f0100d2d:	83 e8 41             	sub    $0x41,%eax
f0100d30:	3c 36                	cmp    $0x36,%al
f0100d32:	77 36                	ja     f0100d6a <mon_setpermission+0x13a>
f0100d34:	0f b6 c0             	movzbl %al,%eax
f0100d37:	ff 24 85 fc 5f 10 f0 	jmp    *-0xfefa004(,%eax,4)
			case 'p':
			case 'P':
				perm |= PTE_P;
f0100d3e:	83 cb 01             	or     $0x1,%ebx
f0100d41:	eb 27                	jmp    f0100d6a <mon_setpermission+0x13a>
				break;
			case 'w':
			case 'W':
				perm |= PTE_W;
f0100d43:	83 cb 02             	or     $0x2,%ebx
f0100d46:	eb 22                	jmp    f0100d6a <mon_setpermission+0x13a>
				break;
			case 'u':
			case 'U':
				perm |= PTE_U;
f0100d48:	83 cb 04             	or     $0x4,%ebx
f0100d4b:	eb 1d                	jmp    f0100d6a <mon_setpermission+0x13a>
				break;
			case 't':
			case 'T':
				perm |= PTE_PWT;
f0100d4d:	83 cb 08             	or     $0x8,%ebx
f0100d50:	eb 18                	jmp    f0100d6a <mon_setpermission+0x13a>
				break;
			case 'c':
			case 'C':
				perm |= PTE_PCD;
f0100d52:	83 cb 10             	or     $0x10,%ebx
f0100d55:	eb 13                	jmp    f0100d6a <mon_setpermission+0x13a>
				break;
			case 'a':
			case 'A':
				perm |= PTE_A;
f0100d57:	83 cb 20             	or     $0x20,%ebx
f0100d5a:	eb 0e                	jmp    f0100d6a <mon_setpermission+0x13a>
				break;
			case 'd':
			case 'D':
				perm |= PTE_D;
f0100d5c:	83 cb 40             	or     $0x40,%ebx
f0100d5f:	90                   	nop
f0100d60:	eb 08                	jmp    f0100d6a <mon_setpermission+0x13a>
				break;
			case 's':
			case 'S':
				perm |= PTE_PS;
f0100d62:	80 cb 80             	or     $0x80,%bl
f0100d65:	eb 03                	jmp    f0100d6a <mon_setpermission+0x13a>
				break;
			case 'g':
			case 'G':
				perm |= PTE_G;
f0100d67:	80 cf 01             	or     $0x1,%bh
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline int
str2permision(const char *buf){
	int perm = 0;
	while(*buf != '\0'){
f0100d6a:	0f b6 02             	movzbl (%edx),%eax
f0100d6d:	84 c0                	test   %al,%al
f0100d6f:	75 b9                	jne    f0100d2a <mon_setpermission+0xfa>
		*ppte = *ppte & (~str2permision(argv[2] + 1));
f0100d71:	f7 d3                	not    %ebx
f0100d73:	21 df                	and    %ebx,%edi
f0100d75:	89 39                	mov    %edi,(%ecx)
	}
	return 0;
}
f0100d77:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d7c:	83 c4 2c             	add    $0x2c,%esp
f0100d7f:	5b                   	pop    %ebx
f0100d80:	5e                   	pop    %esi
f0100d81:	5f                   	pop    %edi
f0100d82:	5d                   	pop    %ebp
f0100d83:	c3                   	ret    

f0100d84 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100d84:	55                   	push   %ebp
f0100d85:	89 e5                	mov    %esp,%ebp
f0100d87:	57                   	push   %edi
f0100d88:	56                   	push   %esi
f0100d89:	53                   	push   %ebx
f0100d8a:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100d8d:	c7 04 24 a4 5d 10 f0 	movl   $0xf0105da4,(%esp)
f0100d94:	e8 ca 2f 00 00       	call   f0103d63 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100d99:	c7 04 24 c8 5d 10 f0 	movl   $0xf0105dc8,(%esp)
f0100da0:	e8 be 2f 00 00       	call   f0103d63 <cprintf>

	if (tf != NULL)
f0100da5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100da9:	74 0b                	je     f0100db6 <monitor+0x32>
		print_trapframe(tf);
f0100dab:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dae:	89 04 24             	mov    %eax,(%esp)
f0100db1:	e8 09 34 00 00       	call   f01041bf <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100db6:	c7 04 24 c5 5a 10 f0 	movl   $0xf0105ac5,(%esp)
f0100dbd:	e8 8e 42 00 00       	call   f0105050 <readline>
f0100dc2:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100dc4:	85 c0                	test   %eax,%eax
f0100dc6:	74 ee                	je     f0100db6 <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100dc8:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100dcf:	be 00 00 00 00       	mov    $0x0,%esi
f0100dd4:	eb 0a                	jmp    f0100de0 <monitor+0x5c>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100dd6:	c6 03 00             	movb   $0x0,(%ebx)
f0100dd9:	89 f7                	mov    %esi,%edi
f0100ddb:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100dde:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100de0:	0f b6 03             	movzbl (%ebx),%eax
f0100de3:	84 c0                	test   %al,%al
f0100de5:	74 63                	je     f0100e4a <monitor+0xc6>
f0100de7:	0f be c0             	movsbl %al,%eax
f0100dea:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dee:	c7 04 24 c9 5a 10 f0 	movl   $0xf0105ac9,(%esp)
f0100df5:	e8 70 44 00 00       	call   f010526a <strchr>
f0100dfa:	85 c0                	test   %eax,%eax
f0100dfc:	75 d8                	jne    f0100dd6 <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f0100dfe:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100e01:	74 47                	je     f0100e4a <monitor+0xc6>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100e03:	83 fe 0f             	cmp    $0xf,%esi
f0100e06:	75 16                	jne    f0100e1e <monitor+0x9a>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100e08:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100e0f:	00 
f0100e10:	c7 04 24 ce 5a 10 f0 	movl   $0xf0105ace,(%esp)
f0100e17:	e8 47 2f 00 00       	call   f0103d63 <cprintf>
f0100e1c:	eb 98                	jmp    f0100db6 <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f0100e1e:	8d 7e 01             	lea    0x1(%esi),%edi
f0100e21:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100e25:	eb 03                	jmp    f0100e2a <monitor+0xa6>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100e27:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100e2a:	0f b6 03             	movzbl (%ebx),%eax
f0100e2d:	84 c0                	test   %al,%al
f0100e2f:	74 ad                	je     f0100dde <monitor+0x5a>
f0100e31:	0f be c0             	movsbl %al,%eax
f0100e34:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e38:	c7 04 24 c9 5a 10 f0 	movl   $0xf0105ac9,(%esp)
f0100e3f:	e8 26 44 00 00       	call   f010526a <strchr>
f0100e44:	85 c0                	test   %eax,%eax
f0100e46:	74 df                	je     f0100e27 <monitor+0xa3>
f0100e48:	eb 94                	jmp    f0100dde <monitor+0x5a>
			buf++;
	}
	argv[argc] = 0;
f0100e4a:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100e51:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100e52:	85 f6                	test   %esi,%esi
f0100e54:	0f 84 5c ff ff ff    	je     f0100db6 <monitor+0x32>
f0100e5a:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e5f:	89 d8                	mov    %ebx,%eax
f0100e61:	c1 e0 04             	shl    $0x4,%eax
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100e64:	8b 80 e0 60 10 f0    	mov    -0xfef9f20(%eax),%eax
f0100e6a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e6e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100e71:	89 04 24             	mov    %eax,(%esp)
f0100e74:	e8 93 43 00 00       	call   f010520c <strcmp>
f0100e79:	85 c0                	test   %eax,%eax
f0100e7b:	75 23                	jne    f0100ea0 <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f0100e7d:	c1 e3 04             	shl    $0x4,%ebx
f0100e80:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e83:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e87:	8d 45 a8             	lea    -0x58(%ebp),%eax
f0100e8a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e8e:	89 34 24             	mov    %esi,(%esp)
f0100e91:	ff 93 ec 60 10 f0    	call   *-0xfef9f14(%ebx)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100e97:	85 c0                	test   %eax,%eax
f0100e99:	78 25                	js     f0100ec0 <monitor+0x13c>
f0100e9b:	e9 16 ff ff ff       	jmp    f0100db6 <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100ea0:	83 c3 01             	add    $0x1,%ebx
f0100ea3:	83 fb 06             	cmp    $0x6,%ebx
f0100ea6:	75 b7                	jne    f0100e5f <monitor+0xdb>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100ea8:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100eab:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100eaf:	c7 04 24 eb 5a 10 f0 	movl   $0xf0105aeb,(%esp)
f0100eb6:	e8 a8 2e 00 00       	call   f0103d63 <cprintf>
f0100ebb:	e9 f6 fe ff ff       	jmp    f0100db6 <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100ec0:	83 c4 5c             	add    $0x5c,%esp
f0100ec3:	5b                   	pop    %ebx
f0100ec4:	5e                   	pop    %esi
f0100ec5:	5f                   	pop    %edi
f0100ec6:	5d                   	pop    %ebp
f0100ec7:	c3                   	ret    
f0100ec8:	66 90                	xchg   %ax,%ax
f0100eca:	66 90                	xchg   %ax,%ax
f0100ecc:	66 90                	xchg   %ax,%ax
f0100ece:	66 90                	xchg   %ax,%ax

f0100ed0 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100ed0:	55                   	push   %ebp
f0100ed1:	89 e5                	mov    %esp,%ebp
f0100ed3:	56                   	push   %esi
f0100ed4:	53                   	push   %ebx
f0100ed5:	83 ec 10             	sub    $0x10,%esp
f0100ed8:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100eda:	89 04 24             	mov    %eax,(%esp)
f0100edd:	e8 11 2e 00 00       	call   f0103cf3 <mc146818_read>
f0100ee2:	89 c6                	mov    %eax,%esi
f0100ee4:	83 c3 01             	add    $0x1,%ebx
f0100ee7:	89 1c 24             	mov    %ebx,(%esp)
f0100eea:	e8 04 2e 00 00       	call   f0103cf3 <mc146818_read>
f0100eef:	c1 e0 08             	shl    $0x8,%eax
f0100ef2:	09 f0                	or     %esi,%eax
}
f0100ef4:	83 c4 10             	add    $0x10,%esp
f0100ef7:	5b                   	pop    %ebx
f0100ef8:	5e                   	pop    %esi
f0100ef9:	5d                   	pop    %ebp
f0100efa:	c3                   	ret    

f0100efb <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100efb:	55                   	push   %ebp
f0100efc:	89 e5                	mov    %esp,%ebp
f0100efe:	83 ec 18             	sub    $0x18,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100f01:	83 3d d8 f1 17 f0 00 	cmpl   $0x0,0xf017f1d8
f0100f08:	0f 85 8a 00 00 00    	jne    f0100f98 <boot_alloc+0x9d>
		extern char end[];	//end point to the end of segment bss
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100f0e:	ba af 0e 18 f0       	mov    $0xf0180eaf,%edx
f0100f13:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100f19:	89 15 d8 f1 17 f0    	mov    %edx,0xf017f1d8
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0)
f0100f1f:	85 c0                	test   %eax,%eax
f0100f21:	75 07                	jne    f0100f2a <boot_alloc+0x2f>
		return nextfree;
f0100f23:	a1 d8 f1 17 f0       	mov    0xf017f1d8,%eax
f0100f28:	eb 78                	jmp    f0100fa2 <boot_alloc+0xa7>
	else if (n > 0){
		result = nextfree;
f0100f2a:	8b 15 d8 f1 17 f0    	mov    0xf017f1d8,%edx
		nextfree += n;
		nextfree = ROUNDUP((char *) nextfree, PGSIZE);
f0100f30:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100f37:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100f3c:	a3 d8 f1 17 f0       	mov    %eax,0xf017f1d8
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f41:	81 3d a4 fe 17 f0 00 	cmpl   $0x400,0xf017fea4
f0100f48:	04 00 00 
f0100f4b:	77 24                	ja     f0100f71 <boot_alloc+0x76>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f4d:	c7 44 24 0c 00 00 40 	movl   $0x400000,0xc(%esp)
f0100f54:	00 
f0100f55:	c7 44 24 08 40 61 10 	movl   $0xf0106140,0x8(%esp)
f0100f5c:	f0 
f0100f5d:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
f0100f64:	00 
f0100f65:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0100f6c:	e8 45 f1 ff ff       	call   f01000b6 <_panic>
		//nextfree should be less than the size of kernel virtual address: 4MB
		if(nextfree >= (char *)KADDR(0x400000))
f0100f71:	3d ff ff 3f f0       	cmp    $0xf03fffff,%eax
f0100f76:	76 1c                	jbe    f0100f94 <boot_alloc+0x99>
			panic("error: nextfree out of the size of kernel virtual address\n");
f0100f78:	c7 44 24 08 64 61 10 	movl   $0xf0106164,0x8(%esp)
f0100f7f:	f0 
f0100f80:	c7 44 24 04 72 00 00 	movl   $0x72,0x4(%esp)
f0100f87:	00 
f0100f88:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0100f8f:	e8 22 f1 ff ff       	call   f01000b6 <_panic>
		return result;
f0100f94:	89 d0                	mov    %edx,%eax
f0100f96:	eb 0a                	jmp    f0100fa2 <boot_alloc+0xa7>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0)
f0100f98:	85 c0                	test   %eax,%eax
f0100f9a:	75 8e                	jne    f0100f2a <boot_alloc+0x2f>
f0100f9c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100fa0:	eb 81                	jmp    f0100f23 <boot_alloc+0x28>
		if(nextfree >= (char *)KADDR(0x400000))
			panic("error: nextfree out of the size of kernel virtual address\n");
		return result;
	}
	return NULL;
}
f0100fa2:	c9                   	leave  
f0100fa3:	c3                   	ret    

f0100fa4 <page2kva>:
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fa4:	2b 05 ac fe 17 f0    	sub    0xf017feac,%eax
f0100faa:	c1 f8 03             	sar    $0x3,%eax
f0100fad:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fb0:	89 c2                	mov    %eax,%edx
f0100fb2:	c1 ea 0c             	shr    $0xc,%edx
f0100fb5:	3b 15 a4 fe 17 f0    	cmp    0xf017fea4,%edx
f0100fbb:	72 26                	jb     f0100fe3 <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100fbd:	55                   	push   %ebp
f0100fbe:	89 e5                	mov    %esp,%ebp
f0100fc0:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fc3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fc7:	c7 44 24 08 40 61 10 	movl   $0xf0106140,0x8(%esp)
f0100fce:	f0 
f0100fcf:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f0100fd6:	00 
f0100fd7:	c7 04 24 71 69 10 f0 	movl   $0xf0106971,(%esp)
f0100fde:	e8 d3 f0 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0100fe3:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
f0100fe8:	c3                   	ret    

f0100fe9 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100fe9:	89 d1                	mov    %edx,%ecx
f0100feb:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100fee:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100ff1:	a8 01                	test   $0x1,%al
f0100ff3:	74 5d                	je     f0101052 <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100ff5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ffa:	89 c1                	mov    %eax,%ecx
f0100ffc:	c1 e9 0c             	shr    $0xc,%ecx
f0100fff:	3b 0d a4 fe 17 f0    	cmp    0xf017fea4,%ecx
f0101005:	72 26                	jb     f010102d <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0101007:	55                   	push   %ebp
f0101008:	89 e5                	mov    %esp,%ebp
f010100a:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010100d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101011:	c7 44 24 08 40 61 10 	movl   $0xf0106140,0x8(%esp)
f0101018:	f0 
f0101019:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0101020:	00 
f0101021:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101028:	e8 89 f0 ff ff       	call   f01000b6 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f010102d:	c1 ea 0c             	shr    $0xc,%edx
f0101030:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0101036:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010103d:	89 c2                	mov    %eax,%edx
f010103f:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0101042:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101047:	85 d2                	test   %edx,%edx
f0101049:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010104e:	0f 44 c2             	cmove  %edx,%eax
f0101051:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0101052:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0101057:	c3                   	ret    

f0101058 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0101058:	55                   	push   %ebp
f0101059:	89 e5                	mov    %esp,%ebp
f010105b:	57                   	push   %edi
f010105c:	56                   	push   %esi
f010105d:	53                   	push   %ebx
f010105e:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0101061:	84 c0                	test   %al,%al
f0101063:	0f 85 07 03 00 00    	jne    f0101370 <check_page_free_list+0x318>
f0101069:	e9 14 03 00 00       	jmp    f0101382 <check_page_free_list+0x32a>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f010106e:	c7 44 24 08 a0 61 10 	movl   $0xf01061a0,0x8(%esp)
f0101075:	f0 
f0101076:	c7 44 24 04 76 02 00 	movl   $0x276,0x4(%esp)
f010107d:	00 
f010107e:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101085:	e8 2c f0 ff ff       	call   f01000b6 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f010108a:	8d 55 d8             	lea    -0x28(%ebp),%edx
f010108d:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101090:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101093:	89 55 e4             	mov    %edx,-0x1c(%ebp)
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101096:	89 c2                	mov    %eax,%edx
f0101098:	2b 15 ac fe 17 f0    	sub    0xf017feac,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f010109e:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01010a4:	0f 95 c2             	setne  %dl
f01010a7:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01010aa:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01010ae:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01010b0:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01010b4:	8b 00                	mov    (%eax),%eax
f01010b6:	85 c0                	test   %eax,%eax
f01010b8:	75 dc                	jne    f0101096 <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01010ba:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010bd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01010c3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010c6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010c9:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f01010cb:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010ce:	a3 e0 f1 17 f0       	mov    %eax,0xf017f1e0
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01010d3:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01010d8:	8b 1d e0 f1 17 f0    	mov    0xf017f1e0,%ebx
f01010de:	eb 63                	jmp    f0101143 <check_page_free_list+0xeb>
f01010e0:	89 d8                	mov    %ebx,%eax
f01010e2:	2b 05 ac fe 17 f0    	sub    0xf017feac,%eax
f01010e8:	c1 f8 03             	sar    $0x3,%eax
f01010eb:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f01010ee:	89 c2                	mov    %eax,%edx
f01010f0:	c1 ea 16             	shr    $0x16,%edx
f01010f3:	39 f2                	cmp    %esi,%edx
f01010f5:	73 4a                	jae    f0101141 <check_page_free_list+0xe9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010f7:	89 c2                	mov    %eax,%edx
f01010f9:	c1 ea 0c             	shr    $0xc,%edx
f01010fc:	3b 15 a4 fe 17 f0    	cmp    0xf017fea4,%edx
f0101102:	72 20                	jb     f0101124 <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101104:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101108:	c7 44 24 08 40 61 10 	movl   $0xf0106140,0x8(%esp)
f010110f:	f0 
f0101110:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f0101117:	00 
f0101118:	c7 04 24 71 69 10 f0 	movl   $0xf0106971,(%esp)
f010111f:	e8 92 ef ff ff       	call   f01000b6 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0101124:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f010112b:	00 
f010112c:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0101133:	00 
	return (void *)(pa + KERNBASE);
f0101134:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101139:	89 04 24             	mov    %eax,(%esp)
f010113c:	e8 66 41 00 00       	call   f01052a7 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101141:	8b 1b                	mov    (%ebx),%ebx
f0101143:	85 db                	test   %ebx,%ebx
f0101145:	75 99                	jne    f01010e0 <check_page_free_list+0x88>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0101147:	b8 00 00 00 00       	mov    $0x0,%eax
f010114c:	e8 aa fd ff ff       	call   f0100efb <boot_alloc>
f0101151:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101154:	8b 15 e0 f1 17 f0    	mov    0xf017f1e0,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f010115a:	8b 0d ac fe 17 f0    	mov    0xf017feac,%ecx
		assert(pp < pages + npages);
f0101160:	a1 a4 fe 17 f0       	mov    0xf017fea4,%eax
f0101165:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0101168:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f010116b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f010116e:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0101171:	bf 00 00 00 00       	mov    $0x0,%edi
f0101176:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101179:	e9 97 01 00 00       	jmp    f0101315 <check_page_free_list+0x2bd>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f010117e:	39 ca                	cmp    %ecx,%edx
f0101180:	73 24                	jae    f01011a6 <check_page_free_list+0x14e>
f0101182:	c7 44 24 0c 7f 69 10 	movl   $0xf010697f,0xc(%esp)
f0101189:	f0 
f010118a:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101191:	f0 
f0101192:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
f0101199:	00 
f010119a:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01011a1:	e8 10 ef ff ff       	call   f01000b6 <_panic>
		assert(pp < pages + npages);
f01011a6:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f01011a9:	72 24                	jb     f01011cf <check_page_free_list+0x177>
f01011ab:	c7 44 24 0c a0 69 10 	movl   $0xf01069a0,0xc(%esp)
f01011b2:	f0 
f01011b3:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01011ba:	f0 
f01011bb:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
f01011c2:	00 
f01011c3:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01011ca:	e8 e7 ee ff ff       	call   f01000b6 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f01011cf:	89 d0                	mov    %edx,%eax
f01011d1:	2b 45 d0             	sub    -0x30(%ebp),%eax
f01011d4:	a8 07                	test   $0x7,%al
f01011d6:	74 24                	je     f01011fc <check_page_free_list+0x1a4>
f01011d8:	c7 44 24 0c c4 61 10 	movl   $0xf01061c4,0xc(%esp)
f01011df:	f0 
f01011e0:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01011e7:	f0 
f01011e8:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
f01011ef:	00 
f01011f0:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01011f7:	e8 ba ee ff ff       	call   f01000b6 <_panic>
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01011fc:	c1 f8 03             	sar    $0x3,%eax
f01011ff:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0101202:	85 c0                	test   %eax,%eax
f0101204:	75 24                	jne    f010122a <check_page_free_list+0x1d2>
f0101206:	c7 44 24 0c b4 69 10 	movl   $0xf01069b4,0xc(%esp)
f010120d:	f0 
f010120e:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101215:	f0 
f0101216:	c7 44 24 04 95 02 00 	movl   $0x295,0x4(%esp)
f010121d:	00 
f010121e:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101225:	e8 8c ee ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f010122a:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f010122f:	75 24                	jne    f0101255 <check_page_free_list+0x1fd>
f0101231:	c7 44 24 0c c5 69 10 	movl   $0xf01069c5,0xc(%esp)
f0101238:	f0 
f0101239:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101240:	f0 
f0101241:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
f0101248:	00 
f0101249:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101250:	e8 61 ee ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0101255:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f010125a:	75 24                	jne    f0101280 <check_page_free_list+0x228>
f010125c:	c7 44 24 0c f8 61 10 	movl   $0xf01061f8,0xc(%esp)
f0101263:	f0 
f0101264:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010126b:	f0 
f010126c:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
f0101273:	00 
f0101274:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010127b:	e8 36 ee ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0101280:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0101285:	75 24                	jne    f01012ab <check_page_free_list+0x253>
f0101287:	c7 44 24 0c de 69 10 	movl   $0xf01069de,0xc(%esp)
f010128e:	f0 
f010128f:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101296:	f0 
f0101297:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f010129e:	00 
f010129f:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01012a6:	e8 0b ee ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f01012ab:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f01012b0:	76 58                	jbe    f010130a <check_page_free_list+0x2b2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012b2:	89 c3                	mov    %eax,%ebx
f01012b4:	c1 eb 0c             	shr    $0xc,%ebx
f01012b7:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f01012ba:	77 20                	ja     f01012dc <check_page_free_list+0x284>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012bc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012c0:	c7 44 24 08 40 61 10 	movl   $0xf0106140,0x8(%esp)
f01012c7:	f0 
f01012c8:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f01012cf:	00 
f01012d0:	c7 04 24 71 69 10 f0 	movl   $0xf0106971,(%esp)
f01012d7:	e8 da ed ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f01012dc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01012e1:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f01012e4:	76 2a                	jbe    f0101310 <check_page_free_list+0x2b8>
f01012e6:	c7 44 24 0c 1c 62 10 	movl   $0xf010621c,0xc(%esp)
f01012ed:	f0 
f01012ee:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01012f5:	f0 
f01012f6:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f01012fd:	00 
f01012fe:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101305:	e8 ac ed ff ff       	call   f01000b6 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f010130a:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f010130e:	eb 03                	jmp    f0101313 <check_page_free_list+0x2bb>
		else
			++nfree_extmem;
f0101310:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101313:	8b 12                	mov    (%edx),%edx
f0101315:	85 d2                	test   %edx,%edx
f0101317:	0f 85 61 fe ff ff    	jne    f010117e <check_page_free_list+0x126>
f010131d:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0101320:	85 db                	test   %ebx,%ebx
f0101322:	7f 24                	jg     f0101348 <check_page_free_list+0x2f0>
f0101324:	c7 44 24 0c f8 69 10 	movl   $0xf01069f8,0xc(%esp)
f010132b:	f0 
f010132c:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101333:	f0 
f0101334:	c7 44 24 04 a1 02 00 	movl   $0x2a1,0x4(%esp)
f010133b:	00 
f010133c:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101343:	e8 6e ed ff ff       	call   f01000b6 <_panic>
	assert(nfree_extmem > 0);
f0101348:	85 ff                	test   %edi,%edi
f010134a:	7f 4d                	jg     f0101399 <check_page_free_list+0x341>
f010134c:	c7 44 24 0c 0a 6a 10 	movl   $0xf0106a0a,0xc(%esp)
f0101353:	f0 
f0101354:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010135b:	f0 
f010135c:	c7 44 24 04 a2 02 00 	movl   $0x2a2,0x4(%esp)
f0101363:	00 
f0101364:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010136b:	e8 46 ed ff ff       	call   f01000b6 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0101370:	a1 e0 f1 17 f0       	mov    0xf017f1e0,%eax
f0101375:	85 c0                	test   %eax,%eax
f0101377:	0f 85 0d fd ff ff    	jne    f010108a <check_page_free_list+0x32>
f010137d:	e9 ec fc ff ff       	jmp    f010106e <check_page_free_list+0x16>
f0101382:	83 3d e0 f1 17 f0 00 	cmpl   $0x0,0xf017f1e0
f0101389:	0f 84 df fc ff ff    	je     f010106e <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010138f:	be 00 04 00 00       	mov    $0x400,%esi
f0101394:	e9 3f fd ff ff       	jmp    f01010d8 <check_page_free_list+0x80>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0101399:	83 c4 4c             	add    $0x4c,%esp
f010139c:	5b                   	pop    %ebx
f010139d:	5e                   	pop    %esi
f010139e:	5f                   	pop    %edi
f010139f:	5d                   	pop    %ebp
f01013a0:	c3                   	ret    

f01013a1 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f01013a1:	55                   	push   %ebp
f01013a2:	89 e5                	mov    %esp,%ebp
f01013a4:	56                   	push   %esi
f01013a5:	53                   	push   %ebx
f01013a6:	83 ec 10             	sub    $0x10,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f01013a9:	be 00 00 00 00       	mov    $0x0,%esi
f01013ae:	bb 00 00 00 00       	mov    $0x0,%ebx
f01013b3:	e9 ef 00 00 00       	jmp    f01014a7 <page_init+0x106>
		if (i == 0){
f01013b8:	85 db                	test   %ebx,%ebx
f01013ba:	75 16                	jne    f01013d2 <page_init+0x31>
			//Mark physical page 0 as in use
			pages[i].pp_ref = 1;
f01013bc:	a1 ac fe 17 f0       	mov    0xf017feac,%eax
f01013c1:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;	//pp_link = NULL means this page has been alloced
f01013c7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f01013cd:	e9 cf 00 00 00       	jmp    f01014a1 <page_init+0x100>
		}else if (i >= 1 && i < npages_basemem){
f01013d2:	3b 1d e4 f1 17 f0    	cmp    0xf017f1e4,%ebx
f01013d8:	73 28                	jae    f0101402 <page_init+0x61>
			//The rest of base memory [PGSIZE, npages_basemen * PGSIZE]
			pages[i].pp_ref = 0;
f01013da:	89 f0                	mov    %esi,%eax
f01013dc:	03 05 ac fe 17 f0    	add    0xf017feac,%eax
f01013e2:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f01013e8:	8b 15 e0 f1 17 f0    	mov    0xf017f1e0,%edx
f01013ee:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f01013f0:	89 f0                	mov    %esi,%eax
f01013f2:	03 05 ac fe 17 f0    	add    0xf017feac,%eax
f01013f8:	a3 e0 f1 17 f0       	mov    %eax,0xf017f1e0
f01013fd:	e9 9f 00 00 00       	jmp    f01014a1 <page_init+0x100>
f0101402:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
		}else if (i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE){
f0101408:	83 f8 5f             	cmp    $0x5f,%eax
f010140b:	77 16                	ja     f0101423 <page_init+0x82>
			//The IO hole [IOPHYSMEM, EXTPHYSMEM)
			pages[i].pp_ref = 1;
f010140d:	89 f0                	mov    %esi,%eax
f010140f:	03 05 ac fe 17 f0    	add    0xf017feac,%eax
f0101415:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f010141b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101421:	eb 7e                	jmp    f01014a1 <page_init+0x100>
		}else if (i >= EXTPHYSMEM/PGSIZE && i < PADDR(boot_alloc(0))/PGSIZE){	//use PADDR() to change the kernel virtual addresss to physical address
f0101423:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0101429:	76 53                	jbe    f010147e <page_init+0xdd>
f010142b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101430:	e8 c6 fa ff ff       	call   f0100efb <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101435:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010143a:	77 20                	ja     f010145c <page_init+0xbb>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010143c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101440:	c7 44 24 08 64 62 10 	movl   $0xf0106264,0x8(%esp)
f0101447:	f0 
f0101448:	c7 44 24 04 2b 01 00 	movl   $0x12b,0x4(%esp)
f010144f:	00 
f0101450:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101457:	e8 5a ec ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010145c:	05 00 00 00 10       	add    $0x10000000,%eax
f0101461:	c1 e8 0c             	shr    $0xc,%eax
f0101464:	39 c3                	cmp    %eax,%ebx
f0101466:	73 16                	jae    f010147e <page_init+0xdd>
			//The extended memory [EXTPHYSMEM, ...)
			pages[i].pp_ref = 1;
f0101468:	89 f0                	mov    %esi,%eax
f010146a:	03 05 ac fe 17 f0    	add    0xf017feac,%eax
f0101470:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0101476:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f010147c:	eb 23                	jmp    f01014a1 <page_init+0x100>
		}else{
			pages[i].pp_ref = 0;
f010147e:	89 f0                	mov    %esi,%eax
f0101480:	03 05 ac fe 17 f0    	add    0xf017feac,%eax
f0101486:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f010148c:	8b 15 e0 f1 17 f0    	mov    0xf017f1e0,%edx
f0101492:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0101494:	89 f0                	mov    %esi,%eax
f0101496:	03 05 ac fe 17 f0    	add    0xf017feac,%eax
f010149c:	a3 e0 f1 17 f0       	mov    %eax,0xf017f1e0
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f01014a1:	83 c3 01             	add    $0x1,%ebx
f01014a4:	83 c6 08             	add    $0x8,%esi
f01014a7:	3b 1d a4 fe 17 f0    	cmp    0xf017fea4,%ebx
f01014ad:	0f 82 05 ff ff ff    	jb     f01013b8 <page_init+0x17>
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f01014b3:	83 c4 10             	add    $0x10,%esp
f01014b6:	5b                   	pop    %ebx
f01014b7:	5e                   	pop    %esi
f01014b8:	5d                   	pop    %ebp
f01014b9:	c3                   	ret    

f01014ba <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f01014ba:	55                   	push   %ebp
f01014bb:	89 e5                	mov    %esp,%ebp
f01014bd:	53                   	push   %ebx
f01014be:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	if (page_free_list == NULL)	//out of free memory
f01014c1:	8b 1d e0 f1 17 f0    	mov    0xf017f1e0,%ebx
f01014c7:	85 db                	test   %ebx,%ebx
f01014c9:	74 6f                	je     f010153a <page_alloc+0x80>
		return NULL;

	struct PageInfo *page = page_free_list;
	page_free_list = page_free_list->pp_link;
f01014cb:	8b 03                	mov    (%ebx),%eax
f01014cd:	a3 e0 f1 17 f0       	mov    %eax,0xf017f1e0
	page->pp_link = NULL;
f01014d2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO)
		memset(page2kva(page), '\0', PGSIZE);	//page2kva():get kernel virtual address by pageNum 
	return page;
f01014d8:	89 d8                	mov    %ebx,%eax
		return NULL;

	struct PageInfo *page = page_free_list;
	page_free_list = page_free_list->pp_link;
	page->pp_link = NULL;
	if (alloc_flags & ALLOC_ZERO)
f01014da:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f01014de:	74 5f                	je     f010153f <page_alloc+0x85>
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014e0:	2b 05 ac fe 17 f0    	sub    0xf017feac,%eax
f01014e6:	c1 f8 03             	sar    $0x3,%eax
f01014e9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014ec:	89 c2                	mov    %eax,%edx
f01014ee:	c1 ea 0c             	shr    $0xc,%edx
f01014f1:	3b 15 a4 fe 17 f0    	cmp    0xf017fea4,%edx
f01014f7:	72 20                	jb     f0101519 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014f9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01014fd:	c7 44 24 08 40 61 10 	movl   $0xf0106140,0x8(%esp)
f0101504:	f0 
f0101505:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f010150c:	00 
f010150d:	c7 04 24 71 69 10 f0 	movl   $0xf0106971,(%esp)
f0101514:	e8 9d eb ff ff       	call   f01000b6 <_panic>
		memset(page2kva(page), '\0', PGSIZE);	//page2kva():get kernel virtual address by pageNum 
f0101519:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101520:	00 
f0101521:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101528:	00 
	return (void *)(pa + KERNBASE);
f0101529:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010152e:	89 04 24             	mov    %eax,(%esp)
f0101531:	e8 71 3d 00 00       	call   f01052a7 <memset>
	return page;
f0101536:	89 d8                	mov    %ebx,%eax
f0101538:	eb 05                	jmp    f010153f <page_alloc+0x85>
struct PageInfo *
page_alloc(int alloc_flags)
{
	// Fill this function in
	if (page_free_list == NULL)	//out of free memory
		return NULL;
f010153a:	b8 00 00 00 00       	mov    $0x0,%eax
	page_free_list = page_free_list->pp_link;
	page->pp_link = NULL;
	if (alloc_flags & ALLOC_ZERO)
		memset(page2kva(page), '\0', PGSIZE);	//page2kva():get kernel virtual address by pageNum 
	return page;
}
f010153f:	83 c4 14             	add    $0x14,%esp
f0101542:	5b                   	pop    %ebx
f0101543:	5d                   	pop    %ebp
f0101544:	c3                   	ret    

f0101545 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101545:	55                   	push   %ebp
f0101546:	89 e5                	mov    %esp,%ebp
f0101548:	83 ec 18             	sub    $0x18,%esp
f010154b:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref  != 0 || pp->pp_link != NULL){
f010154e:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101553:	75 05                	jne    f010155a <page_free+0x15>
f0101555:	83 38 00             	cmpl   $0x0,(%eax)
f0101558:	74 1c                	je     f0101576 <page_free+0x31>
		panic("error(page_free):check before free a page\n");
f010155a:	c7 44 24 08 88 62 10 	movl   $0xf0106288,0x8(%esp)
f0101561:	f0 
f0101562:	c7 44 24 04 5d 01 00 	movl   $0x15d,0x4(%esp)
f0101569:	00 
f010156a:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101571:	e8 40 eb ff ff       	call   f01000b6 <_panic>
		return;
	}
	pp->pp_link = page_free_list;
f0101576:	8b 15 e0 f1 17 f0    	mov    0xf017f1e0,%edx
f010157c:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f010157e:	a3 e0 f1 17 f0       	mov    %eax,0xf017f1e0
	return;
}
f0101583:	c9                   	leave  
f0101584:	c3                   	ret    

f0101585 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101585:	55                   	push   %ebp
f0101586:	89 e5                	mov    %esp,%ebp
f0101588:	83 ec 18             	sub    $0x18,%esp
f010158b:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f010158e:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0101592:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0101595:	66 89 50 04          	mov    %dx,0x4(%eax)
f0101599:	66 85 d2             	test   %dx,%dx
f010159c:	75 08                	jne    f01015a6 <page_decref+0x21>
		page_free(pp);
f010159e:	89 04 24             	mov    %eax,(%esp)
f01015a1:	e8 9f ff ff ff       	call   f0101545 <page_free>
}
f01015a6:	c9                   	leave  
f01015a7:	c3                   	ret    

f01015a8 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01015a8:	55                   	push   %ebp
f01015a9:	89 e5                	mov    %esp,%ebp
f01015ab:	56                   	push   %esi
f01015ac:	53                   	push   %ebx
f01015ad:	83 ec 10             	sub    $0x10,%esp
f01015b0:	8b 45 0c             	mov    0xc(%ebp),%eax
	uint32_t page_dir_index = PDX(va);
	uint32_t page_table_index = PTX(va);
f01015b3:	89 c3                	mov    %eax,%ebx
f01015b5:	c1 eb 0c             	shr    $0xc,%ebx
f01015b8:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
	uint32_t page_dir_index = PDX(va);
f01015be:	c1 e8 16             	shr    $0x16,%eax
	uint32_t page_table_index = PTX(va);
	pte_t *page_tab;
	if (pgdir[page_dir_index] & PTE_P){		//test is exist or not
f01015c1:	8d 34 85 00 00 00 00 	lea    0x0(,%eax,4),%esi
f01015c8:	03 75 08             	add    0x8(%ebp),%esi
f01015cb:	8b 16                	mov    (%esi),%edx
f01015cd:	f6 c2 01             	test   $0x1,%dl
f01015d0:	74 3e                	je     f0101610 <pgdir_walk+0x68>
		page_tab = KADDR(PTE_ADDR(pgdir[page_dir_index]));
f01015d2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01015d8:	89 d0                	mov    %edx,%eax
f01015da:	c1 e8 0c             	shr    $0xc,%eax
f01015dd:	3b 05 a4 fe 17 f0    	cmp    0xf017fea4,%eax
f01015e3:	72 20                	jb     f0101605 <pgdir_walk+0x5d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01015e5:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01015e9:	c7 44 24 08 40 61 10 	movl   $0xf0106140,0x8(%esp)
f01015f0:	f0 
f01015f1:	c7 44 24 04 8d 01 00 	movl   $0x18d,0x4(%esp)
f01015f8:	00 
f01015f9:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101600:	e8 b1 ea ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0101605:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f010160b:	e9 8d 00 00 00       	jmp    f010169d <pgdir_walk+0xf5>
	}else{
		if (create){
f0101610:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101614:	0f 84 88 00 00 00    	je     f01016a2 <pgdir_walk+0xfa>
			struct PageInfo *newPage = page_alloc(ALLOC_ZERO);
f010161a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101621:	e8 94 fe ff ff       	call   f01014ba <page_alloc>
			if (!newPage)
f0101626:	85 c0                	test   %eax,%eax
f0101628:	74 7f                	je     f01016a9 <pgdir_walk+0x101>
				return NULL;
			newPage->pp_ref++;
f010162a:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010162f:	2b 05 ac fe 17 f0    	sub    0xf017feac,%eax
f0101635:	c1 f8 03             	sar    $0x3,%eax
f0101638:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010163b:	89 c2                	mov    %eax,%edx
f010163d:	c1 ea 0c             	shr    $0xc,%edx
f0101640:	3b 15 a4 fe 17 f0    	cmp    0xf017fea4,%edx
f0101646:	72 20                	jb     f0101668 <pgdir_walk+0xc0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101648:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010164c:	c7 44 24 08 40 61 10 	movl   $0xf0106140,0x8(%esp)
f0101653:	f0 
f0101654:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f010165b:	00 
f010165c:	c7 04 24 71 69 10 f0 	movl   $0xf0106971,(%esp)
f0101663:	e8 4e ea ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0101668:	8d 88 00 00 00 f0    	lea    -0x10000000(%eax),%ecx
f010166e:	89 ca                	mov    %ecx,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101670:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0101676:	77 20                	ja     f0101698 <pgdir_walk+0xf0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101678:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010167c:	c7 44 24 08 64 62 10 	movl   $0xf0106264,0x8(%esp)
f0101683:	f0 
f0101684:	c7 44 24 04 95 01 00 	movl   $0x195,0x4(%esp)
f010168b:	00 
f010168c:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101693:	e8 1e ea ff ff       	call   f01000b6 <_panic>
			page_tab = (pte_t *)page2kva(newPage);
			pgdir[page_dir_index] = PADDR(page_tab) | PTE_P | PTE_W | PTE_U;
f0101698:	83 c8 07             	or     $0x7,%eax
f010169b:	89 06                	mov    %eax,(%esi)
		}else{
			return NULL;
		}
	}
	return &page_tab[page_table_index];
f010169d:	8d 04 9a             	lea    (%edx,%ebx,4),%eax
f01016a0:	eb 0c                	jmp    f01016ae <pgdir_walk+0x106>
				return NULL;
			newPage->pp_ref++;
			page_tab = (pte_t *)page2kva(newPage);
			pgdir[page_dir_index] = PADDR(page_tab) | PTE_P | PTE_W | PTE_U;
		}else{
			return NULL;
f01016a2:	b8 00 00 00 00       	mov    $0x0,%eax
f01016a7:	eb 05                	jmp    f01016ae <pgdir_walk+0x106>
		page_tab = KADDR(PTE_ADDR(pgdir[page_dir_index]));
	}else{
		if (create){
			struct PageInfo *newPage = page_alloc(ALLOC_ZERO);
			if (!newPage)
				return NULL;
f01016a9:	b8 00 00 00 00       	mov    $0x0,%eax
		}else{
			return NULL;
		}
	}
	return &page_tab[page_table_index];
}
f01016ae:	83 c4 10             	add    $0x10,%esp
f01016b1:	5b                   	pop    %ebx
f01016b2:	5e                   	pop    %esi
f01016b3:	5d                   	pop    %ebp
f01016b4:	c3                   	ret    

f01016b5 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01016b5:	55                   	push   %ebp
f01016b6:	89 e5                	mov    %esp,%ebp
f01016b8:	57                   	push   %edi
f01016b9:	56                   	push   %esi
f01016ba:	53                   	push   %ebx
f01016bb:	83 ec 2c             	sub    $0x2c,%esp
f01016be:	89 c7                	mov    %eax,%edi
f01016c0:	8b 45 08             	mov    0x8(%ebp),%eax
	pte_t *page_tab;
	// use the code below, when va = 0xf0000000(kernelbase) and size = 0x10000000,
	// en_addr will overflow, so va > end_addr, will not run the code in while(){}
	// size_t end_addr = va + size;
	// insted, we can use page_num to avoid overflow
	size_t page_num = PGNUM(size);
f01016c3:	c1 e9 0c             	shr    $0xc,%ecx
f01016c6:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for(size_t i = 0; i < page_num; i++){
f01016c9:	89 c3                	mov    %eax,%ebx
f01016cb:	be 00 00 00 00       	mov    $0x0,%esi
f01016d0:	29 c2                	sub    %eax,%edx
f01016d2:	89 55 e0             	mov    %edx,-0x20(%ebp)
		// in this function, va's type is uintptr_t
		// when call pgdir_walk(), should change its type to void *
		page_tab = pgdir_walk(pgdir, (void *)va, 1);
		if (!page_tab)
			return;
		*page_tab = pa | perm | PTE_P;
f01016d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016d8:	83 c8 01             	or     $0x1,%eax
f01016db:	89 45 dc             	mov    %eax,-0x24(%ebp)
	// use the code below, when va = 0xf0000000(kernelbase) and size = 0x10000000,
	// en_addr will overflow, so va > end_addr, will not run the code in while(){}
	// size_t end_addr = va + size;
	// insted, we can use page_num to avoid overflow
	size_t page_num = PGNUM(size);
	for(size_t i = 0; i < page_num; i++){
f01016de:	eb 2d                	jmp    f010170d <boot_map_region+0x58>
		// in this function, va's type is uintptr_t
		// when call pgdir_walk(), should change its type to void *
		page_tab = pgdir_walk(pgdir, (void *)va, 1);
f01016e0:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01016e7:	00 
f01016e8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01016eb:	01 d8                	add    %ebx,%eax
f01016ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016f1:	89 3c 24             	mov    %edi,(%esp)
f01016f4:	e8 af fe ff ff       	call   f01015a8 <pgdir_walk>
		if (!page_tab)
f01016f9:	85 c0                	test   %eax,%eax
f01016fb:	74 15                	je     f0101712 <boot_map_region+0x5d>
			return;
		*page_tab = pa | perm | PTE_P;
f01016fd:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101700:	09 da                	or     %ebx,%edx
f0101702:	89 10                	mov    %edx,(%eax)
		pa += PGSIZE;
f0101704:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// use the code below, when va = 0xf0000000(kernelbase) and size = 0x10000000,
	// en_addr will overflow, so va > end_addr, will not run the code in while(){}
	// size_t end_addr = va + size;
	// insted, we can use page_num to avoid overflow
	size_t page_num = PGNUM(size);
	for(size_t i = 0; i < page_num; i++){
f010170a:	83 c6 01             	add    $0x1,%esi
f010170d:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0101710:	75 ce                	jne    f01016e0 <boot_map_region+0x2b>
			return;
		*page_tab = pa | perm | PTE_P;
		pa += PGSIZE;
		va += PGSIZE;
	}
}
f0101712:	83 c4 2c             	add    $0x2c,%esp
f0101715:	5b                   	pop    %ebx
f0101716:	5e                   	pop    %esi
f0101717:	5f                   	pop    %edi
f0101718:	5d                   	pop    %ebp
f0101719:	c3                   	ret    

f010171a <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010171a:	55                   	push   %ebp
f010171b:	89 e5                	mov    %esp,%ebp
f010171d:	53                   	push   %ebx
f010171e:	83 ec 14             	sub    $0x14,%esp
f0101721:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// search without create, so the third parameter is 0
	pte_t *page_tab = pgdir_walk(pgdir, va, 0);
f0101724:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010172b:	00 
f010172c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010172f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101733:	8b 45 08             	mov    0x8(%ebp),%eax
f0101736:	89 04 24             	mov    %eax,(%esp)
f0101739:	e8 6a fe ff ff       	call   f01015a8 <pgdir_walk>
	if (!page_tab)
f010173e:	85 c0                	test   %eax,%eax
f0101740:	74 3a                	je     f010177c <page_lookup+0x62>
		return NULL;	//fail to find
	if (pte_store){
f0101742:	85 db                	test   %ebx,%ebx
f0101744:	74 02                	je     f0101748 <page_lookup+0x2e>
		*pte_store = page_tab;
f0101746:	89 03                	mov    %eax,(%ebx)
	}
	return pa2page(PTE_ADDR(*page_tab));
f0101748:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010174a:	c1 e8 0c             	shr    $0xc,%eax
f010174d:	3b 05 a4 fe 17 f0    	cmp    0xf017fea4,%eax
f0101753:	72 1c                	jb     f0101771 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f0101755:	c7 44 24 08 b4 62 10 	movl   $0xf01062b4,0x8(%esp)
f010175c:	f0 
f010175d:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0101764:	00 
f0101765:	c7 04 24 71 69 10 f0 	movl   $0xf0106971,(%esp)
f010176c:	e8 45 e9 ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f0101771:	8b 15 ac fe 17 f0    	mov    0xf017feac,%edx
f0101777:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010177a:	eb 05                	jmp    f0101781 <page_lookup+0x67>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// search without create, so the third parameter is 0
	pte_t *page_tab = pgdir_walk(pgdir, va, 0);
	if (!page_tab)
		return NULL;	//fail to find
f010177c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store){
		*pte_store = page_tab;
	}
	return pa2page(PTE_ADDR(*page_tab));
}
f0101781:	83 c4 14             	add    $0x14,%esp
f0101784:	5b                   	pop    %ebx
f0101785:	5d                   	pop    %ebp
f0101786:	c3                   	ret    

f0101787 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101787:	55                   	push   %ebp
f0101788:	89 e5                	mov    %esp,%ebp
f010178a:	53                   	push   %ebx
f010178b:	83 ec 24             	sub    $0x24,%esp
f010178e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *page_tab;
	pte_t **pte_store = &page_tab;
	struct PageInfo *pageInfo = page_lookup(pgdir, va, pte_store);
f0101791:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101794:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101798:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010179c:	8b 45 08             	mov    0x8(%ebp),%eax
f010179f:	89 04 24             	mov    %eax,(%esp)
f01017a2:	e8 73 ff ff ff       	call   f010171a <page_lookup>
	if (!pageInfo){
f01017a7:	85 c0                	test   %eax,%eax
f01017a9:	74 14                	je     f01017bf <page_remove+0x38>
		return;
	}
	page_decref(pageInfo);
f01017ab:	89 04 24             	mov    %eax,(%esp)
f01017ae:	e8 d2 fd ff ff       	call   f0101585 <page_decref>
	*page_tab = 0;	//remove
f01017b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01017b6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01017bc:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);
}
f01017bf:	83 c4 24             	add    $0x24,%esp
f01017c2:	5b                   	pop    %ebx
f01017c3:	5d                   	pop    %ebp
f01017c4:	c3                   	ret    

f01017c5 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01017c5:	55                   	push   %ebp
f01017c6:	89 e5                	mov    %esp,%ebp
f01017c8:	57                   	push   %edi
f01017c9:	56                   	push   %esi
f01017ca:	53                   	push   %ebx
f01017cb:	83 ec 1c             	sub    $0x1c,%esp
f01017ce:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017d1:	8b 7d 10             	mov    0x10(%ebp),%edi
	// search with create, if not find, create page
	pte_t *page_tab = pgdir_walk(pgdir, va, 1);
f01017d4:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01017db:	00 
f01017dc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01017e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01017e3:	89 04 24             	mov    %eax,(%esp)
f01017e6:	e8 bd fd ff ff       	call   f01015a8 <pgdir_walk>
f01017eb:	89 c3                	mov    %eax,%ebx
	if (!page_tab)
f01017ed:	85 c0                	test   %eax,%eax
f01017ef:	74 39                	je     f010182a <page_insert+0x65>
		return -E_NO_MEM;	// lack of memory
	pp->pp_ref++;
f01017f1:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	if (*page_tab & PTE_P)	// test is exist or not
f01017f6:	f6 00 01             	testb  $0x1,(%eax)
f01017f9:	74 0f                	je     f010180a <page_insert+0x45>
		page_remove(pgdir, va);
f01017fb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01017ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0101802:	89 04 24             	mov    %eax,(%esp)
f0101805:	e8 7d ff ff ff       	call   f0101787 <page_remove>
	*page_tab = page2pa(pp) | perm | PTE_P;
f010180a:	8b 45 14             	mov    0x14(%ebp),%eax
f010180d:	83 c8 01             	or     $0x1,%eax
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101810:	2b 35 ac fe 17 f0    	sub    0xf017feac,%esi
f0101816:	c1 fe 03             	sar    $0x3,%esi
f0101819:	c1 e6 0c             	shl    $0xc,%esi
f010181c:	09 c6                	or     %eax,%esi
f010181e:	89 33                	mov    %esi,(%ebx)
f0101820:	0f 01 3f             	invlpg (%edi)
	tlb_invalidate(pgdir, va);
	return 0;
f0101823:	b8 00 00 00 00       	mov    $0x0,%eax
f0101828:	eb 05                	jmp    f010182f <page_insert+0x6a>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// search with create, if not find, create page
	pte_t *page_tab = pgdir_walk(pgdir, va, 1);
	if (!page_tab)
		return -E_NO_MEM;	// lack of memory
f010182a:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	if (*page_tab & PTE_P)	// test is exist or not
		page_remove(pgdir, va);
	*page_tab = page2pa(pp) | perm | PTE_P;
	tlb_invalidate(pgdir, va);
	return 0;
}
f010182f:	83 c4 1c             	add    $0x1c,%esp
f0101832:	5b                   	pop    %ebx
f0101833:	5e                   	pop    %esi
f0101834:	5f                   	pop    %edi
f0101835:	5d                   	pop    %ebp
f0101836:	c3                   	ret    

f0101837 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101837:	55                   	push   %ebp
f0101838:	89 e5                	mov    %esp,%ebp
f010183a:	57                   	push   %edi
f010183b:	56                   	push   %esi
f010183c:	53                   	push   %ebx
f010183d:	83 ec 4c             	sub    $0x4c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101840:	b8 15 00 00 00       	mov    $0x15,%eax
f0101845:	e8 86 f6 ff ff       	call   f0100ed0 <nvram_read>
f010184a:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010184c:	b8 17 00 00 00       	mov    $0x17,%eax
f0101851:	e8 7a f6 ff ff       	call   f0100ed0 <nvram_read>
f0101856:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101858:	b8 34 00 00 00       	mov    $0x34,%eax
f010185d:	e8 6e f6 ff ff       	call   f0100ed0 <nvram_read>
f0101862:	c1 e0 06             	shl    $0x6,%eax
f0101865:	89 c2                	mov    %eax,%edx

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
		totalmem = 16 * 1024 + ext16mem;
f0101867:	8d 80 00 40 00 00    	lea    0x4000(%eax),%eax
	extmem = nvram_read(NVRAM_EXTLO);
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f010186d:	85 d2                	test   %edx,%edx
f010186f:	75 0b                	jne    f010187c <mem_init+0x45>
		totalmem = 16 * 1024 + ext16mem;
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0101871:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101877:	85 f6                	test   %esi,%esi
f0101879:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f010187c:	89 c2                	mov    %eax,%edx
f010187e:	c1 ea 02             	shr    $0x2,%edx
f0101881:	89 15 a4 fe 17 f0    	mov    %edx,0xf017fea4
	npages_basemem = basemem / (PGSIZE / 1024);
f0101887:	89 da                	mov    %ebx,%edx
f0101889:	c1 ea 02             	shr    $0x2,%edx
f010188c:	89 15 e4 f1 17 f0    	mov    %edx,0xf017f1e4

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101892:	89 c2                	mov    %eax,%edx
f0101894:	29 da                	sub    %ebx,%edx
f0101896:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010189a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010189e:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018a2:	c7 04 24 d4 62 10 f0 	movl   $0xf01062d4,(%esp)
f01018a9:	e8 b5 24 00 00       	call   f0103d63 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01018ae:	b8 00 10 00 00       	mov    $0x1000,%eax
f01018b3:	e8 43 f6 ff ff       	call   f0100efb <boot_alloc>
f01018b8:	a3 a8 fe 17 f0       	mov    %eax,0xf017fea8
	memset(kern_pgdir, 0, PGSIZE);
f01018bd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01018c4:	00 
f01018c5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01018cc:	00 
f01018cd:	89 04 24             	mov    %eax,(%esp)
f01018d0:	e8 d2 39 00 00       	call   f01052a7 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01018d5:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01018da:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01018df:	77 20                	ja     f0101901 <mem_init+0xca>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01018e1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01018e5:	c7 44 24 08 64 62 10 	movl   $0xf0106264,0x8(%esp)
f01018ec:	f0 
f01018ed:	c7 44 24 04 99 00 00 	movl   $0x99,0x4(%esp)
f01018f4:	00 
f01018f5:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01018fc:	e8 b5 e7 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101901:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101907:	83 ca 05             	or     $0x5,%edx
f010190a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(sizeof(struct PageInfo) * npages);
f0101910:	a1 a4 fe 17 f0       	mov    0xf017fea4,%eax
f0101915:	c1 e0 03             	shl    $0x3,%eax
f0101918:	e8 de f5 ff ff       	call   f0100efb <boot_alloc>
f010191d:	a3 ac fe 17 f0       	mov    %eax,0xf017feac
	memset(pages, 0, sizeof(struct PageInfo) * npages);
f0101922:	8b 0d a4 fe 17 f0    	mov    0xf017fea4,%ecx
f0101928:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f010192f:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101933:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010193a:	00 
f010193b:	89 04 24             	mov    %eax,(%esp)
f010193e:	e8 64 39 00 00       	call   f01052a7 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *) boot_alloc(sizeof(struct Env) * NENV);
f0101943:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101948:	e8 ae f5 ff ff       	call   f0100efb <boot_alloc>
f010194d:	a3 ec f1 17 f0       	mov    %eax,0xf017f1ec
	memset(envs, 0, sizeof(struct Env) * NENV);
f0101952:	c7 44 24 08 00 80 01 	movl   $0x18000,0x8(%esp)
f0101959:	00 
f010195a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101961:	00 
f0101962:	89 04 24             	mov    %eax,(%esp)
f0101965:	e8 3d 39 00 00       	call   f01052a7 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010196a:	e8 32 fa ff ff       	call   f01013a1 <page_init>

	check_page_free_list(1);
f010196f:	b8 01 00 00 00       	mov    $0x1,%eax
f0101974:	e8 df f6 ff ff       	call   f0101058 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101979:	83 3d ac fe 17 f0 00 	cmpl   $0x0,0xf017feac
f0101980:	75 1c                	jne    f010199e <mem_init+0x167>
		panic("'pages' is a null pointer!");
f0101982:	c7 44 24 08 1b 6a 10 	movl   $0xf0106a1b,0x8(%esp)
f0101989:	f0 
f010198a:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
f0101991:	00 
f0101992:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101999:	e8 18 e7 ff ff       	call   f01000b6 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010199e:	a1 e0 f1 17 f0       	mov    0xf017f1e0,%eax
f01019a3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01019a8:	eb 05                	jmp    f01019af <mem_init+0x178>
		++nfree;
f01019aa:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01019ad:	8b 00                	mov    (%eax),%eax
f01019af:	85 c0                	test   %eax,%eax
f01019b1:	75 f7                	jne    f01019aa <mem_init+0x173>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01019b3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019ba:	e8 fb fa ff ff       	call   f01014ba <page_alloc>
f01019bf:	89 c7                	mov    %eax,%edi
f01019c1:	85 c0                	test   %eax,%eax
f01019c3:	75 24                	jne    f01019e9 <mem_init+0x1b2>
f01019c5:	c7 44 24 0c 36 6a 10 	movl   $0xf0106a36,0xc(%esp)
f01019cc:	f0 
f01019cd:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01019d4:	f0 
f01019d5:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f01019dc:	00 
f01019dd:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01019e4:	e8 cd e6 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f01019e9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019f0:	e8 c5 fa ff ff       	call   f01014ba <page_alloc>
f01019f5:	89 c6                	mov    %eax,%esi
f01019f7:	85 c0                	test   %eax,%eax
f01019f9:	75 24                	jne    f0101a1f <mem_init+0x1e8>
f01019fb:	c7 44 24 0c 4c 6a 10 	movl   $0xf0106a4c,0xc(%esp)
f0101a02:	f0 
f0101a03:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101a0a:	f0 
f0101a0b:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
f0101a12:	00 
f0101a13:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101a1a:	e8 97 e6 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101a1f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a26:	e8 8f fa ff ff       	call   f01014ba <page_alloc>
f0101a2b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101a2e:	85 c0                	test   %eax,%eax
f0101a30:	75 24                	jne    f0101a56 <mem_init+0x21f>
f0101a32:	c7 44 24 0c 62 6a 10 	movl   $0xf0106a62,0xc(%esp)
f0101a39:	f0 
f0101a3a:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101a41:	f0 
f0101a42:	c7 44 24 04 bd 02 00 	movl   $0x2bd,0x4(%esp)
f0101a49:	00 
f0101a4a:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101a51:	e8 60 e6 ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a56:	39 f7                	cmp    %esi,%edi
f0101a58:	75 24                	jne    f0101a7e <mem_init+0x247>
f0101a5a:	c7 44 24 0c 78 6a 10 	movl   $0xf0106a78,0xc(%esp)
f0101a61:	f0 
f0101a62:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101a69:	f0 
f0101a6a:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f0101a71:	00 
f0101a72:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101a79:	e8 38 e6 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a7e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a81:	39 c6                	cmp    %eax,%esi
f0101a83:	74 04                	je     f0101a89 <mem_init+0x252>
f0101a85:	39 c7                	cmp    %eax,%edi
f0101a87:	75 24                	jne    f0101aad <mem_init+0x276>
f0101a89:	c7 44 24 0c 10 63 10 	movl   $0xf0106310,0xc(%esp)
f0101a90:	f0 
f0101a91:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101a98:	f0 
f0101a99:	c7 44 24 04 c1 02 00 	movl   $0x2c1,0x4(%esp)
f0101aa0:	00 
f0101aa1:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101aa8:	e8 09 e6 ff ff       	call   f01000b6 <_panic>
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101aad:	8b 15 ac fe 17 f0    	mov    0xf017feac,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101ab3:	a1 a4 fe 17 f0       	mov    0xf017fea4,%eax
f0101ab8:	c1 e0 0c             	shl    $0xc,%eax
f0101abb:	89 f9                	mov    %edi,%ecx
f0101abd:	29 d1                	sub    %edx,%ecx
f0101abf:	c1 f9 03             	sar    $0x3,%ecx
f0101ac2:	c1 e1 0c             	shl    $0xc,%ecx
f0101ac5:	39 c1                	cmp    %eax,%ecx
f0101ac7:	72 24                	jb     f0101aed <mem_init+0x2b6>
f0101ac9:	c7 44 24 0c 8a 6a 10 	movl   $0xf0106a8a,0xc(%esp)
f0101ad0:	f0 
f0101ad1:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101ad8:	f0 
f0101ad9:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
f0101ae0:	00 
f0101ae1:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101ae8:	e8 c9 e5 ff ff       	call   f01000b6 <_panic>
f0101aed:	89 f1                	mov    %esi,%ecx
f0101aef:	29 d1                	sub    %edx,%ecx
f0101af1:	c1 f9 03             	sar    $0x3,%ecx
f0101af4:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101af7:	39 c8                	cmp    %ecx,%eax
f0101af9:	77 24                	ja     f0101b1f <mem_init+0x2e8>
f0101afb:	c7 44 24 0c a7 6a 10 	movl   $0xf0106aa7,0xc(%esp)
f0101b02:	f0 
f0101b03:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101b0a:	f0 
f0101b0b:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f0101b12:	00 
f0101b13:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101b1a:	e8 97 e5 ff ff       	call   f01000b6 <_panic>
f0101b1f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101b22:	29 d1                	sub    %edx,%ecx
f0101b24:	89 ca                	mov    %ecx,%edx
f0101b26:	c1 fa 03             	sar    $0x3,%edx
f0101b29:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101b2c:	39 d0                	cmp    %edx,%eax
f0101b2e:	77 24                	ja     f0101b54 <mem_init+0x31d>
f0101b30:	c7 44 24 0c c4 6a 10 	movl   $0xf0106ac4,0xc(%esp)
f0101b37:	f0 
f0101b38:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101b3f:	f0 
f0101b40:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
f0101b47:	00 
f0101b48:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101b4f:	e8 62 e5 ff ff       	call   f01000b6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101b54:	a1 e0 f1 17 f0       	mov    0xf017f1e0,%eax
f0101b59:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101b5c:	c7 05 e0 f1 17 f0 00 	movl   $0x0,0xf017f1e0
f0101b63:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101b66:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b6d:	e8 48 f9 ff ff       	call   f01014ba <page_alloc>
f0101b72:	85 c0                	test   %eax,%eax
f0101b74:	74 24                	je     f0101b9a <mem_init+0x363>
f0101b76:	c7 44 24 0c e1 6a 10 	movl   $0xf0106ae1,0xc(%esp)
f0101b7d:	f0 
f0101b7e:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101b85:	f0 
f0101b86:	c7 44 24 04 cb 02 00 	movl   $0x2cb,0x4(%esp)
f0101b8d:	00 
f0101b8e:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101b95:	e8 1c e5 ff ff       	call   f01000b6 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101b9a:	89 3c 24             	mov    %edi,(%esp)
f0101b9d:	e8 a3 f9 ff ff       	call   f0101545 <page_free>
	page_free(pp1);
f0101ba2:	89 34 24             	mov    %esi,(%esp)
f0101ba5:	e8 9b f9 ff ff       	call   f0101545 <page_free>
	page_free(pp2);
f0101baa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bad:	89 04 24             	mov    %eax,(%esp)
f0101bb0:	e8 90 f9 ff ff       	call   f0101545 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101bb5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bbc:	e8 f9 f8 ff ff       	call   f01014ba <page_alloc>
f0101bc1:	89 c6                	mov    %eax,%esi
f0101bc3:	85 c0                	test   %eax,%eax
f0101bc5:	75 24                	jne    f0101beb <mem_init+0x3b4>
f0101bc7:	c7 44 24 0c 36 6a 10 	movl   $0xf0106a36,0xc(%esp)
f0101bce:	f0 
f0101bcf:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101bd6:	f0 
f0101bd7:	c7 44 24 04 d2 02 00 	movl   $0x2d2,0x4(%esp)
f0101bde:	00 
f0101bdf:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101be6:	e8 cb e4 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101beb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bf2:	e8 c3 f8 ff ff       	call   f01014ba <page_alloc>
f0101bf7:	89 c7                	mov    %eax,%edi
f0101bf9:	85 c0                	test   %eax,%eax
f0101bfb:	75 24                	jne    f0101c21 <mem_init+0x3ea>
f0101bfd:	c7 44 24 0c 4c 6a 10 	movl   $0xf0106a4c,0xc(%esp)
f0101c04:	f0 
f0101c05:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101c0c:	f0 
f0101c0d:	c7 44 24 04 d3 02 00 	movl   $0x2d3,0x4(%esp)
f0101c14:	00 
f0101c15:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101c1c:	e8 95 e4 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101c21:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c28:	e8 8d f8 ff ff       	call   f01014ba <page_alloc>
f0101c2d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101c30:	85 c0                	test   %eax,%eax
f0101c32:	75 24                	jne    f0101c58 <mem_init+0x421>
f0101c34:	c7 44 24 0c 62 6a 10 	movl   $0xf0106a62,0xc(%esp)
f0101c3b:	f0 
f0101c3c:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101c43:	f0 
f0101c44:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
f0101c4b:	00 
f0101c4c:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101c53:	e8 5e e4 ff ff       	call   f01000b6 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101c58:	39 fe                	cmp    %edi,%esi
f0101c5a:	75 24                	jne    f0101c80 <mem_init+0x449>
f0101c5c:	c7 44 24 0c 78 6a 10 	movl   $0xf0106a78,0xc(%esp)
f0101c63:	f0 
f0101c64:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101c6b:	f0 
f0101c6c:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
f0101c73:	00 
f0101c74:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101c7b:	e8 36 e4 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101c80:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c83:	39 c7                	cmp    %eax,%edi
f0101c85:	74 04                	je     f0101c8b <mem_init+0x454>
f0101c87:	39 c6                	cmp    %eax,%esi
f0101c89:	75 24                	jne    f0101caf <mem_init+0x478>
f0101c8b:	c7 44 24 0c 10 63 10 	movl   $0xf0106310,0xc(%esp)
f0101c92:	f0 
f0101c93:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101c9a:	f0 
f0101c9b:	c7 44 24 04 d7 02 00 	movl   $0x2d7,0x4(%esp)
f0101ca2:	00 
f0101ca3:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101caa:	e8 07 e4 ff ff       	call   f01000b6 <_panic>
	assert(!page_alloc(0));
f0101caf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cb6:	e8 ff f7 ff ff       	call   f01014ba <page_alloc>
f0101cbb:	85 c0                	test   %eax,%eax
f0101cbd:	74 24                	je     f0101ce3 <mem_init+0x4ac>
f0101cbf:	c7 44 24 0c e1 6a 10 	movl   $0xf0106ae1,0xc(%esp)
f0101cc6:	f0 
f0101cc7:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101cce:	f0 
f0101ccf:	c7 44 24 04 d8 02 00 	movl   $0x2d8,0x4(%esp)
f0101cd6:	00 
f0101cd7:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101cde:	e8 d3 e3 ff ff       	call   f01000b6 <_panic>
f0101ce3:	89 f0                	mov    %esi,%eax
f0101ce5:	2b 05 ac fe 17 f0    	sub    0xf017feac,%eax
f0101ceb:	c1 f8 03             	sar    $0x3,%eax
f0101cee:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101cf1:	89 c2                	mov    %eax,%edx
f0101cf3:	c1 ea 0c             	shr    $0xc,%edx
f0101cf6:	3b 15 a4 fe 17 f0    	cmp    0xf017fea4,%edx
f0101cfc:	72 20                	jb     f0101d1e <mem_init+0x4e7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101cfe:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d02:	c7 44 24 08 40 61 10 	movl   $0xf0106140,0x8(%esp)
f0101d09:	f0 
f0101d0a:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f0101d11:	00 
f0101d12:	c7 04 24 71 69 10 f0 	movl   $0xf0106971,(%esp)
f0101d19:	e8 98 e3 ff ff       	call   f01000b6 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101d1e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d25:	00 
f0101d26:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101d2d:	00 
	return (void *)(pa + KERNBASE);
f0101d2e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d33:	89 04 24             	mov    %eax,(%esp)
f0101d36:	e8 6c 35 00 00       	call   f01052a7 <memset>
	page_free(pp0);
f0101d3b:	89 34 24             	mov    %esi,(%esp)
f0101d3e:	e8 02 f8 ff ff       	call   f0101545 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101d43:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101d4a:	e8 6b f7 ff ff       	call   f01014ba <page_alloc>
f0101d4f:	85 c0                	test   %eax,%eax
f0101d51:	75 24                	jne    f0101d77 <mem_init+0x540>
f0101d53:	c7 44 24 0c f0 6a 10 	movl   $0xf0106af0,0xc(%esp)
f0101d5a:	f0 
f0101d5b:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101d62:	f0 
f0101d63:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
f0101d6a:	00 
f0101d6b:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101d72:	e8 3f e3 ff ff       	call   f01000b6 <_panic>
	assert(pp && pp0 == pp);
f0101d77:	39 c6                	cmp    %eax,%esi
f0101d79:	74 24                	je     f0101d9f <mem_init+0x568>
f0101d7b:	c7 44 24 0c 0e 6b 10 	movl   $0xf0106b0e,0xc(%esp)
f0101d82:	f0 
f0101d83:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101d8a:	f0 
f0101d8b:	c7 44 24 04 de 02 00 	movl   $0x2de,0x4(%esp)
f0101d92:	00 
f0101d93:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101d9a:	e8 17 e3 ff ff       	call   f01000b6 <_panic>
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101d9f:	89 f0                	mov    %esi,%eax
f0101da1:	2b 05 ac fe 17 f0    	sub    0xf017feac,%eax
f0101da7:	c1 f8 03             	sar    $0x3,%eax
f0101daa:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101dad:	89 c2                	mov    %eax,%edx
f0101daf:	c1 ea 0c             	shr    $0xc,%edx
f0101db2:	3b 15 a4 fe 17 f0    	cmp    0xf017fea4,%edx
f0101db8:	72 20                	jb     f0101dda <mem_init+0x5a3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101dba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101dbe:	c7 44 24 08 40 61 10 	movl   $0xf0106140,0x8(%esp)
f0101dc5:	f0 
f0101dc6:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f0101dcd:	00 
f0101dce:	c7 04 24 71 69 10 f0 	movl   $0xf0106971,(%esp)
f0101dd5:	e8 dc e2 ff ff       	call   f01000b6 <_panic>
f0101dda:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101de0:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101de6:	80 38 00             	cmpb   $0x0,(%eax)
f0101de9:	74 24                	je     f0101e0f <mem_init+0x5d8>
f0101deb:	c7 44 24 0c 1e 6b 10 	movl   $0xf0106b1e,0xc(%esp)
f0101df2:	f0 
f0101df3:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101dfa:	f0 
f0101dfb:	c7 44 24 04 e1 02 00 	movl   $0x2e1,0x4(%esp)
f0101e02:	00 
f0101e03:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101e0a:	e8 a7 e2 ff ff       	call   f01000b6 <_panic>
f0101e0f:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101e12:	39 d0                	cmp    %edx,%eax
f0101e14:	75 d0                	jne    f0101de6 <mem_init+0x5af>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101e16:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e19:	a3 e0 f1 17 f0       	mov    %eax,0xf017f1e0

	// free the pages we took
	page_free(pp0);
f0101e1e:	89 34 24             	mov    %esi,(%esp)
f0101e21:	e8 1f f7 ff ff       	call   f0101545 <page_free>
	page_free(pp1);
f0101e26:	89 3c 24             	mov    %edi,(%esp)
f0101e29:	e8 17 f7 ff ff       	call   f0101545 <page_free>
	page_free(pp2);
f0101e2e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e31:	89 04 24             	mov    %eax,(%esp)
f0101e34:	e8 0c f7 ff ff       	call   f0101545 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101e39:	a1 e0 f1 17 f0       	mov    0xf017f1e0,%eax
f0101e3e:	eb 05                	jmp    f0101e45 <mem_init+0x60e>
		--nfree;
f0101e40:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101e43:	8b 00                	mov    (%eax),%eax
f0101e45:	85 c0                	test   %eax,%eax
f0101e47:	75 f7                	jne    f0101e40 <mem_init+0x609>
		--nfree;
	assert(nfree == 0);
f0101e49:	85 db                	test   %ebx,%ebx
f0101e4b:	74 24                	je     f0101e71 <mem_init+0x63a>
f0101e4d:	c7 44 24 0c 28 6b 10 	movl   $0xf0106b28,0xc(%esp)
f0101e54:	f0 
f0101e55:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101e5c:	f0 
f0101e5d:	c7 44 24 04 ee 02 00 	movl   $0x2ee,0x4(%esp)
f0101e64:	00 
f0101e65:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101e6c:	e8 45 e2 ff ff       	call   f01000b6 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101e71:	c7 04 24 30 63 10 f0 	movl   $0xf0106330,(%esp)
f0101e78:	e8 e6 1e 00 00       	call   f0103d63 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101e7d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e84:	e8 31 f6 ff ff       	call   f01014ba <page_alloc>
f0101e89:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101e8c:	85 c0                	test   %eax,%eax
f0101e8e:	75 24                	jne    f0101eb4 <mem_init+0x67d>
f0101e90:	c7 44 24 0c 36 6a 10 	movl   $0xf0106a36,0xc(%esp)
f0101e97:	f0 
f0101e98:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101e9f:	f0 
f0101ea0:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0101ea7:	00 
f0101ea8:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101eaf:	e8 02 e2 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101eb4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ebb:	e8 fa f5 ff ff       	call   f01014ba <page_alloc>
f0101ec0:	89 c3                	mov    %eax,%ebx
f0101ec2:	85 c0                	test   %eax,%eax
f0101ec4:	75 24                	jne    f0101eea <mem_init+0x6b3>
f0101ec6:	c7 44 24 0c 4c 6a 10 	movl   $0xf0106a4c,0xc(%esp)
f0101ecd:	f0 
f0101ece:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101ed5:	f0 
f0101ed6:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0101edd:	00 
f0101ede:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101ee5:	e8 cc e1 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101eea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ef1:	e8 c4 f5 ff ff       	call   f01014ba <page_alloc>
f0101ef6:	89 c6                	mov    %eax,%esi
f0101ef8:	85 c0                	test   %eax,%eax
f0101efa:	75 24                	jne    f0101f20 <mem_init+0x6e9>
f0101efc:	c7 44 24 0c 62 6a 10 	movl   $0xf0106a62,0xc(%esp)
f0101f03:	f0 
f0101f04:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101f0b:	f0 
f0101f0c:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0101f13:	00 
f0101f14:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101f1b:	e8 96 e1 ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101f20:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101f23:	75 24                	jne    f0101f49 <mem_init+0x712>
f0101f25:	c7 44 24 0c 78 6a 10 	movl   $0xf0106a78,0xc(%esp)
f0101f2c:	f0 
f0101f2d:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101f34:	f0 
f0101f35:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0101f3c:	00 
f0101f3d:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101f44:	e8 6d e1 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101f49:	39 c3                	cmp    %eax,%ebx
f0101f4b:	74 05                	je     f0101f52 <mem_init+0x71b>
f0101f4d:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101f50:	75 24                	jne    f0101f76 <mem_init+0x73f>
f0101f52:	c7 44 24 0c 10 63 10 	movl   $0xf0106310,0xc(%esp)
f0101f59:	f0 
f0101f5a:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101f61:	f0 
f0101f62:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f0101f69:	00 
f0101f6a:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101f71:	e8 40 e1 ff ff       	call   f01000b6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101f76:	a1 e0 f1 17 f0       	mov    0xf017f1e0,%eax
f0101f7b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101f7e:	c7 05 e0 f1 17 f0 00 	movl   $0x0,0xf017f1e0
f0101f85:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101f88:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f8f:	e8 26 f5 ff ff       	call   f01014ba <page_alloc>
f0101f94:	85 c0                	test   %eax,%eax
f0101f96:	74 24                	je     f0101fbc <mem_init+0x785>
f0101f98:	c7 44 24 0c e1 6a 10 	movl   $0xf0106ae1,0xc(%esp)
f0101f9f:	f0 
f0101fa0:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101fa7:	f0 
f0101fa8:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f0101faf:	00 
f0101fb0:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101fb7:	e8 fa e0 ff ff       	call   f01000b6 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101fbc:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101fbf:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101fc3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101fca:	00 
f0101fcb:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0101fd0:	89 04 24             	mov    %eax,(%esp)
f0101fd3:	e8 42 f7 ff ff       	call   f010171a <page_lookup>
f0101fd8:	85 c0                	test   %eax,%eax
f0101fda:	74 24                	je     f0102000 <mem_init+0x7c9>
f0101fdc:	c7 44 24 0c 50 63 10 	movl   $0xf0106350,0xc(%esp)
f0101fe3:	f0 
f0101fe4:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0101feb:	f0 
f0101fec:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f0101ff3:	00 
f0101ff4:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0101ffb:	e8 b6 e0 ff ff       	call   f01000b6 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102000:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102007:	00 
f0102008:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010200f:	00 
f0102010:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102014:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0102019:	89 04 24             	mov    %eax,(%esp)
f010201c:	e8 a4 f7 ff ff       	call   f01017c5 <page_insert>
f0102021:	85 c0                	test   %eax,%eax
f0102023:	78 24                	js     f0102049 <mem_init+0x812>
f0102025:	c7 44 24 0c 88 63 10 	movl   $0xf0106388,0xc(%esp)
f010202c:	f0 
f010202d:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102034:	f0 
f0102035:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f010203c:	00 
f010203d:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102044:	e8 6d e0 ff ff       	call   f01000b6 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0102049:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010204c:	89 04 24             	mov    %eax,(%esp)
f010204f:	e8 f1 f4 ff ff       	call   f0101545 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102054:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010205b:	00 
f010205c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102063:	00 
f0102064:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102068:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f010206d:	89 04 24             	mov    %eax,(%esp)
f0102070:	e8 50 f7 ff ff       	call   f01017c5 <page_insert>
f0102075:	85 c0                	test   %eax,%eax
f0102077:	74 24                	je     f010209d <mem_init+0x866>
f0102079:	c7 44 24 0c b8 63 10 	movl   $0xf01063b8,0xc(%esp)
f0102080:	f0 
f0102081:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102088:	f0 
f0102089:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f0102090:	00 
f0102091:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102098:	e8 19 e0 ff ff       	call   f01000b6 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010209d:	8b 3d a8 fe 17 f0    	mov    0xf017fea8,%edi
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01020a3:	a1 ac fe 17 f0       	mov    0xf017feac,%eax
f01020a8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01020ab:	8b 17                	mov    (%edi),%edx
f01020ad:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01020b3:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01020b6:	29 c1                	sub    %eax,%ecx
f01020b8:	89 c8                	mov    %ecx,%eax
f01020ba:	c1 f8 03             	sar    $0x3,%eax
f01020bd:	c1 e0 0c             	shl    $0xc,%eax
f01020c0:	39 c2                	cmp    %eax,%edx
f01020c2:	74 24                	je     f01020e8 <mem_init+0x8b1>
f01020c4:	c7 44 24 0c e8 63 10 	movl   $0xf01063e8,0xc(%esp)
f01020cb:	f0 
f01020cc:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01020d3:	f0 
f01020d4:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f01020db:	00 
f01020dc:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01020e3:	e8 ce df ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01020e8:	ba 00 00 00 00       	mov    $0x0,%edx
f01020ed:	89 f8                	mov    %edi,%eax
f01020ef:	e8 f5 ee ff ff       	call   f0100fe9 <check_va2pa>
f01020f4:	89 da                	mov    %ebx,%edx
f01020f6:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01020f9:	c1 fa 03             	sar    $0x3,%edx
f01020fc:	c1 e2 0c             	shl    $0xc,%edx
f01020ff:	39 d0                	cmp    %edx,%eax
f0102101:	74 24                	je     f0102127 <mem_init+0x8f0>
f0102103:	c7 44 24 0c 10 64 10 	movl   $0xf0106410,0xc(%esp)
f010210a:	f0 
f010210b:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102112:	f0 
f0102113:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f010211a:	00 
f010211b:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102122:	e8 8f df ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f0102127:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010212c:	74 24                	je     f0102152 <mem_init+0x91b>
f010212e:	c7 44 24 0c 33 6b 10 	movl   $0xf0106b33,0xc(%esp)
f0102135:	f0 
f0102136:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010213d:	f0 
f010213e:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0102145:	00 
f0102146:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010214d:	e8 64 df ff ff       	call   f01000b6 <_panic>
	assert(pp0->pp_ref == 1);
f0102152:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102155:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010215a:	74 24                	je     f0102180 <mem_init+0x949>
f010215c:	c7 44 24 0c 44 6b 10 	movl   $0xf0106b44,0xc(%esp)
f0102163:	f0 
f0102164:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010216b:	f0 
f010216c:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0102173:	00 
f0102174:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010217b:	e8 36 df ff ff       	call   f01000b6 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102180:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102187:	00 
f0102188:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010218f:	00 
f0102190:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102194:	89 3c 24             	mov    %edi,(%esp)
f0102197:	e8 29 f6 ff ff       	call   f01017c5 <page_insert>
f010219c:	85 c0                	test   %eax,%eax
f010219e:	74 24                	je     f01021c4 <mem_init+0x98d>
f01021a0:	c7 44 24 0c 40 64 10 	movl   $0xf0106440,0xc(%esp)
f01021a7:	f0 
f01021a8:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01021af:	f0 
f01021b0:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f01021b7:	00 
f01021b8:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01021bf:	e8 f2 de ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01021c4:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021c9:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f01021ce:	e8 16 ee ff ff       	call   f0100fe9 <check_va2pa>
f01021d3:	89 f2                	mov    %esi,%edx
f01021d5:	2b 15 ac fe 17 f0    	sub    0xf017feac,%edx
f01021db:	c1 fa 03             	sar    $0x3,%edx
f01021de:	c1 e2 0c             	shl    $0xc,%edx
f01021e1:	39 d0                	cmp    %edx,%eax
f01021e3:	74 24                	je     f0102209 <mem_init+0x9d2>
f01021e5:	c7 44 24 0c 7c 64 10 	movl   $0xf010647c,0xc(%esp)
f01021ec:	f0 
f01021ed:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01021f4:	f0 
f01021f5:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f01021fc:	00 
f01021fd:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102204:	e8 ad de ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0102209:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010220e:	74 24                	je     f0102234 <mem_init+0x9fd>
f0102210:	c7 44 24 0c 55 6b 10 	movl   $0xf0106b55,0xc(%esp)
f0102217:	f0 
f0102218:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010221f:	f0 
f0102220:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f0102227:	00 
f0102228:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010222f:	e8 82 de ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102234:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010223b:	e8 7a f2 ff ff       	call   f01014ba <page_alloc>
f0102240:	85 c0                	test   %eax,%eax
f0102242:	74 24                	je     f0102268 <mem_init+0xa31>
f0102244:	c7 44 24 0c e1 6a 10 	movl   $0xf0106ae1,0xc(%esp)
f010224b:	f0 
f010224c:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102253:	f0 
f0102254:	c7 44 24 04 6f 03 00 	movl   $0x36f,0x4(%esp)
f010225b:	00 
f010225c:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102263:	e8 4e de ff ff       	call   f01000b6 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102268:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010226f:	00 
f0102270:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102277:	00 
f0102278:	89 74 24 04          	mov    %esi,0x4(%esp)
f010227c:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0102281:	89 04 24             	mov    %eax,(%esp)
f0102284:	e8 3c f5 ff ff       	call   f01017c5 <page_insert>
f0102289:	85 c0                	test   %eax,%eax
f010228b:	74 24                	je     f01022b1 <mem_init+0xa7a>
f010228d:	c7 44 24 0c 40 64 10 	movl   $0xf0106440,0xc(%esp)
f0102294:	f0 
f0102295:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010229c:	f0 
f010229d:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f01022a4:	00 
f01022a5:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01022ac:	e8 05 de ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01022b1:	ba 00 10 00 00       	mov    $0x1000,%edx
f01022b6:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f01022bb:	e8 29 ed ff ff       	call   f0100fe9 <check_va2pa>
f01022c0:	89 f2                	mov    %esi,%edx
f01022c2:	2b 15 ac fe 17 f0    	sub    0xf017feac,%edx
f01022c8:	c1 fa 03             	sar    $0x3,%edx
f01022cb:	c1 e2 0c             	shl    $0xc,%edx
f01022ce:	39 d0                	cmp    %edx,%eax
f01022d0:	74 24                	je     f01022f6 <mem_init+0xabf>
f01022d2:	c7 44 24 0c 7c 64 10 	movl   $0xf010647c,0xc(%esp)
f01022d9:	f0 
f01022da:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01022e1:	f0 
f01022e2:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f01022e9:	00 
f01022ea:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01022f1:	e8 c0 dd ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f01022f6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01022fb:	74 24                	je     f0102321 <mem_init+0xaea>
f01022fd:	c7 44 24 0c 55 6b 10 	movl   $0xf0106b55,0xc(%esp)
f0102304:	f0 
f0102305:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010230c:	f0 
f010230d:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f0102314:	00 
f0102315:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010231c:	e8 95 dd ff ff       	call   f01000b6 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0102321:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102328:	e8 8d f1 ff ff       	call   f01014ba <page_alloc>
f010232d:	85 c0                	test   %eax,%eax
f010232f:	74 24                	je     f0102355 <mem_init+0xb1e>
f0102331:	c7 44 24 0c e1 6a 10 	movl   $0xf0106ae1,0xc(%esp)
f0102338:	f0 
f0102339:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102340:	f0 
f0102341:	c7 44 24 04 78 03 00 	movl   $0x378,0x4(%esp)
f0102348:	00 
f0102349:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102350:	e8 61 dd ff ff       	call   f01000b6 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0102355:	8b 15 a8 fe 17 f0    	mov    0xf017fea8,%edx
f010235b:	8b 02                	mov    (%edx),%eax
f010235d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102362:	89 c1                	mov    %eax,%ecx
f0102364:	c1 e9 0c             	shr    $0xc,%ecx
f0102367:	3b 0d a4 fe 17 f0    	cmp    0xf017fea4,%ecx
f010236d:	72 20                	jb     f010238f <mem_init+0xb58>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010236f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102373:	c7 44 24 08 40 61 10 	movl   $0xf0106140,0x8(%esp)
f010237a:	f0 
f010237b:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0102382:	00 
f0102383:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010238a:	e8 27 dd ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f010238f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102394:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102397:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010239e:	00 
f010239f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01023a6:	00 
f01023a7:	89 14 24             	mov    %edx,(%esp)
f01023aa:	e8 f9 f1 ff ff       	call   f01015a8 <pgdir_walk>
f01023af:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01023b2:	8d 57 04             	lea    0x4(%edi),%edx
f01023b5:	39 d0                	cmp    %edx,%eax
f01023b7:	74 24                	je     f01023dd <mem_init+0xba6>
f01023b9:	c7 44 24 0c ac 64 10 	movl   $0xf01064ac,0xc(%esp)
f01023c0:	f0 
f01023c1:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01023c8:	f0 
f01023c9:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f01023d0:	00 
f01023d1:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01023d8:	e8 d9 dc ff ff       	call   f01000b6 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01023dd:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f01023e4:	00 
f01023e5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01023ec:	00 
f01023ed:	89 74 24 04          	mov    %esi,0x4(%esp)
f01023f1:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f01023f6:	89 04 24             	mov    %eax,(%esp)
f01023f9:	e8 c7 f3 ff ff       	call   f01017c5 <page_insert>
f01023fe:	85 c0                	test   %eax,%eax
f0102400:	74 24                	je     f0102426 <mem_init+0xbef>
f0102402:	c7 44 24 0c ec 64 10 	movl   $0xf01064ec,0xc(%esp)
f0102409:	f0 
f010240a:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102411:	f0 
f0102412:	c7 44 24 04 7f 03 00 	movl   $0x37f,0x4(%esp)
f0102419:	00 
f010241a:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102421:	e8 90 dc ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102426:	8b 3d a8 fe 17 f0    	mov    0xf017fea8,%edi
f010242c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102431:	89 f8                	mov    %edi,%eax
f0102433:	e8 b1 eb ff ff       	call   f0100fe9 <check_va2pa>
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102438:	89 f2                	mov    %esi,%edx
f010243a:	2b 15 ac fe 17 f0    	sub    0xf017feac,%edx
f0102440:	c1 fa 03             	sar    $0x3,%edx
f0102443:	c1 e2 0c             	shl    $0xc,%edx
f0102446:	39 d0                	cmp    %edx,%eax
f0102448:	74 24                	je     f010246e <mem_init+0xc37>
f010244a:	c7 44 24 0c 7c 64 10 	movl   $0xf010647c,0xc(%esp)
f0102451:	f0 
f0102452:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102459:	f0 
f010245a:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f0102461:	00 
f0102462:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102469:	e8 48 dc ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f010246e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102473:	74 24                	je     f0102499 <mem_init+0xc62>
f0102475:	c7 44 24 0c 55 6b 10 	movl   $0xf0106b55,0xc(%esp)
f010247c:	f0 
f010247d:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102484:	f0 
f0102485:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f010248c:	00 
f010248d:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102494:	e8 1d dc ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102499:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01024a0:	00 
f01024a1:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01024a8:	00 
f01024a9:	89 3c 24             	mov    %edi,(%esp)
f01024ac:	e8 f7 f0 ff ff       	call   f01015a8 <pgdir_walk>
f01024b1:	f6 00 04             	testb  $0x4,(%eax)
f01024b4:	75 24                	jne    f01024da <mem_init+0xca3>
f01024b6:	c7 44 24 0c 2c 65 10 	movl   $0xf010652c,0xc(%esp)
f01024bd:	f0 
f01024be:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01024c5:	f0 
f01024c6:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f01024cd:	00 
f01024ce:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01024d5:	e8 dc db ff ff       	call   f01000b6 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01024da:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f01024df:	f6 00 04             	testb  $0x4,(%eax)
f01024e2:	75 24                	jne    f0102508 <mem_init+0xcd1>
f01024e4:	c7 44 24 0c 66 6b 10 	movl   $0xf0106b66,0xc(%esp)
f01024eb:	f0 
f01024ec:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01024f3:	f0 
f01024f4:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f01024fb:	00 
f01024fc:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102503:	e8 ae db ff ff       	call   f01000b6 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102508:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010250f:	00 
f0102510:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102517:	00 
f0102518:	89 74 24 04          	mov    %esi,0x4(%esp)
f010251c:	89 04 24             	mov    %eax,(%esp)
f010251f:	e8 a1 f2 ff ff       	call   f01017c5 <page_insert>
f0102524:	85 c0                	test   %eax,%eax
f0102526:	74 24                	je     f010254c <mem_init+0xd15>
f0102528:	c7 44 24 0c 40 64 10 	movl   $0xf0106440,0xc(%esp)
f010252f:	f0 
f0102530:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102537:	f0 
f0102538:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f010253f:	00 
f0102540:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102547:	e8 6a db ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010254c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102553:	00 
f0102554:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010255b:	00 
f010255c:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0102561:	89 04 24             	mov    %eax,(%esp)
f0102564:	e8 3f f0 ff ff       	call   f01015a8 <pgdir_walk>
f0102569:	f6 00 02             	testb  $0x2,(%eax)
f010256c:	75 24                	jne    f0102592 <mem_init+0xd5b>
f010256e:	c7 44 24 0c 60 65 10 	movl   $0xf0106560,0xc(%esp)
f0102575:	f0 
f0102576:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010257d:	f0 
f010257e:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f0102585:	00 
f0102586:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010258d:	e8 24 db ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102592:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102599:	00 
f010259a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01025a1:	00 
f01025a2:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f01025a7:	89 04 24             	mov    %eax,(%esp)
f01025aa:	e8 f9 ef ff ff       	call   f01015a8 <pgdir_walk>
f01025af:	f6 00 04             	testb  $0x4,(%eax)
f01025b2:	74 24                	je     f01025d8 <mem_init+0xda1>
f01025b4:	c7 44 24 0c 94 65 10 	movl   $0xf0106594,0xc(%esp)
f01025bb:	f0 
f01025bc:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01025c3:	f0 
f01025c4:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f01025cb:	00 
f01025cc:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01025d3:	e8 de da ff ff       	call   f01000b6 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01025d8:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01025df:	00 
f01025e0:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f01025e7:	00 
f01025e8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01025eb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01025ef:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f01025f4:	89 04 24             	mov    %eax,(%esp)
f01025f7:	e8 c9 f1 ff ff       	call   f01017c5 <page_insert>
f01025fc:	85 c0                	test   %eax,%eax
f01025fe:	78 24                	js     f0102624 <mem_init+0xded>
f0102600:	c7 44 24 0c cc 65 10 	movl   $0xf01065cc,0xc(%esp)
f0102607:	f0 
f0102608:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010260f:	f0 
f0102610:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f0102617:	00 
f0102618:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010261f:	e8 92 da ff ff       	call   f01000b6 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102624:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010262b:	00 
f010262c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102633:	00 
f0102634:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102638:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f010263d:	89 04 24             	mov    %eax,(%esp)
f0102640:	e8 80 f1 ff ff       	call   f01017c5 <page_insert>
f0102645:	85 c0                	test   %eax,%eax
f0102647:	74 24                	je     f010266d <mem_init+0xe36>
f0102649:	c7 44 24 0c 04 66 10 	movl   $0xf0106604,0xc(%esp)
f0102650:	f0 
f0102651:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102658:	f0 
f0102659:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f0102660:	00 
f0102661:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102668:	e8 49 da ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010266d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102674:	00 
f0102675:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010267c:	00 
f010267d:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0102682:	89 04 24             	mov    %eax,(%esp)
f0102685:	e8 1e ef ff ff       	call   f01015a8 <pgdir_walk>
f010268a:	f6 00 04             	testb  $0x4,(%eax)
f010268d:	74 24                	je     f01026b3 <mem_init+0xe7c>
f010268f:	c7 44 24 0c 94 65 10 	movl   $0xf0106594,0xc(%esp)
f0102696:	f0 
f0102697:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010269e:	f0 
f010269f:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f01026a6:	00 
f01026a7:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01026ae:	e8 03 da ff ff       	call   f01000b6 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01026b3:	8b 3d a8 fe 17 f0    	mov    0xf017fea8,%edi
f01026b9:	ba 00 00 00 00       	mov    $0x0,%edx
f01026be:	89 f8                	mov    %edi,%eax
f01026c0:	e8 24 e9 ff ff       	call   f0100fe9 <check_va2pa>
f01026c5:	89 c1                	mov    %eax,%ecx
f01026c7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01026ca:	89 d8                	mov    %ebx,%eax
f01026cc:	2b 05 ac fe 17 f0    	sub    0xf017feac,%eax
f01026d2:	c1 f8 03             	sar    $0x3,%eax
f01026d5:	c1 e0 0c             	shl    $0xc,%eax
f01026d8:	39 c1                	cmp    %eax,%ecx
f01026da:	74 24                	je     f0102700 <mem_init+0xec9>
f01026dc:	c7 44 24 0c 40 66 10 	movl   $0xf0106640,0xc(%esp)
f01026e3:	f0 
f01026e4:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01026eb:	f0 
f01026ec:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f01026f3:	00 
f01026f4:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01026fb:	e8 b6 d9 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102700:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102705:	89 f8                	mov    %edi,%eax
f0102707:	e8 dd e8 ff ff       	call   f0100fe9 <check_va2pa>
f010270c:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f010270f:	74 24                	je     f0102735 <mem_init+0xefe>
f0102711:	c7 44 24 0c 6c 66 10 	movl   $0xf010666c,0xc(%esp)
f0102718:	f0 
f0102719:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102720:	f0 
f0102721:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0102728:	00 
f0102729:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102730:	e8 81 d9 ff ff       	call   f01000b6 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102735:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f010273a:	74 24                	je     f0102760 <mem_init+0xf29>
f010273c:	c7 44 24 0c 7c 6b 10 	movl   $0xf0106b7c,0xc(%esp)
f0102743:	f0 
f0102744:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010274b:	f0 
f010274c:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f0102753:	00 
f0102754:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010275b:	e8 56 d9 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f0102760:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102765:	74 24                	je     f010278b <mem_init+0xf54>
f0102767:	c7 44 24 0c 8d 6b 10 	movl   $0xf0106b8d,0xc(%esp)
f010276e:	f0 
f010276f:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102776:	f0 
f0102777:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f010277e:	00 
f010277f:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102786:	e8 2b d9 ff ff       	call   f01000b6 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010278b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102792:	e8 23 ed ff ff       	call   f01014ba <page_alloc>
f0102797:	85 c0                	test   %eax,%eax
f0102799:	74 04                	je     f010279f <mem_init+0xf68>
f010279b:	39 c6                	cmp    %eax,%esi
f010279d:	74 24                	je     f01027c3 <mem_init+0xf8c>
f010279f:	c7 44 24 0c 9c 66 10 	movl   $0xf010669c,0xc(%esp)
f01027a6:	f0 
f01027a7:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01027ae:	f0 
f01027af:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f01027b6:	00 
f01027b7:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01027be:	e8 f3 d8 ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01027c3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01027ca:	00 
f01027cb:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f01027d0:	89 04 24             	mov    %eax,(%esp)
f01027d3:	e8 af ef ff ff       	call   f0101787 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01027d8:	8b 3d a8 fe 17 f0    	mov    0xf017fea8,%edi
f01027de:	ba 00 00 00 00       	mov    $0x0,%edx
f01027e3:	89 f8                	mov    %edi,%eax
f01027e5:	e8 ff e7 ff ff       	call   f0100fe9 <check_va2pa>
f01027ea:	83 f8 ff             	cmp    $0xffffffff,%eax
f01027ed:	74 24                	je     f0102813 <mem_init+0xfdc>
f01027ef:	c7 44 24 0c c0 66 10 	movl   $0xf01066c0,0xc(%esp)
f01027f6:	f0 
f01027f7:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01027fe:	f0 
f01027ff:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f0102806:	00 
f0102807:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010280e:	e8 a3 d8 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102813:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102818:	89 f8                	mov    %edi,%eax
f010281a:	e8 ca e7 ff ff       	call   f0100fe9 <check_va2pa>
f010281f:	89 da                	mov    %ebx,%edx
f0102821:	2b 15 ac fe 17 f0    	sub    0xf017feac,%edx
f0102827:	c1 fa 03             	sar    $0x3,%edx
f010282a:	c1 e2 0c             	shl    $0xc,%edx
f010282d:	39 d0                	cmp    %edx,%eax
f010282f:	74 24                	je     f0102855 <mem_init+0x101e>
f0102831:	c7 44 24 0c 6c 66 10 	movl   $0xf010666c,0xc(%esp)
f0102838:	f0 
f0102839:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102840:	f0 
f0102841:	c7 44 24 04 9e 03 00 	movl   $0x39e,0x4(%esp)
f0102848:	00 
f0102849:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102850:	e8 61 d8 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f0102855:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010285a:	74 24                	je     f0102880 <mem_init+0x1049>
f010285c:	c7 44 24 0c 33 6b 10 	movl   $0xf0106b33,0xc(%esp)
f0102863:	f0 
f0102864:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010286b:	f0 
f010286c:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f0102873:	00 
f0102874:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010287b:	e8 36 d8 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f0102880:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102885:	74 24                	je     f01028ab <mem_init+0x1074>
f0102887:	c7 44 24 0c 8d 6b 10 	movl   $0xf0106b8d,0xc(%esp)
f010288e:	f0 
f010288f:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102896:	f0 
f0102897:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f010289e:	00 
f010289f:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01028a6:	e8 0b d8 ff ff       	call   f01000b6 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01028ab:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01028b2:	00 
f01028b3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01028ba:	00 
f01028bb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01028bf:	89 3c 24             	mov    %edi,(%esp)
f01028c2:	e8 fe ee ff ff       	call   f01017c5 <page_insert>
f01028c7:	85 c0                	test   %eax,%eax
f01028c9:	74 24                	je     f01028ef <mem_init+0x10b8>
f01028cb:	c7 44 24 0c e4 66 10 	movl   $0xf01066e4,0xc(%esp)
f01028d2:	f0 
f01028d3:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01028da:	f0 
f01028db:	c7 44 24 04 a3 03 00 	movl   $0x3a3,0x4(%esp)
f01028e2:	00 
f01028e3:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01028ea:	e8 c7 d7 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref);
f01028ef:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01028f4:	75 24                	jne    f010291a <mem_init+0x10e3>
f01028f6:	c7 44 24 0c 9e 6b 10 	movl   $0xf0106b9e,0xc(%esp)
f01028fd:	f0 
f01028fe:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102905:	f0 
f0102906:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f010290d:	00 
f010290e:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102915:	e8 9c d7 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_link == NULL);
f010291a:	83 3b 00             	cmpl   $0x0,(%ebx)
f010291d:	74 24                	je     f0102943 <mem_init+0x110c>
f010291f:	c7 44 24 0c aa 6b 10 	movl   $0xf0106baa,0xc(%esp)
f0102926:	f0 
f0102927:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010292e:	f0 
f010292f:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f0102936:	00 
f0102937:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010293e:	e8 73 d7 ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102943:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010294a:	00 
f010294b:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0102950:	89 04 24             	mov    %eax,(%esp)
f0102953:	e8 2f ee ff ff       	call   f0101787 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102958:	8b 3d a8 fe 17 f0    	mov    0xf017fea8,%edi
f010295e:	ba 00 00 00 00       	mov    $0x0,%edx
f0102963:	89 f8                	mov    %edi,%eax
f0102965:	e8 7f e6 ff ff       	call   f0100fe9 <check_va2pa>
f010296a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010296d:	74 24                	je     f0102993 <mem_init+0x115c>
f010296f:	c7 44 24 0c c0 66 10 	movl   $0xf01066c0,0xc(%esp)
f0102976:	f0 
f0102977:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010297e:	f0 
f010297f:	c7 44 24 04 a9 03 00 	movl   $0x3a9,0x4(%esp)
f0102986:	00 
f0102987:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010298e:	e8 23 d7 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102993:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102998:	89 f8                	mov    %edi,%eax
f010299a:	e8 4a e6 ff ff       	call   f0100fe9 <check_va2pa>
f010299f:	83 f8 ff             	cmp    $0xffffffff,%eax
f01029a2:	74 24                	je     f01029c8 <mem_init+0x1191>
f01029a4:	c7 44 24 0c 1c 67 10 	movl   $0xf010671c,0xc(%esp)
f01029ab:	f0 
f01029ac:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01029b3:	f0 
f01029b4:	c7 44 24 04 aa 03 00 	movl   $0x3aa,0x4(%esp)
f01029bb:	00 
f01029bc:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01029c3:	e8 ee d6 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f01029c8:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01029cd:	74 24                	je     f01029f3 <mem_init+0x11bc>
f01029cf:	c7 44 24 0c bf 6b 10 	movl   $0xf0106bbf,0xc(%esp)
f01029d6:	f0 
f01029d7:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01029de:	f0 
f01029df:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f01029e6:	00 
f01029e7:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01029ee:	e8 c3 d6 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f01029f3:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01029f8:	74 24                	je     f0102a1e <mem_init+0x11e7>
f01029fa:	c7 44 24 0c 8d 6b 10 	movl   $0xf0106b8d,0xc(%esp)
f0102a01:	f0 
f0102a02:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102a09:	f0 
f0102a0a:	c7 44 24 04 ac 03 00 	movl   $0x3ac,0x4(%esp)
f0102a11:	00 
f0102a12:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102a19:	e8 98 d6 ff ff       	call   f01000b6 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102a1e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a25:	e8 90 ea ff ff       	call   f01014ba <page_alloc>
f0102a2a:	85 c0                	test   %eax,%eax
f0102a2c:	74 04                	je     f0102a32 <mem_init+0x11fb>
f0102a2e:	39 c3                	cmp    %eax,%ebx
f0102a30:	74 24                	je     f0102a56 <mem_init+0x121f>
f0102a32:	c7 44 24 0c 44 67 10 	movl   $0xf0106744,0xc(%esp)
f0102a39:	f0 
f0102a3a:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102a41:	f0 
f0102a42:	c7 44 24 04 af 03 00 	movl   $0x3af,0x4(%esp)
f0102a49:	00 
f0102a4a:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102a51:	e8 60 d6 ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102a56:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a5d:	e8 58 ea ff ff       	call   f01014ba <page_alloc>
f0102a62:	85 c0                	test   %eax,%eax
f0102a64:	74 24                	je     f0102a8a <mem_init+0x1253>
f0102a66:	c7 44 24 0c e1 6a 10 	movl   $0xf0106ae1,0xc(%esp)
f0102a6d:	f0 
f0102a6e:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102a75:	f0 
f0102a76:	c7 44 24 04 b2 03 00 	movl   $0x3b2,0x4(%esp)
f0102a7d:	00 
f0102a7e:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102a85:	e8 2c d6 ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102a8a:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0102a8f:	8b 08                	mov    (%eax),%ecx
f0102a91:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102a97:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102a9a:	2b 15 ac fe 17 f0    	sub    0xf017feac,%edx
f0102aa0:	c1 fa 03             	sar    $0x3,%edx
f0102aa3:	c1 e2 0c             	shl    $0xc,%edx
f0102aa6:	39 d1                	cmp    %edx,%ecx
f0102aa8:	74 24                	je     f0102ace <mem_init+0x1297>
f0102aaa:	c7 44 24 0c e8 63 10 	movl   $0xf01063e8,0xc(%esp)
f0102ab1:	f0 
f0102ab2:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102ab9:	f0 
f0102aba:	c7 44 24 04 b5 03 00 	movl   $0x3b5,0x4(%esp)
f0102ac1:	00 
f0102ac2:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102ac9:	e8 e8 d5 ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f0102ace:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102ad4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ad7:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102adc:	74 24                	je     f0102b02 <mem_init+0x12cb>
f0102ade:	c7 44 24 0c 44 6b 10 	movl   $0xf0106b44,0xc(%esp)
f0102ae5:	f0 
f0102ae6:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102aed:	f0 
f0102aee:	c7 44 24 04 b7 03 00 	movl   $0x3b7,0x4(%esp)
f0102af5:	00 
f0102af6:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102afd:	e8 b4 d5 ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f0102b02:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b05:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102b0b:	89 04 24             	mov    %eax,(%esp)
f0102b0e:	e8 32 ea ff ff       	call   f0101545 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102b13:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102b1a:	00 
f0102b1b:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102b22:	00 
f0102b23:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0102b28:	89 04 24             	mov    %eax,(%esp)
f0102b2b:	e8 78 ea ff ff       	call   f01015a8 <pgdir_walk>
f0102b30:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102b33:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102b36:	8b 15 a8 fe 17 f0    	mov    0xf017fea8,%edx
f0102b3c:	8b 7a 04             	mov    0x4(%edx),%edi
f0102b3f:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b45:	8b 0d a4 fe 17 f0    	mov    0xf017fea4,%ecx
f0102b4b:	89 f8                	mov    %edi,%eax
f0102b4d:	c1 e8 0c             	shr    $0xc,%eax
f0102b50:	39 c8                	cmp    %ecx,%eax
f0102b52:	72 20                	jb     f0102b74 <mem_init+0x133d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b54:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102b58:	c7 44 24 08 40 61 10 	movl   $0xf0106140,0x8(%esp)
f0102b5f:	f0 
f0102b60:	c7 44 24 04 be 03 00 	movl   $0x3be,0x4(%esp)
f0102b67:	00 
f0102b68:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102b6f:	e8 42 d5 ff ff       	call   f01000b6 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102b74:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102b7a:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102b7d:	74 24                	je     f0102ba3 <mem_init+0x136c>
f0102b7f:	c7 44 24 0c d0 6b 10 	movl   $0xf0106bd0,0xc(%esp)
f0102b86:	f0 
f0102b87:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102b8e:	f0 
f0102b8f:	c7 44 24 04 bf 03 00 	movl   $0x3bf,0x4(%esp)
f0102b96:	00 
f0102b97:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102b9e:	e8 13 d5 ff ff       	call   f01000b6 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102ba3:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102baa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102bad:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bb3:	2b 05 ac fe 17 f0    	sub    0xf017feac,%eax
f0102bb9:	c1 f8 03             	sar    $0x3,%eax
f0102bbc:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bbf:	89 c2                	mov    %eax,%edx
f0102bc1:	c1 ea 0c             	shr    $0xc,%edx
f0102bc4:	39 d1                	cmp    %edx,%ecx
f0102bc6:	77 20                	ja     f0102be8 <mem_init+0x13b1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bc8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102bcc:	c7 44 24 08 40 61 10 	movl   $0xf0106140,0x8(%esp)
f0102bd3:	f0 
f0102bd4:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f0102bdb:	00 
f0102bdc:	c7 04 24 71 69 10 f0 	movl   $0xf0106971,(%esp)
f0102be3:	e8 ce d4 ff ff       	call   f01000b6 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102be8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102bef:	00 
f0102bf0:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102bf7:	00 
	return (void *)(pa + KERNBASE);
f0102bf8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102bfd:	89 04 24             	mov    %eax,(%esp)
f0102c00:	e8 a2 26 00 00       	call   f01052a7 <memset>
	page_free(pp0);
f0102c05:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102c08:	89 3c 24             	mov    %edi,(%esp)
f0102c0b:	e8 35 e9 ff ff       	call   f0101545 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102c10:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102c17:	00 
f0102c18:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102c1f:	00 
f0102c20:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0102c25:	89 04 24             	mov    %eax,(%esp)
f0102c28:	e8 7b e9 ff ff       	call   f01015a8 <pgdir_walk>
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c2d:	89 fa                	mov    %edi,%edx
f0102c2f:	2b 15 ac fe 17 f0    	sub    0xf017feac,%edx
f0102c35:	c1 fa 03             	sar    $0x3,%edx
f0102c38:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c3b:	89 d0                	mov    %edx,%eax
f0102c3d:	c1 e8 0c             	shr    $0xc,%eax
f0102c40:	3b 05 a4 fe 17 f0    	cmp    0xf017fea4,%eax
f0102c46:	72 20                	jb     f0102c68 <mem_init+0x1431>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c48:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102c4c:	c7 44 24 08 40 61 10 	movl   $0xf0106140,0x8(%esp)
f0102c53:	f0 
f0102c54:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f0102c5b:	00 
f0102c5c:	c7 04 24 71 69 10 f0 	movl   $0xf0106971,(%esp)
f0102c63:	e8 4e d4 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0102c68:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102c6e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102c71:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102c77:	f6 00 01             	testb  $0x1,(%eax)
f0102c7a:	74 24                	je     f0102ca0 <mem_init+0x1469>
f0102c7c:	c7 44 24 0c e8 6b 10 	movl   $0xf0106be8,0xc(%esp)
f0102c83:	f0 
f0102c84:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102c8b:	f0 
f0102c8c:	c7 44 24 04 c9 03 00 	movl   $0x3c9,0x4(%esp)
f0102c93:	00 
f0102c94:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102c9b:	e8 16 d4 ff ff       	call   f01000b6 <_panic>
f0102ca0:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102ca3:	39 d0                	cmp    %edx,%eax
f0102ca5:	75 d0                	jne    f0102c77 <mem_init+0x1440>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102ca7:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0102cac:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102cb2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102cb5:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102cbb:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102cbe:	89 0d e0 f1 17 f0    	mov    %ecx,0xf017f1e0

	// free the pages we took
	page_free(pp0);
f0102cc4:	89 04 24             	mov    %eax,(%esp)
f0102cc7:	e8 79 e8 ff ff       	call   f0101545 <page_free>
	page_free(pp1);
f0102ccc:	89 1c 24             	mov    %ebx,(%esp)
f0102ccf:	e8 71 e8 ff ff       	call   f0101545 <page_free>
	page_free(pp2);
f0102cd4:	89 34 24             	mov    %esi,(%esp)
f0102cd7:	e8 69 e8 ff ff       	call   f0101545 <page_free>

	cprintf("check_page() succeeded!\n");
f0102cdc:	c7 04 24 ff 6b 10 f0 	movl   $0xf0106bff,(%esp)
f0102ce3:	e8 7b 10 00 00       	call   f0103d63 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, (uintptr_t)UPAGES, npages * sizeof(struct PageInfo), PADDR(pages), PTE_U | PTE_P);
f0102ce8:	a1 ac fe 17 f0       	mov    0xf017feac,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ced:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102cf2:	77 20                	ja     f0102d14 <mem_init+0x14dd>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102cf4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102cf8:	c7 44 24 08 64 62 10 	movl   $0xf0106264,0x8(%esp)
f0102cff:	f0 
f0102d00:	c7 44 24 04 c1 00 00 	movl   $0xc1,0x4(%esp)
f0102d07:	00 
f0102d08:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102d0f:	e8 a2 d3 ff ff       	call   f01000b6 <_panic>
f0102d14:	8b 3d a4 fe 17 f0    	mov    0xf017fea4,%edi
f0102d1a:	8d 0c fd 00 00 00 00 	lea    0x0(,%edi,8),%ecx
f0102d21:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102d28:	00 
	return (physaddr_t)kva - KERNBASE;
f0102d29:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d2e:	89 04 24             	mov    %eax,(%esp)
f0102d31:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102d36:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0102d3b:	e8 75 e9 ff ff       	call   f01016b5 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, (uintptr_t)UENVS, NENV * sizeof(struct Env), PADDR(envs), PTE_U | PTE_P);
f0102d40:	a1 ec f1 17 f0       	mov    0xf017f1ec,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d45:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d4a:	77 20                	ja     f0102d6c <mem_init+0x1535>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d4c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d50:	c7 44 24 08 64 62 10 	movl   $0xf0106264,0x8(%esp)
f0102d57:	f0 
f0102d58:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
f0102d5f:	00 
f0102d60:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102d67:	e8 4a d3 ff ff       	call   f01000b6 <_panic>
f0102d6c:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102d73:	00 
	return (physaddr_t)kva - KERNBASE;
f0102d74:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d79:	89 04 24             	mov    %eax,(%esp)
f0102d7c:	b9 00 80 01 00       	mov    $0x18000,%ecx
f0102d81:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102d86:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0102d8b:	e8 25 e9 ff ff       	call   f01016b5 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d90:	bb 00 30 11 f0       	mov    $0xf0113000,%ebx
f0102d95:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102d9b:	77 20                	ja     f0102dbd <mem_init+0x1586>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d9d:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102da1:	c7 44 24 08 64 62 10 	movl   $0xf0106264,0x8(%esp)
f0102da8:	f0 
f0102da9:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
f0102db0:	00 
f0102db1:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102db8:	e8 f9 d2 ff ff       	call   f01000b6 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, (uintptr_t)(KSTACKTOP - KSTKSIZE), KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f0102dbd:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102dc4:	00 
f0102dc5:	c7 04 24 00 30 11 00 	movl   $0x113000,(%esp)
f0102dcc:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102dd1:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102dd6:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0102ddb:	e8 d5 e8 ff ff       	call   f01016b5 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, (uintptr_t)KERNBASE, ROUNDUP(0xffffffff - KERNBASE, PGSIZE), 0, PTE_W | PTE_P);
f0102de0:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102de7:	00 
f0102de8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102def:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102df4:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102df9:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0102dfe:	e8 b2 e8 ff ff       	call   f01016b5 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102e03:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0102e08:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102e0b:	a1 a4 fe 17 f0       	mov    0xf017fea4,%eax
f0102e10:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102e13:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102e1a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102e1f:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102e22:	8b 3d ac fe 17 f0    	mov    0xf017feac,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e28:	89 7d c8             	mov    %edi,-0x38(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102e2b:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0102e31:	89 45 c4             	mov    %eax,-0x3c(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102e34:	be 00 00 00 00       	mov    $0x0,%esi
f0102e39:	eb 6b                	jmp    f0102ea6 <mem_init+0x166f>
f0102e3b:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102e41:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e44:	e8 a0 e1 ff ff       	call   f0100fe9 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e49:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f0102e50:	77 20                	ja     f0102e72 <mem_init+0x163b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e52:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102e56:	c7 44 24 08 64 62 10 	movl   $0xf0106264,0x8(%esp)
f0102e5d:	f0 
f0102e5e:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0102e65:	00 
f0102e66:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102e6d:	e8 44 d2 ff ff       	call   f01000b6 <_panic>
f0102e72:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102e75:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102e78:	39 d0                	cmp    %edx,%eax
f0102e7a:	74 24                	je     f0102ea0 <mem_init+0x1669>
f0102e7c:	c7 44 24 0c 68 67 10 	movl   $0xf0106768,0xc(%esp)
f0102e83:	f0 
f0102e84:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102e8b:	f0 
f0102e8c:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0102e93:	00 
f0102e94:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102e9b:	e8 16 d2 ff ff       	call   f01000b6 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102ea0:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102ea6:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0102ea9:	77 90                	ja     f0102e3b <mem_init+0x1604>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102eab:	8b 35 ec f1 17 f0    	mov    0xf017f1ec,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102eb1:	89 f7                	mov    %esi,%edi
f0102eb3:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102eb8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ebb:	e8 29 e1 ff ff       	call   f0100fe9 <check_va2pa>
f0102ec0:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102ec6:	77 20                	ja     f0102ee8 <mem_init+0x16b1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ec8:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102ecc:	c7 44 24 08 64 62 10 	movl   $0xf0106264,0x8(%esp)
f0102ed3:	f0 
f0102ed4:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0102edb:	00 
f0102edc:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102ee3:	e8 ce d1 ff ff       	call   f01000b6 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ee8:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102eed:	81 c7 00 00 40 21    	add    $0x21400000,%edi
f0102ef3:	8d 14 37             	lea    (%edi,%esi,1),%edx
f0102ef6:	39 c2                	cmp    %eax,%edx
f0102ef8:	74 24                	je     f0102f1e <mem_init+0x16e7>
f0102efa:	c7 44 24 0c 9c 67 10 	movl   $0xf010679c,0xc(%esp)
f0102f01:	f0 
f0102f02:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102f09:	f0 
f0102f0a:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0102f11:	00 
f0102f12:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102f19:	e8 98 d1 ff ff       	call   f01000b6 <_panic>
f0102f1e:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102f24:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102f2a:	0f 85 26 05 00 00    	jne    f0103456 <mem_init+0x1c1f>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102f30:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102f33:	c1 e7 0c             	shl    $0xc,%edi
f0102f36:	be 00 00 00 00       	mov    $0x0,%esi
f0102f3b:	eb 3c                	jmp    f0102f79 <mem_init+0x1742>
f0102f3d:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102f43:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102f46:	e8 9e e0 ff ff       	call   f0100fe9 <check_va2pa>
f0102f4b:	39 c6                	cmp    %eax,%esi
f0102f4d:	74 24                	je     f0102f73 <mem_init+0x173c>
f0102f4f:	c7 44 24 0c d0 67 10 	movl   $0xf01067d0,0xc(%esp)
f0102f56:	f0 
f0102f57:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102f5e:	f0 
f0102f5f:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f0102f66:	00 
f0102f67:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102f6e:	e8 43 d1 ff ff       	call   f01000b6 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102f73:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102f79:	39 fe                	cmp    %edi,%esi
f0102f7b:	72 c0                	jb     f0102f3d <mem_init+0x1706>
f0102f7d:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102f82:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102f88:	89 f2                	mov    %esi,%edx
f0102f8a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102f8d:	e8 57 e0 ff ff       	call   f0100fe9 <check_va2pa>
f0102f92:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f0102f95:	39 d0                	cmp    %edx,%eax
f0102f97:	74 24                	je     f0102fbd <mem_init+0x1786>
f0102f99:	c7 44 24 0c f8 67 10 	movl   $0xf01067f8,0xc(%esp)
f0102fa0:	f0 
f0102fa1:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102fa8:	f0 
f0102fa9:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f0102fb0:	00 
f0102fb1:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0102fb8:	e8 f9 d0 ff ff       	call   f01000b6 <_panic>
f0102fbd:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102fc3:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102fc9:	75 bd                	jne    f0102f88 <mem_init+0x1751>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102fcb:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102fd0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102fd3:	89 f8                	mov    %edi,%eax
f0102fd5:	e8 0f e0 ff ff       	call   f0100fe9 <check_va2pa>
f0102fda:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102fdd:	75 0c                	jne    f0102feb <mem_init+0x17b4>
f0102fdf:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fe4:	89 fa                	mov    %edi,%edx
f0102fe6:	e9 f0 00 00 00       	jmp    f01030db <mem_init+0x18a4>
f0102feb:	c7 44 24 0c 40 68 10 	movl   $0xf0106840,0xc(%esp)
f0102ff2:	f0 
f0102ff3:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0102ffa:	f0 
f0102ffb:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0103002:	00 
f0103003:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010300a:	e8 a7 d0 ff ff       	call   f01000b6 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010300f:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103014:	72 3c                	jb     f0103052 <mem_init+0x181b>
f0103016:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010301b:	76 07                	jbe    f0103024 <mem_init+0x17ed>
f010301d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0103022:	75 2e                	jne    f0103052 <mem_init+0x181b>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0103024:	f6 04 82 01          	testb  $0x1,(%edx,%eax,4)
f0103028:	0f 85 aa 00 00 00    	jne    f01030d8 <mem_init+0x18a1>
f010302e:	c7 44 24 0c 18 6c 10 	movl   $0xf0106c18,0xc(%esp)
f0103035:	f0 
f0103036:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010303d:	f0 
f010303e:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f0103045:	00 
f0103046:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010304d:	e8 64 d0 ff ff       	call   f01000b6 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0103052:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0103057:	76 55                	jbe    f01030ae <mem_init+0x1877>
				assert(pgdir[i] & PTE_P);
f0103059:	8b 0c 82             	mov    (%edx,%eax,4),%ecx
f010305c:	f6 c1 01             	test   $0x1,%cl
f010305f:	75 24                	jne    f0103085 <mem_init+0x184e>
f0103061:	c7 44 24 0c 18 6c 10 	movl   $0xf0106c18,0xc(%esp)
f0103068:	f0 
f0103069:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0103070:	f0 
f0103071:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0103078:	00 
f0103079:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0103080:	e8 31 d0 ff ff       	call   f01000b6 <_panic>
				assert(pgdir[i] & PTE_W);
f0103085:	f6 c1 02             	test   $0x2,%cl
f0103088:	75 4e                	jne    f01030d8 <mem_init+0x18a1>
f010308a:	c7 44 24 0c 29 6c 10 	movl   $0xf0106c29,0xc(%esp)
f0103091:	f0 
f0103092:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0103099:	f0 
f010309a:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f01030a1:	00 
f01030a2:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01030a9:	e8 08 d0 ff ff       	call   f01000b6 <_panic>
			} else
				assert(pgdir[i] == 0);
f01030ae:	83 3c 82 00          	cmpl   $0x0,(%edx,%eax,4)
f01030b2:	74 24                	je     f01030d8 <mem_init+0x18a1>
f01030b4:	c7 44 24 0c 3a 6c 10 	movl   $0xf0106c3a,0xc(%esp)
f01030bb:	f0 
f01030bc:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01030c3:	f0 
f01030c4:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f01030cb:	00 
f01030cc:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01030d3:	e8 de cf ff ff       	call   f01000b6 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01030d8:	83 c0 01             	add    $0x1,%eax
f01030db:	3d 00 04 00 00       	cmp    $0x400,%eax
f01030e0:	0f 85 29 ff ff ff    	jne    f010300f <mem_init+0x17d8>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01030e6:	c7 04 24 70 68 10 f0 	movl   $0xf0106870,(%esp)
f01030ed:	e8 71 0c 00 00       	call   f0103d63 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01030f2:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f01030f7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030fc:	77 20                	ja     f010311e <mem_init+0x18e7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103102:	c7 44 24 08 64 62 10 	movl   $0xf0106264,0x8(%esp)
f0103109:	f0 
f010310a:	c7 44 24 04 ed 00 00 	movl   $0xed,0x4(%esp)
f0103111:	00 
f0103112:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0103119:	e8 98 cf ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010311e:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103123:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0103126:	b8 00 00 00 00       	mov    $0x0,%eax
f010312b:	e8 28 df ff ff       	call   f0101058 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0103130:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0103133:	83 e0 f3             	and    $0xfffffff3,%eax
f0103136:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f010313b:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010313e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103145:	e8 70 e3 ff ff       	call   f01014ba <page_alloc>
f010314a:	89 c3                	mov    %eax,%ebx
f010314c:	85 c0                	test   %eax,%eax
f010314e:	75 24                	jne    f0103174 <mem_init+0x193d>
f0103150:	c7 44 24 0c 36 6a 10 	movl   $0xf0106a36,0xc(%esp)
f0103157:	f0 
f0103158:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010315f:	f0 
f0103160:	c7 44 24 04 e4 03 00 	movl   $0x3e4,0x4(%esp)
f0103167:	00 
f0103168:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010316f:	e8 42 cf ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0103174:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010317b:	e8 3a e3 ff ff       	call   f01014ba <page_alloc>
f0103180:	89 c7                	mov    %eax,%edi
f0103182:	85 c0                	test   %eax,%eax
f0103184:	75 24                	jne    f01031aa <mem_init+0x1973>
f0103186:	c7 44 24 0c 4c 6a 10 	movl   $0xf0106a4c,0xc(%esp)
f010318d:	f0 
f010318e:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0103195:	f0 
f0103196:	c7 44 24 04 e5 03 00 	movl   $0x3e5,0x4(%esp)
f010319d:	00 
f010319e:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01031a5:	e8 0c cf ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f01031aa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01031b1:	e8 04 e3 ff ff       	call   f01014ba <page_alloc>
f01031b6:	89 c6                	mov    %eax,%esi
f01031b8:	85 c0                	test   %eax,%eax
f01031ba:	75 24                	jne    f01031e0 <mem_init+0x19a9>
f01031bc:	c7 44 24 0c 62 6a 10 	movl   $0xf0106a62,0xc(%esp)
f01031c3:	f0 
f01031c4:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01031cb:	f0 
f01031cc:	c7 44 24 04 e6 03 00 	movl   $0x3e6,0x4(%esp)
f01031d3:	00 
f01031d4:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01031db:	e8 d6 ce ff ff       	call   f01000b6 <_panic>
	page_free(pp0);
f01031e0:	89 1c 24             	mov    %ebx,(%esp)
f01031e3:	e8 5d e3 ff ff       	call   f0101545 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f01031e8:	89 f8                	mov    %edi,%eax
f01031ea:	e8 b5 dd ff ff       	call   f0100fa4 <page2kva>
f01031ef:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01031f6:	00 
f01031f7:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01031fe:	00 
f01031ff:	89 04 24             	mov    %eax,(%esp)
f0103202:	e8 a0 20 00 00       	call   f01052a7 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0103207:	89 f0                	mov    %esi,%eax
f0103209:	e8 96 dd ff ff       	call   f0100fa4 <page2kva>
f010320e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103215:	00 
f0103216:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010321d:	00 
f010321e:	89 04 24             	mov    %eax,(%esp)
f0103221:	e8 81 20 00 00       	call   f01052a7 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0103226:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010322d:	00 
f010322e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103235:	00 
f0103236:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010323a:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f010323f:	89 04 24             	mov    %eax,(%esp)
f0103242:	e8 7e e5 ff ff       	call   f01017c5 <page_insert>
	assert(pp1->pp_ref == 1);
f0103247:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010324c:	74 24                	je     f0103272 <mem_init+0x1a3b>
f010324e:	c7 44 24 0c 33 6b 10 	movl   $0xf0106b33,0xc(%esp)
f0103255:	f0 
f0103256:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010325d:	f0 
f010325e:	c7 44 24 04 eb 03 00 	movl   $0x3eb,0x4(%esp)
f0103265:	00 
f0103266:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010326d:	e8 44 ce ff ff       	call   f01000b6 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103272:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0103279:	01 01 01 
f010327c:	74 24                	je     f01032a2 <mem_init+0x1a6b>
f010327e:	c7 44 24 0c 90 68 10 	movl   $0xf0106890,0xc(%esp)
f0103285:	f0 
f0103286:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010328d:	f0 
f010328e:	c7 44 24 04 ec 03 00 	movl   $0x3ec,0x4(%esp)
f0103295:	00 
f0103296:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f010329d:	e8 14 ce ff ff       	call   f01000b6 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01032a2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01032a9:	00 
f01032aa:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01032b1:	00 
f01032b2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01032b6:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f01032bb:	89 04 24             	mov    %eax,(%esp)
f01032be:	e8 02 e5 ff ff       	call   f01017c5 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01032c3:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01032ca:	02 02 02 
f01032cd:	74 24                	je     f01032f3 <mem_init+0x1abc>
f01032cf:	c7 44 24 0c b4 68 10 	movl   $0xf01068b4,0xc(%esp)
f01032d6:	f0 
f01032d7:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01032de:	f0 
f01032df:	c7 44 24 04 ee 03 00 	movl   $0x3ee,0x4(%esp)
f01032e6:	00 
f01032e7:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01032ee:	e8 c3 cd ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f01032f3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01032f8:	74 24                	je     f010331e <mem_init+0x1ae7>
f01032fa:	c7 44 24 0c 55 6b 10 	movl   $0xf0106b55,0xc(%esp)
f0103301:	f0 
f0103302:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0103309:	f0 
f010330a:	c7 44 24 04 ef 03 00 	movl   $0x3ef,0x4(%esp)
f0103311:	00 
f0103312:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0103319:	e8 98 cd ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f010331e:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0103323:	74 24                	je     f0103349 <mem_init+0x1b12>
f0103325:	c7 44 24 0c bf 6b 10 	movl   $0xf0106bbf,0xc(%esp)
f010332c:	f0 
f010332d:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0103334:	f0 
f0103335:	c7 44 24 04 f0 03 00 	movl   $0x3f0,0x4(%esp)
f010333c:	00 
f010333d:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0103344:	e8 6d cd ff ff       	call   f01000b6 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0103349:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0103350:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0103353:	89 f0                	mov    %esi,%eax
f0103355:	e8 4a dc ff ff       	call   f0100fa4 <page2kva>
f010335a:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0103360:	74 24                	je     f0103386 <mem_init+0x1b4f>
f0103362:	c7 44 24 0c d8 68 10 	movl   $0xf01068d8,0xc(%esp)
f0103369:	f0 
f010336a:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0103371:	f0 
f0103372:	c7 44 24 04 f2 03 00 	movl   $0x3f2,0x4(%esp)
f0103379:	00 
f010337a:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0103381:	e8 30 cd ff ff       	call   f01000b6 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0103386:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010338d:	00 
f010338e:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f0103393:	89 04 24             	mov    %eax,(%esp)
f0103396:	e8 ec e3 ff ff       	call   f0101787 <page_remove>
	assert(pp2->pp_ref == 0);
f010339b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01033a0:	74 24                	je     f01033c6 <mem_init+0x1b8f>
f01033a2:	c7 44 24 0c 8d 6b 10 	movl   $0xf0106b8d,0xc(%esp)
f01033a9:	f0 
f01033aa:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01033b1:	f0 
f01033b2:	c7 44 24 04 f4 03 00 	movl   $0x3f4,0x4(%esp)
f01033b9:	00 
f01033ba:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f01033c1:	e8 f0 cc ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01033c6:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f01033cb:	8b 08                	mov    (%eax),%ecx
f01033cd:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
}

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01033d3:	89 da                	mov    %ebx,%edx
f01033d5:	2b 15 ac fe 17 f0    	sub    0xf017feac,%edx
f01033db:	c1 fa 03             	sar    $0x3,%edx
f01033de:	c1 e2 0c             	shl    $0xc,%edx
f01033e1:	39 d1                	cmp    %edx,%ecx
f01033e3:	74 24                	je     f0103409 <mem_init+0x1bd2>
f01033e5:	c7 44 24 0c e8 63 10 	movl   $0xf01063e8,0xc(%esp)
f01033ec:	f0 
f01033ed:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01033f4:	f0 
f01033f5:	c7 44 24 04 f7 03 00 	movl   $0x3f7,0x4(%esp)
f01033fc:	00 
f01033fd:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0103404:	e8 ad cc ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f0103409:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010340f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0103414:	74 24                	je     f010343a <mem_init+0x1c03>
f0103416:	c7 44 24 0c 44 6b 10 	movl   $0xf0106b44,0xc(%esp)
f010341d:	f0 
f010341e:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f0103425:	f0 
f0103426:	c7 44 24 04 f9 03 00 	movl   $0x3f9,0x4(%esp)
f010342d:	00 
f010342e:	c7 04 24 65 69 10 f0 	movl   $0xf0106965,(%esp)
f0103435:	e8 7c cc ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f010343a:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0103440:	89 1c 24             	mov    %ebx,(%esp)
f0103443:	e8 fd e0 ff ff       	call   f0101545 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0103448:	c7 04 24 04 69 10 f0 	movl   $0xf0106904,(%esp)
f010344f:	e8 0f 09 00 00       	call   f0103d63 <cprintf>
f0103454:	eb 0f                	jmp    f0103465 <mem_init+0x1c2e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0103456:	89 f2                	mov    %esi,%edx
f0103458:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010345b:	e8 89 db ff ff       	call   f0100fe9 <check_va2pa>
f0103460:	e9 8e fa ff ff       	jmp    f0102ef3 <mem_init+0x16bc>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0103465:	83 c4 4c             	add    $0x4c,%esp
f0103468:	5b                   	pop    %ebx
f0103469:	5e                   	pop    %esi
f010346a:	5f                   	pop    %edi
f010346b:	5d                   	pop    %ebp
f010346c:	c3                   	ret    

f010346d <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010346d:	55                   	push   %ebp
f010346e:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0103470:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103473:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0103476:	5d                   	pop    %ebp
f0103477:	c3                   	ret    

f0103478 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0103478:	55                   	push   %ebp
f0103479:	89 e5                	mov    %esp,%ebp
f010347b:	57                   	push   %edi
f010347c:	56                   	push   %esi
f010347d:	53                   	push   %ebx
f010347e:	83 ec 2c             	sub    $0x2c,%esp
f0103481:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	if ((uintptr_t)va >= ULIM){
f0103484:	81 7d 0c ff ff 7f ef 	cmpl   $0xef7fffff,0xc(%ebp)
f010348b:	76 12                	jbe    f010349f <user_mem_check+0x27>
		user_mem_check_addr = (uintptr_t)va;
f010348d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103490:	a3 dc f1 17 f0       	mov    %eax,0xf017f1dc
		return -E_FAULT;
f0103495:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f010349a:	e9 8b 00 00 00       	jmp    f010352a <user_mem_check+0xb2>
	}
	uintptr_t start_addr = ROUNDDOWN((uintptr_t)va, PGSIZE);
f010349f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01034a2:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t end_addr = ROUNDUP((uintptr_t)va + len, PGSIZE);
f01034a8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034ab:	03 45 10             	add    0x10(%ebp),%eax
f01034ae:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01034b1:	05 ff 0f 00 00       	add    $0xfff,%eax
f01034b6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01034bb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (; start_addr < end_addr; start_addr += PGSIZE){
		pte_t *page_tab = pgdir_walk(env->env_pgdir, (void *)start_addr, 0);
		if ((*page_tab & (perm | PTE_P)) != (perm | PTE_P)){
f01034be:	8b 75 14             	mov    0x14(%ebp),%esi
f01034c1:	83 ce 01             	or     $0x1,%esi
		user_mem_check_addr = (uintptr_t)va;
		return -E_FAULT;
	}
	uintptr_t start_addr = ROUNDDOWN((uintptr_t)va, PGSIZE);
	uintptr_t end_addr = ROUNDUP((uintptr_t)va + len, PGSIZE);
	for (; start_addr < end_addr; start_addr += PGSIZE){
f01034c4:	eb 5a                	jmp    f0103520 <user_mem_check+0xa8>
		pte_t *page_tab = pgdir_walk(env->env_pgdir, (void *)start_addr, 0);
f01034c6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01034cd:	00 
f01034ce:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034d2:	8b 47 5c             	mov    0x5c(%edi),%eax
f01034d5:	89 04 24             	mov    %eax,(%esp)
f01034d8:	e8 cb e0 ff ff       	call   f01015a8 <pgdir_walk>
		if ((*page_tab & (perm | PTE_P)) != (perm | PTE_P)){
f01034dd:	89 f2                	mov    %esi,%edx
f01034df:	23 10                	and    (%eax),%edx
f01034e1:	39 d6                	cmp    %edx,%esi
f01034e3:	74 35                	je     f010351a <user_mem_check+0xa2>
			if (start_addr <= (uintptr_t)va){
f01034e5:	39 5d 0c             	cmp    %ebx,0xc(%ebp)
f01034e8:	72 0f                	jb     f01034f9 <user_mem_check+0x81>
				user_mem_check_addr = (uintptr_t)va;
f01034ea:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034ed:	a3 dc f1 17 f0       	mov    %eax,0xf017f1dc
			}else if (start_addr >= (uintptr_t)va + len){
				user_mem_check_addr = (uintptr_t)va + len;
			}else{
				user_mem_check_addr = start_addr;
			}
			return -E_FAULT;
f01034f2:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01034f7:	eb 31                	jmp    f010352a <user_mem_check+0xb2>
	for (; start_addr < end_addr; start_addr += PGSIZE){
		pte_t *page_tab = pgdir_walk(env->env_pgdir, (void *)start_addr, 0);
		if ((*page_tab & (perm | PTE_P)) != (perm | PTE_P)){
			if (start_addr <= (uintptr_t)va){
				user_mem_check_addr = (uintptr_t)va;
			}else if (start_addr >= (uintptr_t)va + len){
f01034f9:	39 5d e0             	cmp    %ebx,-0x20(%ebp)
f01034fc:	77 0f                	ja     f010350d <user_mem_check+0x95>
				user_mem_check_addr = (uintptr_t)va + len;
f01034fe:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103501:	a3 dc f1 17 f0       	mov    %eax,0xf017f1dc
			}else{
				user_mem_check_addr = start_addr;
			}
			return -E_FAULT;
f0103506:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f010350b:	eb 1d                	jmp    f010352a <user_mem_check+0xb2>
			if (start_addr <= (uintptr_t)va){
				user_mem_check_addr = (uintptr_t)va;
			}else if (start_addr >= (uintptr_t)va + len){
				user_mem_check_addr = (uintptr_t)va + len;
			}else{
				user_mem_check_addr = start_addr;
f010350d:	89 1d dc f1 17 f0    	mov    %ebx,0xf017f1dc
			}
			return -E_FAULT;
f0103513:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0103518:	eb 10                	jmp    f010352a <user_mem_check+0xb2>
		user_mem_check_addr = (uintptr_t)va;
		return -E_FAULT;
	}
	uintptr_t start_addr = ROUNDDOWN((uintptr_t)va, PGSIZE);
	uintptr_t end_addr = ROUNDUP((uintptr_t)va + len, PGSIZE);
	for (; start_addr < end_addr; start_addr += PGSIZE){
f010351a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0103520:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0103523:	72 a1                	jb     f01034c6 <user_mem_check+0x4e>
				user_mem_check_addr = start_addr;
			}
			return -E_FAULT;
		}
	}
	return 0;
f0103525:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010352a:	83 c4 2c             	add    $0x2c,%esp
f010352d:	5b                   	pop    %ebx
f010352e:	5e                   	pop    %esi
f010352f:	5f                   	pop    %edi
f0103530:	5d                   	pop    %ebp
f0103531:	c3                   	ret    

f0103532 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0103532:	55                   	push   %ebp
f0103533:	89 e5                	mov    %esp,%ebp
f0103535:	53                   	push   %ebx
f0103536:	83 ec 14             	sub    $0x14,%esp
f0103539:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f010353c:	8b 45 14             	mov    0x14(%ebp),%eax
f010353f:	83 c8 04             	or     $0x4,%eax
f0103542:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103546:	8b 45 10             	mov    0x10(%ebp),%eax
f0103549:	89 44 24 08          	mov    %eax,0x8(%esp)
f010354d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103550:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103554:	89 1c 24             	mov    %ebx,(%esp)
f0103557:	e8 1c ff ff ff       	call   f0103478 <user_mem_check>
f010355c:	85 c0                	test   %eax,%eax
f010355e:	79 24                	jns    f0103584 <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f0103560:	a1 dc f1 17 f0       	mov    0xf017f1dc,%eax
f0103565:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103569:	8b 43 48             	mov    0x48(%ebx),%eax
f010356c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103570:	c7 04 24 30 69 10 f0 	movl   $0xf0106930,(%esp)
f0103577:	e8 e7 07 00 00       	call   f0103d63 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f010357c:	89 1c 24             	mov    %ebx,(%esp)
f010357f:	e8 ac 06 00 00       	call   f0103c30 <env_destroy>
	}
}
f0103584:	83 c4 14             	add    $0x14,%esp
f0103587:	5b                   	pop    %ebx
f0103588:	5d                   	pop    %ebp
f0103589:	c3                   	ret    

f010358a <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f010358a:	55                   	push   %ebp
f010358b:	89 e5                	mov    %esp,%ebp
f010358d:	57                   	push   %edi
f010358e:	56                   	push   %esi
f010358f:	53                   	push   %ebx
f0103590:	83 ec 1c             	sub    $0x1c,%esp
f0103593:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t start_addr = (uintptr_t)ROUNDDOWN(va, PGSIZE);
f0103595:	89 d3                	mov    %edx,%ebx
f0103597:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t end_addr = (uintptr_t)ROUNDUP(va + len, PGSIZE);
f010359d:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01035a4:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

	for(; start_addr < end_addr; start_addr += PGSIZE){
f01035aa:	eb 6d                	jmp    f0103619 <region_alloc+0x8f>
		struct PageInfo *page = page_alloc(ALLOC_ZERO);
f01035ac:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01035b3:	e8 02 df ff ff       	call   f01014ba <page_alloc>
		if(!page)
f01035b8:	85 c0                	test   %eax,%eax
f01035ba:	75 1c                	jne    f01035d8 <region_alloc+0x4e>
			panic("out of memory when allocing region!");
f01035bc:	c7 44 24 08 48 6c 10 	movl   $0xf0106c48,0x8(%esp)
f01035c3:	f0 
f01035c4:	c7 44 24 04 24 01 00 	movl   $0x124,0x4(%esp)
f01035cb:	00 
f01035cc:	c7 04 24 c2 6c 10 f0 	movl   $0xf0106cc2,(%esp)
f01035d3:	e8 de ca ff ff       	call   f01000b6 <_panic>
		if(page_insert(e->env_pgdir, page, (void *)start_addr, PTE_U | PTE_W | PTE_P) < 0)
f01035d8:	c7 44 24 0c 07 00 00 	movl   $0x7,0xc(%esp)
f01035df:	00 
f01035e0:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01035e4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035e8:	8b 47 5c             	mov    0x5c(%edi),%eax
f01035eb:	89 04 24             	mov    %eax,(%esp)
f01035ee:	e8 d2 e1 ff ff       	call   f01017c5 <page_insert>
f01035f3:	85 c0                	test   %eax,%eax
f01035f5:	79 1c                	jns    f0103613 <region_alloc+0x89>
			panic("fail when inserting page!");
f01035f7:	c7 44 24 08 cd 6c 10 	movl   $0xf0106ccd,0x8(%esp)
f01035fe:	f0 
f01035ff:	c7 44 24 04 26 01 00 	movl   $0x126,0x4(%esp)
f0103606:	00 
f0103607:	c7 04 24 c2 6c 10 f0 	movl   $0xf0106cc2,(%esp)
f010360e:	e8 a3 ca ff ff       	call   f01000b6 <_panic>
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t start_addr = (uintptr_t)ROUNDDOWN(va, PGSIZE);
	uintptr_t end_addr = (uintptr_t)ROUNDUP(va + len, PGSIZE);

	for(; start_addr < end_addr; start_addr += PGSIZE){
f0103613:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0103619:	39 f3                	cmp    %esi,%ebx
f010361b:	72 8f                	jb     f01035ac <region_alloc+0x22>
		if(!page)
			panic("out of memory when allocing region!");
		if(page_insert(e->env_pgdir, page, (void *)start_addr, PTE_U | PTE_W | PTE_P) < 0)
			panic("fail when inserting page!");
	}
}
f010361d:	83 c4 1c             	add    $0x1c,%esp
f0103620:	5b                   	pop    %ebx
f0103621:	5e                   	pop    %esi
f0103622:	5f                   	pop    %edi
f0103623:	5d                   	pop    %ebp
f0103624:	c3                   	ret    

f0103625 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0103625:	55                   	push   %ebp
f0103626:	89 e5                	mov    %esp,%ebp
f0103628:	8b 45 08             	mov    0x8(%ebp),%eax
f010362b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f010362e:	85 c0                	test   %eax,%eax
f0103630:	75 11                	jne    f0103643 <envid2env+0x1e>
		*env_store = curenv;
f0103632:	a1 e8 f1 17 f0       	mov    0xf017f1e8,%eax
f0103637:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010363a:	89 01                	mov    %eax,(%ecx)
		return 0;
f010363c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103641:	eb 5e                	jmp    f01036a1 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103643:	89 c2                	mov    %eax,%edx
f0103645:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010364b:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010364e:	c1 e2 05             	shl    $0x5,%edx
f0103651:	03 15 ec f1 17 f0    	add    0xf017f1ec,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103657:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f010365b:	74 05                	je     f0103662 <envid2env+0x3d>
f010365d:	39 42 48             	cmp    %eax,0x48(%edx)
f0103660:	74 10                	je     f0103672 <envid2env+0x4d>
		*env_store = 0;
f0103662:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103665:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010366b:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103670:	eb 2f                	jmp    f01036a1 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103672:	84 c9                	test   %cl,%cl
f0103674:	74 21                	je     f0103697 <envid2env+0x72>
f0103676:	a1 e8 f1 17 f0       	mov    0xf017f1e8,%eax
f010367b:	39 c2                	cmp    %eax,%edx
f010367d:	74 18                	je     f0103697 <envid2env+0x72>
f010367f:	8b 40 48             	mov    0x48(%eax),%eax
f0103682:	39 42 4c             	cmp    %eax,0x4c(%edx)
f0103685:	74 10                	je     f0103697 <envid2env+0x72>
		*env_store = 0;
f0103687:	8b 45 0c             	mov    0xc(%ebp),%eax
f010368a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103690:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103695:	eb 0a                	jmp    f01036a1 <envid2env+0x7c>
	}

	*env_store = e;
f0103697:	8b 45 0c             	mov    0xc(%ebp),%eax
f010369a:	89 10                	mov    %edx,(%eax)
	return 0;
f010369c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01036a1:	5d                   	pop    %ebp
f01036a2:	c3                   	ret    

f01036a3 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01036a3:	55                   	push   %ebp
f01036a4:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f01036a6:	b8 00 d3 11 f0       	mov    $0xf011d300,%eax
f01036ab:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.11
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f01036ae:	b8 23 00 00 00       	mov    $0x23,%eax
f01036b3:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f01036b5:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f01036b7:	b0 10                	mov    $0x10,%al
f01036b9:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01036bb:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01036bd:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01036bf:	ea c6 36 10 f0 08 00 	ljmp   $0x8,$0xf01036c6
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f01036c6:	b0 00                	mov    $0x0,%al
f01036c8:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01036cb:	5d                   	pop    %ebp
f01036cc:	c3                   	ret    

f01036cd <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01036cd:	55                   	push   %ebp
f01036ce:	89 e5                	mov    %esp,%ebp
f01036d0:	56                   	push   %esi
f01036d1:	53                   	push   %ebx
	// LAB 3: Your code here
	env_free_list = NULL;
	uint32_t i = NENV;
	while (i > 0){
		i--;
		envs[i].env_id = 0;
f01036d2:	8b 35 ec f1 17 f0    	mov    0xf017f1ec,%esi
f01036d8:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f01036de:	ba 00 04 00 00       	mov    $0x400,%edx
f01036e3:	b9 00 00 00 00       	mov    $0x0,%ecx
f01036e8:	89 c3                	mov    %eax,%ebx
f01036ea:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f01036f1:	89 48 44             	mov    %ecx,0x44(%eax)
f01036f4:	83 e8 60             	sub    $0x60,%eax
{
	// Set up envs array
	// LAB 3: Your code here
	env_free_list = NULL;
	uint32_t i = NENV;
	while (i > 0){
f01036f7:	83 ea 01             	sub    $0x1,%edx
f01036fa:	74 04                	je     f0103700 <env_init+0x33>
		i--;
		envs[i].env_id = 0;
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
f01036fc:	89 d9                	mov    %ebx,%ecx
f01036fe:	eb e8                	jmp    f01036e8 <env_init+0x1b>
f0103700:	89 35 f0 f1 17 f0    	mov    %esi,0xf017f1f0
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f0103706:	e8 98 ff ff ff       	call   f01036a3 <env_init_percpu>
}
f010370b:	5b                   	pop    %ebx
f010370c:	5e                   	pop    %esi
f010370d:	5d                   	pop    %ebp
f010370e:	c3                   	ret    

f010370f <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f010370f:	55                   	push   %ebp
f0103710:	89 e5                	mov    %esp,%ebp
f0103712:	53                   	push   %ebx
f0103713:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103716:	8b 1d f0 f1 17 f0    	mov    0xf017f1f0,%ebx
f010371c:	85 db                	test   %ebx,%ebx
f010371e:	0f 84 8e 01 00 00    	je     f01038b2 <env_alloc+0x1a3>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103724:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010372b:	e8 8a dd ff ff       	call   f01014ba <page_alloc>
f0103730:	85 c0                	test   %eax,%eax
f0103732:	0f 84 81 01 00 00    	je     f01038b9 <env_alloc+0x1aa>
f0103738:	89 c2                	mov    %eax,%edx
f010373a:	2b 15 ac fe 17 f0    	sub    0xf017feac,%edx
f0103740:	c1 fa 03             	sar    $0x3,%edx
f0103743:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103746:	89 d1                	mov    %edx,%ecx
f0103748:	c1 e9 0c             	shr    $0xc,%ecx
f010374b:	3b 0d a4 fe 17 f0    	cmp    0xf017fea4,%ecx
f0103751:	72 20                	jb     f0103773 <env_alloc+0x64>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103753:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103757:	c7 44 24 08 40 61 10 	movl   $0xf0106140,0x8(%esp)
f010375e:	f0 
f010375f:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f0103766:	00 
f0103767:	c7 04 24 71 69 10 f0 	movl   $0xf0106971,(%esp)
f010376e:	e8 43 c9 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0103773:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0103779:	89 53 5c             	mov    %edx,0x5c(%ebx)
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = (pde_t *)page2kva(p);
	p->pp_ref++;
f010377c:	66 83 40 04 01       	addw   $0x1,0x4(%eax)

	for (i = 0; i < PDX(UTOP); i++)
f0103781:	b8 00 00 00 00       	mov    $0x0,%eax
f0103786:	ba 00 00 00 00       	mov    $0x0,%edx
		e->env_pgdir[i] = 0;
f010378b:	8b 4b 5c             	mov    0x5c(%ebx),%ecx
f010378e:	c7 04 91 00 00 00 00 	movl   $0x0,(%ecx,%edx,4)

	// LAB 3: Your code here.
	e->env_pgdir = (pde_t *)page2kva(p);
	p->pp_ref++;

	for (i = 0; i < PDX(UTOP); i++)
f0103795:	83 c0 01             	add    $0x1,%eax
f0103798:	89 c2                	mov    %eax,%edx
f010379a:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010379f:	75 ea                	jne    f010378b <env_alloc+0x7c>
f01037a1:	66 b8 ec 0e          	mov    $0xeec,%ax
		e->env_pgdir[i] = 0;
	for (i = PDX(UTOP); i < NPDENTRIES; i++)
		e->env_pgdir[i] = kern_pgdir[i];
f01037a5:	8b 15 a8 fe 17 f0    	mov    0xf017fea8,%edx
f01037ab:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f01037ae:	8b 53 5c             	mov    0x5c(%ebx),%edx
f01037b1:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f01037b4:	83 c0 04             	add    $0x4,%eax
	e->env_pgdir = (pde_t *)page2kva(p);
	p->pp_ref++;

	for (i = 0; i < PDX(UTOP); i++)
		e->env_pgdir[i] = 0;
	for (i = PDX(UTOP); i < NPDENTRIES; i++)
f01037b7:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01037bc:	75 e7                	jne    f01037a5 <env_alloc+0x96>
		e->env_pgdir[i] = kern_pgdir[i];

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01037be:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01037c1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01037c6:	77 20                	ja     f01037e8 <env_alloc+0xd9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01037c8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01037cc:	c7 44 24 08 64 62 10 	movl   $0xf0106264,0x8(%esp)
f01037d3:	f0 
f01037d4:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
f01037db:	00 
f01037dc:	c7 04 24 c2 6c 10 f0 	movl   $0xf0106cc2,(%esp)
f01037e3:	e8 ce c8 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01037e8:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01037ee:	83 ca 05             	or     $0x5,%edx
f01037f1:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01037f7:	8b 43 48             	mov    0x48(%ebx),%eax
f01037fa:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01037ff:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103804:	ba 00 10 00 00       	mov    $0x1000,%edx
f0103809:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010380c:	89 da                	mov    %ebx,%edx
f010380e:	2b 15 ec f1 17 f0    	sub    0xf017f1ec,%edx
f0103814:	c1 fa 05             	sar    $0x5,%edx
f0103817:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010381d:	09 d0                	or     %edx,%eax
f010381f:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103822:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103825:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103828:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f010382f:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103836:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010383d:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103844:	00 
f0103845:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010384c:	00 
f010384d:	89 1c 24             	mov    %ebx,(%esp)
f0103850:	e8 52 1a 00 00       	call   f01052a7 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103855:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f010385b:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103861:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103867:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f010386e:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0103874:	8b 43 44             	mov    0x44(%ebx),%eax
f0103877:	a3 f0 f1 17 f0       	mov    %eax,0xf017f1f0
	*newenv_store = e;
f010387c:	8b 45 08             	mov    0x8(%ebp),%eax
f010387f:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103881:	8b 53 48             	mov    0x48(%ebx),%edx
f0103884:	a1 e8 f1 17 f0       	mov    0xf017f1e8,%eax
f0103889:	85 c0                	test   %eax,%eax
f010388b:	74 05                	je     f0103892 <env_alloc+0x183>
f010388d:	8b 40 48             	mov    0x48(%eax),%eax
f0103890:	eb 05                	jmp    f0103897 <env_alloc+0x188>
f0103892:	b8 00 00 00 00       	mov    $0x0,%eax
f0103897:	89 54 24 08          	mov    %edx,0x8(%esp)
f010389b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010389f:	c7 04 24 e7 6c 10 f0 	movl   $0xf0106ce7,(%esp)
f01038a6:	e8 b8 04 00 00       	call   f0103d63 <cprintf>
	return 0;
f01038ab:	b8 00 00 00 00       	mov    $0x0,%eax
f01038b0:	eb 0c                	jmp    f01038be <env_alloc+0x1af>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01038b2:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01038b7:	eb 05                	jmp    f01038be <env_alloc+0x1af>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f01038b9:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01038be:	83 c4 14             	add    $0x14,%esp
f01038c1:	5b                   	pop    %ebx
f01038c2:	5d                   	pop    %ebp
f01038c3:	c3                   	ret    

f01038c4 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01038c4:	55                   	push   %ebp
f01038c5:	89 e5                	mov    %esp,%ebp
f01038c7:	57                   	push   %edi
f01038c8:	56                   	push   %esi
f01038c9:	53                   	push   %ebx
f01038ca:	83 ec 3c             	sub    $0x3c,%esp
f01038cd:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *newEnv;
	if (env_alloc(&newEnv, 0) < 0)
f01038d0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01038d7:	00 
f01038d8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01038db:	89 04 24             	mov    %eax,(%esp)
f01038de:	e8 2c fe ff ff       	call   f010370f <env_alloc>
f01038e3:	85 c0                	test   %eax,%eax
f01038e5:	79 1c                	jns    f0103903 <env_create+0x3f>
		panic("fail to alloc env!");
f01038e7:	c7 44 24 08 fc 6c 10 	movl   $0xf0106cfc,0x8(%esp)
f01038ee:	f0 
f01038ef:	c7 44 24 04 8d 01 00 	movl   $0x18d,0x4(%esp)
f01038f6:	00 
f01038f7:	c7 04 24 c2 6c 10 f0 	movl   $0xf0106cc2,(%esp)
f01038fe:	e8 b3 c7 ff ff       	call   f01000b6 <_panic>
	load_icode(newEnv, binary);
f0103903:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103906:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// LAB 3: Your code here.
	// Use lcr3() to switch to its address space.
	// switch address space for loading program segments

	struct Elf *ELFHeader = (struct Elf *)binary;
	if (ELFHeader->e_magic != ELF_MAGIC)
f0103909:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f010390f:	74 1c                	je     f010392d <env_create+0x69>
		panic("the binary is not elg!\n");
f0103911:	c7 44 24 08 0f 6d 10 	movl   $0xf0106d0f,0x8(%esp)
f0103918:	f0 
f0103919:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
f0103920:	00 
f0103921:	c7 04 24 c2 6c 10 f0 	movl   $0xf0106cc2,(%esp)
f0103928:	e8 89 c7 ff ff       	call   f01000b6 <_panic>

	struct Proghdr *ph, *eph;
	ph = (struct Proghdr *)(binary + ELFHeader->e_phoff);
f010392d:	89 fb                	mov    %edi,%ebx
f010392f:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHeader->e_phnum;
f0103932:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103936:	c1 e6 05             	shl    $0x5,%esi
f0103939:	01 de                	add    %ebx,%esi

	lcr3(PADDR(e->env_pgdir));
f010393b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010393e:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103941:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103946:	77 20                	ja     f0103968 <env_create+0xa4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103948:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010394c:	c7 44 24 08 64 62 10 	movl   $0xf0106264,0x8(%esp)
f0103953:	f0 
f0103954:	c7 44 24 04 6b 01 00 	movl   $0x16b,0x4(%esp)
f010395b:	00 
f010395c:	c7 04 24 c2 6c 10 f0 	movl   $0xf0106cc2,(%esp)
f0103963:	e8 4e c7 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103968:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010396d:	0f 22 d8             	mov    %eax,%cr3
f0103970:	eb 6c                	jmp    f01039de <env_create+0x11a>
	for (; ph < eph; ph ++){
		if (ph->p_type == ELF_PROG_LOAD){
f0103972:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103975:	75 64                	jne    f01039db <env_create+0x117>
			if (ph->p_filesz > ph->p_memsz)
f0103977:	8b 4b 14             	mov    0x14(%ebx),%ecx
f010397a:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f010397d:	76 1c                	jbe    f010399b <env_create+0xd7>
				panic("file size overflow memory size!");
f010397f:	c7 44 24 08 6c 6c 10 	movl   $0xf0106c6c,0x8(%esp)
f0103986:	f0 
f0103987:	c7 44 24 04 6f 01 00 	movl   $0x16f,0x4(%esp)
f010398e:	00 
f010398f:	c7 04 24 c2 6c 10 f0 	movl   $0xf0106cc2,(%esp)
f0103996:	e8 1b c7 ff ff       	call   f01000b6 <_panic>
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f010399b:	8b 53 08             	mov    0x8(%ebx),%edx
f010399e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01039a1:	e8 e4 fb ff ff       	call   f010358a <region_alloc>
			memset((void *)ph->p_va, 0, ph->p_memsz);
f01039a6:	8b 43 14             	mov    0x14(%ebx),%eax
f01039a9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01039ad:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01039b4:	00 
f01039b5:	8b 43 08             	mov    0x8(%ebx),%eax
f01039b8:	89 04 24             	mov    %eax,(%esp)
f01039bb:	e8 e7 18 00 00       	call   f01052a7 <memset>
			memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f01039c0:	8b 43 10             	mov    0x10(%ebx),%eax
f01039c3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01039c7:	89 f8                	mov    %edi,%eax
f01039c9:	03 43 04             	add    0x4(%ebx),%eax
f01039cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039d0:	8b 43 08             	mov    0x8(%ebx),%eax
f01039d3:	89 04 24             	mov    %eax,(%esp)
f01039d6:	e8 81 19 00 00       	call   f010535c <memcpy>
	struct Proghdr *ph, *eph;
	ph = (struct Proghdr *)(binary + ELFHeader->e_phoff);
	eph = ph + ELFHeader->e_phnum;

	lcr3(PADDR(e->env_pgdir));
	for (; ph < eph; ph ++){
f01039db:	83 c3 20             	add    $0x20,%ebx
f01039de:	39 de                	cmp    %ebx,%esi
f01039e0:	77 90                	ja     f0103972 <env_create+0xae>
			memset((void *)ph->p_va, 0, ph->p_memsz);
			memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
		}
	}

	e->env_tf.tf_eip = ELFHeader->e_entry;
f01039e2:	8b 47 18             	mov    0x18(%edi),%eax
f01039e5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01039e8:	89 47 30             	mov    %eax,0x30(%edi)

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *)(USTACKTOP - PGSIZE), PGSIZE);
f01039eb:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01039f0:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01039f5:	89 f8                	mov    %edi,%eax
f01039f7:	e8 8e fb ff ff       	call   f010358a <region_alloc>
	lcr3(PADDR(kern_pgdir));
f01039fc:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103a01:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103a06:	77 20                	ja     f0103a28 <env_create+0x164>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103a08:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103a0c:	c7 44 24 08 64 62 10 	movl   $0xf0106264,0x8(%esp)
f0103a13:	f0 
f0103a14:	c7 44 24 04 7d 01 00 	movl   $0x17d,0x4(%esp)
f0103a1b:	00 
f0103a1c:	c7 04 24 c2 6c 10 f0 	movl   $0xf0106cc2,(%esp)
f0103a23:	e8 8e c6 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103a28:	05 00 00 00 10       	add    $0x10000000,%eax
f0103a2d:	0f 22 d8             	mov    %eax,%cr3
	// LAB 3: Your code here.
	struct Env *newEnv;
	if (env_alloc(&newEnv, 0) < 0)
		panic("fail to alloc env!");
	load_icode(newEnv, binary);
	newEnv->env_type = type;
f0103a30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a33:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a36:	89 50 50             	mov    %edx,0x50(%eax)
	newEnv->env_parent_id = 0;
f0103a39:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
}
f0103a40:	83 c4 3c             	add    $0x3c,%esp
f0103a43:	5b                   	pop    %ebx
f0103a44:	5e                   	pop    %esi
f0103a45:	5f                   	pop    %edi
f0103a46:	5d                   	pop    %ebp
f0103a47:	c3                   	ret    

f0103a48 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103a48:	55                   	push   %ebp
f0103a49:	89 e5                	mov    %esp,%ebp
f0103a4b:	57                   	push   %edi
f0103a4c:	56                   	push   %esi
f0103a4d:	53                   	push   %ebx
f0103a4e:	83 ec 2c             	sub    $0x2c,%esp
f0103a51:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103a54:	a1 e8 f1 17 f0       	mov    0xf017f1e8,%eax
f0103a59:	39 c7                	cmp    %eax,%edi
f0103a5b:	75 37                	jne    f0103a94 <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f0103a5d:	8b 15 a8 fe 17 f0    	mov    0xf017fea8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103a63:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103a69:	77 20                	ja     f0103a8b <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103a6b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103a6f:	c7 44 24 08 64 62 10 	movl   $0xf0106264,0x8(%esp)
f0103a76:	f0 
f0103a77:	c7 44 24 04 a1 01 00 	movl   $0x1a1,0x4(%esp)
f0103a7e:	00 
f0103a7f:	c7 04 24 c2 6c 10 f0 	movl   $0xf0106cc2,(%esp)
f0103a86:	e8 2b c6 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103a8b:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103a91:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103a94:	8b 57 48             	mov    0x48(%edi),%edx
f0103a97:	85 c0                	test   %eax,%eax
f0103a99:	74 05                	je     f0103aa0 <env_free+0x58>
f0103a9b:	8b 40 48             	mov    0x48(%eax),%eax
f0103a9e:	eb 05                	jmp    f0103aa5 <env_free+0x5d>
f0103aa0:	b8 00 00 00 00       	mov    $0x0,%eax
f0103aa5:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103aa9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103aad:	c7 04 24 27 6d 10 f0 	movl   $0xf0106d27,(%esp)
f0103ab4:	e8 aa 02 00 00       	call   f0103d63 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103ab9:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103ac0:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103ac3:	89 c8                	mov    %ecx,%eax
f0103ac5:	c1 e0 02             	shl    $0x2,%eax
f0103ac8:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103acb:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103ace:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f0103ad1:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103ad7:	0f 84 b7 00 00 00    	je     f0103b94 <env_free+0x14c>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103add:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103ae3:	89 f0                	mov    %esi,%eax
f0103ae5:	c1 e8 0c             	shr    $0xc,%eax
f0103ae8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103aeb:	3b 05 a4 fe 17 f0    	cmp    0xf017fea4,%eax
f0103af1:	72 20                	jb     f0103b13 <env_free+0xcb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103af3:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103af7:	c7 44 24 08 40 61 10 	movl   $0xf0106140,0x8(%esp)
f0103afe:	f0 
f0103aff:	c7 44 24 04 b0 01 00 	movl   $0x1b0,0x4(%esp)
f0103b06:	00 
f0103b07:	c7 04 24 c2 6c 10 f0 	movl   $0xf0106cc2,(%esp)
f0103b0e:	e8 a3 c5 ff ff       	call   f01000b6 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103b13:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103b16:	c1 e0 16             	shl    $0x16,%eax
f0103b19:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103b1c:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103b21:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103b28:	01 
f0103b29:	74 17                	je     f0103b42 <env_free+0xfa>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103b2b:	89 d8                	mov    %ebx,%eax
f0103b2d:	c1 e0 0c             	shl    $0xc,%eax
f0103b30:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103b33:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b37:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103b3a:	89 04 24             	mov    %eax,(%esp)
f0103b3d:	e8 45 dc ff ff       	call   f0101787 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103b42:	83 c3 01             	add    $0x1,%ebx
f0103b45:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103b4b:	75 d4                	jne    f0103b21 <env_free+0xd9>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103b4d:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103b50:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103b53:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103b5a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103b5d:	3b 05 a4 fe 17 f0    	cmp    0xf017fea4,%eax
f0103b63:	72 1c                	jb     f0103b81 <env_free+0x139>
		panic("pa2page called with invalid pa");
f0103b65:	c7 44 24 08 b4 62 10 	movl   $0xf01062b4,0x8(%esp)
f0103b6c:	f0 
f0103b6d:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0103b74:	00 
f0103b75:	c7 04 24 71 69 10 f0 	movl   $0xf0106971,(%esp)
f0103b7c:	e8 35 c5 ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f0103b81:	a1 ac fe 17 f0       	mov    0xf017feac,%eax
f0103b86:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103b89:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f0103b8c:	89 04 24             	mov    %eax,(%esp)
f0103b8f:	e8 f1 d9 ff ff       	call   f0101585 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103b94:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103b98:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103b9f:	0f 85 1b ff ff ff    	jne    f0103ac0 <env_free+0x78>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103ba5:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103ba8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103bad:	77 20                	ja     f0103bcf <env_free+0x187>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103baf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103bb3:	c7 44 24 08 64 62 10 	movl   $0xf0106264,0x8(%esp)
f0103bba:	f0 
f0103bbb:	c7 44 24 04 be 01 00 	movl   $0x1be,0x4(%esp)
f0103bc2:	00 
f0103bc3:	c7 04 24 c2 6c 10 f0 	movl   $0xf0106cc2,(%esp)
f0103bca:	e8 e7 c4 ff ff       	call   f01000b6 <_panic>
	e->env_pgdir = 0;
f0103bcf:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103bd6:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103bdb:	c1 e8 0c             	shr    $0xc,%eax
f0103bde:	3b 05 a4 fe 17 f0    	cmp    0xf017fea4,%eax
f0103be4:	72 1c                	jb     f0103c02 <env_free+0x1ba>
		panic("pa2page called with invalid pa");
f0103be6:	c7 44 24 08 b4 62 10 	movl   $0xf01062b4,0x8(%esp)
f0103bed:	f0 
f0103bee:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0103bf5:	00 
f0103bf6:	c7 04 24 71 69 10 f0 	movl   $0xf0106971,(%esp)
f0103bfd:	e8 b4 c4 ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f0103c02:	8b 15 ac fe 17 f0    	mov    0xf017feac,%edx
f0103c08:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f0103c0b:	89 04 24             	mov    %eax,(%esp)
f0103c0e:	e8 72 d9 ff ff       	call   f0101585 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103c13:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103c1a:	a1 f0 f1 17 f0       	mov    0xf017f1f0,%eax
f0103c1f:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103c22:	89 3d f0 f1 17 f0    	mov    %edi,0xf017f1f0
}
f0103c28:	83 c4 2c             	add    $0x2c,%esp
f0103c2b:	5b                   	pop    %ebx
f0103c2c:	5e                   	pop    %esi
f0103c2d:	5f                   	pop    %edi
f0103c2e:	5d                   	pop    %ebp
f0103c2f:	c3                   	ret    

f0103c30 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0103c30:	55                   	push   %ebp
f0103c31:	89 e5                	mov    %esp,%ebp
f0103c33:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f0103c36:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c39:	89 04 24             	mov    %eax,(%esp)
f0103c3c:	e8 07 fe ff ff       	call   f0103a48 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0103c41:	c7 04 24 8c 6c 10 f0 	movl   $0xf0106c8c,(%esp)
f0103c48:	e8 16 01 00 00       	call   f0103d63 <cprintf>
	while (1)
		monitor(NULL);
f0103c4d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103c54:	e8 2b d1 ff ff       	call   f0100d84 <monitor>
f0103c59:	eb f2                	jmp    f0103c4d <env_destroy+0x1d>

f0103c5b <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103c5b:	55                   	push   %ebp
f0103c5c:	89 e5                	mov    %esp,%ebp
f0103c5e:	83 ec 18             	sub    $0x18,%esp
	asm volatile(
f0103c61:	8b 65 08             	mov    0x8(%ebp),%esp
f0103c64:	61                   	popa   
f0103c65:	07                   	pop    %es
f0103c66:	1f                   	pop    %ds
f0103c67:	83 c4 08             	add    $0x8,%esp
f0103c6a:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103c6b:	c7 44 24 08 3d 6d 10 	movl   $0xf0106d3d,0x8(%esp)
f0103c72:	f0 
f0103c73:	c7 44 24 04 e7 01 00 	movl   $0x1e7,0x4(%esp)
f0103c7a:	00 
f0103c7b:	c7 04 24 c2 6c 10 f0 	movl   $0xf0106cc2,(%esp)
f0103c82:	e8 2f c4 ff ff       	call   f01000b6 <_panic>

f0103c87 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103c87:	55                   	push   %ebp
f0103c88:	89 e5                	mov    %esp,%ebp
f0103c8a:	83 ec 18             	sub    $0x18,%esp
f0103c8d:	8b 45 08             	mov    0x8(%ebp),%eax
	//	      what other states it can be in),
	//	   2. Set 'curenv' to the new environment,
	//	   3. Set its status to ENV_RUNNING,
	//	   4. Update its 'env_runs' counter,
	//	   5. Use lcr3() to switch to its address space.
	if (curenv != NULL && curenv->env_status == ENV_RUNNING)
f0103c90:	8b 15 e8 f1 17 f0    	mov    0xf017f1e8,%edx
f0103c96:	85 d2                	test   %edx,%edx
f0103c98:	74 0d                	je     f0103ca7 <env_run+0x20>
f0103c9a:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0103c9e:	75 07                	jne    f0103ca7 <env_run+0x20>
		curenv->env_status = ENV_RUNNABLE;
f0103ca0:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)

	curenv = e;
f0103ca7:	a3 e8 f1 17 f0       	mov    %eax,0xf017f1e8
	e->env_status = ENV_RUNNING;
f0103cac:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++;
f0103cb3:	83 40 58 01          	addl   $0x1,0x58(%eax)

	lcr3(PADDR(e->env_pgdir));
f0103cb7:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103cba:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103cc0:	77 20                	ja     f0103ce2 <env_run+0x5b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103cc2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103cc6:	c7 44 24 08 64 62 10 	movl   $0xf0106264,0x8(%esp)
f0103ccd:	f0 
f0103cce:	c7 44 24 04 08 02 00 	movl   $0x208,0x4(%esp)
f0103cd5:	00 
f0103cd6:	c7 04 24 c2 6c 10 f0 	movl   $0xf0106cc2,(%esp)
f0103cdd:	e8 d4 c3 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103ce2:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103ce8:	0f 22 da             	mov    %edx,%cr3

	// Step 2: Use env_pop_tf() to restore the envi ronment's
	//	   registers and drop into user mode in the
	//	   environment.
	env_pop_tf(&(e->env_tf));
f0103ceb:	89 04 24             	mov    %eax,(%esp)
f0103cee:	e8 68 ff ff ff       	call   f0103c5b <env_pop_tf>

f0103cf3 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103cf3:	55                   	push   %ebp
f0103cf4:	89 e5                	mov    %esp,%ebp
f0103cf6:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103cfa:	ba 70 00 00 00       	mov    $0x70,%edx
f0103cff:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103d00:	b2 71                	mov    $0x71,%dl
f0103d02:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103d03:	0f b6 c0             	movzbl %al,%eax
}
f0103d06:	5d                   	pop    %ebp
f0103d07:	c3                   	ret    

f0103d08 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103d08:	55                   	push   %ebp
f0103d09:	89 e5                	mov    %esp,%ebp
f0103d0b:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103d0f:	ba 70 00 00 00       	mov    $0x70,%edx
f0103d14:	ee                   	out    %al,(%dx)
f0103d15:	b2 71                	mov    $0x71,%dl
f0103d17:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103d1a:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103d1b:	5d                   	pop    %ebp
f0103d1c:	c3                   	ret    

f0103d1d <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103d1d:	55                   	push   %ebp
f0103d1e:	89 e5                	mov    %esp,%ebp
f0103d20:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0103d23:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d26:	89 04 24             	mov    %eax,(%esp)
f0103d29:	e8 f3 c8 ff ff       	call   f0100621 <cputchar>
	*cnt++;
}
f0103d2e:	c9                   	leave  
f0103d2f:	c3                   	ret    

f0103d30 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103d30:	55                   	push   %ebp
f0103d31:	89 e5                	mov    %esp,%ebp
f0103d33:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0103d36:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103d3d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103d40:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103d44:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d47:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103d4b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103d4e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d52:	c7 04 24 1d 3d 10 f0 	movl   $0xf0103d1d,(%esp)
f0103d59:	e8 90 0e 00 00       	call   f0104bee <vprintfmt>
	return cnt;
}
f0103d5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103d61:	c9                   	leave  
f0103d62:	c3                   	ret    

f0103d63 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103d63:	55                   	push   %ebp
f0103d64:	89 e5                	mov    %esp,%ebp
f0103d66:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103d69:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103d6c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d70:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d73:	89 04 24             	mov    %eax,(%esp)
f0103d76:	e8 b5 ff ff ff       	call   f0103d30 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103d7b:	c9                   	leave  
f0103d7c:	c3                   	ret    
f0103d7d:	66 90                	xchg   %ax,%ax
f0103d7f:	90                   	nop

f0103d80 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103d80:	55                   	push   %ebp
f0103d81:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103d83:	c7 05 24 fa 17 f0 00 	movl   $0xf0000000,0xf017fa24
f0103d8a:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103d8d:	66 c7 05 28 fa 17 f0 	movw   $0x10,0xf017fa28
f0103d94:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103d96:	66 c7 05 48 d3 11 f0 	movw   $0x67,0xf011d348
f0103d9d:	67 00 
f0103d9f:	b8 20 fa 17 f0       	mov    $0xf017fa20,%eax
f0103da4:	66 a3 4a d3 11 f0    	mov    %ax,0xf011d34a
f0103daa:	89 c2                	mov    %eax,%edx
f0103dac:	c1 ea 10             	shr    $0x10,%edx
f0103daf:	88 15 4c d3 11 f0    	mov    %dl,0xf011d34c
f0103db5:	c6 05 4e d3 11 f0 40 	movb   $0x40,0xf011d34e
f0103dbc:	c1 e8 18             	shr    $0x18,%eax
f0103dbf:	a2 4f d3 11 f0       	mov    %al,0xf011d34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103dc4:	c6 05 4d d3 11 f0 89 	movb   $0x89,0xf011d34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0103dcb:	b8 28 00 00 00       	mov    $0x28,%eax
f0103dd0:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0103dd3:	b8 50 d3 11 f0       	mov    $0xf011d350,%eax
f0103dd8:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103ddb:	5d                   	pop    %ebp
f0103ddc:	c3                   	ret    

f0103ddd <trap_init>:
}


void
trap_init(void)
{
f0103ddd:	55                   	push   %ebp
f0103dde:	89 e5                	mov    %esp,%ebp
	void t_mchk();
	void t_simderr();
	void t_syscall();

	// trap
	SETGATE(idt[T_DIVIDE], 1, GD_KT, t_divide, 0);
f0103de0:	b8 18 45 10 f0       	mov    $0xf0104518,%eax
f0103de5:	66 a3 00 f2 17 f0    	mov    %ax,0xf017f200
f0103deb:	66 c7 05 02 f2 17 f0 	movw   $0x8,0xf017f202
f0103df2:	08 00 
f0103df4:	c6 05 04 f2 17 f0 00 	movb   $0x0,0xf017f204
f0103dfb:	c6 05 05 f2 17 f0 8f 	movb   $0x8f,0xf017f205
f0103e02:	c1 e8 10             	shr    $0x10,%eax
f0103e05:	66 a3 06 f2 17 f0    	mov    %ax,0xf017f206
	SETGATE(idt[T_DEBUG], 1, GD_KT, t_debug, 0);
f0103e0b:	b8 1e 45 10 f0       	mov    $0xf010451e,%eax
f0103e10:	66 a3 08 f2 17 f0    	mov    %ax,0xf017f208
f0103e16:	66 c7 05 0a f2 17 f0 	movw   $0x8,0xf017f20a
f0103e1d:	08 00 
f0103e1f:	c6 05 0c f2 17 f0 00 	movb   $0x0,0xf017f20c
f0103e26:	c6 05 0d f2 17 f0 8f 	movb   $0x8f,0xf017f20d
f0103e2d:	c1 e8 10             	shr    $0x10,%eax
f0103e30:	66 a3 0e f2 17 f0    	mov    %ax,0xf017f20e
	SETGATE(idt[T_NMI], 1, GD_KT, t_nmi, 0);
f0103e36:	b8 24 45 10 f0       	mov    $0xf0104524,%eax
f0103e3b:	66 a3 10 f2 17 f0    	mov    %ax,0xf017f210
f0103e41:	66 c7 05 12 f2 17 f0 	movw   $0x8,0xf017f212
f0103e48:	08 00 
f0103e4a:	c6 05 14 f2 17 f0 00 	movb   $0x0,0xf017f214
f0103e51:	c6 05 15 f2 17 f0 8f 	movb   $0x8f,0xf017f215
f0103e58:	c1 e8 10             	shr    $0x10,%eax
f0103e5b:	66 a3 16 f2 17 f0    	mov    %ax,0xf017f216
	SETGATE(idt[T_BRKPT], 1, GD_KT, t_brkpt, 3);
f0103e61:	b8 2a 45 10 f0       	mov    $0xf010452a,%eax
f0103e66:	66 a3 18 f2 17 f0    	mov    %ax,0xf017f218
f0103e6c:	66 c7 05 1a f2 17 f0 	movw   $0x8,0xf017f21a
f0103e73:	08 00 
f0103e75:	c6 05 1c f2 17 f0 00 	movb   $0x0,0xf017f21c
f0103e7c:	c6 05 1d f2 17 f0 ef 	movb   $0xef,0xf017f21d
f0103e83:	c1 e8 10             	shr    $0x10,%eax
f0103e86:	66 a3 1e f2 17 f0    	mov    %ax,0xf017f21e
	SETGATE(idt[T_OFLOW], 1, GD_KT, t_oflow, 0);
f0103e8c:	b8 30 45 10 f0       	mov    $0xf0104530,%eax
f0103e91:	66 a3 20 f2 17 f0    	mov    %ax,0xf017f220
f0103e97:	66 c7 05 22 f2 17 f0 	movw   $0x8,0xf017f222
f0103e9e:	08 00 
f0103ea0:	c6 05 24 f2 17 f0 00 	movb   $0x0,0xf017f224
f0103ea7:	c6 05 25 f2 17 f0 8f 	movb   $0x8f,0xf017f225
f0103eae:	c1 e8 10             	shr    $0x10,%eax
f0103eb1:	66 a3 26 f2 17 f0    	mov    %ax,0xf017f226
	SETGATE(idt[T_BOUND], 1, GD_KT, t_bound, 0);
f0103eb7:	b8 36 45 10 f0       	mov    $0xf0104536,%eax
f0103ebc:	66 a3 28 f2 17 f0    	mov    %ax,0xf017f228
f0103ec2:	66 c7 05 2a f2 17 f0 	movw   $0x8,0xf017f22a
f0103ec9:	08 00 
f0103ecb:	c6 05 2c f2 17 f0 00 	movb   $0x0,0xf017f22c
f0103ed2:	c6 05 2d f2 17 f0 8f 	movb   $0x8f,0xf017f22d
f0103ed9:	c1 e8 10             	shr    $0x10,%eax
f0103edc:	66 a3 2e f2 17 f0    	mov    %ax,0xf017f22e
	SETGATE(idt[T_ILLOP], 1, GD_KT, t_illop, 0);
f0103ee2:	b8 3c 45 10 f0       	mov    $0xf010453c,%eax
f0103ee7:	66 a3 30 f2 17 f0    	mov    %ax,0xf017f230
f0103eed:	66 c7 05 32 f2 17 f0 	movw   $0x8,0xf017f232
f0103ef4:	08 00 
f0103ef6:	c6 05 34 f2 17 f0 00 	movb   $0x0,0xf017f234
f0103efd:	c6 05 35 f2 17 f0 8f 	movb   $0x8f,0xf017f235
f0103f04:	c1 e8 10             	shr    $0x10,%eax
f0103f07:	66 a3 36 f2 17 f0    	mov    %ax,0xf017f236
	SETGATE(idt[T_DEVICE], 1, GD_KT, t_device, 0);
f0103f0d:	b8 42 45 10 f0       	mov    $0xf0104542,%eax
f0103f12:	66 a3 38 f2 17 f0    	mov    %ax,0xf017f238
f0103f18:	66 c7 05 3a f2 17 f0 	movw   $0x8,0xf017f23a
f0103f1f:	08 00 
f0103f21:	c6 05 3c f2 17 f0 00 	movb   $0x0,0xf017f23c
f0103f28:	c6 05 3d f2 17 f0 8f 	movb   $0x8f,0xf017f23d
f0103f2f:	c1 e8 10             	shr    $0x10,%eax
f0103f32:	66 a3 3e f2 17 f0    	mov    %ax,0xf017f23e
	SETGATE(idt[T_DBLFLT], 1, GD_KT, t_dblflt, 0);
f0103f38:	b8 48 45 10 f0       	mov    $0xf0104548,%eax
f0103f3d:	66 a3 40 f2 17 f0    	mov    %ax,0xf017f240
f0103f43:	66 c7 05 42 f2 17 f0 	movw   $0x8,0xf017f242
f0103f4a:	08 00 
f0103f4c:	c6 05 44 f2 17 f0 00 	movb   $0x0,0xf017f244
f0103f53:	c6 05 45 f2 17 f0 8f 	movb   $0x8f,0xf017f245
f0103f5a:	c1 e8 10             	shr    $0x10,%eax
f0103f5d:	66 a3 46 f2 17 f0    	mov    %ax,0xf017f246
	SETGATE(idt[T_TSS], 1, GD_KT, t_tss, 0);
f0103f63:	b8 4c 45 10 f0       	mov    $0xf010454c,%eax
f0103f68:	66 a3 50 f2 17 f0    	mov    %ax,0xf017f250
f0103f6e:	66 c7 05 52 f2 17 f0 	movw   $0x8,0xf017f252
f0103f75:	08 00 
f0103f77:	c6 05 54 f2 17 f0 00 	movb   $0x0,0xf017f254
f0103f7e:	c6 05 55 f2 17 f0 8f 	movb   $0x8f,0xf017f255
f0103f85:	c1 e8 10             	shr    $0x10,%eax
f0103f88:	66 a3 56 f2 17 f0    	mov    %ax,0xf017f256
	SETGATE(idt[T_SEGNP], 1, GD_KT, t_segnp, 0);
f0103f8e:	b8 50 45 10 f0       	mov    $0xf0104550,%eax
f0103f93:	66 a3 58 f2 17 f0    	mov    %ax,0xf017f258
f0103f99:	66 c7 05 5a f2 17 f0 	movw   $0x8,0xf017f25a
f0103fa0:	08 00 
f0103fa2:	c6 05 5c f2 17 f0 00 	movb   $0x0,0xf017f25c
f0103fa9:	c6 05 5d f2 17 f0 8f 	movb   $0x8f,0xf017f25d
f0103fb0:	c1 e8 10             	shr    $0x10,%eax
f0103fb3:	66 a3 5e f2 17 f0    	mov    %ax,0xf017f25e
	SETGATE(idt[T_STACK], 1, GD_KT, t_stack, 0);
f0103fb9:	b8 54 45 10 f0       	mov    $0xf0104554,%eax
f0103fbe:	66 a3 60 f2 17 f0    	mov    %ax,0xf017f260
f0103fc4:	66 c7 05 62 f2 17 f0 	movw   $0x8,0xf017f262
f0103fcb:	08 00 
f0103fcd:	c6 05 64 f2 17 f0 00 	movb   $0x0,0xf017f264
f0103fd4:	c6 05 65 f2 17 f0 8f 	movb   $0x8f,0xf017f265
f0103fdb:	c1 e8 10             	shr    $0x10,%eax
f0103fde:	66 a3 66 f2 17 f0    	mov    %ax,0xf017f266
	SETGATE(idt[T_GPFLT], 1, GD_KT, t_gpflt, 0);
f0103fe4:	b8 58 45 10 f0       	mov    $0xf0104558,%eax
f0103fe9:	66 a3 68 f2 17 f0    	mov    %ax,0xf017f268
f0103fef:	66 c7 05 6a f2 17 f0 	movw   $0x8,0xf017f26a
f0103ff6:	08 00 
f0103ff8:	c6 05 6c f2 17 f0 00 	movb   $0x0,0xf017f26c
f0103fff:	c6 05 6d f2 17 f0 8f 	movb   $0x8f,0xf017f26d
f0104006:	c1 e8 10             	shr    $0x10,%eax
f0104009:	66 a3 6e f2 17 f0    	mov    %ax,0xf017f26e
	SETGATE(idt[T_PGFLT], 1, GD_KT, t_pgflt, 0);
f010400f:	b8 5c 45 10 f0       	mov    $0xf010455c,%eax
f0104014:	66 a3 70 f2 17 f0    	mov    %ax,0xf017f270
f010401a:	66 c7 05 72 f2 17 f0 	movw   $0x8,0xf017f272
f0104021:	08 00 
f0104023:	c6 05 74 f2 17 f0 00 	movb   $0x0,0xf017f274
f010402a:	c6 05 75 f2 17 f0 8f 	movb   $0x8f,0xf017f275
f0104031:	c1 e8 10             	shr    $0x10,%eax
f0104034:	66 a3 76 f2 17 f0    	mov    %ax,0xf017f276
	SETGATE(idt[T_FPERR], 1, GD_KT, t_fperr, 0);
f010403a:	b8 60 45 10 f0       	mov    $0xf0104560,%eax
f010403f:	66 a3 80 f2 17 f0    	mov    %ax,0xf017f280
f0104045:	66 c7 05 82 f2 17 f0 	movw   $0x8,0xf017f282
f010404c:	08 00 
f010404e:	c6 05 84 f2 17 f0 00 	movb   $0x0,0xf017f284
f0104055:	c6 05 85 f2 17 f0 8f 	movb   $0x8f,0xf017f285
f010405c:	c1 e8 10             	shr    $0x10,%eax
f010405f:	66 a3 86 f2 17 f0    	mov    %ax,0xf017f286
	SETGATE(idt[T_ALIGN], 1, GD_KT, t_align, 0);
f0104065:	b8 66 45 10 f0       	mov    $0xf0104566,%eax
f010406a:	66 a3 88 f2 17 f0    	mov    %ax,0xf017f288
f0104070:	66 c7 05 8a f2 17 f0 	movw   $0x8,0xf017f28a
f0104077:	08 00 
f0104079:	c6 05 8c f2 17 f0 00 	movb   $0x0,0xf017f28c
f0104080:	c6 05 8d f2 17 f0 8f 	movb   $0x8f,0xf017f28d
f0104087:	c1 e8 10             	shr    $0x10,%eax
f010408a:	66 a3 8e f2 17 f0    	mov    %ax,0xf017f28e
	SETGATE(idt[T_MCHK], 1, GD_KT, t_mchk, 0);
f0104090:	b8 6a 45 10 f0       	mov    $0xf010456a,%eax
f0104095:	66 a3 90 f2 17 f0    	mov    %ax,0xf017f290
f010409b:	66 c7 05 92 f2 17 f0 	movw   $0x8,0xf017f292
f01040a2:	08 00 
f01040a4:	c6 05 94 f2 17 f0 00 	movb   $0x0,0xf017f294
f01040ab:	c6 05 95 f2 17 f0 8f 	movb   $0x8f,0xf017f295
f01040b2:	c1 e8 10             	shr    $0x10,%eax
f01040b5:	66 a3 96 f2 17 f0    	mov    %ax,0xf017f296
	SETGATE(idt[T_SIMDERR], 1, GD_KT, t_simderr, 0);
f01040bb:	b8 70 45 10 f0       	mov    $0xf0104570,%eax
f01040c0:	66 a3 98 f2 17 f0    	mov    %ax,0xf017f298
f01040c6:	66 c7 05 9a f2 17 f0 	movw   $0x8,0xf017f29a
f01040cd:	08 00 
f01040cf:	c6 05 9c f2 17 f0 00 	movb   $0x0,0xf017f29c
f01040d6:	c6 05 9d f2 17 f0 8f 	movb   $0x8f,0xf017f29d
f01040dd:	c1 e8 10             	shr    $0x10,%eax
f01040e0:	66 a3 9e f2 17 f0    	mov    %ax,0xf017f29e

	// interrupt
	SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
f01040e6:	b8 76 45 10 f0       	mov    $0xf0104576,%eax
f01040eb:	66 a3 80 f3 17 f0    	mov    %ax,0xf017f380
f01040f1:	66 c7 05 82 f3 17 f0 	movw   $0x8,0xf017f382
f01040f8:	08 00 
f01040fa:	c6 05 84 f3 17 f0 00 	movb   $0x0,0xf017f384
f0104101:	c6 05 85 f3 17 f0 ee 	movb   $0xee,0xf017f385
f0104108:	c1 e8 10             	shr    $0x10,%eax
f010410b:	66 a3 86 f3 17 f0    	mov    %ax,0xf017f386
	// Per-CPU setup 
	trap_init_percpu();
f0104111:	e8 6a fc ff ff       	call   f0103d80 <trap_init_percpu>
}
f0104116:	5d                   	pop    %ebp
f0104117:	c3                   	ret    

f0104118 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0104118:	55                   	push   %ebp
f0104119:	89 e5                	mov    %esp,%ebp
f010411b:	53                   	push   %ebx
f010411c:	83 ec 14             	sub    $0x14,%esp
f010411f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0104122:	8b 03                	mov    (%ebx),%eax
f0104124:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104128:	c7 04 24 49 6d 10 f0 	movl   $0xf0106d49,(%esp)
f010412f:	e8 2f fc ff ff       	call   f0103d63 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0104134:	8b 43 04             	mov    0x4(%ebx),%eax
f0104137:	89 44 24 04          	mov    %eax,0x4(%esp)
f010413b:	c7 04 24 58 6d 10 f0 	movl   $0xf0106d58,(%esp)
f0104142:	e8 1c fc ff ff       	call   f0103d63 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0104147:	8b 43 08             	mov    0x8(%ebx),%eax
f010414a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010414e:	c7 04 24 67 6d 10 f0 	movl   $0xf0106d67,(%esp)
f0104155:	e8 09 fc ff ff       	call   f0103d63 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f010415a:	8b 43 0c             	mov    0xc(%ebx),%eax
f010415d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104161:	c7 04 24 76 6d 10 f0 	movl   $0xf0106d76,(%esp)
f0104168:	e8 f6 fb ff ff       	call   f0103d63 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f010416d:	8b 43 10             	mov    0x10(%ebx),%eax
f0104170:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104174:	c7 04 24 85 6d 10 f0 	movl   $0xf0106d85,(%esp)
f010417b:	e8 e3 fb ff ff       	call   f0103d63 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0104180:	8b 43 14             	mov    0x14(%ebx),%eax
f0104183:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104187:	c7 04 24 94 6d 10 f0 	movl   $0xf0106d94,(%esp)
f010418e:	e8 d0 fb ff ff       	call   f0103d63 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0104193:	8b 43 18             	mov    0x18(%ebx),%eax
f0104196:	89 44 24 04          	mov    %eax,0x4(%esp)
f010419a:	c7 04 24 a3 6d 10 f0 	movl   $0xf0106da3,(%esp)
f01041a1:	e8 bd fb ff ff       	call   f0103d63 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01041a6:	8b 43 1c             	mov    0x1c(%ebx),%eax
f01041a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01041ad:	c7 04 24 b2 6d 10 f0 	movl   $0xf0106db2,(%esp)
f01041b4:	e8 aa fb ff ff       	call   f0103d63 <cprintf>
}
f01041b9:	83 c4 14             	add    $0x14,%esp
f01041bc:	5b                   	pop    %ebx
f01041bd:	5d                   	pop    %ebp
f01041be:	c3                   	ret    

f01041bf <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f01041bf:	55                   	push   %ebp
f01041c0:	89 e5                	mov    %esp,%ebp
f01041c2:	56                   	push   %esi
f01041c3:	53                   	push   %ebx
f01041c4:	83 ec 10             	sub    $0x10,%esp
f01041c7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f01041ca:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01041ce:	c7 04 24 02 6f 10 f0 	movl   $0xf0106f02,(%esp)
f01041d5:	e8 89 fb ff ff       	call   f0103d63 <cprintf>
	print_regs(&tf->tf_regs);
f01041da:	89 1c 24             	mov    %ebx,(%esp)
f01041dd:	e8 36 ff ff ff       	call   f0104118 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01041e2:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01041e6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01041ea:	c7 04 24 03 6e 10 f0 	movl   $0xf0106e03,(%esp)
f01041f1:	e8 6d fb ff ff       	call   f0103d63 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01041f6:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01041fa:	89 44 24 04          	mov    %eax,0x4(%esp)
f01041fe:	c7 04 24 16 6e 10 f0 	movl   $0xf0106e16,(%esp)
f0104205:	e8 59 fb ff ff       	call   f0103d63 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010420a:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f010420d:	83 f8 13             	cmp    $0x13,%eax
f0104210:	77 09                	ja     f010421b <print_trapframe+0x5c>
		return excnames[trapno];
f0104212:	8b 14 85 e0 70 10 f0 	mov    -0xfef8f20(,%eax,4),%edx
f0104219:	eb 10                	jmp    f010422b <print_trapframe+0x6c>
	if (trapno == T_SYSCALL)
		return "System call";
f010421b:	83 f8 30             	cmp    $0x30,%eax
f010421e:	ba c1 6d 10 f0       	mov    $0xf0106dc1,%edx
f0104223:	b9 cd 6d 10 f0       	mov    $0xf0106dcd,%ecx
f0104228:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010422b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010422f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104233:	c7 04 24 29 6e 10 f0 	movl   $0xf0106e29,(%esp)
f010423a:	e8 24 fb ff ff       	call   f0103d63 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f010423f:	3b 1d 00 fa 17 f0    	cmp    0xf017fa00,%ebx
f0104245:	75 19                	jne    f0104260 <print_trapframe+0xa1>
f0104247:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010424b:	75 13                	jne    f0104260 <print_trapframe+0xa1>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f010424d:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0104250:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104254:	c7 04 24 3b 6e 10 f0 	movl   $0xf0106e3b,(%esp)
f010425b:	e8 03 fb ff ff       	call   f0103d63 <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0104260:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0104263:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104267:	c7 04 24 4a 6e 10 f0 	movl   $0xf0106e4a,(%esp)
f010426e:	e8 f0 fa ff ff       	call   f0103d63 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0104273:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0104277:	75 51                	jne    f01042ca <print_trapframe+0x10b>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0104279:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f010427c:	89 c2                	mov    %eax,%edx
f010427e:	83 e2 01             	and    $0x1,%edx
f0104281:	ba dc 6d 10 f0       	mov    $0xf0106ddc,%edx
f0104286:	b9 e7 6d 10 f0       	mov    $0xf0106de7,%ecx
f010428b:	0f 45 ca             	cmovne %edx,%ecx
f010428e:	89 c2                	mov    %eax,%edx
f0104290:	83 e2 02             	and    $0x2,%edx
f0104293:	ba f3 6d 10 f0       	mov    $0xf0106df3,%edx
f0104298:	be f9 6d 10 f0       	mov    $0xf0106df9,%esi
f010429d:	0f 44 d6             	cmove  %esi,%edx
f01042a0:	83 e0 04             	and    $0x4,%eax
f01042a3:	b8 fe 6d 10 f0       	mov    $0xf0106dfe,%eax
f01042a8:	be 2d 6f 10 f0       	mov    $0xf0106f2d,%esi
f01042ad:	0f 44 c6             	cmove  %esi,%eax
f01042b0:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01042b4:	89 54 24 08          	mov    %edx,0x8(%esp)
f01042b8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042bc:	c7 04 24 58 6e 10 f0 	movl   $0xf0106e58,(%esp)
f01042c3:	e8 9b fa ff ff       	call   f0103d63 <cprintf>
f01042c8:	eb 0c                	jmp    f01042d6 <print_trapframe+0x117>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f01042ca:	c7 04 24 c3 5a 10 f0 	movl   $0xf0105ac3,(%esp)
f01042d1:	e8 8d fa ff ff       	call   f0103d63 <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01042d6:	8b 43 30             	mov    0x30(%ebx),%eax
f01042d9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042dd:	c7 04 24 67 6e 10 f0 	movl   $0xf0106e67,(%esp)
f01042e4:	e8 7a fa ff ff       	call   f0103d63 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01042e9:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f01042ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042f1:	c7 04 24 76 6e 10 f0 	movl   $0xf0106e76,(%esp)
f01042f8:	e8 66 fa ff ff       	call   f0103d63 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01042fd:	8b 43 38             	mov    0x38(%ebx),%eax
f0104300:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104304:	c7 04 24 89 6e 10 f0 	movl   $0xf0106e89,(%esp)
f010430b:	e8 53 fa ff ff       	call   f0103d63 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0104310:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0104314:	74 27                	je     f010433d <print_trapframe+0x17e>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0104316:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0104319:	89 44 24 04          	mov    %eax,0x4(%esp)
f010431d:	c7 04 24 98 6e 10 f0 	movl   $0xf0106e98,(%esp)
f0104324:	e8 3a fa ff ff       	call   f0103d63 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0104329:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f010432d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104331:	c7 04 24 a7 6e 10 f0 	movl   $0xf0106ea7,(%esp)
f0104338:	e8 26 fa ff ff       	call   f0103d63 <cprintf>
	}
}
f010433d:	83 c4 10             	add    $0x10,%esp
f0104340:	5b                   	pop    %ebx
f0104341:	5e                   	pop    %esi
f0104342:	5d                   	pop    %ebp
f0104343:	c3                   	ret    

f0104344 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0104344:	55                   	push   %ebp
f0104345:	89 e5                	mov    %esp,%ebp
f0104347:	53                   	push   %ebx
f0104348:	83 ec 14             	sub    $0x14,%esp
f010434b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010434e:	0f 20 d0             	mov    %cr2,%eax
	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	// to determine whether a fault happened in user mode or in kernel mode
	// check the low bits of the tf_cs. 
	if ((tf->tf_cs & 3) == 0)
f0104351:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0104355:	75 1c                	jne    f0104373 <page_fault_handler+0x2f>
		panic("Page fault in kernel-mode");
f0104357:	c7 44 24 08 ba 6e 10 	movl   $0xf0106eba,0x8(%esp)
f010435e:	f0 
f010435f:	c7 44 24 04 09 01 00 	movl   $0x109,0x4(%esp)
f0104366:	00 
f0104367:	c7 04 24 d4 6e 10 f0 	movl   $0xf0106ed4,(%esp)
f010436e:	e8 43 bd ff ff       	call   f01000b6 <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104373:	8b 53 30             	mov    0x30(%ebx),%edx
f0104376:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010437a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010437e:	a1 e8 f1 17 f0       	mov    0xf017f1e8,%eax
f0104383:	8b 40 48             	mov    0x48(%eax),%eax
f0104386:	89 44 24 04          	mov    %eax,0x4(%esp)
f010438a:	c7 04 24 78 70 10 f0 	movl   $0xf0107078,(%esp)
f0104391:	e8 cd f9 ff ff       	call   f0103d63 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0104396:	89 1c 24             	mov    %ebx,(%esp)
f0104399:	e8 21 fe ff ff       	call   f01041bf <print_trapframe>
	env_destroy(curenv);
f010439e:	a1 e8 f1 17 f0       	mov    0xf017f1e8,%eax
f01043a3:	89 04 24             	mov    %eax,(%esp)
f01043a6:	e8 85 f8 ff ff       	call   f0103c30 <env_destroy>
}
f01043ab:	83 c4 14             	add    $0x14,%esp
f01043ae:	5b                   	pop    %ebx
f01043af:	5d                   	pop    %ebp
f01043b0:	c3                   	ret    

f01043b1 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01043b1:	55                   	push   %ebp
f01043b2:	89 e5                	mov    %esp,%ebp
f01043b4:	57                   	push   %edi
f01043b5:	56                   	push   %esi
f01043b6:	83 ec 20             	sub    $0x20,%esp
f01043b9:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01043bc:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01043bd:	9c                   	pushf  
f01043be:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01043bf:	f6 c4 02             	test   $0x2,%ah
f01043c2:	74 24                	je     f01043e8 <trap+0x37>
f01043c4:	c7 44 24 0c e0 6e 10 	movl   $0xf0106ee0,0xc(%esp)
f01043cb:	f0 
f01043cc:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01043d3:	f0 
f01043d4:	c7 44 24 04 de 00 00 	movl   $0xde,0x4(%esp)
f01043db:	00 
f01043dc:	c7 04 24 d4 6e 10 f0 	movl   $0xf0106ed4,(%esp)
f01043e3:	e8 ce bc ff ff       	call   f01000b6 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f01043e8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01043ec:	c7 04 24 f9 6e 10 f0 	movl   $0xf0106ef9,(%esp)
f01043f3:	e8 6b f9 ff ff       	call   f0103d63 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f01043f8:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01043fc:	83 e0 03             	and    $0x3,%eax
f01043ff:	66 83 f8 03          	cmp    $0x3,%ax
f0104403:	75 3c                	jne    f0104441 <trap+0x90>
		// Trapped from user mode.
		assert(curenv);
f0104405:	a1 e8 f1 17 f0       	mov    0xf017f1e8,%eax
f010440a:	85 c0                	test   %eax,%eax
f010440c:	75 24                	jne    f0104432 <trap+0x81>
f010440e:	c7 44 24 0c 14 6f 10 	movl   $0xf0106f14,0xc(%esp)
f0104415:	f0 
f0104416:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f010441d:	f0 
f010441e:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
f0104425:	00 
f0104426:	c7 04 24 d4 6e 10 f0 	movl   $0xf0106ed4,(%esp)
f010442d:	e8 84 bc ff ff       	call   f01000b6 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0104432:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104437:	89 c7                	mov    %eax,%edi
f0104439:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f010443b:	8b 35 e8 f1 17 f0    	mov    0xf017f1e8,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0104441:	89 35 00 fa 17 f0    	mov    %esi,0xf017fa00
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch(tf->tf_trapno){
f0104447:	8b 46 28             	mov    0x28(%esi),%eax
f010444a:	83 f8 0e             	cmp    $0xe,%eax
f010444d:	74 0c                	je     f010445b <trap+0xaa>
f010444f:	83 f8 30             	cmp    $0x30,%eax
f0104452:	74 1e                	je     f0104472 <trap+0xc1>
f0104454:	83 f8 03             	cmp    $0x3,%eax
f0104457:	75 4b                	jne    f01044a4 <trap+0xf3>
f0104459:	eb 0c                	jmp    f0104467 <trap+0xb6>
		case T_PGFLT:
			page_fault_handler(tf);
f010445b:	89 34 24             	mov    %esi,(%esp)
f010445e:	66 90                	xchg   %ax,%ax
f0104460:	e8 df fe ff ff       	call   f0104344 <page_fault_handler>
f0104465:	eb 75                	jmp    f01044dc <trap+0x12b>
			break;
		case T_BRKPT:
			monitor(tf);
f0104467:	89 34 24             	mov    %esi,(%esp)
f010446a:	e8 15 c9 ff ff       	call   f0100d84 <monitor>
f010446f:	90                   	nop
f0104470:	eb 6a                	jmp    f01044dc <trap+0x12b>
			break;
		case T_SYSCALL:
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, 
f0104472:	8b 46 04             	mov    0x4(%esi),%eax
f0104475:	89 44 24 14          	mov    %eax,0x14(%esp)
f0104479:	8b 06                	mov    (%esi),%eax
f010447b:	89 44 24 10          	mov    %eax,0x10(%esp)
f010447f:	8b 46 10             	mov    0x10(%esi),%eax
f0104482:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104486:	8b 46 18             	mov    0x18(%esi),%eax
f0104489:	89 44 24 08          	mov    %eax,0x8(%esp)
f010448d:	8b 46 14             	mov    0x14(%esi),%eax
f0104490:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104494:	8b 46 1c             	mov    0x1c(%esi),%eax
f0104497:	89 04 24             	mov    %eax,(%esp)
f010449a:	e8 f1 00 00 00       	call   f0104590 <syscall>
f010449f:	89 46 1c             	mov    %eax,0x1c(%esi)
f01044a2:	eb 38                	jmp    f01044dc <trap+0x12b>
				tf->tf_regs.reg_ebx, tf->tf_regs.reg_edi,
				tf->tf_regs.reg_esi);
			break;
		default:
			// Unexpected trap: The user process or the kernel has a bug.
			print_trapframe(tf);
f01044a4:	89 34 24             	mov    %esi,(%esp)
f01044a7:	e8 13 fd ff ff       	call   f01041bf <print_trapframe>
			if (tf->tf_cs == GD_KT)
f01044ac:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01044b1:	75 1c                	jne    f01044cf <trap+0x11e>
				panic("unhandled trap in kernel");
f01044b3:	c7 44 24 08 1b 6f 10 	movl   $0xf0106f1b,0x8(%esp)
f01044ba:	f0 
f01044bb:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
f01044c2:	00 
f01044c3:	c7 04 24 d4 6e 10 f0 	movl   $0xf0106ed4,(%esp)
f01044ca:	e8 e7 bb ff ff       	call   f01000b6 <_panic>
			else {
				env_destroy(curenv);
f01044cf:	a1 e8 f1 17 f0       	mov    0xf017f1e8,%eax
f01044d4:	89 04 24             	mov    %eax,(%esp)
f01044d7:	e8 54 f7 ff ff       	call   f0103c30 <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01044dc:	a1 e8 f1 17 f0       	mov    0xf017f1e8,%eax
f01044e1:	85 c0                	test   %eax,%eax
f01044e3:	74 06                	je     f01044eb <trap+0x13a>
f01044e5:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01044e9:	74 24                	je     f010450f <trap+0x15e>
f01044eb:	c7 44 24 0c 9c 70 10 	movl   $0xf010709c,0xc(%esp)
f01044f2:	f0 
f01044f3:	c7 44 24 08 8b 69 10 	movl   $0xf010698b,0x8(%esp)
f01044fa:	f0 
f01044fb:	c7 44 24 04 f6 00 00 	movl   $0xf6,0x4(%esp)
f0104502:	00 
f0104503:	c7 04 24 d4 6e 10 f0 	movl   $0xf0106ed4,(%esp)
f010450a:	e8 a7 bb ff ff       	call   f01000b6 <_panic>
	env_run(curenv);
f010450f:	89 04 24             	mov    %eax,(%esp)
f0104512:	e8 70 f7 ff ff       	call   f0103c87 <env_run>
f0104517:	90                   	nop

f0104518 <t_divide>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(t_divide, T_DIVIDE);
f0104518:	6a 00                	push   $0x0
f010451a:	6a 00                	push   $0x0
f010451c:	eb 5e                	jmp    f010457c <_alltraps>

f010451e <t_debug>:
TRAPHANDLER_NOEC(t_debug, T_DEBUG);
f010451e:	6a 00                	push   $0x0
f0104520:	6a 01                	push   $0x1
f0104522:	eb 58                	jmp    f010457c <_alltraps>

f0104524 <t_nmi>:
TRAPHANDLER_NOEC(t_nmi, T_NMI);
f0104524:	6a 00                	push   $0x0
f0104526:	6a 02                	push   $0x2
f0104528:	eb 52                	jmp    f010457c <_alltraps>

f010452a <t_brkpt>:
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT);
f010452a:	6a 00                	push   $0x0
f010452c:	6a 03                	push   $0x3
f010452e:	eb 4c                	jmp    f010457c <_alltraps>

f0104530 <t_oflow>:
TRAPHANDLER_NOEC(t_oflow, T_OFLOW);
f0104530:	6a 00                	push   $0x0
f0104532:	6a 04                	push   $0x4
f0104534:	eb 46                	jmp    f010457c <_alltraps>

f0104536 <t_bound>:
TRAPHANDLER_NOEC(t_bound, T_BOUND);
f0104536:	6a 00                	push   $0x0
f0104538:	6a 05                	push   $0x5
f010453a:	eb 40                	jmp    f010457c <_alltraps>

f010453c <t_illop>:
TRAPHANDLER_NOEC(t_illop, T_ILLOP);
f010453c:	6a 00                	push   $0x0
f010453e:	6a 06                	push   $0x6
f0104540:	eb 3a                	jmp    f010457c <_alltraps>

f0104542 <t_device>:
TRAPHANDLER_NOEC(t_device, T_DEVICE);
f0104542:	6a 00                	push   $0x0
f0104544:	6a 07                	push   $0x7
f0104546:	eb 34                	jmp    f010457c <_alltraps>

f0104548 <t_dblflt>:
TRAPHANDLER(t_dblflt, T_DBLFLT);
f0104548:	6a 08                	push   $0x8
f010454a:	eb 30                	jmp    f010457c <_alltraps>

f010454c <t_tss>:
TRAPHANDLER(t_tss, T_TSS);
f010454c:	6a 0a                	push   $0xa
f010454e:	eb 2c                	jmp    f010457c <_alltraps>

f0104550 <t_segnp>:
TRAPHANDLER(t_segnp, T_SEGNP);
f0104550:	6a 0b                	push   $0xb
f0104552:	eb 28                	jmp    f010457c <_alltraps>

f0104554 <t_stack>:
TRAPHANDLER(t_stack, T_STACK);
f0104554:	6a 0c                	push   $0xc
f0104556:	eb 24                	jmp    f010457c <_alltraps>

f0104558 <t_gpflt>:
TRAPHANDLER(t_gpflt, T_GPFLT);
f0104558:	6a 0d                	push   $0xd
f010455a:	eb 20                	jmp    f010457c <_alltraps>

f010455c <t_pgflt>:
TRAPHANDLER(t_pgflt, T_PGFLT);
f010455c:	6a 0e                	push   $0xe
f010455e:	eb 1c                	jmp    f010457c <_alltraps>

f0104560 <t_fperr>:
TRAPHANDLER_NOEC(t_fperr, T_FPERR);
f0104560:	6a 00                	push   $0x0
f0104562:	6a 10                	push   $0x10
f0104564:	eb 16                	jmp    f010457c <_alltraps>

f0104566 <t_align>:
TRAPHANDLER(t_align, T_ALIGN);
f0104566:	6a 11                	push   $0x11
f0104568:	eb 12                	jmp    f010457c <_alltraps>

f010456a <t_mchk>:
TRAPHANDLER_NOEC(t_mchk, T_MCHK);
f010456a:	6a 00                	push   $0x0
f010456c:	6a 12                	push   $0x12
f010456e:	eb 0c                	jmp    f010457c <_alltraps>

f0104570 <t_simderr>:
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR);
f0104570:	6a 00                	push   $0x0
f0104572:	6a 13                	push   $0x13
f0104574:	eb 06                	jmp    f010457c <_alltraps>

f0104576 <t_syscall>:
TRAPHANDLER_NOEC(t_syscall, T_SYSCALL);
f0104576:	6a 00                	push   $0x0
f0104578:	6a 30                	push   $0x30
f010457a:	eb 00                	jmp    f010457c <_alltraps>

f010457c <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds 
f010457c:	1e                   	push   %ds
	pushl %es 
f010457d:	06                   	push   %es
	pushal
f010457e:	60                   	pusha  

	movw $GD_KD, %ax
f010457f:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0104583:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0104585:	8e c0                	mov    %eax,%es
	pushl %esp
f0104587:	54                   	push   %esp
f0104588:	e8 24 fe ff ff       	call   f01043b1 <trap>
f010458d:	66 90                	xchg   %ax,%ax
f010458f:	90                   	nop

f0104590 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104590:	55                   	push   %ebp
f0104591:	89 e5                	mov    %esp,%ebp
f0104593:	83 ec 28             	sub    $0x28,%esp
f0104596:	8b 45 08             	mov    0x8(%ebp),%eax
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	int32_t retVal = 0;
	switch (syscallno) {
f0104599:	83 f8 01             	cmp    $0x1,%eax
f010459c:	74 60                	je     f01045fe <syscall+0x6e>
f010459e:	83 f8 01             	cmp    $0x1,%eax
f01045a1:	72 14                	jb     f01045b7 <syscall+0x27>
f01045a3:	83 f8 02             	cmp    $0x2,%eax
f01045a6:	0f 84 c5 00 00 00    	je     f0104671 <syscall+0xe1>
f01045ac:	83 f8 03             	cmp    $0x3,%eax
f01045af:	90                   	nop
f01045b0:	74 53                	je     f0104605 <syscall+0x75>
f01045b2:	e9 c4 00 00 00       	jmp    f010467b <syscall+0xeb>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f01045b7:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f01045be:	00 
f01045bf:	8b 45 10             	mov    0x10(%ebp),%eax
f01045c2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01045c6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01045c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01045cd:	a1 e8 f1 17 f0       	mov    0xf017f1e8,%eax
f01045d2:	89 04 24             	mov    %eax,(%esp)
f01045d5:	e8 58 ef ff ff       	call   f0103532 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01045da:	8b 45 0c             	mov    0xc(%ebp),%eax
f01045dd:	89 44 24 08          	mov    %eax,0x8(%esp)
f01045e1:	8b 45 10             	mov    0x10(%ebp),%eax
f01045e4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01045e8:	c7 04 24 30 71 10 f0 	movl   $0xf0107130,(%esp)
f01045ef:	e8 6f f7 ff ff       	call   f0103d63 <cprintf>
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	int32_t retVal = 0;
f01045f4:	b8 00 00 00 00       	mov    $0x0,%eax
f01045f9:	e9 82 00 00 00       	jmp    f0104680 <syscall+0xf0>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01045fe:	e8 e2 be ff ff       	call   f01004e5 <cons_getc>
		case SYS_cputs:
			sys_cputs((const char *)a1, (size_t) a2);
			break;
		case SYS_cgetc:
			retVal = sys_cgetc();
			break;
f0104603:	eb 7b                	jmp    f0104680 <syscall+0xf0>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104605:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010460c:	00 
f010460d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104610:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104614:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104617:	89 04 24             	mov    %eax,(%esp)
f010461a:	e8 06 f0 ff ff       	call   f0103625 <envid2env>
f010461f:	85 c0                	test   %eax,%eax
f0104621:	78 5d                	js     f0104680 <syscall+0xf0>
		return r;
	if (e == curenv)
f0104623:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104626:	8b 15 e8 f1 17 f0    	mov    0xf017f1e8,%edx
f010462c:	39 d0                	cmp    %edx,%eax
f010462e:	75 15                	jne    f0104645 <syscall+0xb5>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104630:	8b 40 48             	mov    0x48(%eax),%eax
f0104633:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104637:	c7 04 24 35 71 10 f0 	movl   $0xf0107135,(%esp)
f010463e:	e8 20 f7 ff ff       	call   f0103d63 <cprintf>
f0104643:	eb 1a                	jmp    f010465f <syscall+0xcf>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104645:	8b 40 48             	mov    0x48(%eax),%eax
f0104648:	89 44 24 08          	mov    %eax,0x8(%esp)
f010464c:	8b 42 48             	mov    0x48(%edx),%eax
f010464f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104653:	c7 04 24 50 71 10 f0 	movl   $0xf0107150,(%esp)
f010465a:	e8 04 f7 ff ff       	call   f0103d63 <cprintf>
	env_destroy(e);
f010465f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104662:	89 04 24             	mov    %eax,(%esp)
f0104665:	e8 c6 f5 ff ff       	call   f0103c30 <env_destroy>
	return 0;
f010466a:	b8 00 00 00 00       	mov    $0x0,%eax
		case SYS_cgetc:
			retVal = sys_cgetc();
			break;
		case SYS_env_destroy:
			retVal = sys_env_destroy(a1);
			break;
f010466f:	eb 0f                	jmp    f0104680 <syscall+0xf0>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104671:	a1 e8 f1 17 f0       	mov    0xf017f1e8,%eax
f0104676:	8b 40 48             	mov    0x48(%eax),%eax
		case SYS_env_destroy:
			retVal = sys_env_destroy(a1);
			break;
		case SYS_getenvid:
			retVal = sys_getenvid();
			break;
f0104679:	eb 05                	jmp    f0104680 <syscall+0xf0>
		default:
			retVal = -E_INVAL;
f010467b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
	return retVal;
}
f0104680:	c9                   	leave  
f0104681:	c3                   	ret    

f0104682 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104682:	55                   	push   %ebp
f0104683:	89 e5                	mov    %esp,%ebp
f0104685:	57                   	push   %edi
f0104686:	56                   	push   %esi
f0104687:	53                   	push   %ebx
f0104688:	83 ec 14             	sub    $0x14,%esp
f010468b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010468e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104691:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104694:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104697:	8b 1a                	mov    (%edx),%ebx
f0104699:	8b 01                	mov    (%ecx),%eax
f010469b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010469e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01046a5:	e9 88 00 00 00       	jmp    f0104732 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f01046aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01046ad:	01 d8                	add    %ebx,%eax
f01046af:	89 c7                	mov    %eax,%edi
f01046b1:	c1 ef 1f             	shr    $0x1f,%edi
f01046b4:	01 c7                	add    %eax,%edi
f01046b6:	d1 ff                	sar    %edi
f01046b8:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01046bb:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01046be:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01046c1:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01046c3:	eb 03                	jmp    f01046c8 <stab_binsearch+0x46>
			m--;
f01046c5:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01046c8:	39 c3                	cmp    %eax,%ebx
f01046ca:	7f 1f                	jg     f01046eb <stab_binsearch+0x69>
f01046cc:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01046d0:	83 ea 0c             	sub    $0xc,%edx
f01046d3:	39 f1                	cmp    %esi,%ecx
f01046d5:	75 ee                	jne    f01046c5 <stab_binsearch+0x43>
f01046d7:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01046da:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01046dd:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01046e0:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01046e4:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01046e7:	76 18                	jbe    f0104701 <stab_binsearch+0x7f>
f01046e9:	eb 05                	jmp    f01046f0 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01046eb:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01046ee:	eb 42                	jmp    f0104732 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01046f0:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01046f3:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01046f5:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01046f8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01046ff:	eb 31                	jmp    f0104732 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0104701:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104704:	73 17                	jae    f010471d <stab_binsearch+0x9b>
			*region_right = m - 1;
f0104706:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0104709:	83 e8 01             	sub    $0x1,%eax
f010470c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010470f:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104712:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104714:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010471b:	eb 15                	jmp    f0104732 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010471d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104720:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0104723:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f0104725:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104729:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010472b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104732:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104735:	0f 8e 6f ff ff ff    	jle    f01046aa <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010473b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010473f:	75 0f                	jne    f0104750 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0104741:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104744:	8b 00                	mov    (%eax),%eax
f0104746:	83 e8 01             	sub    $0x1,%eax
f0104749:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010474c:	89 07                	mov    %eax,(%edi)
f010474e:	eb 2c                	jmp    f010477c <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104750:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104753:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104755:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104758:	8b 0f                	mov    (%edi),%ecx
f010475a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010475d:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0104760:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104763:	eb 03                	jmp    f0104768 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104765:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104768:	39 c8                	cmp    %ecx,%eax
f010476a:	7e 0b                	jle    f0104777 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f010476c:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104770:	83 ea 0c             	sub    $0xc,%edx
f0104773:	39 f3                	cmp    %esi,%ebx
f0104775:	75 ee                	jne    f0104765 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104777:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010477a:	89 07                	mov    %eax,(%edi)
	}
}
f010477c:	83 c4 14             	add    $0x14,%esp
f010477f:	5b                   	pop    %ebx
f0104780:	5e                   	pop    %esi
f0104781:	5f                   	pop    %edi
f0104782:	5d                   	pop    %ebp
f0104783:	c3                   	ret    

f0104784 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104784:	55                   	push   %ebp
f0104785:	89 e5                	mov    %esp,%ebp
f0104787:	57                   	push   %edi
f0104788:	56                   	push   %esi
f0104789:	53                   	push   %ebx
f010478a:	83 ec 4c             	sub    $0x4c,%esp
f010478d:	8b 75 08             	mov    0x8(%ebp),%esi
f0104790:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104793:	c7 07 68 71 10 f0    	movl   $0xf0107168,(%edi)
	info->eip_line = 0;
f0104799:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f01047a0:	c7 47 08 68 71 10 f0 	movl   $0xf0107168,0x8(%edi)
	info->eip_fn_namelen = 9;
f01047a7:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f01047ae:	89 77 10             	mov    %esi,0x10(%edi)
	info->eip_fn_narg = 0;
f01047b1:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01047b8:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01047be:	0f 87 ae 00 00 00    	ja     f0104872 <debuginfo_eip+0xee>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) < 0)
f01047c4:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f01047cb:	00 
f01047cc:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f01047d3:	00 
f01047d4:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f01047db:	00 
f01047dc:	a1 e8 f1 17 f0       	mov    0xf017f1e8,%eax
f01047e1:	89 04 24             	mov    %eax,(%esp)
f01047e4:	e8 8f ec ff ff       	call   f0103478 <user_mem_check>
f01047e9:	85 c0                	test   %eax,%eax
f01047eb:	0f 88 47 02 00 00    	js     f0104a38 <debuginfo_eip+0x2b4>
			return -1;
		stabs = usd->stabs;
f01047f1:	a1 00 00 20 00       	mov    0x200000,%eax
f01047f6:	89 c1                	mov    %eax,%ecx
f01047f8:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f01047fb:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f0104801:	a1 08 00 20 00       	mov    0x200008,%eax
f0104806:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0104809:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f010480f:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)stabs, stab_end - stabs, PTE_U) < 0)
f0104812:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0104819:	00 
f010481a:	89 d8                	mov    %ebx,%eax
f010481c:	29 c8                	sub    %ecx,%eax
f010481e:	c1 f8 02             	sar    $0x2,%eax
f0104821:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0104827:	89 44 24 08          	mov    %eax,0x8(%esp)
f010482b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010482f:	a1 e8 f1 17 f0       	mov    0xf017f1e8,%eax
f0104834:	89 04 24             	mov    %eax,(%esp)
f0104837:	e8 3c ec ff ff       	call   f0103478 <user_mem_check>
f010483c:	85 c0                	test   %eax,%eax
f010483e:	0f 88 fb 01 00 00    	js     f0104a3f <debuginfo_eip+0x2bb>
			return -1;
		if (user_mem_check(curenv, (void *)stabstr, stabstr_end - stabstr, PTE_U) < 0)
f0104844:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f010484b:	00 
f010484c:	8b 55 bc             	mov    -0x44(%ebp),%edx
f010484f:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0104852:	29 ca                	sub    %ecx,%edx
f0104854:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104858:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010485c:	a1 e8 f1 17 f0       	mov    0xf017f1e8,%eax
f0104861:	89 04 24             	mov    %eax,(%esp)
f0104864:	e8 0f ec ff ff       	call   f0103478 <user_mem_check>
f0104869:	85 c0                	test   %eax,%eax
f010486b:	79 1f                	jns    f010488c <debuginfo_eip+0x108>
f010486d:	e9 d4 01 00 00       	jmp    f0104a46 <debuginfo_eip+0x2c2>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104872:	c7 45 bc 7d 27 11 f0 	movl   $0xf011277d,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104879:	c7 45 c0 89 fb 10 f0 	movl   $0xf010fb89,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104880:	bb 88 fb 10 f0       	mov    $0xf010fb88,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104885:	c7 45 c4 80 73 10 f0 	movl   $0xf0107380,-0x3c(%ebp)
		if (user_mem_check(curenv, (void *)stabstr, stabstr_end - stabstr, PTE_U) < 0)
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010488c:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010488f:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f0104892:	0f 83 b5 01 00 00    	jae    f0104a4d <debuginfo_eip+0x2c9>
f0104898:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f010489c:	0f 85 b2 01 00 00    	jne    f0104a54 <debuginfo_eip+0x2d0>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01048a2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01048a9:	2b 5d c4             	sub    -0x3c(%ebp),%ebx
f01048ac:	c1 fb 02             	sar    $0x2,%ebx
f01048af:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f01048b5:	83 e8 01             	sub    $0x1,%eax
f01048b8:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01048bb:	89 74 24 04          	mov    %esi,0x4(%esp)
f01048bf:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01048c6:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01048c9:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01048cc:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01048cf:	89 d8                	mov    %ebx,%eax
f01048d1:	e8 ac fd ff ff       	call   f0104682 <stab_binsearch>
	if (lfile == 0)
f01048d6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01048d9:	85 c0                	test   %eax,%eax
f01048db:	0f 84 7a 01 00 00    	je     f0104a5b <debuginfo_eip+0x2d7>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01048e1:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01048e4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01048e7:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01048ea:	89 74 24 04          	mov    %esi,0x4(%esp)
f01048ee:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f01048f5:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01048f8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01048fb:	89 d8                	mov    %ebx,%eax
f01048fd:	e8 80 fd ff ff       	call   f0104682 <stab_binsearch>

	if (lfun <= rfun) {
f0104902:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104905:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0104908:	39 c8                	cmp    %ecx,%eax
f010490a:	7f 32                	jg     f010493e <debuginfo_eip+0x1ba>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010490c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010490f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104912:	8d 1c 93             	lea    (%ebx,%edx,4),%ebx
f0104915:	8b 13                	mov    (%ebx),%edx
f0104917:	89 55 b8             	mov    %edx,-0x48(%ebp)
f010491a:	8b 55 bc             	mov    -0x44(%ebp),%edx
f010491d:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104920:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f0104923:	73 09                	jae    f010492e <debuginfo_eip+0x1aa>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104925:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0104928:	03 55 c0             	add    -0x40(%ebp),%edx
f010492b:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010492e:	8b 53 08             	mov    0x8(%ebx),%edx
f0104931:	89 57 10             	mov    %edx,0x10(%edi)
		addr -= info->eip_fn_addr;
f0104934:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0104936:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104939:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f010493c:	eb 0f                	jmp    f010494d <debuginfo_eip+0x1c9>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010493e:	89 77 10             	mov    %esi,0x10(%edi)
		lline = lfile;
f0104941:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104944:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104947:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010494a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010494d:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0104954:	00 
f0104955:	8b 47 08             	mov    0x8(%edi),%eax
f0104958:	89 04 24             	mov    %eax,(%esp)
f010495b:	e8 2b 09 00 00       	call   f010528b <strfind>
f0104960:	2b 47 08             	sub    0x8(%edi),%eax
f0104963:	89 47 0c             	mov    %eax,0xc(%edi)
	//
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0104966:	89 74 24 04          	mov    %esi,0x4(%esp)
f010496a:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0104971:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104974:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104977:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f010497a:	89 f0                	mov    %esi,%eax
f010497c:	e8 01 fd ff ff       	call   f0104682 <stab_binsearch>
	
	if(lline <= rline){
f0104981:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104984:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104987:	0f 8f d5 00 00 00    	jg     f0104a62 <debuginfo_eip+0x2de>
		info->eip_line = stabs[lline].n_desc;
f010498d:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104990:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0104995:	89 47 04             	mov    %eax,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104998:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010499b:	89 c3                	mov    %eax,%ebx
f010499d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01049a0:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01049a3:	8d 14 96             	lea    (%esi,%edx,4),%edx
f01049a6:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01049a9:	89 df                	mov    %ebx,%edi
f01049ab:	eb 06                	jmp    f01049b3 <debuginfo_eip+0x22f>
f01049ad:	83 e8 01             	sub    $0x1,%eax
f01049b0:	83 ea 0c             	sub    $0xc,%edx
f01049b3:	89 c6                	mov    %eax,%esi
f01049b5:	39 c7                	cmp    %eax,%edi
f01049b7:	7f 3c                	jg     f01049f5 <debuginfo_eip+0x271>
	       && stabs[lline].n_type != N_SOL
f01049b9:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01049bd:	80 f9 84             	cmp    $0x84,%cl
f01049c0:	75 08                	jne    f01049ca <debuginfo_eip+0x246>
f01049c2:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01049c5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01049c8:	eb 11                	jmp    f01049db <debuginfo_eip+0x257>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01049ca:	80 f9 64             	cmp    $0x64,%cl
f01049cd:	75 de                	jne    f01049ad <debuginfo_eip+0x229>
f01049cf:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f01049d3:	74 d8                	je     f01049ad <debuginfo_eip+0x229>
f01049d5:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01049d8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01049db:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01049de:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01049e1:	8b 04 86             	mov    (%esi,%eax,4),%eax
f01049e4:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01049e7:	2b 55 c0             	sub    -0x40(%ebp),%edx
f01049ea:	39 d0                	cmp    %edx,%eax
f01049ec:	73 0a                	jae    f01049f8 <debuginfo_eip+0x274>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01049ee:	03 45 c0             	add    -0x40(%ebp),%eax
f01049f1:	89 07                	mov    %eax,(%edi)
f01049f3:	eb 03                	jmp    f01049f8 <debuginfo_eip+0x274>
f01049f5:	8b 7d 0c             	mov    0xc(%ebp),%edi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01049f8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01049fb:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01049fe:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104a03:	39 da                	cmp    %ebx,%edx
f0104a05:	7d 67                	jge    f0104a6e <debuginfo_eip+0x2ea>
		for (lline = lfun + 1;
f0104a07:	83 c2 01             	add    $0x1,%edx
f0104a0a:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104a0d:	89 d0                	mov    %edx,%eax
f0104a0f:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104a12:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104a15:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0104a18:	eb 04                	jmp    f0104a1e <debuginfo_eip+0x29a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104a1a:	83 47 14 01          	addl   $0x1,0x14(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104a1e:	39 c3                	cmp    %eax,%ebx
f0104a20:	7e 47                	jle    f0104a69 <debuginfo_eip+0x2e5>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104a22:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104a26:	83 c0 01             	add    $0x1,%eax
f0104a29:	83 c2 0c             	add    $0xc,%edx
f0104a2c:	80 f9 a0             	cmp    $0xa0,%cl
f0104a2f:	74 e9                	je     f0104a1a <debuginfo_eip+0x296>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104a31:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a36:	eb 36                	jmp    f0104a6e <debuginfo_eip+0x2ea>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) < 0)
			return -1;
f0104a38:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a3d:	eb 2f                	jmp    f0104a6e <debuginfo_eip+0x2ea>
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (void *)stabs, stab_end - stabs, PTE_U) < 0)
			return -1;
f0104a3f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a44:	eb 28                	jmp    f0104a6e <debuginfo_eip+0x2ea>
		if (user_mem_check(curenv, (void *)stabstr, stabstr_end - stabstr, PTE_U) < 0)
			return -1;
f0104a46:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a4b:	eb 21                	jmp    f0104a6e <debuginfo_eip+0x2ea>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104a4d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a52:	eb 1a                	jmp    f0104a6e <debuginfo_eip+0x2ea>
f0104a54:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a59:	eb 13                	jmp    f0104a6e <debuginfo_eip+0x2ea>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104a5b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a60:	eb 0c                	jmp    f0104a6e <debuginfo_eip+0x2ea>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	
	if(lline <= rline){
		info->eip_line = stabs[lline].n_desc;
	}else{
		return -1;
f0104a62:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a67:	eb 05                	jmp    f0104a6e <debuginfo_eip+0x2ea>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104a69:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104a6e:	83 c4 4c             	add    $0x4c,%esp
f0104a71:	5b                   	pop    %ebx
f0104a72:	5e                   	pop    %esi
f0104a73:	5f                   	pop    %edi
f0104a74:	5d                   	pop    %ebp
f0104a75:	c3                   	ret    
f0104a76:	66 90                	xchg   %ax,%ax
f0104a78:	66 90                	xchg   %ax,%ax
f0104a7a:	66 90                	xchg   %ax,%ax
f0104a7c:	66 90                	xchg   %ax,%ax
f0104a7e:	66 90                	xchg   %ax,%ax

f0104a80 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104a80:	55                   	push   %ebp
f0104a81:	89 e5                	mov    %esp,%ebp
f0104a83:	57                   	push   %edi
f0104a84:	56                   	push   %esi
f0104a85:	53                   	push   %ebx
f0104a86:	83 ec 3c             	sub    $0x3c,%esp
f0104a89:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104a8c:	89 d7                	mov    %edx,%edi
f0104a8e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a91:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104a94:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104a97:	89 c3                	mov    %eax,%ebx
f0104a99:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104a9c:	8b 45 10             	mov    0x10(%ebp),%eax
f0104a9f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104aa2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104aa7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104aaa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104aad:	39 d9                	cmp    %ebx,%ecx
f0104aaf:	72 05                	jb     f0104ab6 <printnum+0x36>
f0104ab1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0104ab4:	77 69                	ja     f0104b1f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104ab6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0104ab9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0104abd:	83 ee 01             	sub    $0x1,%esi
f0104ac0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104ac4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104ac8:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104acc:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104ad0:	89 c3                	mov    %eax,%ebx
f0104ad2:	89 d6                	mov    %edx,%esi
f0104ad4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104ad7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104ada:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104ade:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104ae2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104ae5:	89 04 24             	mov    %eax,(%esp)
f0104ae8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104aeb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104aef:	e8 bc 09 00 00       	call   f01054b0 <__udivdi3>
f0104af4:	89 d9                	mov    %ebx,%ecx
f0104af6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104afa:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104afe:	89 04 24             	mov    %eax,(%esp)
f0104b01:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104b05:	89 fa                	mov    %edi,%edx
f0104b07:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b0a:	e8 71 ff ff ff       	call   f0104a80 <printnum>
f0104b0f:	eb 1b                	jmp    f0104b2c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104b11:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104b15:	8b 45 18             	mov    0x18(%ebp),%eax
f0104b18:	89 04 24             	mov    %eax,(%esp)
f0104b1b:	ff d3                	call   *%ebx
f0104b1d:	eb 03                	jmp    f0104b22 <printnum+0xa2>
f0104b1f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104b22:	83 ee 01             	sub    $0x1,%esi
f0104b25:	85 f6                	test   %esi,%esi
f0104b27:	7f e8                	jg     f0104b11 <printnum+0x91>
f0104b29:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104b2c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104b30:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104b34:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104b37:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104b3a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104b3e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104b42:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104b45:	89 04 24             	mov    %eax,(%esp)
f0104b48:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104b4b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b4f:	e8 8c 0a 00 00       	call   f01055e0 <__umoddi3>
f0104b54:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104b58:	0f be 80 72 71 10 f0 	movsbl -0xfef8e8e(%eax),%eax
f0104b5f:	89 04 24             	mov    %eax,(%esp)
f0104b62:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b65:	ff d0                	call   *%eax
}
f0104b67:	83 c4 3c             	add    $0x3c,%esp
f0104b6a:	5b                   	pop    %ebx
f0104b6b:	5e                   	pop    %esi
f0104b6c:	5f                   	pop    %edi
f0104b6d:	5d                   	pop    %ebp
f0104b6e:	c3                   	ret    

f0104b6f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104b6f:	55                   	push   %ebp
f0104b70:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104b72:	83 fa 01             	cmp    $0x1,%edx
f0104b75:	7e 0e                	jle    f0104b85 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104b77:	8b 10                	mov    (%eax),%edx
f0104b79:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104b7c:	89 08                	mov    %ecx,(%eax)
f0104b7e:	8b 02                	mov    (%edx),%eax
f0104b80:	8b 52 04             	mov    0x4(%edx),%edx
f0104b83:	eb 22                	jmp    f0104ba7 <getuint+0x38>
	else if (lflag)
f0104b85:	85 d2                	test   %edx,%edx
f0104b87:	74 10                	je     f0104b99 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104b89:	8b 10                	mov    (%eax),%edx
f0104b8b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104b8e:	89 08                	mov    %ecx,(%eax)
f0104b90:	8b 02                	mov    (%edx),%eax
f0104b92:	ba 00 00 00 00       	mov    $0x0,%edx
f0104b97:	eb 0e                	jmp    f0104ba7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104b99:	8b 10                	mov    (%eax),%edx
f0104b9b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104b9e:	89 08                	mov    %ecx,(%eax)
f0104ba0:	8b 02                	mov    (%edx),%eax
f0104ba2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104ba7:	5d                   	pop    %ebp
f0104ba8:	c3                   	ret    

f0104ba9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104ba9:	55                   	push   %ebp
f0104baa:	89 e5                	mov    %esp,%ebp
f0104bac:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104baf:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104bb3:	8b 10                	mov    (%eax),%edx
f0104bb5:	3b 50 04             	cmp    0x4(%eax),%edx
f0104bb8:	73 0a                	jae    f0104bc4 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104bba:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104bbd:	89 08                	mov    %ecx,(%eax)
f0104bbf:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bc2:	88 02                	mov    %al,(%edx)
}
f0104bc4:	5d                   	pop    %ebp
f0104bc5:	c3                   	ret    

f0104bc6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104bc6:	55                   	push   %ebp
f0104bc7:	89 e5                	mov    %esp,%ebp
f0104bc9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0104bcc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104bcf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104bd3:	8b 45 10             	mov    0x10(%ebp),%eax
f0104bd6:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104bda:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104bdd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104be1:	8b 45 08             	mov    0x8(%ebp),%eax
f0104be4:	89 04 24             	mov    %eax,(%esp)
f0104be7:	e8 02 00 00 00       	call   f0104bee <vprintfmt>
	va_end(ap);
}
f0104bec:	c9                   	leave  
f0104bed:	c3                   	ret    

f0104bee <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104bee:	55                   	push   %ebp
f0104bef:	89 e5                	mov    %esp,%ebp
f0104bf1:	57                   	push   %edi
f0104bf2:	56                   	push   %esi
f0104bf3:	53                   	push   %ebx
f0104bf4:	83 ec 3c             	sub    $0x3c,%esp
f0104bf7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104bfa:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0104bfd:	eb 14                	jmp    f0104c13 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104bff:	85 c0                	test   %eax,%eax
f0104c01:	0f 84 b3 03 00 00    	je     f0104fba <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0104c07:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104c0b:	89 04 24             	mov    %eax,(%esp)
f0104c0e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104c11:	89 f3                	mov    %esi,%ebx
f0104c13:	8d 73 01             	lea    0x1(%ebx),%esi
f0104c16:	0f b6 03             	movzbl (%ebx),%eax
f0104c19:	83 f8 25             	cmp    $0x25,%eax
f0104c1c:	75 e1                	jne    f0104bff <vprintfmt+0x11>
f0104c1e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0104c22:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0104c29:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0104c30:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0104c37:	ba 00 00 00 00       	mov    $0x0,%edx
f0104c3c:	eb 1d                	jmp    f0104c5b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104c3e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104c40:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0104c44:	eb 15                	jmp    f0104c5b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104c46:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104c48:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0104c4c:	eb 0d                	jmp    f0104c5b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0104c4e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104c51:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104c54:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104c5b:	8d 5e 01             	lea    0x1(%esi),%ebx
f0104c5e:	0f b6 0e             	movzbl (%esi),%ecx
f0104c61:	0f b6 c1             	movzbl %cl,%eax
f0104c64:	83 e9 23             	sub    $0x23,%ecx
f0104c67:	80 f9 55             	cmp    $0x55,%cl
f0104c6a:	0f 87 2a 03 00 00    	ja     f0104f9a <vprintfmt+0x3ac>
f0104c70:	0f b6 c9             	movzbl %cl,%ecx
f0104c73:	ff 24 8d fc 71 10 f0 	jmp    *-0xfef8e04(,%ecx,4)
f0104c7a:	89 de                	mov    %ebx,%esi
f0104c7c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104c81:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0104c84:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0104c88:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0104c8b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0104c8e:	83 fb 09             	cmp    $0x9,%ebx
f0104c91:	77 36                	ja     f0104cc9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104c93:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104c96:	eb e9                	jmp    f0104c81 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104c98:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c9b:	8d 48 04             	lea    0x4(%eax),%ecx
f0104c9e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104ca1:	8b 00                	mov    (%eax),%eax
f0104ca3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104ca6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104ca8:	eb 22                	jmp    f0104ccc <vprintfmt+0xde>
f0104caa:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104cad:	85 c9                	test   %ecx,%ecx
f0104caf:	b8 00 00 00 00       	mov    $0x0,%eax
f0104cb4:	0f 49 c1             	cmovns %ecx,%eax
f0104cb7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104cba:	89 de                	mov    %ebx,%esi
f0104cbc:	eb 9d                	jmp    f0104c5b <vprintfmt+0x6d>
f0104cbe:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104cc0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0104cc7:	eb 92                	jmp    f0104c5b <vprintfmt+0x6d>
f0104cc9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f0104ccc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104cd0:	79 89                	jns    f0104c5b <vprintfmt+0x6d>
f0104cd2:	e9 77 ff ff ff       	jmp    f0104c4e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104cd7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104cda:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104cdc:	e9 7a ff ff ff       	jmp    f0104c5b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104ce1:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ce4:	8d 50 04             	lea    0x4(%eax),%edx
f0104ce7:	89 55 14             	mov    %edx,0x14(%ebp)
f0104cea:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104cee:	8b 00                	mov    (%eax),%eax
f0104cf0:	89 04 24             	mov    %eax,(%esp)
f0104cf3:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104cf6:	e9 18 ff ff ff       	jmp    f0104c13 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104cfb:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cfe:	8d 50 04             	lea    0x4(%eax),%edx
f0104d01:	89 55 14             	mov    %edx,0x14(%ebp)
f0104d04:	8b 00                	mov    (%eax),%eax
f0104d06:	99                   	cltd   
f0104d07:	31 d0                	xor    %edx,%eax
f0104d09:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104d0b:	83 f8 06             	cmp    $0x6,%eax
f0104d0e:	7f 0b                	jg     f0104d1b <vprintfmt+0x12d>
f0104d10:	8b 14 85 54 73 10 f0 	mov    -0xfef8cac(,%eax,4),%edx
f0104d17:	85 d2                	test   %edx,%edx
f0104d19:	75 20                	jne    f0104d3b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f0104d1b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104d1f:	c7 44 24 08 8a 71 10 	movl   $0xf010718a,0x8(%esp)
f0104d26:	f0 
f0104d27:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104d2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d2e:	89 04 24             	mov    %eax,(%esp)
f0104d31:	e8 90 fe ff ff       	call   f0104bc6 <printfmt>
f0104d36:	e9 d8 fe ff ff       	jmp    f0104c13 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0104d3b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104d3f:	c7 44 24 08 9d 69 10 	movl   $0xf010699d,0x8(%esp)
f0104d46:	f0 
f0104d47:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104d4b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d4e:	89 04 24             	mov    %eax,(%esp)
f0104d51:	e8 70 fe ff ff       	call   f0104bc6 <printfmt>
f0104d56:	e9 b8 fe ff ff       	jmp    f0104c13 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d5b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104d5e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104d61:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104d64:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d67:	8d 50 04             	lea    0x4(%eax),%edx
f0104d6a:	89 55 14             	mov    %edx,0x14(%ebp)
f0104d6d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0104d6f:	85 f6                	test   %esi,%esi
f0104d71:	b8 83 71 10 f0       	mov    $0xf0107183,%eax
f0104d76:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0104d79:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0104d7d:	0f 84 97 00 00 00    	je     f0104e1a <vprintfmt+0x22c>
f0104d83:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0104d87:	0f 8e 9b 00 00 00    	jle    f0104e28 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104d8d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104d91:	89 34 24             	mov    %esi,(%esp)
f0104d94:	e8 9f 03 00 00       	call   f0105138 <strnlen>
f0104d99:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0104d9c:	29 c2                	sub    %eax,%edx
f0104d9e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0104da1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0104da5:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104da8:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0104dab:	8b 75 08             	mov    0x8(%ebp),%esi
f0104dae:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104db1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104db3:	eb 0f                	jmp    f0104dc4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0104db5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104db9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104dbc:	89 04 24             	mov    %eax,(%esp)
f0104dbf:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104dc1:	83 eb 01             	sub    $0x1,%ebx
f0104dc4:	85 db                	test   %ebx,%ebx
f0104dc6:	7f ed                	jg     f0104db5 <vprintfmt+0x1c7>
f0104dc8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0104dcb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0104dce:	85 d2                	test   %edx,%edx
f0104dd0:	b8 00 00 00 00       	mov    $0x0,%eax
f0104dd5:	0f 49 c2             	cmovns %edx,%eax
f0104dd8:	29 c2                	sub    %eax,%edx
f0104dda:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0104ddd:	89 d7                	mov    %edx,%edi
f0104ddf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104de2:	eb 50                	jmp    f0104e34 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104de4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104de8:	74 1e                	je     f0104e08 <vprintfmt+0x21a>
f0104dea:	0f be d2             	movsbl %dl,%edx
f0104ded:	83 ea 20             	sub    $0x20,%edx
f0104df0:	83 fa 5e             	cmp    $0x5e,%edx
f0104df3:	76 13                	jbe    f0104e08 <vprintfmt+0x21a>
					putch('?', putdat);
f0104df5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104df8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104dfc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0104e03:	ff 55 08             	call   *0x8(%ebp)
f0104e06:	eb 0d                	jmp    f0104e15 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0104e08:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104e0b:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104e0f:	89 04 24             	mov    %eax,(%esp)
f0104e12:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104e15:	83 ef 01             	sub    $0x1,%edi
f0104e18:	eb 1a                	jmp    f0104e34 <vprintfmt+0x246>
f0104e1a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0104e1d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0104e20:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104e23:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104e26:	eb 0c                	jmp    f0104e34 <vprintfmt+0x246>
f0104e28:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0104e2b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0104e2e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104e31:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104e34:	83 c6 01             	add    $0x1,%esi
f0104e37:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0104e3b:	0f be c2             	movsbl %dl,%eax
f0104e3e:	85 c0                	test   %eax,%eax
f0104e40:	74 27                	je     f0104e69 <vprintfmt+0x27b>
f0104e42:	85 db                	test   %ebx,%ebx
f0104e44:	78 9e                	js     f0104de4 <vprintfmt+0x1f6>
f0104e46:	83 eb 01             	sub    $0x1,%ebx
f0104e49:	79 99                	jns    f0104de4 <vprintfmt+0x1f6>
f0104e4b:	89 f8                	mov    %edi,%eax
f0104e4d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104e50:	8b 75 08             	mov    0x8(%ebp),%esi
f0104e53:	89 c3                	mov    %eax,%ebx
f0104e55:	eb 1a                	jmp    f0104e71 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104e57:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104e5b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0104e62:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104e64:	83 eb 01             	sub    $0x1,%ebx
f0104e67:	eb 08                	jmp    f0104e71 <vprintfmt+0x283>
f0104e69:	89 fb                	mov    %edi,%ebx
f0104e6b:	8b 75 08             	mov    0x8(%ebp),%esi
f0104e6e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104e71:	85 db                	test   %ebx,%ebx
f0104e73:	7f e2                	jg     f0104e57 <vprintfmt+0x269>
f0104e75:	89 75 08             	mov    %esi,0x8(%ebp)
f0104e78:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0104e7b:	e9 93 fd ff ff       	jmp    f0104c13 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104e80:	83 fa 01             	cmp    $0x1,%edx
f0104e83:	7e 16                	jle    f0104e9b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0104e85:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e88:	8d 50 08             	lea    0x8(%eax),%edx
f0104e8b:	89 55 14             	mov    %edx,0x14(%ebp)
f0104e8e:	8b 50 04             	mov    0x4(%eax),%edx
f0104e91:	8b 00                	mov    (%eax),%eax
f0104e93:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104e96:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104e99:	eb 32                	jmp    f0104ecd <vprintfmt+0x2df>
	else if (lflag)
f0104e9b:	85 d2                	test   %edx,%edx
f0104e9d:	74 18                	je     f0104eb7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f0104e9f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ea2:	8d 50 04             	lea    0x4(%eax),%edx
f0104ea5:	89 55 14             	mov    %edx,0x14(%ebp)
f0104ea8:	8b 30                	mov    (%eax),%esi
f0104eaa:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0104ead:	89 f0                	mov    %esi,%eax
f0104eaf:	c1 f8 1f             	sar    $0x1f,%eax
f0104eb2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104eb5:	eb 16                	jmp    f0104ecd <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0104eb7:	8b 45 14             	mov    0x14(%ebp),%eax
f0104eba:	8d 50 04             	lea    0x4(%eax),%edx
f0104ebd:	89 55 14             	mov    %edx,0x14(%ebp)
f0104ec0:	8b 30                	mov    (%eax),%esi
f0104ec2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0104ec5:	89 f0                	mov    %esi,%eax
f0104ec7:	c1 f8 1f             	sar    $0x1f,%eax
f0104eca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104ecd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104ed0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104ed3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104ed8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104edc:	0f 89 80 00 00 00    	jns    f0104f62 <vprintfmt+0x374>
				putch('-', putdat);
f0104ee2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104ee6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0104eed:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0104ef0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104ef3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104ef6:	f7 d8                	neg    %eax
f0104ef8:	83 d2 00             	adc    $0x0,%edx
f0104efb:	f7 da                	neg    %edx
			}
			base = 10;
f0104efd:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104f02:	eb 5e                	jmp    f0104f62 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104f04:	8d 45 14             	lea    0x14(%ebp),%eax
f0104f07:	e8 63 fc ff ff       	call   f0104b6f <getuint>
			base = 10;
f0104f0c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104f11:	eb 4f                	jmp    f0104f62 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0104f13:	8d 45 14             	lea    0x14(%ebp),%eax
f0104f16:	e8 54 fc ff ff       	call   f0104b6f <getuint>
			base = 8;
f0104f1b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104f20:	eb 40                	jmp    f0104f62 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f0104f22:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104f26:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0104f2d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0104f30:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104f34:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0104f3b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104f3e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f41:	8d 50 04             	lea    0x4(%eax),%edx
f0104f44:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104f47:	8b 00                	mov    (%eax),%eax
f0104f49:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104f4e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104f53:	eb 0d                	jmp    f0104f62 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104f55:	8d 45 14             	lea    0x14(%ebp),%eax
f0104f58:	e8 12 fc ff ff       	call   f0104b6f <getuint>
			base = 16;
f0104f5d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104f62:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0104f66:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104f6a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0104f6d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104f71:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104f75:	89 04 24             	mov    %eax,(%esp)
f0104f78:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104f7c:	89 fa                	mov    %edi,%edx
f0104f7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f81:	e8 fa fa ff ff       	call   f0104a80 <printnum>
			break;
f0104f86:	e9 88 fc ff ff       	jmp    f0104c13 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104f8b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104f8f:	89 04 24             	mov    %eax,(%esp)
f0104f92:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104f95:	e9 79 fc ff ff       	jmp    f0104c13 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104f9a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104f9e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0104fa5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104fa8:	89 f3                	mov    %esi,%ebx
f0104faa:	eb 03                	jmp    f0104faf <vprintfmt+0x3c1>
f0104fac:	83 eb 01             	sub    $0x1,%ebx
f0104faf:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0104fb3:	75 f7                	jne    f0104fac <vprintfmt+0x3be>
f0104fb5:	e9 59 fc ff ff       	jmp    f0104c13 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0104fba:	83 c4 3c             	add    $0x3c,%esp
f0104fbd:	5b                   	pop    %ebx
f0104fbe:	5e                   	pop    %esi
f0104fbf:	5f                   	pop    %edi
f0104fc0:	5d                   	pop    %ebp
f0104fc1:	c3                   	ret    

f0104fc2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104fc2:	55                   	push   %ebp
f0104fc3:	89 e5                	mov    %esp,%ebp
f0104fc5:	83 ec 28             	sub    $0x28,%esp
f0104fc8:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fcb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104fce:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104fd1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104fd5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104fd8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104fdf:	85 c0                	test   %eax,%eax
f0104fe1:	74 30                	je     f0105013 <vsnprintf+0x51>
f0104fe3:	85 d2                	test   %edx,%edx
f0104fe5:	7e 2c                	jle    f0105013 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104fe7:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fea:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104fee:	8b 45 10             	mov    0x10(%ebp),%eax
f0104ff1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104ff5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104ff8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ffc:	c7 04 24 a9 4b 10 f0 	movl   $0xf0104ba9,(%esp)
f0105003:	e8 e6 fb ff ff       	call   f0104bee <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0105008:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010500b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010500e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105011:	eb 05                	jmp    f0105018 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0105013:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0105018:	c9                   	leave  
f0105019:	c3                   	ret    

f010501a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010501a:	55                   	push   %ebp
f010501b:	89 e5                	mov    %esp,%ebp
f010501d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0105020:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0105023:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105027:	8b 45 10             	mov    0x10(%ebp),%eax
f010502a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010502e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105031:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105035:	8b 45 08             	mov    0x8(%ebp),%eax
f0105038:	89 04 24             	mov    %eax,(%esp)
f010503b:	e8 82 ff ff ff       	call   f0104fc2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0105040:	c9                   	leave  
f0105041:	c3                   	ret    
f0105042:	66 90                	xchg   %ax,%ax
f0105044:	66 90                	xchg   %ax,%ax
f0105046:	66 90                	xchg   %ax,%ax
f0105048:	66 90                	xchg   %ax,%ax
f010504a:	66 90                	xchg   %ax,%ax
f010504c:	66 90                	xchg   %ax,%ax
f010504e:	66 90                	xchg   %ax,%ax

f0105050 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0105050:	55                   	push   %ebp
f0105051:	89 e5                	mov    %esp,%ebp
f0105053:	57                   	push   %edi
f0105054:	56                   	push   %esi
f0105055:	53                   	push   %ebx
f0105056:	83 ec 1c             	sub    $0x1c,%esp
f0105059:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010505c:	85 c0                	test   %eax,%eax
f010505e:	74 10                	je     f0105070 <readline+0x20>
		cprintf("%s", prompt);
f0105060:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105064:	c7 04 24 9d 69 10 f0 	movl   $0xf010699d,(%esp)
f010506b:	e8 f3 ec ff ff       	call   f0103d63 <cprintf>

	i = 0;
	echoing = iscons(0);
f0105070:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0105077:	e8 c6 b5 ff ff       	call   f0100642 <iscons>
f010507c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010507e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105083:	e8 a9 b5 ff ff       	call   f0100631 <getchar>
f0105088:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010508a:	85 c0                	test   %eax,%eax
f010508c:	79 17                	jns    f01050a5 <readline+0x55>
			cprintf("read error: %e\n", c);
f010508e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105092:	c7 04 24 70 73 10 f0 	movl   $0xf0107370,(%esp)
f0105099:	e8 c5 ec ff ff       	call   f0103d63 <cprintf>
			return NULL;
f010509e:	b8 00 00 00 00       	mov    $0x0,%eax
f01050a3:	eb 6d                	jmp    f0105112 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01050a5:	83 f8 7f             	cmp    $0x7f,%eax
f01050a8:	74 05                	je     f01050af <readline+0x5f>
f01050aa:	83 f8 08             	cmp    $0x8,%eax
f01050ad:	75 19                	jne    f01050c8 <readline+0x78>
f01050af:	85 f6                	test   %esi,%esi
f01050b1:	7e 15                	jle    f01050c8 <readline+0x78>
			if (echoing)
f01050b3:	85 ff                	test   %edi,%edi
f01050b5:	74 0c                	je     f01050c3 <readline+0x73>
				cputchar('\b');
f01050b7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01050be:	e8 5e b5 ff ff       	call   f0100621 <cputchar>
			i--;
f01050c3:	83 ee 01             	sub    $0x1,%esi
f01050c6:	eb bb                	jmp    f0105083 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01050c8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01050ce:	7f 1c                	jg     f01050ec <readline+0x9c>
f01050d0:	83 fb 1f             	cmp    $0x1f,%ebx
f01050d3:	7e 17                	jle    f01050ec <readline+0x9c>
			if (echoing)
f01050d5:	85 ff                	test   %edi,%edi
f01050d7:	74 08                	je     f01050e1 <readline+0x91>
				cputchar(c);
f01050d9:	89 1c 24             	mov    %ebx,(%esp)
f01050dc:	e8 40 b5 ff ff       	call   f0100621 <cputchar>
			buf[i++] = c;
f01050e1:	88 9e a0 fa 17 f0    	mov    %bl,-0xfe80560(%esi)
f01050e7:	8d 76 01             	lea    0x1(%esi),%esi
f01050ea:	eb 97                	jmp    f0105083 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01050ec:	83 fb 0d             	cmp    $0xd,%ebx
f01050ef:	74 05                	je     f01050f6 <readline+0xa6>
f01050f1:	83 fb 0a             	cmp    $0xa,%ebx
f01050f4:	75 8d                	jne    f0105083 <readline+0x33>
			if (echoing)
f01050f6:	85 ff                	test   %edi,%edi
f01050f8:	74 0c                	je     f0105106 <readline+0xb6>
				cputchar('\n');
f01050fa:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0105101:	e8 1b b5 ff ff       	call   f0100621 <cputchar>
			buf[i] = 0;
f0105106:	c6 86 a0 fa 17 f0 00 	movb   $0x0,-0xfe80560(%esi)
			return buf;
f010510d:	b8 a0 fa 17 f0       	mov    $0xf017faa0,%eax
		}
	}
}
f0105112:	83 c4 1c             	add    $0x1c,%esp
f0105115:	5b                   	pop    %ebx
f0105116:	5e                   	pop    %esi
f0105117:	5f                   	pop    %edi
f0105118:	5d                   	pop    %ebp
f0105119:	c3                   	ret    
f010511a:	66 90                	xchg   %ax,%ax
f010511c:	66 90                	xchg   %ax,%ax
f010511e:	66 90                	xchg   %ax,%ax

f0105120 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105120:	55                   	push   %ebp
f0105121:	89 e5                	mov    %esp,%ebp
f0105123:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0105126:	b8 00 00 00 00       	mov    $0x0,%eax
f010512b:	eb 03                	jmp    f0105130 <strlen+0x10>
		n++;
f010512d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0105130:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105134:	75 f7                	jne    f010512d <strlen+0xd>
		n++;
	return n;
}
f0105136:	5d                   	pop    %ebp
f0105137:	c3                   	ret    

f0105138 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0105138:	55                   	push   %ebp
f0105139:	89 e5                	mov    %esp,%ebp
f010513b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010513e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105141:	b8 00 00 00 00       	mov    $0x0,%eax
f0105146:	eb 03                	jmp    f010514b <strnlen+0x13>
		n++;
f0105148:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010514b:	39 d0                	cmp    %edx,%eax
f010514d:	74 06                	je     f0105155 <strnlen+0x1d>
f010514f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0105153:	75 f3                	jne    f0105148 <strnlen+0x10>
		n++;
	return n;
}
f0105155:	5d                   	pop    %ebp
f0105156:	c3                   	ret    

f0105157 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0105157:	55                   	push   %ebp
f0105158:	89 e5                	mov    %esp,%ebp
f010515a:	53                   	push   %ebx
f010515b:	8b 45 08             	mov    0x8(%ebp),%eax
f010515e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0105161:	89 c2                	mov    %eax,%edx
f0105163:	83 c2 01             	add    $0x1,%edx
f0105166:	83 c1 01             	add    $0x1,%ecx
f0105169:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010516d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105170:	84 db                	test   %bl,%bl
f0105172:	75 ef                	jne    f0105163 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0105174:	5b                   	pop    %ebx
f0105175:	5d                   	pop    %ebp
f0105176:	c3                   	ret    

f0105177 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105177:	55                   	push   %ebp
f0105178:	89 e5                	mov    %esp,%ebp
f010517a:	53                   	push   %ebx
f010517b:	83 ec 08             	sub    $0x8,%esp
f010517e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105181:	89 1c 24             	mov    %ebx,(%esp)
f0105184:	e8 97 ff ff ff       	call   f0105120 <strlen>
	strcpy(dst + len, src);
f0105189:	8b 55 0c             	mov    0xc(%ebp),%edx
f010518c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105190:	01 d8                	add    %ebx,%eax
f0105192:	89 04 24             	mov    %eax,(%esp)
f0105195:	e8 bd ff ff ff       	call   f0105157 <strcpy>
	return dst;
}
f010519a:	89 d8                	mov    %ebx,%eax
f010519c:	83 c4 08             	add    $0x8,%esp
f010519f:	5b                   	pop    %ebx
f01051a0:	5d                   	pop    %ebp
f01051a1:	c3                   	ret    

f01051a2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01051a2:	55                   	push   %ebp
f01051a3:	89 e5                	mov    %esp,%ebp
f01051a5:	56                   	push   %esi
f01051a6:	53                   	push   %ebx
f01051a7:	8b 75 08             	mov    0x8(%ebp),%esi
f01051aa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01051ad:	89 f3                	mov    %esi,%ebx
f01051af:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01051b2:	89 f2                	mov    %esi,%edx
f01051b4:	eb 0f                	jmp    f01051c5 <strncpy+0x23>
		*dst++ = *src;
f01051b6:	83 c2 01             	add    $0x1,%edx
f01051b9:	0f b6 01             	movzbl (%ecx),%eax
f01051bc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01051bf:	80 39 01             	cmpb   $0x1,(%ecx)
f01051c2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01051c5:	39 da                	cmp    %ebx,%edx
f01051c7:	75 ed                	jne    f01051b6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01051c9:	89 f0                	mov    %esi,%eax
f01051cb:	5b                   	pop    %ebx
f01051cc:	5e                   	pop    %esi
f01051cd:	5d                   	pop    %ebp
f01051ce:	c3                   	ret    

f01051cf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01051cf:	55                   	push   %ebp
f01051d0:	89 e5                	mov    %esp,%ebp
f01051d2:	56                   	push   %esi
f01051d3:	53                   	push   %ebx
f01051d4:	8b 75 08             	mov    0x8(%ebp),%esi
f01051d7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01051da:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01051dd:	89 f0                	mov    %esi,%eax
f01051df:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01051e3:	85 c9                	test   %ecx,%ecx
f01051e5:	75 0b                	jne    f01051f2 <strlcpy+0x23>
f01051e7:	eb 1d                	jmp    f0105206 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01051e9:	83 c0 01             	add    $0x1,%eax
f01051ec:	83 c2 01             	add    $0x1,%edx
f01051ef:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01051f2:	39 d8                	cmp    %ebx,%eax
f01051f4:	74 0b                	je     f0105201 <strlcpy+0x32>
f01051f6:	0f b6 0a             	movzbl (%edx),%ecx
f01051f9:	84 c9                	test   %cl,%cl
f01051fb:	75 ec                	jne    f01051e9 <strlcpy+0x1a>
f01051fd:	89 c2                	mov    %eax,%edx
f01051ff:	eb 02                	jmp    f0105203 <strlcpy+0x34>
f0105201:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0105203:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0105206:	29 f0                	sub    %esi,%eax
}
f0105208:	5b                   	pop    %ebx
f0105209:	5e                   	pop    %esi
f010520a:	5d                   	pop    %ebp
f010520b:	c3                   	ret    

f010520c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010520c:	55                   	push   %ebp
f010520d:	89 e5                	mov    %esp,%ebp
f010520f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105212:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105215:	eb 06                	jmp    f010521d <strcmp+0x11>
		p++, q++;
f0105217:	83 c1 01             	add    $0x1,%ecx
f010521a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010521d:	0f b6 01             	movzbl (%ecx),%eax
f0105220:	84 c0                	test   %al,%al
f0105222:	74 04                	je     f0105228 <strcmp+0x1c>
f0105224:	3a 02                	cmp    (%edx),%al
f0105226:	74 ef                	je     f0105217 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105228:	0f b6 c0             	movzbl %al,%eax
f010522b:	0f b6 12             	movzbl (%edx),%edx
f010522e:	29 d0                	sub    %edx,%eax
}
f0105230:	5d                   	pop    %ebp
f0105231:	c3                   	ret    

f0105232 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105232:	55                   	push   %ebp
f0105233:	89 e5                	mov    %esp,%ebp
f0105235:	53                   	push   %ebx
f0105236:	8b 45 08             	mov    0x8(%ebp),%eax
f0105239:	8b 55 0c             	mov    0xc(%ebp),%edx
f010523c:	89 c3                	mov    %eax,%ebx
f010523e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105241:	eb 06                	jmp    f0105249 <strncmp+0x17>
		n--, p++, q++;
f0105243:	83 c0 01             	add    $0x1,%eax
f0105246:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0105249:	39 d8                	cmp    %ebx,%eax
f010524b:	74 15                	je     f0105262 <strncmp+0x30>
f010524d:	0f b6 08             	movzbl (%eax),%ecx
f0105250:	84 c9                	test   %cl,%cl
f0105252:	74 04                	je     f0105258 <strncmp+0x26>
f0105254:	3a 0a                	cmp    (%edx),%cl
f0105256:	74 eb                	je     f0105243 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105258:	0f b6 00             	movzbl (%eax),%eax
f010525b:	0f b6 12             	movzbl (%edx),%edx
f010525e:	29 d0                	sub    %edx,%eax
f0105260:	eb 05                	jmp    f0105267 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0105262:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0105267:	5b                   	pop    %ebx
f0105268:	5d                   	pop    %ebp
f0105269:	c3                   	ret    

f010526a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010526a:	55                   	push   %ebp
f010526b:	89 e5                	mov    %esp,%ebp
f010526d:	8b 45 08             	mov    0x8(%ebp),%eax
f0105270:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105274:	eb 07                	jmp    f010527d <strchr+0x13>
		if (*s == c)
f0105276:	38 ca                	cmp    %cl,%dl
f0105278:	74 0f                	je     f0105289 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010527a:	83 c0 01             	add    $0x1,%eax
f010527d:	0f b6 10             	movzbl (%eax),%edx
f0105280:	84 d2                	test   %dl,%dl
f0105282:	75 f2                	jne    f0105276 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0105284:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105289:	5d                   	pop    %ebp
f010528a:	c3                   	ret    

f010528b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010528b:	55                   	push   %ebp
f010528c:	89 e5                	mov    %esp,%ebp
f010528e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105291:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105295:	eb 07                	jmp    f010529e <strfind+0x13>
		if (*s == c)
f0105297:	38 ca                	cmp    %cl,%dl
f0105299:	74 0a                	je     f01052a5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010529b:	83 c0 01             	add    $0x1,%eax
f010529e:	0f b6 10             	movzbl (%eax),%edx
f01052a1:	84 d2                	test   %dl,%dl
f01052a3:	75 f2                	jne    f0105297 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f01052a5:	5d                   	pop    %ebp
f01052a6:	c3                   	ret    

f01052a7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01052a7:	55                   	push   %ebp
f01052a8:	89 e5                	mov    %esp,%ebp
f01052aa:	57                   	push   %edi
f01052ab:	56                   	push   %esi
f01052ac:	53                   	push   %ebx
f01052ad:	8b 7d 08             	mov    0x8(%ebp),%edi
f01052b0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01052b3:	85 c9                	test   %ecx,%ecx
f01052b5:	74 36                	je     f01052ed <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01052b7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01052bd:	75 28                	jne    f01052e7 <memset+0x40>
f01052bf:	f6 c1 03             	test   $0x3,%cl
f01052c2:	75 23                	jne    f01052e7 <memset+0x40>
		c &= 0xFF;
f01052c4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01052c8:	89 d3                	mov    %edx,%ebx
f01052ca:	c1 e3 08             	shl    $0x8,%ebx
f01052cd:	89 d6                	mov    %edx,%esi
f01052cf:	c1 e6 18             	shl    $0x18,%esi
f01052d2:	89 d0                	mov    %edx,%eax
f01052d4:	c1 e0 10             	shl    $0x10,%eax
f01052d7:	09 f0                	or     %esi,%eax
f01052d9:	09 c2                	or     %eax,%edx
f01052db:	89 d0                	mov    %edx,%eax
f01052dd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01052df:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01052e2:	fc                   	cld    
f01052e3:	f3 ab                	rep stos %eax,%es:(%edi)
f01052e5:	eb 06                	jmp    f01052ed <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01052e7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01052ea:	fc                   	cld    
f01052eb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01052ed:	89 f8                	mov    %edi,%eax
f01052ef:	5b                   	pop    %ebx
f01052f0:	5e                   	pop    %esi
f01052f1:	5f                   	pop    %edi
f01052f2:	5d                   	pop    %ebp
f01052f3:	c3                   	ret    

f01052f4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01052f4:	55                   	push   %ebp
f01052f5:	89 e5                	mov    %esp,%ebp
f01052f7:	57                   	push   %edi
f01052f8:	56                   	push   %esi
f01052f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01052fc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01052ff:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105302:	39 c6                	cmp    %eax,%esi
f0105304:	73 35                	jae    f010533b <memmove+0x47>
f0105306:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105309:	39 d0                	cmp    %edx,%eax
f010530b:	73 2e                	jae    f010533b <memmove+0x47>
		s += n;
		d += n;
f010530d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0105310:	89 d6                	mov    %edx,%esi
f0105312:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105314:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010531a:	75 13                	jne    f010532f <memmove+0x3b>
f010531c:	f6 c1 03             	test   $0x3,%cl
f010531f:	75 0e                	jne    f010532f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105321:	83 ef 04             	sub    $0x4,%edi
f0105324:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105327:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010532a:	fd                   	std    
f010532b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010532d:	eb 09                	jmp    f0105338 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010532f:	83 ef 01             	sub    $0x1,%edi
f0105332:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0105335:	fd                   	std    
f0105336:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105338:	fc                   	cld    
f0105339:	eb 1d                	jmp    f0105358 <memmove+0x64>
f010533b:	89 f2                	mov    %esi,%edx
f010533d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010533f:	f6 c2 03             	test   $0x3,%dl
f0105342:	75 0f                	jne    f0105353 <memmove+0x5f>
f0105344:	f6 c1 03             	test   $0x3,%cl
f0105347:	75 0a                	jne    f0105353 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105349:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010534c:	89 c7                	mov    %eax,%edi
f010534e:	fc                   	cld    
f010534f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105351:	eb 05                	jmp    f0105358 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105353:	89 c7                	mov    %eax,%edi
f0105355:	fc                   	cld    
f0105356:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105358:	5e                   	pop    %esi
f0105359:	5f                   	pop    %edi
f010535a:	5d                   	pop    %ebp
f010535b:	c3                   	ret    

f010535c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010535c:	55                   	push   %ebp
f010535d:	89 e5                	mov    %esp,%ebp
f010535f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0105362:	8b 45 10             	mov    0x10(%ebp),%eax
f0105365:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105369:	8b 45 0c             	mov    0xc(%ebp),%eax
f010536c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105370:	8b 45 08             	mov    0x8(%ebp),%eax
f0105373:	89 04 24             	mov    %eax,(%esp)
f0105376:	e8 79 ff ff ff       	call   f01052f4 <memmove>
}
f010537b:	c9                   	leave  
f010537c:	c3                   	ret    

f010537d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010537d:	55                   	push   %ebp
f010537e:	89 e5                	mov    %esp,%ebp
f0105380:	56                   	push   %esi
f0105381:	53                   	push   %ebx
f0105382:	8b 55 08             	mov    0x8(%ebp),%edx
f0105385:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105388:	89 d6                	mov    %edx,%esi
f010538a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010538d:	eb 1a                	jmp    f01053a9 <memcmp+0x2c>
		if (*s1 != *s2)
f010538f:	0f b6 02             	movzbl (%edx),%eax
f0105392:	0f b6 19             	movzbl (%ecx),%ebx
f0105395:	38 d8                	cmp    %bl,%al
f0105397:	74 0a                	je     f01053a3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105399:	0f b6 c0             	movzbl %al,%eax
f010539c:	0f b6 db             	movzbl %bl,%ebx
f010539f:	29 d8                	sub    %ebx,%eax
f01053a1:	eb 0f                	jmp    f01053b2 <memcmp+0x35>
		s1++, s2++;
f01053a3:	83 c2 01             	add    $0x1,%edx
f01053a6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01053a9:	39 f2                	cmp    %esi,%edx
f01053ab:	75 e2                	jne    f010538f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01053ad:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01053b2:	5b                   	pop    %ebx
f01053b3:	5e                   	pop    %esi
f01053b4:	5d                   	pop    %ebp
f01053b5:	c3                   	ret    

f01053b6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01053b6:	55                   	push   %ebp
f01053b7:	89 e5                	mov    %esp,%ebp
f01053b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01053bc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01053bf:	89 c2                	mov    %eax,%edx
f01053c1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01053c4:	eb 07                	jmp    f01053cd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01053c6:	38 08                	cmp    %cl,(%eax)
f01053c8:	74 07                	je     f01053d1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01053ca:	83 c0 01             	add    $0x1,%eax
f01053cd:	39 d0                	cmp    %edx,%eax
f01053cf:	72 f5                	jb     f01053c6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01053d1:	5d                   	pop    %ebp
f01053d2:	c3                   	ret    

f01053d3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01053d3:	55                   	push   %ebp
f01053d4:	89 e5                	mov    %esp,%ebp
f01053d6:	57                   	push   %edi
f01053d7:	56                   	push   %esi
f01053d8:	53                   	push   %ebx
f01053d9:	8b 55 08             	mov    0x8(%ebp),%edx
f01053dc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01053df:	eb 03                	jmp    f01053e4 <strtol+0x11>
		s++;
f01053e1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01053e4:	0f b6 0a             	movzbl (%edx),%ecx
f01053e7:	80 f9 09             	cmp    $0x9,%cl
f01053ea:	74 f5                	je     f01053e1 <strtol+0xe>
f01053ec:	80 f9 20             	cmp    $0x20,%cl
f01053ef:	74 f0                	je     f01053e1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01053f1:	80 f9 2b             	cmp    $0x2b,%cl
f01053f4:	75 0a                	jne    f0105400 <strtol+0x2d>
		s++;
f01053f6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01053f9:	bf 00 00 00 00       	mov    $0x0,%edi
f01053fe:	eb 11                	jmp    f0105411 <strtol+0x3e>
f0105400:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0105405:	80 f9 2d             	cmp    $0x2d,%cl
f0105408:	75 07                	jne    f0105411 <strtol+0x3e>
		s++, neg = 1;
f010540a:	8d 52 01             	lea    0x1(%edx),%edx
f010540d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105411:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0105416:	75 15                	jne    f010542d <strtol+0x5a>
f0105418:	80 3a 30             	cmpb   $0x30,(%edx)
f010541b:	75 10                	jne    f010542d <strtol+0x5a>
f010541d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0105421:	75 0a                	jne    f010542d <strtol+0x5a>
		s += 2, base = 16;
f0105423:	83 c2 02             	add    $0x2,%edx
f0105426:	b8 10 00 00 00       	mov    $0x10,%eax
f010542b:	eb 10                	jmp    f010543d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010542d:	85 c0                	test   %eax,%eax
f010542f:	75 0c                	jne    f010543d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105431:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105433:	80 3a 30             	cmpb   $0x30,(%edx)
f0105436:	75 05                	jne    f010543d <strtol+0x6a>
		s++, base = 8;
f0105438:	83 c2 01             	add    $0x1,%edx
f010543b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010543d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0105442:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0105445:	0f b6 0a             	movzbl (%edx),%ecx
f0105448:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010544b:	89 f0                	mov    %esi,%eax
f010544d:	3c 09                	cmp    $0x9,%al
f010544f:	77 08                	ja     f0105459 <strtol+0x86>
			dig = *s - '0';
f0105451:	0f be c9             	movsbl %cl,%ecx
f0105454:	83 e9 30             	sub    $0x30,%ecx
f0105457:	eb 20                	jmp    f0105479 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0105459:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010545c:	89 f0                	mov    %esi,%eax
f010545e:	3c 19                	cmp    $0x19,%al
f0105460:	77 08                	ja     f010546a <strtol+0x97>
			dig = *s - 'a' + 10;
f0105462:	0f be c9             	movsbl %cl,%ecx
f0105465:	83 e9 57             	sub    $0x57,%ecx
f0105468:	eb 0f                	jmp    f0105479 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010546a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010546d:	89 f0                	mov    %esi,%eax
f010546f:	3c 19                	cmp    $0x19,%al
f0105471:	77 16                	ja     f0105489 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0105473:	0f be c9             	movsbl %cl,%ecx
f0105476:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0105479:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010547c:	7d 0f                	jge    f010548d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010547e:	83 c2 01             	add    $0x1,%edx
f0105481:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0105485:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0105487:	eb bc                	jmp    f0105445 <strtol+0x72>
f0105489:	89 d8                	mov    %ebx,%eax
f010548b:	eb 02                	jmp    f010548f <strtol+0xbc>
f010548d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010548f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105493:	74 05                	je     f010549a <strtol+0xc7>
		*endptr = (char *) s;
f0105495:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105498:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010549a:	f7 d8                	neg    %eax
f010549c:	85 ff                	test   %edi,%edi
f010549e:	0f 44 c3             	cmove  %ebx,%eax
}
f01054a1:	5b                   	pop    %ebx
f01054a2:	5e                   	pop    %esi
f01054a3:	5f                   	pop    %edi
f01054a4:	5d                   	pop    %ebp
f01054a5:	c3                   	ret    
f01054a6:	66 90                	xchg   %ax,%ax
f01054a8:	66 90                	xchg   %ax,%ax
f01054aa:	66 90                	xchg   %ax,%ax
f01054ac:	66 90                	xchg   %ax,%ax
f01054ae:	66 90                	xchg   %ax,%ax

f01054b0 <__udivdi3>:
f01054b0:	55                   	push   %ebp
f01054b1:	57                   	push   %edi
f01054b2:	56                   	push   %esi
f01054b3:	83 ec 0c             	sub    $0xc,%esp
f01054b6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01054ba:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01054be:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01054c2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01054c6:	85 c0                	test   %eax,%eax
f01054c8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01054cc:	89 ea                	mov    %ebp,%edx
f01054ce:	89 0c 24             	mov    %ecx,(%esp)
f01054d1:	75 2d                	jne    f0105500 <__udivdi3+0x50>
f01054d3:	39 e9                	cmp    %ebp,%ecx
f01054d5:	77 61                	ja     f0105538 <__udivdi3+0x88>
f01054d7:	85 c9                	test   %ecx,%ecx
f01054d9:	89 ce                	mov    %ecx,%esi
f01054db:	75 0b                	jne    f01054e8 <__udivdi3+0x38>
f01054dd:	b8 01 00 00 00       	mov    $0x1,%eax
f01054e2:	31 d2                	xor    %edx,%edx
f01054e4:	f7 f1                	div    %ecx
f01054e6:	89 c6                	mov    %eax,%esi
f01054e8:	31 d2                	xor    %edx,%edx
f01054ea:	89 e8                	mov    %ebp,%eax
f01054ec:	f7 f6                	div    %esi
f01054ee:	89 c5                	mov    %eax,%ebp
f01054f0:	89 f8                	mov    %edi,%eax
f01054f2:	f7 f6                	div    %esi
f01054f4:	89 ea                	mov    %ebp,%edx
f01054f6:	83 c4 0c             	add    $0xc,%esp
f01054f9:	5e                   	pop    %esi
f01054fa:	5f                   	pop    %edi
f01054fb:	5d                   	pop    %ebp
f01054fc:	c3                   	ret    
f01054fd:	8d 76 00             	lea    0x0(%esi),%esi
f0105500:	39 e8                	cmp    %ebp,%eax
f0105502:	77 24                	ja     f0105528 <__udivdi3+0x78>
f0105504:	0f bd e8             	bsr    %eax,%ebp
f0105507:	83 f5 1f             	xor    $0x1f,%ebp
f010550a:	75 3c                	jne    f0105548 <__udivdi3+0x98>
f010550c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0105510:	39 34 24             	cmp    %esi,(%esp)
f0105513:	0f 86 9f 00 00 00    	jbe    f01055b8 <__udivdi3+0x108>
f0105519:	39 d0                	cmp    %edx,%eax
f010551b:	0f 82 97 00 00 00    	jb     f01055b8 <__udivdi3+0x108>
f0105521:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105528:	31 d2                	xor    %edx,%edx
f010552a:	31 c0                	xor    %eax,%eax
f010552c:	83 c4 0c             	add    $0xc,%esp
f010552f:	5e                   	pop    %esi
f0105530:	5f                   	pop    %edi
f0105531:	5d                   	pop    %ebp
f0105532:	c3                   	ret    
f0105533:	90                   	nop
f0105534:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105538:	89 f8                	mov    %edi,%eax
f010553a:	f7 f1                	div    %ecx
f010553c:	31 d2                	xor    %edx,%edx
f010553e:	83 c4 0c             	add    $0xc,%esp
f0105541:	5e                   	pop    %esi
f0105542:	5f                   	pop    %edi
f0105543:	5d                   	pop    %ebp
f0105544:	c3                   	ret    
f0105545:	8d 76 00             	lea    0x0(%esi),%esi
f0105548:	89 e9                	mov    %ebp,%ecx
f010554a:	8b 3c 24             	mov    (%esp),%edi
f010554d:	d3 e0                	shl    %cl,%eax
f010554f:	89 c6                	mov    %eax,%esi
f0105551:	b8 20 00 00 00       	mov    $0x20,%eax
f0105556:	29 e8                	sub    %ebp,%eax
f0105558:	89 c1                	mov    %eax,%ecx
f010555a:	d3 ef                	shr    %cl,%edi
f010555c:	89 e9                	mov    %ebp,%ecx
f010555e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0105562:	8b 3c 24             	mov    (%esp),%edi
f0105565:	09 74 24 08          	or     %esi,0x8(%esp)
f0105569:	89 d6                	mov    %edx,%esi
f010556b:	d3 e7                	shl    %cl,%edi
f010556d:	89 c1                	mov    %eax,%ecx
f010556f:	89 3c 24             	mov    %edi,(%esp)
f0105572:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105576:	d3 ee                	shr    %cl,%esi
f0105578:	89 e9                	mov    %ebp,%ecx
f010557a:	d3 e2                	shl    %cl,%edx
f010557c:	89 c1                	mov    %eax,%ecx
f010557e:	d3 ef                	shr    %cl,%edi
f0105580:	09 d7                	or     %edx,%edi
f0105582:	89 f2                	mov    %esi,%edx
f0105584:	89 f8                	mov    %edi,%eax
f0105586:	f7 74 24 08          	divl   0x8(%esp)
f010558a:	89 d6                	mov    %edx,%esi
f010558c:	89 c7                	mov    %eax,%edi
f010558e:	f7 24 24             	mull   (%esp)
f0105591:	39 d6                	cmp    %edx,%esi
f0105593:	89 14 24             	mov    %edx,(%esp)
f0105596:	72 30                	jb     f01055c8 <__udivdi3+0x118>
f0105598:	8b 54 24 04          	mov    0x4(%esp),%edx
f010559c:	89 e9                	mov    %ebp,%ecx
f010559e:	d3 e2                	shl    %cl,%edx
f01055a0:	39 c2                	cmp    %eax,%edx
f01055a2:	73 05                	jae    f01055a9 <__udivdi3+0xf9>
f01055a4:	3b 34 24             	cmp    (%esp),%esi
f01055a7:	74 1f                	je     f01055c8 <__udivdi3+0x118>
f01055a9:	89 f8                	mov    %edi,%eax
f01055ab:	31 d2                	xor    %edx,%edx
f01055ad:	e9 7a ff ff ff       	jmp    f010552c <__udivdi3+0x7c>
f01055b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01055b8:	31 d2                	xor    %edx,%edx
f01055ba:	b8 01 00 00 00       	mov    $0x1,%eax
f01055bf:	e9 68 ff ff ff       	jmp    f010552c <__udivdi3+0x7c>
f01055c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01055c8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01055cb:	31 d2                	xor    %edx,%edx
f01055cd:	83 c4 0c             	add    $0xc,%esp
f01055d0:	5e                   	pop    %esi
f01055d1:	5f                   	pop    %edi
f01055d2:	5d                   	pop    %ebp
f01055d3:	c3                   	ret    
f01055d4:	66 90                	xchg   %ax,%ax
f01055d6:	66 90                	xchg   %ax,%ax
f01055d8:	66 90                	xchg   %ax,%ax
f01055da:	66 90                	xchg   %ax,%ax
f01055dc:	66 90                	xchg   %ax,%ax
f01055de:	66 90                	xchg   %ax,%ax

f01055e0 <__umoddi3>:
f01055e0:	55                   	push   %ebp
f01055e1:	57                   	push   %edi
f01055e2:	56                   	push   %esi
f01055e3:	83 ec 14             	sub    $0x14,%esp
f01055e6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01055ea:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01055ee:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f01055f2:	89 c7                	mov    %eax,%edi
f01055f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01055f8:	8b 44 24 30          	mov    0x30(%esp),%eax
f01055fc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0105600:	89 34 24             	mov    %esi,(%esp)
f0105603:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105607:	85 c0                	test   %eax,%eax
f0105609:	89 c2                	mov    %eax,%edx
f010560b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010560f:	75 17                	jne    f0105628 <__umoddi3+0x48>
f0105611:	39 fe                	cmp    %edi,%esi
f0105613:	76 4b                	jbe    f0105660 <__umoddi3+0x80>
f0105615:	89 c8                	mov    %ecx,%eax
f0105617:	89 fa                	mov    %edi,%edx
f0105619:	f7 f6                	div    %esi
f010561b:	89 d0                	mov    %edx,%eax
f010561d:	31 d2                	xor    %edx,%edx
f010561f:	83 c4 14             	add    $0x14,%esp
f0105622:	5e                   	pop    %esi
f0105623:	5f                   	pop    %edi
f0105624:	5d                   	pop    %ebp
f0105625:	c3                   	ret    
f0105626:	66 90                	xchg   %ax,%ax
f0105628:	39 f8                	cmp    %edi,%eax
f010562a:	77 54                	ja     f0105680 <__umoddi3+0xa0>
f010562c:	0f bd e8             	bsr    %eax,%ebp
f010562f:	83 f5 1f             	xor    $0x1f,%ebp
f0105632:	75 5c                	jne    f0105690 <__umoddi3+0xb0>
f0105634:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0105638:	39 3c 24             	cmp    %edi,(%esp)
f010563b:	0f 87 e7 00 00 00    	ja     f0105728 <__umoddi3+0x148>
f0105641:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105645:	29 f1                	sub    %esi,%ecx
f0105647:	19 c7                	sbb    %eax,%edi
f0105649:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010564d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0105651:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105655:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105659:	83 c4 14             	add    $0x14,%esp
f010565c:	5e                   	pop    %esi
f010565d:	5f                   	pop    %edi
f010565e:	5d                   	pop    %ebp
f010565f:	c3                   	ret    
f0105660:	85 f6                	test   %esi,%esi
f0105662:	89 f5                	mov    %esi,%ebp
f0105664:	75 0b                	jne    f0105671 <__umoddi3+0x91>
f0105666:	b8 01 00 00 00       	mov    $0x1,%eax
f010566b:	31 d2                	xor    %edx,%edx
f010566d:	f7 f6                	div    %esi
f010566f:	89 c5                	mov    %eax,%ebp
f0105671:	8b 44 24 04          	mov    0x4(%esp),%eax
f0105675:	31 d2                	xor    %edx,%edx
f0105677:	f7 f5                	div    %ebp
f0105679:	89 c8                	mov    %ecx,%eax
f010567b:	f7 f5                	div    %ebp
f010567d:	eb 9c                	jmp    f010561b <__umoddi3+0x3b>
f010567f:	90                   	nop
f0105680:	89 c8                	mov    %ecx,%eax
f0105682:	89 fa                	mov    %edi,%edx
f0105684:	83 c4 14             	add    $0x14,%esp
f0105687:	5e                   	pop    %esi
f0105688:	5f                   	pop    %edi
f0105689:	5d                   	pop    %ebp
f010568a:	c3                   	ret    
f010568b:	90                   	nop
f010568c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105690:	8b 04 24             	mov    (%esp),%eax
f0105693:	be 20 00 00 00       	mov    $0x20,%esi
f0105698:	89 e9                	mov    %ebp,%ecx
f010569a:	29 ee                	sub    %ebp,%esi
f010569c:	d3 e2                	shl    %cl,%edx
f010569e:	89 f1                	mov    %esi,%ecx
f01056a0:	d3 e8                	shr    %cl,%eax
f01056a2:	89 e9                	mov    %ebp,%ecx
f01056a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01056a8:	8b 04 24             	mov    (%esp),%eax
f01056ab:	09 54 24 04          	or     %edx,0x4(%esp)
f01056af:	89 fa                	mov    %edi,%edx
f01056b1:	d3 e0                	shl    %cl,%eax
f01056b3:	89 f1                	mov    %esi,%ecx
f01056b5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01056b9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01056bd:	d3 ea                	shr    %cl,%edx
f01056bf:	89 e9                	mov    %ebp,%ecx
f01056c1:	d3 e7                	shl    %cl,%edi
f01056c3:	89 f1                	mov    %esi,%ecx
f01056c5:	d3 e8                	shr    %cl,%eax
f01056c7:	89 e9                	mov    %ebp,%ecx
f01056c9:	09 f8                	or     %edi,%eax
f01056cb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01056cf:	f7 74 24 04          	divl   0x4(%esp)
f01056d3:	d3 e7                	shl    %cl,%edi
f01056d5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01056d9:	89 d7                	mov    %edx,%edi
f01056db:	f7 64 24 08          	mull   0x8(%esp)
f01056df:	39 d7                	cmp    %edx,%edi
f01056e1:	89 c1                	mov    %eax,%ecx
f01056e3:	89 14 24             	mov    %edx,(%esp)
f01056e6:	72 2c                	jb     f0105714 <__umoddi3+0x134>
f01056e8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f01056ec:	72 22                	jb     f0105710 <__umoddi3+0x130>
f01056ee:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01056f2:	29 c8                	sub    %ecx,%eax
f01056f4:	19 d7                	sbb    %edx,%edi
f01056f6:	89 e9                	mov    %ebp,%ecx
f01056f8:	89 fa                	mov    %edi,%edx
f01056fa:	d3 e8                	shr    %cl,%eax
f01056fc:	89 f1                	mov    %esi,%ecx
f01056fe:	d3 e2                	shl    %cl,%edx
f0105700:	89 e9                	mov    %ebp,%ecx
f0105702:	d3 ef                	shr    %cl,%edi
f0105704:	09 d0                	or     %edx,%eax
f0105706:	89 fa                	mov    %edi,%edx
f0105708:	83 c4 14             	add    $0x14,%esp
f010570b:	5e                   	pop    %esi
f010570c:	5f                   	pop    %edi
f010570d:	5d                   	pop    %ebp
f010570e:	c3                   	ret    
f010570f:	90                   	nop
f0105710:	39 d7                	cmp    %edx,%edi
f0105712:	75 da                	jne    f01056ee <__umoddi3+0x10e>
f0105714:	8b 14 24             	mov    (%esp),%edx
f0105717:	89 c1                	mov    %eax,%ecx
f0105719:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010571d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0105721:	eb cb                	jmp    f01056ee <__umoddi3+0x10e>
f0105723:	90                   	nop
f0105724:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105728:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010572c:	0f 82 0f ff ff ff    	jb     f0105641 <__umoddi3+0x61>
f0105732:	e9 1a ff ff ff       	jmp    f0105651 <__umoddi3+0x71>
