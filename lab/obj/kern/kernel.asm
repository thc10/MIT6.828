
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
f0100063:	e8 3f 4f 00 00       	call   f0104fa7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 c2 04 00 00       	call   f010052f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 40 54 10 f0 	movl   $0xf0105440,(%esp)
f010007c:	e8 df 3b 00 00       	call   f0103c60 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 b1 17 00 00       	call   f0101837 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100086:	e8 3f 35 00 00       	call   f01035ca <env_init>
	trap_init();
f010008b:	90                   	nop
f010008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100090:	e8 42 3c 00 00       	call   f0103cd7 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100095:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010009c:	00 
f010009d:	c7 04 24 59 3c 13 f0 	movl   $0xf0133c59,(%esp)
f01000a4:	e8 18 37 00 00       	call   f01037c1 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a9:	a1 e8 f1 17 f0       	mov    0xf017f1e8,%eax
f01000ae:	89 04 24             	mov    %eax,(%esp)
f01000b1:	e8 ce 3a 00 00       	call   f0103b84 <env_run>

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
f01000e3:	c7 04 24 5b 54 10 f0 	movl   $0xf010545b,(%esp)
f01000ea:	e8 71 3b 00 00       	call   f0103c60 <cprintf>
	vcprintf(fmt, ap);
f01000ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000f3:	89 34 24             	mov    %esi,(%esp)
f01000f6:	e8 32 3b 00 00       	call   f0103c2d <vcprintf>
	cprintf("\n");
f01000fb:	c7 04 24 c3 57 10 f0 	movl   $0xf01057c3,(%esp)
f0100102:	e8 59 3b 00 00       	call   f0103c60 <cprintf>
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
f010012d:	c7 04 24 73 54 10 f0 	movl   $0xf0105473,(%esp)
f0100134:	e8 27 3b 00 00       	call   f0103c60 <cprintf>
	vcprintf(fmt, ap);
f0100139:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010013d:	8b 45 10             	mov    0x10(%ebp),%eax
f0100140:	89 04 24             	mov    %eax,(%esp)
f0100143:	e8 e5 3a 00 00       	call   f0103c2d <vcprintf>
	cprintf("\n");
f0100148:	c7 04 24 c3 57 10 f0 	movl   $0xf01057c3,(%esp)
f010014f:	e8 0c 3b 00 00       	call   f0103c60 <cprintf>
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
f010020d:	0f b6 82 e0 55 10 f0 	movzbl -0xfefaa20(%edx),%eax
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
f010024a:	0f b6 82 e0 55 10 f0 	movzbl -0xfefaa20(%edx),%eax
f0100251:	0b 05 a0 ef 17 f0    	or     0xf017efa0,%eax
	shift ^= togglecode[data];
f0100257:	0f b6 8a e0 54 10 f0 	movzbl -0xfefab20(%edx),%ecx
f010025e:	31 c8                	xor    %ecx,%eax
f0100260:	a3 a0 ef 17 f0       	mov    %eax,0xf017efa0

	c = charcode[shift & (CTL | SHIFT)][data];
f0100265:	89 c1                	mov    %eax,%ecx
f0100267:	83 e1 03             	and    $0x3,%ecx
f010026a:	8b 0c 8d c0 54 10 f0 	mov    -0xfefab40(,%ecx,4),%ecx
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
f01002aa:	c7 04 24 8d 54 10 f0 	movl   $0xf010548d,(%esp)
f01002b1:	e8 aa 39 00 00       	call   f0103c60 <cprintf>
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
f0100459:	e8 96 4b 00 00       	call   f0104ff4 <memmove>
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
f010060d:	c7 04 24 99 54 10 f0 	movl   $0xf0105499,(%esp)
f0100614:	e8 47 36 00 00       	call   f0103c60 <cprintf>
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
f010065c:	bb e4 5d 10 f0       	mov    $0xf0105de4,%ebx
f0100661:	be 44 5e 10 f0       	mov    $0xf0105e44,%esi
	int i;

	if(argc == 2){
f0100666:	83 7d 08 02          	cmpl   $0x2,0x8(%ebp)
f010066a:	75 2d                	jne    f0100699 <mon_help+0x49>
f010066c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100671:	89 d8                	mov    %ebx,%eax
f0100673:	c1 e0 04             	shl    $0x4,%eax
		for (i = 0; i < ARRAY_SIZE(commands); i++)
			if (strcmp(argv[1], commands[i].name) == 0)
f0100676:	8b 80 e0 5d 10 f0    	mov    -0xfefa220(%eax),%eax
f010067c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100680:	8b 47 04             	mov    0x4(%edi),%eax
f0100683:	89 04 24             	mov    %eax,(%esp)
f0100686:	e8 81 48 00 00       	call   f0104f0c <strcmp>
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
f01006a6:	c7 04 24 e0 56 10 f0 	movl   $0xf01056e0,(%esp)
f01006ad:	e8 ae 35 00 00       	call   f0103c60 <cprintf>
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
f01006c2:	c7 04 24 e9 56 10 f0 	movl   $0xf01056e9,(%esp)
f01006c9:	e8 92 35 00 00       	call   f0103c60 <cprintf>
f01006ce:	eb 27                	jmp    f01006f7 <mon_help+0xa7>
		else
			cprintf("%s\nUsage : %s\n", commands[i].desc, commands[i].usage);
f01006d0:	89 d8                	mov    %ebx,%eax
f01006d2:	c1 e0 04             	shl    $0x4,%eax
f01006d5:	8b 90 e8 5d 10 f0    	mov    -0xfefa218(%eax),%edx
f01006db:	05 e0 5d 10 f0       	add    $0xf0105de0,%eax
f01006e0:	89 54 24 08          	mov    %edx,0x8(%esp)
f01006e4:	8b 40 04             	mov    0x4(%eax),%eax
f01006e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006eb:	c7 04 24 fc 56 10 f0 	movl   $0xf01056fc,(%esp)
f01006f2:	e8 69 35 00 00       	call   f0103c60 <cprintf>
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
f010070a:	c7 04 24 0b 57 10 f0 	movl   $0xf010570b,(%esp)
f0100711:	e8 4a 35 00 00       	call   f0103c60 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100716:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010071d:	00 
f010071e:	c7 04 24 78 58 10 f0 	movl   $0xf0105878,(%esp)
f0100725:	e8 36 35 00 00       	call   f0103c60 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010072a:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100731:	00 
f0100732:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100739:	f0 
f010073a:	c7 04 24 a0 58 10 f0 	movl   $0xf01058a0,(%esp)
f0100741:	e8 1a 35 00 00       	call   f0103c60 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100746:	c7 44 24 08 37 54 10 	movl   $0x105437,0x8(%esp)
f010074d:	00 
f010074e:	c7 44 24 04 37 54 10 	movl   $0xf0105437,0x4(%esp)
f0100755:	f0 
f0100756:	c7 04 24 c4 58 10 f0 	movl   $0xf01058c4,(%esp)
f010075d:	e8 fe 34 00 00       	call   f0103c60 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100762:	c7 44 24 08 9d ef 17 	movl   $0x17ef9d,0x8(%esp)
f0100769:	00 
f010076a:	c7 44 24 04 9d ef 17 	movl   $0xf017ef9d,0x4(%esp)
f0100771:	f0 
f0100772:	c7 04 24 e8 58 10 f0 	movl   $0xf01058e8,(%esp)
f0100779:	e8 e2 34 00 00       	call   f0103c60 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010077e:	c7 44 24 08 b0 fe 17 	movl   $0x17feb0,0x8(%esp)
f0100785:	00 
f0100786:	c7 44 24 04 b0 fe 17 	movl   $0xf017feb0,0x4(%esp)
f010078d:	f0 
f010078e:	c7 04 24 0c 59 10 f0 	movl   $0xf010590c,(%esp)
f0100795:	e8 c6 34 00 00       	call   f0103c60 <cprintf>
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
f01007bb:	c7 04 24 30 59 10 f0 	movl   $0xf0105930,(%esp)
f01007c2:	e8 99 34 00 00       	call   f0103c60 <cprintf>
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
f01007d9:	c7 04 24 24 57 10 f0 	movl   $0xf0105724,(%esp)
f01007e0:	e8 7b 34 00 00       	call   f0103c60 <cprintf>
	while(ebp != 0){
f01007e5:	eb 77                	jmp    f010085e <mon_backtrace+0x90>
		eip = *((uint32_t *)ebp + 1);
f01007e7:	8b 7e 04             	mov    0x4(%esi),%edi
		debuginfo_eip(eip, &info);
f01007ea:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007f1:	89 3c 24             	mov    %edi,(%esp)
f01007f4:	e8 32 3d 00 00       	call   f010452b <debuginfo_eip>
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
f01007f9:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01007fd:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100801:	c7 04 24 36 57 10 f0 	movl   $0xf0105736,(%esp)
f0100808:	e8 53 34 00 00       	call   f0103c60 <cprintf>
		for(int i = 2; i < 7; i++){
f010080d:	bb 02 00 00 00       	mov    $0x2,%ebx
			cprintf(" %08x", *((uint32_t*)ebp + i));
f0100812:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f0100815:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100819:	c7 04 24 51 57 10 f0 	movl   $0xf0105751,(%esp)
f0100820:	e8 3b 34 00 00       	call   f0103c60 <cprintf>
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
f0100850:	c7 04 24 57 57 10 f0 	movl   $0xf0105757,(%esp)
f0100857:	e8 04 34 00 00       	call   f0103c60 <cprintf>
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
f0100889:	c7 04 24 5c 59 10 f0 	movl   $0xf010595c,(%esp)
f0100890:	e8 cb 33 00 00       	call   f0103c60 <cprintf>
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
f01008af:	e8 1f 48 00 00       	call   f01050d3 <strtol>
	if (*errStr){
f01008b4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01008b7:	80 3a 00             	cmpb   $0x0,(%edx)
f01008ba:	74 18                	je     f01008d4 <mon_showmappings+0x65>
		cprintf("error : invalid input : %s .\n", argv[1]);
f01008bc:	8b 43 04             	mov    0x4(%ebx),%eax
f01008bf:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008c3:	c7 04 24 71 57 10 f0 	movl   $0xf0105771,(%esp)
f01008ca:	e8 91 33 00 00       	call   f0103c60 <cprintf>
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
f0100903:	e8 cb 47 00 00       	call   f01050d3 <strtol>
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
f0100928:	c7 04 24 71 57 10 f0 	movl   $0xf0105771,(%esp)
f010092f:	e8 2c 33 00 00       	call   f0103c60 <cprintf>
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
f0100962:	c7 04 24 88 59 10 f0 	movl   $0xf0105988,(%esp)
f0100969:	e8 f2 32 00 00       	call   f0103c60 <cprintf>
f010096e:	e9 ff 00 00 00       	jmp    f0100a72 <mon_showmappings+0x203>
		}else{
			cprintf("virtual address 0x%08x physical address 0x%08x permission: ", 
f0100973:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100978:	89 44 24 08          	mov    %eax,0x8(%esp)
f010097c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100980:	c7 04 24 ac 59 10 f0 	movl   $0xf01059ac,(%esp)
f0100987:	e8 d4 32 00 00       	call   f0103c60 <cprintf>
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
f0100a66:	c7 04 24 8f 57 10 f0 	movl   $0xf010578f,(%esp)
f0100a6d:	e8 ee 31 00 00       	call   f0103c60 <cprintf>
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
f0100aab:	c7 04 24 e8 59 10 f0 	movl   $0xf01059e8,(%esp)
f0100ab2:	e8 a9 31 00 00       	call   f0103c60 <cprintf>
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
f0100ad0:	c7 04 24 e8 59 10 f0 	movl   $0xf01059e8,(%esp)
f0100ad7:	e8 84 31 00 00       	call   f0103c60 <cprintf>
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
f0100afb:	e8 d3 45 00 00       	call   f01050d3 <strtol>
	if (*errStr){
f0100b00:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100b03:	80 3a 00             	cmpb   $0x0,(%edx)
f0100b06:	74 18                	je     f0100b20 <mon_dump+0x8f>
		cprintf("error : invalid input : %s .\n", argv[1]);
f0100b08:	8b 47 04             	mov    0x4(%edi),%eax
f0100b0b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b0f:	c7 04 24 71 57 10 f0 	movl   $0xf0105771,(%esp)
f0100b16:	e8 45 31 00 00       	call   f0103c60 <cprintf>
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
f0100b3c:	e8 92 45 00 00       	call   f01050d3 <strtol>
	if (*errStr){
f0100b41:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100b44:	80 3a 00             	cmpb   $0x0,(%edx)
f0100b47:	74 18                	je     f0100b61 <mon_dump+0xd0>
		cprintf("error : invalid input : %s .\n", argv[2]);
f0100b49:	8b 47 08             	mov    0x8(%edi),%eax
f0100b4c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b50:	c7 04 24 71 57 10 f0 	movl   $0xf0105771,(%esp)
f0100b57:	e8 04 31 00 00       	call   f0103c60 <cprintf>
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
f0100b97:	c7 04 24 14 5a 10 f0 	movl   $0xf0105a14,(%esp)
f0100b9e:	e8 bd 30 00 00       	call   f0103c60 <cprintf>
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
f0100bcc:	c7 04 24 4c 5a 10 f0 	movl   $0xf0105a4c,(%esp)
f0100bd3:	e8 88 30 00 00       	call   f0103c60 <cprintf>
f0100bd8:	eb 3e                	jmp    f0100c18 <mon_dump+0x187>
		}else{
			cprintf("virtual addr 0x%08x physical addr 0x%08x memory ", PTE_ADDR(*ppte) | PGOFF(start_addr));
f0100bda:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100bdf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100be3:	c7 04 24 70 5a 10 f0 	movl   $0xf0105a70,(%esp)
f0100bea:	e8 71 30 00 00       	call   f0103c60 <cprintf>
f0100bef:	bb 10 00 00 00       	mov    $0x10,%ebx
			for (int i = 0; i < 16; i++)
				cprintf("%02x ", *(unsigned char *)start_addr);
f0100bf4:	0f b6 06             	movzbl (%esi),%eax
f0100bf7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bfb:	c7 04 24 a3 57 10 f0 	movl   $0xf01057a3,(%esp)
f0100c02:	e8 59 30 00 00       	call   f0103c60 <cprintf>
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
f0100c0c:	c7 04 24 c3 57 10 f0 	movl   $0xf01057c3,(%esp)
f0100c13:	e8 48 30 00 00       	call   f0103c60 <cprintf>
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
f0100c50:	c7 04 24 a9 57 10 f0 	movl   $0xf01057a9,(%esp)
f0100c57:	e8 04 30 00 00       	call   f0103c60 <cprintf>
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
f0100c76:	e8 58 44 00 00       	call   f01050d3 <strtol>
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
f0100cab:	c7 04 24 88 59 10 f0 	movl   $0xf0105988,(%esp)
f0100cb2:	e8 a9 2f 00 00       	call   f0103c60 <cprintf>
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
f0100cdd:	ff 24 85 20 5c 10 f0 	jmp    *-0xfefa3e0(,%eax,4)
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
f0100d37:	ff 24 85 fc 5c 10 f0 	jmp    *-0xfefa304(,%eax,4)
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
f0100d8d:	c7 04 24 a4 5a 10 f0 	movl   $0xf0105aa4,(%esp)
f0100d94:	e8 c7 2e 00 00       	call   f0103c60 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100d99:	c7 04 24 c8 5a 10 f0 	movl   $0xf0105ac8,(%esp)
f0100da0:	e8 bb 2e 00 00       	call   f0103c60 <cprintf>

	if (tf != NULL)
f0100da5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100da9:	74 0b                	je     f0100db6 <monitor+0x32>
		print_trapframe(tf);
f0100dab:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dae:	89 04 24             	mov    %eax,(%esp)
f0100db1:	e8 03 33 00 00       	call   f01040b9 <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100db6:	c7 04 24 c5 57 10 f0 	movl   $0xf01057c5,(%esp)
f0100dbd:	e8 8e 3f 00 00       	call   f0104d50 <readline>
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
f0100dee:	c7 04 24 c9 57 10 f0 	movl   $0xf01057c9,(%esp)
f0100df5:	e8 70 41 00 00       	call   f0104f6a <strchr>
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
f0100e10:	c7 04 24 ce 57 10 f0 	movl   $0xf01057ce,(%esp)
f0100e17:	e8 44 2e 00 00       	call   f0103c60 <cprintf>
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
f0100e38:	c7 04 24 c9 57 10 f0 	movl   $0xf01057c9,(%esp)
f0100e3f:	e8 26 41 00 00       	call   f0104f6a <strchr>
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
f0100e64:	8b 80 e0 5d 10 f0    	mov    -0xfefa220(%eax),%eax
f0100e6a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e6e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100e71:	89 04 24             	mov    %eax,(%esp)
f0100e74:	e8 93 40 00 00       	call   f0104f0c <strcmp>
f0100e79:	85 c0                	test   %eax,%eax
f0100e7b:	75 23                	jne    f0100ea0 <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f0100e7d:	c1 e3 04             	shl    $0x4,%ebx
f0100e80:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e83:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e87:	8d 45 a8             	lea    -0x58(%ebp),%eax
f0100e8a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e8e:	89 34 24             	mov    %esi,(%esp)
f0100e91:	ff 93 ec 5d 10 f0    	call   *-0xfefa214(%ebx)
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
f0100eaf:	c7 04 24 eb 57 10 f0 	movl   $0xf01057eb,(%esp)
f0100eb6:	e8 a5 2d 00 00       	call   f0103c60 <cprintf>
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
f0100edd:	e8 0e 2d 00 00       	call   f0103bf0 <mc146818_read>
f0100ee2:	89 c6                	mov    %eax,%esi
f0100ee4:	83 c3 01             	add    $0x1,%ebx
f0100ee7:	89 1c 24             	mov    %ebx,(%esp)
f0100eea:	e8 01 2d 00 00       	call   f0103bf0 <mc146818_read>
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
f0100f55:	c7 44 24 08 40 5e 10 	movl   $0xf0105e40,0x8(%esp)
f0100f5c:	f0 
f0100f5d:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
f0100f64:	00 
f0100f65:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0100f6c:	e8 45 f1 ff ff       	call   f01000b6 <_panic>
		//nextfree should be less than the size of kernel virtual address: 4MB
		if(nextfree >= (char *)KADDR(0x400000))
f0100f71:	3d ff ff 3f f0       	cmp    $0xf03fffff,%eax
f0100f76:	76 1c                	jbe    f0100f94 <boot_alloc+0x99>
			panic("error: nextfree out of the size of kernel virtual address\n");
f0100f78:	c7 44 24 08 64 5e 10 	movl   $0xf0105e64,0x8(%esp)
f0100f7f:	f0 
f0100f80:	c7 44 24 04 72 00 00 	movl   $0x72,0x4(%esp)
f0100f87:	00 
f0100f88:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0100fc7:	c7 44 24 08 40 5e 10 	movl   $0xf0105e40,0x8(%esp)
f0100fce:	f0 
f0100fcf:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f0100fd6:	00 
f0100fd7:	c7 04 24 39 66 10 f0 	movl   $0xf0106639,(%esp)
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
f0101011:	c7 44 24 08 40 5e 10 	movl   $0xf0105e40,0x8(%esp)
f0101018:	f0 
f0101019:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0101020:	00 
f0101021:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f010106e:	c7 44 24 08 a0 5e 10 	movl   $0xf0105ea0,0x8(%esp)
f0101075:	f0 
f0101076:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
f010107d:	00 
f010107e:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f01010ce:	a3 dc f1 17 f0       	mov    %eax,0xf017f1dc
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
f01010d8:	8b 1d dc f1 17 f0    	mov    0xf017f1dc,%ebx
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
f0101108:	c7 44 24 08 40 5e 10 	movl   $0xf0105e40,0x8(%esp)
f010110f:	f0 
f0101110:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f0101117:	00 
f0101118:	c7 04 24 39 66 10 f0 	movl   $0xf0106639,(%esp)
f010111f:	e8 92 ef ff ff       	call   f01000b6 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0101124:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f010112b:	00 
f010112c:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0101133:	00 
	return (void *)(pa + KERNBASE);
f0101134:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101139:	89 04 24             	mov    %eax,(%esp)
f010113c:	e8 66 3e 00 00       	call   f0104fa7 <memset>
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
f0101154:	8b 15 dc f1 17 f0    	mov    0xf017f1dc,%edx
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
f0101182:	c7 44 24 0c 47 66 10 	movl   $0xf0106647,0xc(%esp)
f0101189:	f0 
f010118a:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101191:	f0 
f0101192:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f0101199:	00 
f010119a:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f01011a1:	e8 10 ef ff ff       	call   f01000b6 <_panic>
		assert(pp < pages + npages);
f01011a6:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f01011a9:	72 24                	jb     f01011cf <check_page_free_list+0x177>
f01011ab:	c7 44 24 0c 68 66 10 	movl   $0xf0106668,0xc(%esp)
f01011b2:	f0 
f01011b3:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01011ba:	f0 
f01011bb:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f01011c2:	00 
f01011c3:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f01011ca:	e8 e7 ee ff ff       	call   f01000b6 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f01011cf:	89 d0                	mov    %edx,%eax
f01011d1:	2b 45 d0             	sub    -0x30(%ebp),%eax
f01011d4:	a8 07                	test   $0x7,%al
f01011d6:	74 24                	je     f01011fc <check_page_free_list+0x1a4>
f01011d8:	c7 44 24 0c c4 5e 10 	movl   $0xf0105ec4,0xc(%esp)
f01011df:	f0 
f01011e0:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01011e7:	f0 
f01011e8:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f01011ef:	00 
f01011f0:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0101206:	c7 44 24 0c 7c 66 10 	movl   $0xf010667c,0xc(%esp)
f010120d:	f0 
f010120e:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101215:	f0 
f0101216:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
f010121d:	00 
f010121e:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101225:	e8 8c ee ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f010122a:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f010122f:	75 24                	jne    f0101255 <check_page_free_list+0x1fd>
f0101231:	c7 44 24 0c 8d 66 10 	movl   $0xf010668d,0xc(%esp)
f0101238:	f0 
f0101239:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101240:	f0 
f0101241:	c7 44 24 04 84 02 00 	movl   $0x284,0x4(%esp)
f0101248:	00 
f0101249:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101250:	e8 61 ee ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0101255:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f010125a:	75 24                	jne    f0101280 <check_page_free_list+0x228>
f010125c:	c7 44 24 0c f8 5e 10 	movl   $0xf0105ef8,0xc(%esp)
f0101263:	f0 
f0101264:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010126b:	f0 
f010126c:	c7 44 24 04 85 02 00 	movl   $0x285,0x4(%esp)
f0101273:	00 
f0101274:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f010127b:	e8 36 ee ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0101280:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0101285:	75 24                	jne    f01012ab <check_page_free_list+0x253>
f0101287:	c7 44 24 0c a6 66 10 	movl   $0xf01066a6,0xc(%esp)
f010128e:	f0 
f010128f:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101296:	f0 
f0101297:	c7 44 24 04 86 02 00 	movl   $0x286,0x4(%esp)
f010129e:	00 
f010129f:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f01012c0:	c7 44 24 08 40 5e 10 	movl   $0xf0105e40,0x8(%esp)
f01012c7:	f0 
f01012c8:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f01012cf:	00 
f01012d0:	c7 04 24 39 66 10 f0 	movl   $0xf0106639,(%esp)
f01012d7:	e8 da ed ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f01012dc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01012e1:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f01012e4:	76 2a                	jbe    f0101310 <check_page_free_list+0x2b8>
f01012e6:	c7 44 24 0c 1c 5f 10 	movl   $0xf0105f1c,0xc(%esp)
f01012ed:	f0 
f01012ee:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01012f5:	f0 
f01012f6:	c7 44 24 04 87 02 00 	movl   $0x287,0x4(%esp)
f01012fd:	00 
f01012fe:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0101324:	c7 44 24 0c c0 66 10 	movl   $0xf01066c0,0xc(%esp)
f010132b:	f0 
f010132c:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101333:	f0 
f0101334:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
f010133b:	00 
f010133c:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101343:	e8 6e ed ff ff       	call   f01000b6 <_panic>
	assert(nfree_extmem > 0);
f0101348:	85 ff                	test   %edi,%edi
f010134a:	7f 4d                	jg     f0101399 <check_page_free_list+0x341>
f010134c:	c7 44 24 0c d2 66 10 	movl   $0xf01066d2,0xc(%esp)
f0101353:	f0 
f0101354:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010135b:	f0 
f010135c:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
f0101363:	00 
f0101364:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f010136b:	e8 46 ed ff ff       	call   f01000b6 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0101370:	a1 dc f1 17 f0       	mov    0xf017f1dc,%eax
f0101375:	85 c0                	test   %eax,%eax
f0101377:	0f 85 0d fd ff ff    	jne    f010108a <check_page_free_list+0x32>
f010137d:	e9 ec fc ff ff       	jmp    f010106e <check_page_free_list+0x16>
f0101382:	83 3d dc f1 17 f0 00 	cmpl   $0x0,0xf017f1dc
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
f01013d2:	3b 1d e0 f1 17 f0    	cmp    0xf017f1e0,%ebx
f01013d8:	73 28                	jae    f0101402 <page_init+0x61>
			//The rest of base memory [PGSIZE, npages_basemen * PGSIZE]
			pages[i].pp_ref = 0;
f01013da:	89 f0                	mov    %esi,%eax
f01013dc:	03 05 ac fe 17 f0    	add    0xf017feac,%eax
f01013e2:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f01013e8:	8b 15 dc f1 17 f0    	mov    0xf017f1dc,%edx
f01013ee:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f01013f0:	89 f0                	mov    %esi,%eax
f01013f2:	03 05 ac fe 17 f0    	add    0xf017feac,%eax
f01013f8:	a3 dc f1 17 f0       	mov    %eax,0xf017f1dc
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
f0101440:	c7 44 24 08 64 5f 10 	movl   $0xf0105f64,0x8(%esp)
f0101447:	f0 
f0101448:	c7 44 24 04 2b 01 00 	movl   $0x12b,0x4(%esp)
f010144f:	00 
f0101450:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f010148c:	8b 15 dc f1 17 f0    	mov    0xf017f1dc,%edx
f0101492:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0101494:	89 f0                	mov    %esi,%eax
f0101496:	03 05 ac fe 17 f0    	add    0xf017feac,%eax
f010149c:	a3 dc f1 17 f0       	mov    %eax,0xf017f1dc
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
f01014c1:	8b 1d dc f1 17 f0    	mov    0xf017f1dc,%ebx
f01014c7:	85 db                	test   %ebx,%ebx
f01014c9:	74 6f                	je     f010153a <page_alloc+0x80>
		return NULL;

	struct PageInfo *page = page_free_list;
	page_free_list = page_free_list->pp_link;
f01014cb:	8b 03                	mov    (%ebx),%eax
f01014cd:	a3 dc f1 17 f0       	mov    %eax,0xf017f1dc
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
f01014fd:	c7 44 24 08 40 5e 10 	movl   $0xf0105e40,0x8(%esp)
f0101504:	f0 
f0101505:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f010150c:	00 
f010150d:	c7 04 24 39 66 10 f0 	movl   $0xf0106639,(%esp)
f0101514:	e8 9d eb ff ff       	call   f01000b6 <_panic>
		memset(page2kva(page), '\0', PGSIZE);	//page2kva():get kernel virtual address by pageNum 
f0101519:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101520:	00 
f0101521:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101528:	00 
	return (void *)(pa + KERNBASE);
f0101529:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010152e:	89 04 24             	mov    %eax,(%esp)
f0101531:	e8 71 3a 00 00       	call   f0104fa7 <memset>
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
f010155a:	c7 44 24 08 88 5f 10 	movl   $0xf0105f88,0x8(%esp)
f0101561:	f0 
f0101562:	c7 44 24 04 5d 01 00 	movl   $0x15d,0x4(%esp)
f0101569:	00 
f010156a:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101571:	e8 40 eb ff ff       	call   f01000b6 <_panic>
		return;
	}
	pp->pp_link = page_free_list;
f0101576:	8b 15 dc f1 17 f0    	mov    0xf017f1dc,%edx
f010157c:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f010157e:	a3 dc f1 17 f0       	mov    %eax,0xf017f1dc
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
f01015e9:	c7 44 24 08 40 5e 10 	movl   $0xf0105e40,0x8(%esp)
f01015f0:	f0 
f01015f1:	c7 44 24 04 8d 01 00 	movl   $0x18d,0x4(%esp)
f01015f8:	00 
f01015f9:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f010164c:	c7 44 24 08 40 5e 10 	movl   $0xf0105e40,0x8(%esp)
f0101653:	f0 
f0101654:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f010165b:	00 
f010165c:	c7 04 24 39 66 10 f0 	movl   $0xf0106639,(%esp)
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
f010167c:	c7 44 24 08 64 5f 10 	movl   $0xf0105f64,0x8(%esp)
f0101683:	f0 
f0101684:	c7 44 24 04 95 01 00 	movl   $0x195,0x4(%esp)
f010168b:	00 
f010168c:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0101755:	c7 44 24 08 b4 5f 10 	movl   $0xf0105fb4,0x8(%esp)
f010175c:	f0 
f010175d:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0101764:	00 
f0101765:	c7 04 24 39 66 10 f0 	movl   $0xf0106639,(%esp)
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
f010188c:	89 15 e0 f1 17 f0    	mov    %edx,0xf017f1e0

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101892:	89 c2                	mov    %eax,%edx
f0101894:	29 da                	sub    %ebx,%edx
f0101896:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010189a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010189e:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018a2:	c7 04 24 d4 5f 10 f0 	movl   $0xf0105fd4,(%esp)
f01018a9:	e8 b2 23 00 00       	call   f0103c60 <cprintf>
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
f01018d0:	e8 d2 36 00 00       	call   f0104fa7 <memset>
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
f01018e5:	c7 44 24 08 64 5f 10 	movl   $0xf0105f64,0x8(%esp)
f01018ec:	f0 
f01018ed:	c7 44 24 04 99 00 00 	movl   $0x99,0x4(%esp)
f01018f4:	00 
f01018f5:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f010193e:	e8 64 36 00 00       	call   f0104fa7 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *) boot_alloc(sizeof(struct Env) * NENV);
f0101943:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101948:	e8 ae f5 ff ff       	call   f0100efb <boot_alloc>
f010194d:	a3 e8 f1 17 f0       	mov    %eax,0xf017f1e8
	memset(envs, 0, sizeof(struct Env) * NENV);
f0101952:	c7 44 24 08 00 80 01 	movl   $0x18000,0x8(%esp)
f0101959:	00 
f010195a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101961:	00 
f0101962:	89 04 24             	mov    %eax,(%esp)
f0101965:	e8 3d 36 00 00       	call   f0104fa7 <memset>
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
f0101982:	c7 44 24 08 e3 66 10 	movl   $0xf01066e3,0x8(%esp)
f0101989:	f0 
f010198a:	c7 44 24 04 a1 02 00 	movl   $0x2a1,0x4(%esp)
f0101991:	00 
f0101992:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101999:	e8 18 e7 ff ff       	call   f01000b6 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010199e:	a1 dc f1 17 f0       	mov    0xf017f1dc,%eax
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
f01019c5:	c7 44 24 0c fe 66 10 	movl   $0xf01066fe,0xc(%esp)
f01019cc:	f0 
f01019cd:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01019d4:	f0 
f01019d5:	c7 44 24 04 a9 02 00 	movl   $0x2a9,0x4(%esp)
f01019dc:	00 
f01019dd:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f01019e4:	e8 cd e6 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f01019e9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019f0:	e8 c5 fa ff ff       	call   f01014ba <page_alloc>
f01019f5:	89 c6                	mov    %eax,%esi
f01019f7:	85 c0                	test   %eax,%eax
f01019f9:	75 24                	jne    f0101a1f <mem_init+0x1e8>
f01019fb:	c7 44 24 0c 14 67 10 	movl   $0xf0106714,0xc(%esp)
f0101a02:	f0 
f0101a03:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101a0a:	f0 
f0101a0b:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
f0101a12:	00 
f0101a13:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101a1a:	e8 97 e6 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101a1f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a26:	e8 8f fa ff ff       	call   f01014ba <page_alloc>
f0101a2b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101a2e:	85 c0                	test   %eax,%eax
f0101a30:	75 24                	jne    f0101a56 <mem_init+0x21f>
f0101a32:	c7 44 24 0c 2a 67 10 	movl   $0xf010672a,0xc(%esp)
f0101a39:	f0 
f0101a3a:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101a41:	f0 
f0101a42:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
f0101a49:	00 
f0101a4a:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101a51:	e8 60 e6 ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a56:	39 f7                	cmp    %esi,%edi
f0101a58:	75 24                	jne    f0101a7e <mem_init+0x247>
f0101a5a:	c7 44 24 0c 40 67 10 	movl   $0xf0106740,0xc(%esp)
f0101a61:	f0 
f0101a62:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101a69:	f0 
f0101a6a:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f0101a71:	00 
f0101a72:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101a79:	e8 38 e6 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a7e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a81:	39 c6                	cmp    %eax,%esi
f0101a83:	74 04                	je     f0101a89 <mem_init+0x252>
f0101a85:	39 c7                	cmp    %eax,%edi
f0101a87:	75 24                	jne    f0101aad <mem_init+0x276>
f0101a89:	c7 44 24 0c 10 60 10 	movl   $0xf0106010,0xc(%esp)
f0101a90:	f0 
f0101a91:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101a98:	f0 
f0101a99:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f0101aa0:	00 
f0101aa1:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0101ac9:	c7 44 24 0c 52 67 10 	movl   $0xf0106752,0xc(%esp)
f0101ad0:	f0 
f0101ad1:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101ad8:	f0 
f0101ad9:	c7 44 24 04 b0 02 00 	movl   $0x2b0,0x4(%esp)
f0101ae0:	00 
f0101ae1:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101ae8:	e8 c9 e5 ff ff       	call   f01000b6 <_panic>
f0101aed:	89 f1                	mov    %esi,%ecx
f0101aef:	29 d1                	sub    %edx,%ecx
f0101af1:	c1 f9 03             	sar    $0x3,%ecx
f0101af4:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101af7:	39 c8                	cmp    %ecx,%eax
f0101af9:	77 24                	ja     f0101b1f <mem_init+0x2e8>
f0101afb:	c7 44 24 0c 6f 67 10 	movl   $0xf010676f,0xc(%esp)
f0101b02:	f0 
f0101b03:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101b0a:	f0 
f0101b0b:	c7 44 24 04 b1 02 00 	movl   $0x2b1,0x4(%esp)
f0101b12:	00 
f0101b13:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101b1a:	e8 97 e5 ff ff       	call   f01000b6 <_panic>
f0101b1f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101b22:	29 d1                	sub    %edx,%ecx
f0101b24:	89 ca                	mov    %ecx,%edx
f0101b26:	c1 fa 03             	sar    $0x3,%edx
f0101b29:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101b2c:	39 d0                	cmp    %edx,%eax
f0101b2e:	77 24                	ja     f0101b54 <mem_init+0x31d>
f0101b30:	c7 44 24 0c 8c 67 10 	movl   $0xf010678c,0xc(%esp)
f0101b37:	f0 
f0101b38:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101b3f:	f0 
f0101b40:	c7 44 24 04 b2 02 00 	movl   $0x2b2,0x4(%esp)
f0101b47:	00 
f0101b48:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101b4f:	e8 62 e5 ff ff       	call   f01000b6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101b54:	a1 dc f1 17 f0       	mov    0xf017f1dc,%eax
f0101b59:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101b5c:	c7 05 dc f1 17 f0 00 	movl   $0x0,0xf017f1dc
f0101b63:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101b66:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b6d:	e8 48 f9 ff ff       	call   f01014ba <page_alloc>
f0101b72:	85 c0                	test   %eax,%eax
f0101b74:	74 24                	je     f0101b9a <mem_init+0x363>
f0101b76:	c7 44 24 0c a9 67 10 	movl   $0xf01067a9,0xc(%esp)
f0101b7d:	f0 
f0101b7e:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101b85:	f0 
f0101b86:	c7 44 24 04 b9 02 00 	movl   $0x2b9,0x4(%esp)
f0101b8d:	00 
f0101b8e:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0101bc7:	c7 44 24 0c fe 66 10 	movl   $0xf01066fe,0xc(%esp)
f0101bce:	f0 
f0101bcf:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101bd6:	f0 
f0101bd7:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f0101bde:	00 
f0101bdf:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101be6:	e8 cb e4 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101beb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bf2:	e8 c3 f8 ff ff       	call   f01014ba <page_alloc>
f0101bf7:	89 c7                	mov    %eax,%edi
f0101bf9:	85 c0                	test   %eax,%eax
f0101bfb:	75 24                	jne    f0101c21 <mem_init+0x3ea>
f0101bfd:	c7 44 24 0c 14 67 10 	movl   $0xf0106714,0xc(%esp)
f0101c04:	f0 
f0101c05:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101c0c:	f0 
f0101c0d:	c7 44 24 04 c1 02 00 	movl   $0x2c1,0x4(%esp)
f0101c14:	00 
f0101c15:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101c1c:	e8 95 e4 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101c21:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c28:	e8 8d f8 ff ff       	call   f01014ba <page_alloc>
f0101c2d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101c30:	85 c0                	test   %eax,%eax
f0101c32:	75 24                	jne    f0101c58 <mem_init+0x421>
f0101c34:	c7 44 24 0c 2a 67 10 	movl   $0xf010672a,0xc(%esp)
f0101c3b:	f0 
f0101c3c:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101c43:	f0 
f0101c44:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
f0101c4b:	00 
f0101c4c:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101c53:	e8 5e e4 ff ff       	call   f01000b6 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101c58:	39 fe                	cmp    %edi,%esi
f0101c5a:	75 24                	jne    f0101c80 <mem_init+0x449>
f0101c5c:	c7 44 24 0c 40 67 10 	movl   $0xf0106740,0xc(%esp)
f0101c63:	f0 
f0101c64:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101c6b:	f0 
f0101c6c:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
f0101c73:	00 
f0101c74:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101c7b:	e8 36 e4 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101c80:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c83:	39 c7                	cmp    %eax,%edi
f0101c85:	74 04                	je     f0101c8b <mem_init+0x454>
f0101c87:	39 c6                	cmp    %eax,%esi
f0101c89:	75 24                	jne    f0101caf <mem_init+0x478>
f0101c8b:	c7 44 24 0c 10 60 10 	movl   $0xf0106010,0xc(%esp)
f0101c92:	f0 
f0101c93:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101c9a:	f0 
f0101c9b:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f0101ca2:	00 
f0101ca3:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101caa:	e8 07 e4 ff ff       	call   f01000b6 <_panic>
	assert(!page_alloc(0));
f0101caf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cb6:	e8 ff f7 ff ff       	call   f01014ba <page_alloc>
f0101cbb:	85 c0                	test   %eax,%eax
f0101cbd:	74 24                	je     f0101ce3 <mem_init+0x4ac>
f0101cbf:	c7 44 24 0c a9 67 10 	movl   $0xf01067a9,0xc(%esp)
f0101cc6:	f0 
f0101cc7:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101cce:	f0 
f0101ccf:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f0101cd6:	00 
f0101cd7:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0101d02:	c7 44 24 08 40 5e 10 	movl   $0xf0105e40,0x8(%esp)
f0101d09:	f0 
f0101d0a:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f0101d11:	00 
f0101d12:	c7 04 24 39 66 10 f0 	movl   $0xf0106639,(%esp)
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
f0101d36:	e8 6c 32 00 00       	call   f0104fa7 <memset>
	page_free(pp0);
f0101d3b:	89 34 24             	mov    %esi,(%esp)
f0101d3e:	e8 02 f8 ff ff       	call   f0101545 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101d43:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101d4a:	e8 6b f7 ff ff       	call   f01014ba <page_alloc>
f0101d4f:	85 c0                	test   %eax,%eax
f0101d51:	75 24                	jne    f0101d77 <mem_init+0x540>
f0101d53:	c7 44 24 0c b8 67 10 	movl   $0xf01067b8,0xc(%esp)
f0101d5a:	f0 
f0101d5b:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101d62:	f0 
f0101d63:	c7 44 24 04 cb 02 00 	movl   $0x2cb,0x4(%esp)
f0101d6a:	00 
f0101d6b:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101d72:	e8 3f e3 ff ff       	call   f01000b6 <_panic>
	assert(pp && pp0 == pp);
f0101d77:	39 c6                	cmp    %eax,%esi
f0101d79:	74 24                	je     f0101d9f <mem_init+0x568>
f0101d7b:	c7 44 24 0c d6 67 10 	movl   $0xf01067d6,0xc(%esp)
f0101d82:	f0 
f0101d83:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101d8a:	f0 
f0101d8b:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
f0101d92:	00 
f0101d93:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0101dbe:	c7 44 24 08 40 5e 10 	movl   $0xf0105e40,0x8(%esp)
f0101dc5:	f0 
f0101dc6:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f0101dcd:	00 
f0101dce:	c7 04 24 39 66 10 f0 	movl   $0xf0106639,(%esp)
f0101dd5:	e8 dc e2 ff ff       	call   f01000b6 <_panic>
f0101dda:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101de0:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101de6:	80 38 00             	cmpb   $0x0,(%eax)
f0101de9:	74 24                	je     f0101e0f <mem_init+0x5d8>
f0101deb:	c7 44 24 0c e6 67 10 	movl   $0xf01067e6,0xc(%esp)
f0101df2:	f0 
f0101df3:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101dfa:	f0 
f0101dfb:	c7 44 24 04 cf 02 00 	movl   $0x2cf,0x4(%esp)
f0101e02:	00 
f0101e03:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0101e19:	a3 dc f1 17 f0       	mov    %eax,0xf017f1dc

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
f0101e39:	a1 dc f1 17 f0       	mov    0xf017f1dc,%eax
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
f0101e4d:	c7 44 24 0c f0 67 10 	movl   $0xf01067f0,0xc(%esp)
f0101e54:	f0 
f0101e55:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101e5c:	f0 
f0101e5d:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
f0101e64:	00 
f0101e65:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101e6c:	e8 45 e2 ff ff       	call   f01000b6 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101e71:	c7 04 24 30 60 10 f0 	movl   $0xf0106030,(%esp)
f0101e78:	e8 e3 1d 00 00       	call   f0103c60 <cprintf>
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
f0101e90:	c7 44 24 0c fe 66 10 	movl   $0xf01066fe,0xc(%esp)
f0101e97:	f0 
f0101e98:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101e9f:	f0 
f0101ea0:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f0101ea7:	00 
f0101ea8:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101eaf:	e8 02 e2 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101eb4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ebb:	e8 fa f5 ff ff       	call   f01014ba <page_alloc>
f0101ec0:	89 c3                	mov    %eax,%ebx
f0101ec2:	85 c0                	test   %eax,%eax
f0101ec4:	75 24                	jne    f0101eea <mem_init+0x6b3>
f0101ec6:	c7 44 24 0c 14 67 10 	movl   $0xf0106714,0xc(%esp)
f0101ecd:	f0 
f0101ece:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101ed5:	f0 
f0101ed6:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0101edd:	00 
f0101ede:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101ee5:	e8 cc e1 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101eea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ef1:	e8 c4 f5 ff ff       	call   f01014ba <page_alloc>
f0101ef6:	89 c6                	mov    %eax,%esi
f0101ef8:	85 c0                	test   %eax,%eax
f0101efa:	75 24                	jne    f0101f20 <mem_init+0x6e9>
f0101efc:	c7 44 24 0c 2a 67 10 	movl   $0xf010672a,0xc(%esp)
f0101f03:	f0 
f0101f04:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101f0b:	f0 
f0101f0c:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0101f13:	00 
f0101f14:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101f1b:	e8 96 e1 ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101f20:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101f23:	75 24                	jne    f0101f49 <mem_init+0x712>
f0101f25:	c7 44 24 0c 40 67 10 	movl   $0xf0106740,0xc(%esp)
f0101f2c:	f0 
f0101f2d:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101f34:	f0 
f0101f35:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f0101f3c:	00 
f0101f3d:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101f44:	e8 6d e1 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101f49:	39 c3                	cmp    %eax,%ebx
f0101f4b:	74 05                	je     f0101f52 <mem_init+0x71b>
f0101f4d:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101f50:	75 24                	jne    f0101f76 <mem_init+0x73f>
f0101f52:	c7 44 24 0c 10 60 10 	movl   $0xf0106010,0xc(%esp)
f0101f59:	f0 
f0101f5a:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101f61:	f0 
f0101f62:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0101f69:	00 
f0101f6a:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0101f71:	e8 40 e1 ff ff       	call   f01000b6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101f76:	a1 dc f1 17 f0       	mov    0xf017f1dc,%eax
f0101f7b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101f7e:	c7 05 dc f1 17 f0 00 	movl   $0x0,0xf017f1dc
f0101f85:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101f88:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f8f:	e8 26 f5 ff ff       	call   f01014ba <page_alloc>
f0101f94:	85 c0                	test   %eax,%eax
f0101f96:	74 24                	je     f0101fbc <mem_init+0x785>
f0101f98:	c7 44 24 0c a9 67 10 	movl   $0xf01067a9,0xc(%esp)
f0101f9f:	f0 
f0101fa0:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101fa7:	f0 
f0101fa8:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f0101faf:	00 
f0101fb0:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0101fdc:	c7 44 24 0c 50 60 10 	movl   $0xf0106050,0xc(%esp)
f0101fe3:	f0 
f0101fe4:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0101feb:	f0 
f0101fec:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0101ff3:	00 
f0101ff4:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102025:	c7 44 24 0c 88 60 10 	movl   $0xf0106088,0xc(%esp)
f010202c:	f0 
f010202d:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102034:	f0 
f0102035:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f010203c:	00 
f010203d:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102079:	c7 44 24 0c b8 60 10 	movl   $0xf01060b8,0xc(%esp)
f0102080:	f0 
f0102081:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102088:	f0 
f0102089:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0102090:	00 
f0102091:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f01020c4:	c7 44 24 0c e8 60 10 	movl   $0xf01060e8,0xc(%esp)
f01020cb:	f0 
f01020cc:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01020d3:	f0 
f01020d4:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f01020db:	00 
f01020dc:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102103:	c7 44 24 0c 10 61 10 	movl   $0xf0106110,0xc(%esp)
f010210a:	f0 
f010210b:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102112:	f0 
f0102113:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f010211a:	00 
f010211b:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0102122:	e8 8f df ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f0102127:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010212c:	74 24                	je     f0102152 <mem_init+0x91b>
f010212e:	c7 44 24 0c fb 67 10 	movl   $0xf01067fb,0xc(%esp)
f0102135:	f0 
f0102136:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010213d:	f0 
f010213e:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f0102145:	00 
f0102146:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f010214d:	e8 64 df ff ff       	call   f01000b6 <_panic>
	assert(pp0->pp_ref == 1);
f0102152:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102155:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010215a:	74 24                	je     f0102180 <mem_init+0x949>
f010215c:	c7 44 24 0c 0c 68 10 	movl   $0xf010680c,0xc(%esp)
f0102163:	f0 
f0102164:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010216b:	f0 
f010216c:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f0102173:	00 
f0102174:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f01021a0:	c7 44 24 0c 40 61 10 	movl   $0xf0106140,0xc(%esp)
f01021a7:	f0 
f01021a8:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01021af:	f0 
f01021b0:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f01021b7:	00 
f01021b8:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f01021e5:	c7 44 24 0c 7c 61 10 	movl   $0xf010617c,0xc(%esp)
f01021ec:	f0 
f01021ed:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01021f4:	f0 
f01021f5:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f01021fc:	00 
f01021fd:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0102204:	e8 ad de ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0102209:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010220e:	74 24                	je     f0102234 <mem_init+0x9fd>
f0102210:	c7 44 24 0c 1d 68 10 	movl   $0xf010681d,0xc(%esp)
f0102217:	f0 
f0102218:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010221f:	f0 
f0102220:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0102227:	00 
f0102228:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f010222f:	e8 82 de ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102234:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010223b:	e8 7a f2 ff ff       	call   f01014ba <page_alloc>
f0102240:	85 c0                	test   %eax,%eax
f0102242:	74 24                	je     f0102268 <mem_init+0xa31>
f0102244:	c7 44 24 0c a9 67 10 	movl   $0xf01067a9,0xc(%esp)
f010224b:	f0 
f010224c:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102253:	f0 
f0102254:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f010225b:	00 
f010225c:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f010228d:	c7 44 24 0c 40 61 10 	movl   $0xf0106140,0xc(%esp)
f0102294:	f0 
f0102295:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010229c:	f0 
f010229d:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f01022a4:	00 
f01022a5:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f01022d2:	c7 44 24 0c 7c 61 10 	movl   $0xf010617c,0xc(%esp)
f01022d9:	f0 
f01022da:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01022e1:	f0 
f01022e2:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f01022e9:	00 
f01022ea:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f01022f1:	e8 c0 dd ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f01022f6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01022fb:	74 24                	je     f0102321 <mem_init+0xaea>
f01022fd:	c7 44 24 0c 1d 68 10 	movl   $0xf010681d,0xc(%esp)
f0102304:	f0 
f0102305:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010230c:	f0 
f010230d:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f0102314:	00 
f0102315:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f010231c:	e8 95 dd ff ff       	call   f01000b6 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0102321:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102328:	e8 8d f1 ff ff       	call   f01014ba <page_alloc>
f010232d:	85 c0                	test   %eax,%eax
f010232f:	74 24                	je     f0102355 <mem_init+0xb1e>
f0102331:	c7 44 24 0c a9 67 10 	movl   $0xf01067a9,0xc(%esp)
f0102338:	f0 
f0102339:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102340:	f0 
f0102341:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0102348:	00 
f0102349:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102373:	c7 44 24 08 40 5e 10 	movl   $0xf0105e40,0x8(%esp)
f010237a:	f0 
f010237b:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0102382:	00 
f0102383:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f01023b9:	c7 44 24 0c ac 61 10 	movl   $0xf01061ac,0xc(%esp)
f01023c0:	f0 
f01023c1:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01023c8:	f0 
f01023c9:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f01023d0:	00 
f01023d1:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102402:	c7 44 24 0c ec 61 10 	movl   $0xf01061ec,0xc(%esp)
f0102409:	f0 
f010240a:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102411:	f0 
f0102412:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f0102419:	00 
f010241a:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f010244a:	c7 44 24 0c 7c 61 10 	movl   $0xf010617c,0xc(%esp)
f0102451:	f0 
f0102452:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102459:	f0 
f010245a:	c7 44 24 04 6e 03 00 	movl   $0x36e,0x4(%esp)
f0102461:	00 
f0102462:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0102469:	e8 48 dc ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f010246e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102473:	74 24                	je     f0102499 <mem_init+0xc62>
f0102475:	c7 44 24 0c 1d 68 10 	movl   $0xf010681d,0xc(%esp)
f010247c:	f0 
f010247d:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102484:	f0 
f0102485:	c7 44 24 04 6f 03 00 	movl   $0x36f,0x4(%esp)
f010248c:	00 
f010248d:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f01024b6:	c7 44 24 0c 2c 62 10 	movl   $0xf010622c,0xc(%esp)
f01024bd:	f0 
f01024be:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01024c5:	f0 
f01024c6:	c7 44 24 04 70 03 00 	movl   $0x370,0x4(%esp)
f01024cd:	00 
f01024ce:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f01024d5:	e8 dc db ff ff       	call   f01000b6 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01024da:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
f01024df:	f6 00 04             	testb  $0x4,(%eax)
f01024e2:	75 24                	jne    f0102508 <mem_init+0xcd1>
f01024e4:	c7 44 24 0c 2e 68 10 	movl   $0xf010682e,0xc(%esp)
f01024eb:	f0 
f01024ec:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01024f3:	f0 
f01024f4:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f01024fb:	00 
f01024fc:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102528:	c7 44 24 0c 40 61 10 	movl   $0xf0106140,0xc(%esp)
f010252f:	f0 
f0102530:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102537:	f0 
f0102538:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f010253f:	00 
f0102540:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f010256e:	c7 44 24 0c 60 62 10 	movl   $0xf0106260,0xc(%esp)
f0102575:	f0 
f0102576:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010257d:	f0 
f010257e:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f0102585:	00 
f0102586:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f01025b4:	c7 44 24 0c 94 62 10 	movl   $0xf0106294,0xc(%esp)
f01025bb:	f0 
f01025bc:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01025c3:	f0 
f01025c4:	c7 44 24 04 76 03 00 	movl   $0x376,0x4(%esp)
f01025cb:	00 
f01025cc:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102600:	c7 44 24 0c cc 62 10 	movl   $0xf01062cc,0xc(%esp)
f0102607:	f0 
f0102608:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010260f:	f0 
f0102610:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f0102617:	00 
f0102618:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102649:	c7 44 24 0c 04 63 10 	movl   $0xf0106304,0xc(%esp)
f0102650:	f0 
f0102651:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102658:	f0 
f0102659:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f0102660:	00 
f0102661:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f010268f:	c7 44 24 0c 94 62 10 	movl   $0xf0106294,0xc(%esp)
f0102696:	f0 
f0102697:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010269e:	f0 
f010269f:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f01026a6:	00 
f01026a7:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f01026dc:	c7 44 24 0c 40 63 10 	movl   $0xf0106340,0xc(%esp)
f01026e3:	f0 
f01026e4:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01026eb:	f0 
f01026ec:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f01026f3:	00 
f01026f4:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f01026fb:	e8 b6 d9 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102700:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102705:	89 f8                	mov    %edi,%eax
f0102707:	e8 dd e8 ff ff       	call   f0100fe9 <check_va2pa>
f010270c:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f010270f:	74 24                	je     f0102735 <mem_init+0xefe>
f0102711:	c7 44 24 0c 6c 63 10 	movl   $0xf010636c,0xc(%esp)
f0102718:	f0 
f0102719:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102720:	f0 
f0102721:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0102728:	00 
f0102729:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0102730:	e8 81 d9 ff ff       	call   f01000b6 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102735:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f010273a:	74 24                	je     f0102760 <mem_init+0xf29>
f010273c:	c7 44 24 0c 44 68 10 	movl   $0xf0106844,0xc(%esp)
f0102743:	f0 
f0102744:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010274b:	f0 
f010274c:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f0102753:	00 
f0102754:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f010275b:	e8 56 d9 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f0102760:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102765:	74 24                	je     f010278b <mem_init+0xf54>
f0102767:	c7 44 24 0c 55 68 10 	movl   $0xf0106855,0xc(%esp)
f010276e:	f0 
f010276f:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102776:	f0 
f0102777:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f010277e:	00 
f010277f:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0102786:	e8 2b d9 ff ff       	call   f01000b6 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010278b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102792:	e8 23 ed ff ff       	call   f01014ba <page_alloc>
f0102797:	85 c0                	test   %eax,%eax
f0102799:	74 04                	je     f010279f <mem_init+0xf68>
f010279b:	39 c6                	cmp    %eax,%esi
f010279d:	74 24                	je     f01027c3 <mem_init+0xf8c>
f010279f:	c7 44 24 0c 9c 63 10 	movl   $0xf010639c,0xc(%esp)
f01027a6:	f0 
f01027a7:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01027ae:	f0 
f01027af:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f01027b6:	00 
f01027b7:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f01027ef:	c7 44 24 0c c0 63 10 	movl   $0xf01063c0,0xc(%esp)
f01027f6:	f0 
f01027f7:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01027fe:	f0 
f01027ff:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f0102806:	00 
f0102807:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102831:	c7 44 24 0c 6c 63 10 	movl   $0xf010636c,0xc(%esp)
f0102838:	f0 
f0102839:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102840:	f0 
f0102841:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0102848:	00 
f0102849:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0102850:	e8 61 d8 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f0102855:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010285a:	74 24                	je     f0102880 <mem_init+0x1049>
f010285c:	c7 44 24 0c fb 67 10 	movl   $0xf01067fb,0xc(%esp)
f0102863:	f0 
f0102864:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010286b:	f0 
f010286c:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f0102873:	00 
f0102874:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f010287b:	e8 36 d8 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f0102880:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102885:	74 24                	je     f01028ab <mem_init+0x1074>
f0102887:	c7 44 24 0c 55 68 10 	movl   $0xf0106855,0xc(%esp)
f010288e:	f0 
f010288f:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102896:	f0 
f0102897:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f010289e:	00 
f010289f:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f01028cb:	c7 44 24 0c e4 63 10 	movl   $0xf01063e4,0xc(%esp)
f01028d2:	f0 
f01028d3:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01028da:	f0 
f01028db:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f01028e2:	00 
f01028e3:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f01028ea:	e8 c7 d7 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref);
f01028ef:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01028f4:	75 24                	jne    f010291a <mem_init+0x10e3>
f01028f6:	c7 44 24 0c 66 68 10 	movl   $0xf0106866,0xc(%esp)
f01028fd:	f0 
f01028fe:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102905:	f0 
f0102906:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f010290d:	00 
f010290e:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0102915:	e8 9c d7 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_link == NULL);
f010291a:	83 3b 00             	cmpl   $0x0,(%ebx)
f010291d:	74 24                	je     f0102943 <mem_init+0x110c>
f010291f:	c7 44 24 0c 72 68 10 	movl   $0xf0106872,0xc(%esp)
f0102926:	f0 
f0102927:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010292e:	f0 
f010292f:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0102936:	00 
f0102937:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f010296f:	c7 44 24 0c c0 63 10 	movl   $0xf01063c0,0xc(%esp)
f0102976:	f0 
f0102977:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010297e:	f0 
f010297f:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0102986:	00 
f0102987:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f010298e:	e8 23 d7 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102993:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102998:	89 f8                	mov    %edi,%eax
f010299a:	e8 4a e6 ff ff       	call   f0100fe9 <check_va2pa>
f010299f:	83 f8 ff             	cmp    $0xffffffff,%eax
f01029a2:	74 24                	je     f01029c8 <mem_init+0x1191>
f01029a4:	c7 44 24 0c 1c 64 10 	movl   $0xf010641c,0xc(%esp)
f01029ab:	f0 
f01029ac:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01029b3:	f0 
f01029b4:	c7 44 24 04 98 03 00 	movl   $0x398,0x4(%esp)
f01029bb:	00 
f01029bc:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f01029c3:	e8 ee d6 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f01029c8:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01029cd:	74 24                	je     f01029f3 <mem_init+0x11bc>
f01029cf:	c7 44 24 0c 87 68 10 	movl   $0xf0106887,0xc(%esp)
f01029d6:	f0 
f01029d7:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01029de:	f0 
f01029df:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f01029e6:	00 
f01029e7:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f01029ee:	e8 c3 d6 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f01029f3:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01029f8:	74 24                	je     f0102a1e <mem_init+0x11e7>
f01029fa:	c7 44 24 0c 55 68 10 	movl   $0xf0106855,0xc(%esp)
f0102a01:	f0 
f0102a02:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102a09:	f0 
f0102a0a:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0102a11:	00 
f0102a12:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0102a19:	e8 98 d6 ff ff       	call   f01000b6 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102a1e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a25:	e8 90 ea ff ff       	call   f01014ba <page_alloc>
f0102a2a:	85 c0                	test   %eax,%eax
f0102a2c:	74 04                	je     f0102a32 <mem_init+0x11fb>
f0102a2e:	39 c3                	cmp    %eax,%ebx
f0102a30:	74 24                	je     f0102a56 <mem_init+0x121f>
f0102a32:	c7 44 24 0c 44 64 10 	movl   $0xf0106444,0xc(%esp)
f0102a39:	f0 
f0102a3a:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102a41:	f0 
f0102a42:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f0102a49:	00 
f0102a4a:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0102a51:	e8 60 d6 ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102a56:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a5d:	e8 58 ea ff ff       	call   f01014ba <page_alloc>
f0102a62:	85 c0                	test   %eax,%eax
f0102a64:	74 24                	je     f0102a8a <mem_init+0x1253>
f0102a66:	c7 44 24 0c a9 67 10 	movl   $0xf01067a9,0xc(%esp)
f0102a6d:	f0 
f0102a6e:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102a75:	f0 
f0102a76:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f0102a7d:	00 
f0102a7e:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102aaa:	c7 44 24 0c e8 60 10 	movl   $0xf01060e8,0xc(%esp)
f0102ab1:	f0 
f0102ab2:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102ab9:	f0 
f0102aba:	c7 44 24 04 a3 03 00 	movl   $0x3a3,0x4(%esp)
f0102ac1:	00 
f0102ac2:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0102ac9:	e8 e8 d5 ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f0102ace:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102ad4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ad7:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102adc:	74 24                	je     f0102b02 <mem_init+0x12cb>
f0102ade:	c7 44 24 0c 0c 68 10 	movl   $0xf010680c,0xc(%esp)
f0102ae5:	f0 
f0102ae6:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102aed:	f0 
f0102aee:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f0102af5:	00 
f0102af6:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102b58:	c7 44 24 08 40 5e 10 	movl   $0xf0105e40,0x8(%esp)
f0102b5f:	f0 
f0102b60:	c7 44 24 04 ac 03 00 	movl   $0x3ac,0x4(%esp)
f0102b67:	00 
f0102b68:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0102b6f:	e8 42 d5 ff ff       	call   f01000b6 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102b74:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102b7a:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102b7d:	74 24                	je     f0102ba3 <mem_init+0x136c>
f0102b7f:	c7 44 24 0c 98 68 10 	movl   $0xf0106898,0xc(%esp)
f0102b86:	f0 
f0102b87:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102b8e:	f0 
f0102b8f:	c7 44 24 04 ad 03 00 	movl   $0x3ad,0x4(%esp)
f0102b96:	00 
f0102b97:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102bcc:	c7 44 24 08 40 5e 10 	movl   $0xf0105e40,0x8(%esp)
f0102bd3:	f0 
f0102bd4:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f0102bdb:	00 
f0102bdc:	c7 04 24 39 66 10 f0 	movl   $0xf0106639,(%esp)
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
f0102c00:	e8 a2 23 00 00       	call   f0104fa7 <memset>
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
f0102c4c:	c7 44 24 08 40 5e 10 	movl   $0xf0105e40,0x8(%esp)
f0102c53:	f0 
f0102c54:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f0102c5b:	00 
f0102c5c:	c7 04 24 39 66 10 f0 	movl   $0xf0106639,(%esp)
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
f0102c7c:	c7 44 24 0c b0 68 10 	movl   $0xf01068b0,0xc(%esp)
f0102c83:	f0 
f0102c84:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102c8b:	f0 
f0102c8c:	c7 44 24 04 b7 03 00 	movl   $0x3b7,0x4(%esp)
f0102c93:	00 
f0102c94:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102cbe:	89 0d dc f1 17 f0    	mov    %ecx,0xf017f1dc

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
f0102cdc:	c7 04 24 c7 68 10 f0 	movl   $0xf01068c7,(%esp)
f0102ce3:	e8 78 0f 00 00       	call   f0103c60 <cprintf>
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
f0102cf8:	c7 44 24 08 64 5f 10 	movl   $0xf0105f64,0x8(%esp)
f0102cff:	f0 
f0102d00:	c7 44 24 04 c1 00 00 	movl   $0xc1,0x4(%esp)
f0102d07:	00 
f0102d08:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102d40:	a1 e8 f1 17 f0       	mov    0xf017f1e8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d45:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d4a:	77 20                	ja     f0102d6c <mem_init+0x1535>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d4c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d50:	c7 44 24 08 64 5f 10 	movl   $0xf0105f64,0x8(%esp)
f0102d57:	f0 
f0102d58:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
f0102d5f:	00 
f0102d60:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102da1:	c7 44 24 08 64 5f 10 	movl   $0xf0105f64,0x8(%esp)
f0102da8:	f0 
f0102da9:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
f0102db0:	00 
f0102db1:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102e56:	c7 44 24 08 64 5f 10 	movl   $0xf0105f64,0x8(%esp)
f0102e5d:	f0 
f0102e5e:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
f0102e65:	00 
f0102e66:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0102e6d:	e8 44 d2 ff ff       	call   f01000b6 <_panic>
f0102e72:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102e75:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102e78:	39 d0                	cmp    %edx,%eax
f0102e7a:	74 24                	je     f0102ea0 <mem_init+0x1669>
f0102e7c:	c7 44 24 0c 68 64 10 	movl   $0xf0106468,0xc(%esp)
f0102e83:	f0 
f0102e84:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102e8b:	f0 
f0102e8c:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
f0102e93:	00 
f0102e94:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102eab:	8b 35 e8 f1 17 f0    	mov    0xf017f1e8,%esi
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
f0102ecc:	c7 44 24 08 64 5f 10 	movl   $0xf0105f64,0x8(%esp)
f0102ed3:	f0 
f0102ed4:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f0102edb:	00 
f0102edc:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102efa:	c7 44 24 0c 9c 64 10 	movl   $0xf010649c,0xc(%esp)
f0102f01:	f0 
f0102f02:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102f09:	f0 
f0102f0a:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f0102f11:	00 
f0102f12:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102f4f:	c7 44 24 0c d0 64 10 	movl   $0xf01064d0,0xc(%esp)
f0102f56:	f0 
f0102f57:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102f5e:	f0 
f0102f5f:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f0102f66:	00 
f0102f67:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102f99:	c7 44 24 0c f8 64 10 	movl   $0xf01064f8,0xc(%esp)
f0102fa0:	f0 
f0102fa1:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102fa8:	f0 
f0102fa9:	c7 44 24 04 01 03 00 	movl   $0x301,0x4(%esp)
f0102fb0:	00 
f0102fb1:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0102feb:	c7 44 24 0c 40 65 10 	movl   $0xf0106540,0xc(%esp)
f0102ff2:	f0 
f0102ff3:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0102ffa:	f0 
f0102ffb:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0103002:	00 
f0103003:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f010302e:	c7 44 24 0c e0 68 10 	movl   $0xf01068e0,0xc(%esp)
f0103035:	f0 
f0103036:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010303d:	f0 
f010303e:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0103045:	00 
f0103046:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0103061:	c7 44 24 0c e0 68 10 	movl   $0xf01068e0,0xc(%esp)
f0103068:	f0 
f0103069:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0103070:	f0 
f0103071:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f0103078:	00 
f0103079:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0103080:	e8 31 d0 ff ff       	call   f01000b6 <_panic>
				assert(pgdir[i] & PTE_W);
f0103085:	f6 c1 02             	test   $0x2,%cl
f0103088:	75 4e                	jne    f01030d8 <mem_init+0x18a1>
f010308a:	c7 44 24 0c f1 68 10 	movl   $0xf01068f1,0xc(%esp)
f0103091:	f0 
f0103092:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0103099:	f0 
f010309a:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f01030a1:	00 
f01030a2:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f01030a9:	e8 08 d0 ff ff       	call   f01000b6 <_panic>
			} else
				assert(pgdir[i] == 0);
f01030ae:	83 3c 82 00          	cmpl   $0x0,(%edx,%eax,4)
f01030b2:	74 24                	je     f01030d8 <mem_init+0x18a1>
f01030b4:	c7 44 24 0c 02 69 10 	movl   $0xf0106902,0xc(%esp)
f01030bb:	f0 
f01030bc:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01030c3:	f0 
f01030c4:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f01030cb:	00 
f01030cc:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f01030e6:	c7 04 24 70 65 10 f0 	movl   $0xf0106570,(%esp)
f01030ed:	e8 6e 0b 00 00       	call   f0103c60 <cprintf>
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
f0103102:	c7 44 24 08 64 5f 10 	movl   $0xf0105f64,0x8(%esp)
f0103109:	f0 
f010310a:	c7 44 24 04 ed 00 00 	movl   $0xed,0x4(%esp)
f0103111:	00 
f0103112:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0103150:	c7 44 24 0c fe 66 10 	movl   $0xf01066fe,0xc(%esp)
f0103157:	f0 
f0103158:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010315f:	f0 
f0103160:	c7 44 24 04 d2 03 00 	movl   $0x3d2,0x4(%esp)
f0103167:	00 
f0103168:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f010316f:	e8 42 cf ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0103174:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010317b:	e8 3a e3 ff ff       	call   f01014ba <page_alloc>
f0103180:	89 c7                	mov    %eax,%edi
f0103182:	85 c0                	test   %eax,%eax
f0103184:	75 24                	jne    f01031aa <mem_init+0x1973>
f0103186:	c7 44 24 0c 14 67 10 	movl   $0xf0106714,0xc(%esp)
f010318d:	f0 
f010318e:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0103195:	f0 
f0103196:	c7 44 24 04 d3 03 00 	movl   $0x3d3,0x4(%esp)
f010319d:	00 
f010319e:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f01031a5:	e8 0c cf ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f01031aa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01031b1:	e8 04 e3 ff ff       	call   f01014ba <page_alloc>
f01031b6:	89 c6                	mov    %eax,%esi
f01031b8:	85 c0                	test   %eax,%eax
f01031ba:	75 24                	jne    f01031e0 <mem_init+0x19a9>
f01031bc:	c7 44 24 0c 2a 67 10 	movl   $0xf010672a,0xc(%esp)
f01031c3:	f0 
f01031c4:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01031cb:	f0 
f01031cc:	c7 44 24 04 d4 03 00 	movl   $0x3d4,0x4(%esp)
f01031d3:	00 
f01031d4:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f0103202:	e8 a0 1d 00 00       	call   f0104fa7 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0103207:	89 f0                	mov    %esi,%eax
f0103209:	e8 96 dd ff ff       	call   f0100fa4 <page2kva>
f010320e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103215:	00 
f0103216:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010321d:	00 
f010321e:	89 04 24             	mov    %eax,(%esp)
f0103221:	e8 81 1d 00 00       	call   f0104fa7 <memset>
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
f010324e:	c7 44 24 0c fb 67 10 	movl   $0xf01067fb,0xc(%esp)
f0103255:	f0 
f0103256:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010325d:	f0 
f010325e:	c7 44 24 04 d9 03 00 	movl   $0x3d9,0x4(%esp)
f0103265:	00 
f0103266:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f010326d:	e8 44 ce ff ff       	call   f01000b6 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103272:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0103279:	01 01 01 
f010327c:	74 24                	je     f01032a2 <mem_init+0x1a6b>
f010327e:	c7 44 24 0c 90 65 10 	movl   $0xf0106590,0xc(%esp)
f0103285:	f0 
f0103286:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010328d:	f0 
f010328e:	c7 44 24 04 da 03 00 	movl   $0x3da,0x4(%esp)
f0103295:	00 
f0103296:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f01032cf:	c7 44 24 0c b4 65 10 	movl   $0xf01065b4,0xc(%esp)
f01032d6:	f0 
f01032d7:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01032de:	f0 
f01032df:	c7 44 24 04 dc 03 00 	movl   $0x3dc,0x4(%esp)
f01032e6:	00 
f01032e7:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f01032ee:	e8 c3 cd ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f01032f3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01032f8:	74 24                	je     f010331e <mem_init+0x1ae7>
f01032fa:	c7 44 24 0c 1d 68 10 	movl   $0xf010681d,0xc(%esp)
f0103301:	f0 
f0103302:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0103309:	f0 
f010330a:	c7 44 24 04 dd 03 00 	movl   $0x3dd,0x4(%esp)
f0103311:	00 
f0103312:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0103319:	e8 98 cd ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f010331e:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0103323:	74 24                	je     f0103349 <mem_init+0x1b12>
f0103325:	c7 44 24 0c 87 68 10 	movl   $0xf0106887,0xc(%esp)
f010332c:	f0 
f010332d:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0103334:	f0 
f0103335:	c7 44 24 04 de 03 00 	movl   $0x3de,0x4(%esp)
f010333c:	00 
f010333d:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0103344:	e8 6d cd ff ff       	call   f01000b6 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0103349:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0103350:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0103353:	89 f0                	mov    %esi,%eax
f0103355:	e8 4a dc ff ff       	call   f0100fa4 <page2kva>
f010335a:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0103360:	74 24                	je     f0103386 <mem_init+0x1b4f>
f0103362:	c7 44 24 0c d8 65 10 	movl   $0xf01065d8,0xc(%esp)
f0103369:	f0 
f010336a:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0103371:	f0 
f0103372:	c7 44 24 04 e0 03 00 	movl   $0x3e0,0x4(%esp)
f0103379:	00 
f010337a:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f01033a2:	c7 44 24 0c 55 68 10 	movl   $0xf0106855,0xc(%esp)
f01033a9:	f0 
f01033aa:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01033b1:	f0 
f01033b2:	c7 44 24 04 e2 03 00 	movl   $0x3e2,0x4(%esp)
f01033b9:	00 
f01033ba:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
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
f01033e5:	c7 44 24 0c e8 60 10 	movl   $0xf01060e8,0xc(%esp)
f01033ec:	f0 
f01033ed:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01033f4:	f0 
f01033f5:	c7 44 24 04 e5 03 00 	movl   $0x3e5,0x4(%esp)
f01033fc:	00 
f01033fd:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0103404:	e8 ad cc ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f0103409:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010340f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0103414:	74 24                	je     f010343a <mem_init+0x1c03>
f0103416:	c7 44 24 0c 0c 68 10 	movl   $0xf010680c,0xc(%esp)
f010341d:	f0 
f010341e:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0103425:	f0 
f0103426:	c7 44 24 04 e7 03 00 	movl   $0x3e7,0x4(%esp)
f010342d:	00 
f010342e:	c7 04 24 2d 66 10 f0 	movl   $0xf010662d,(%esp)
f0103435:	e8 7c cc ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f010343a:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0103440:	89 1c 24             	mov    %ebx,(%esp)
f0103443:	e8 fd e0 ff ff       	call   f0101545 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0103448:	c7 04 24 04 66 10 f0 	movl   $0xf0106604,(%esp)
f010344f:	e8 0c 08 00 00       	call   f0103c60 <cprintf>
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
	// LAB 3: Your code here.

	return 0;
}
f010347b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103480:	5d                   	pop    %ebp
f0103481:	c3                   	ret    

f0103482 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0103482:	55                   	push   %ebp
f0103483:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f0103485:	5d                   	pop    %ebp
f0103486:	c3                   	ret    

f0103487 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103487:	55                   	push   %ebp
f0103488:	89 e5                	mov    %esp,%ebp
f010348a:	57                   	push   %edi
f010348b:	56                   	push   %esi
f010348c:	53                   	push   %ebx
f010348d:	83 ec 1c             	sub    $0x1c,%esp
f0103490:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t start_addr = (uintptr_t)ROUNDDOWN(va, PGSIZE);
f0103492:	89 d3                	mov    %edx,%ebx
f0103494:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t end_addr = (uintptr_t)ROUNDUP(va + len, PGSIZE);
f010349a:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01034a1:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

	for(; start_addr < end_addr; start_addr += PGSIZE){
f01034a7:	eb 6d                	jmp    f0103516 <region_alloc+0x8f>
		struct PageInfo *page = page_alloc(ALLOC_ZERO);
f01034a9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01034b0:	e8 05 e0 ff ff       	call   f01014ba <page_alloc>
		if(!page)
f01034b5:	85 c0                	test   %eax,%eax
f01034b7:	75 1c                	jne    f01034d5 <region_alloc+0x4e>
			panic("out of memory when allocing region!");
f01034b9:	c7 44 24 08 10 69 10 	movl   $0xf0106910,0x8(%esp)
f01034c0:	f0 
f01034c1:	c7 44 24 04 24 01 00 	movl   $0x124,0x4(%esp)
f01034c8:	00 
f01034c9:	c7 04 24 8a 69 10 f0 	movl   $0xf010698a,(%esp)
f01034d0:	e8 e1 cb ff ff       	call   f01000b6 <_panic>
		if(page_insert(e->env_pgdir, page, (void *)start_addr, PTE_U | PTE_W | PTE_P) < 0)
f01034d5:	c7 44 24 0c 07 00 00 	movl   $0x7,0xc(%esp)
f01034dc:	00 
f01034dd:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01034e1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034e5:	8b 47 5c             	mov    0x5c(%edi),%eax
f01034e8:	89 04 24             	mov    %eax,(%esp)
f01034eb:	e8 d5 e2 ff ff       	call   f01017c5 <page_insert>
f01034f0:	85 c0                	test   %eax,%eax
f01034f2:	79 1c                	jns    f0103510 <region_alloc+0x89>
			panic("fail when inserting page!");
f01034f4:	c7 44 24 08 95 69 10 	movl   $0xf0106995,0x8(%esp)
f01034fb:	f0 
f01034fc:	c7 44 24 04 26 01 00 	movl   $0x126,0x4(%esp)
f0103503:	00 
f0103504:	c7 04 24 8a 69 10 f0 	movl   $0xf010698a,(%esp)
f010350b:	e8 a6 cb ff ff       	call   f01000b6 <_panic>
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t start_addr = (uintptr_t)ROUNDDOWN(va, PGSIZE);
	uintptr_t end_addr = (uintptr_t)ROUNDUP(va + len, PGSIZE);

	for(; start_addr < end_addr; start_addr += PGSIZE){
f0103510:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0103516:	39 f3                	cmp    %esi,%ebx
f0103518:	72 8f                	jb     f01034a9 <region_alloc+0x22>
		if(!page)
			panic("out of memory when allocing region!");
		if(page_insert(e->env_pgdir, page, (void *)start_addr, PTE_U | PTE_W | PTE_P) < 0)
			panic("fail when inserting page!");
	}
}
f010351a:	83 c4 1c             	add    $0x1c,%esp
f010351d:	5b                   	pop    %ebx
f010351e:	5e                   	pop    %esi
f010351f:	5f                   	pop    %edi
f0103520:	5d                   	pop    %ebp
f0103521:	c3                   	ret    

f0103522 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0103522:	55                   	push   %ebp
f0103523:	89 e5                	mov    %esp,%ebp
f0103525:	8b 45 08             	mov    0x8(%ebp),%eax
f0103528:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f010352b:	85 c0                	test   %eax,%eax
f010352d:	75 11                	jne    f0103540 <envid2env+0x1e>
		*env_store = curenv;
f010352f:	a1 e4 f1 17 f0       	mov    0xf017f1e4,%eax
f0103534:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103537:	89 01                	mov    %eax,(%ecx)
		return 0;
f0103539:	b8 00 00 00 00       	mov    $0x0,%eax
f010353e:	eb 5e                	jmp    f010359e <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103540:	89 c2                	mov    %eax,%edx
f0103542:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0103548:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010354b:	c1 e2 05             	shl    $0x5,%edx
f010354e:	03 15 e8 f1 17 f0    	add    0xf017f1e8,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103554:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0103558:	74 05                	je     f010355f <envid2env+0x3d>
f010355a:	39 42 48             	cmp    %eax,0x48(%edx)
f010355d:	74 10                	je     f010356f <envid2env+0x4d>
		*env_store = 0;
f010355f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103562:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103568:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010356d:	eb 2f                	jmp    f010359e <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010356f:	84 c9                	test   %cl,%cl
f0103571:	74 21                	je     f0103594 <envid2env+0x72>
f0103573:	a1 e4 f1 17 f0       	mov    0xf017f1e4,%eax
f0103578:	39 c2                	cmp    %eax,%edx
f010357a:	74 18                	je     f0103594 <envid2env+0x72>
f010357c:	8b 40 48             	mov    0x48(%eax),%eax
f010357f:	39 42 4c             	cmp    %eax,0x4c(%edx)
f0103582:	74 10                	je     f0103594 <envid2env+0x72>
		*env_store = 0;
f0103584:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103587:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010358d:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103592:	eb 0a                	jmp    f010359e <envid2env+0x7c>
	}

	*env_store = e;
f0103594:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103597:	89 10                	mov    %edx,(%eax)
	return 0;
f0103599:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010359e:	5d                   	pop    %ebp
f010359f:	c3                   	ret    

f01035a0 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01035a0:	55                   	push   %ebp
f01035a1:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f01035a3:	b8 00 d3 11 f0       	mov    $0xf011d300,%eax
f01035a8:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.11
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f01035ab:	b8 23 00 00 00       	mov    $0x23,%eax
f01035b0:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f01035b2:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f01035b4:	b0 10                	mov    $0x10,%al
f01035b6:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01035b8:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01035ba:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01035bc:	ea c3 35 10 f0 08 00 	ljmp   $0x8,$0xf01035c3
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f01035c3:	b0 00                	mov    $0x0,%al
f01035c5:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01035c8:	5d                   	pop    %ebp
f01035c9:	c3                   	ret    

f01035ca <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01035ca:	55                   	push   %ebp
f01035cb:	89 e5                	mov    %esp,%ebp
f01035cd:	56                   	push   %esi
f01035ce:	53                   	push   %ebx
	// LAB 3: Your code here
	env_free_list = NULL;
	uint32_t i = NENV - 1;
	while (i > 0){
		i--;
		envs[i].env_id = 0;
f01035cf:	8b 35 e8 f1 17 f0    	mov    0xf017f1e8,%esi
f01035d5:	8d 86 40 7f 01 00    	lea    0x17f40(%esi),%eax
f01035db:	ba ff 03 00 00       	mov    $0x3ff,%edx
f01035e0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01035e5:	89 c3                	mov    %eax,%ebx
f01035e7:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f01035ee:	89 48 44             	mov    %ecx,0x44(%eax)
f01035f1:	83 e8 60             	sub    $0x60,%eax
{
	// Set up envs array
	// LAB 3: Your code here
	env_free_list = NULL;
	uint32_t i = NENV - 1;
	while (i > 0){
f01035f4:	83 ea 01             	sub    $0x1,%edx
f01035f7:	74 04                	je     f01035fd <env_init+0x33>
		i--;
		envs[i].env_id = 0;
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
f01035f9:	89 d9                	mov    %ebx,%ecx
f01035fb:	eb e8                	jmp    f01035e5 <env_init+0x1b>
f01035fd:	89 35 ec f1 17 f0    	mov    %esi,0xf017f1ec
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f0103603:	e8 98 ff ff ff       	call   f01035a0 <env_init_percpu>
}
f0103608:	5b                   	pop    %ebx
f0103609:	5e                   	pop    %esi
f010360a:	5d                   	pop    %ebp
f010360b:	c3                   	ret    

f010360c <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f010360c:	55                   	push   %ebp
f010360d:	89 e5                	mov    %esp,%ebp
f010360f:	53                   	push   %ebx
f0103610:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103613:	8b 1d ec f1 17 f0    	mov    0xf017f1ec,%ebx
f0103619:	85 db                	test   %ebx,%ebx
f010361b:	0f 84 8e 01 00 00    	je     f01037af <env_alloc+0x1a3>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103621:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0103628:	e8 8d de ff ff       	call   f01014ba <page_alloc>
f010362d:	85 c0                	test   %eax,%eax
f010362f:	0f 84 81 01 00 00    	je     f01037b6 <env_alloc+0x1aa>
f0103635:	89 c2                	mov    %eax,%edx
f0103637:	2b 15 ac fe 17 f0    	sub    0xf017feac,%edx
f010363d:	c1 fa 03             	sar    $0x3,%edx
f0103640:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103643:	89 d1                	mov    %edx,%ecx
f0103645:	c1 e9 0c             	shr    $0xc,%ecx
f0103648:	3b 0d a4 fe 17 f0    	cmp    0xf017fea4,%ecx
f010364e:	72 20                	jb     f0103670 <env_alloc+0x64>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103650:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103654:	c7 44 24 08 40 5e 10 	movl   $0xf0105e40,0x8(%esp)
f010365b:	f0 
f010365c:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
f0103663:	00 
f0103664:	c7 04 24 39 66 10 f0 	movl   $0xf0106639,(%esp)
f010366b:	e8 46 ca ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0103670:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0103676:	89 53 5c             	mov    %edx,0x5c(%ebx)
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = (pde_t *)page2kva(p);
	p->pp_ref++;
f0103679:	66 83 40 04 01       	addw   $0x1,0x4(%eax)

	for (i = 0; i < PDX(UTOP); i++)
f010367e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103683:	ba 00 00 00 00       	mov    $0x0,%edx
		e->env_pgdir[i] = 0;
f0103688:	8b 4b 5c             	mov    0x5c(%ebx),%ecx
f010368b:	c7 04 91 00 00 00 00 	movl   $0x0,(%ecx,%edx,4)

	// LAB 3: Your code here.
	e->env_pgdir = (pde_t *)page2kva(p);
	p->pp_ref++;

	for (i = 0; i < PDX(UTOP); i++)
f0103692:	83 c0 01             	add    $0x1,%eax
f0103695:	89 c2                	mov    %eax,%edx
f0103697:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010369c:	75 ea                	jne    f0103688 <env_alloc+0x7c>
f010369e:	66 b8 ec 0e          	mov    $0xeec,%ax
		e->env_pgdir[i] = 0;
	for (i = PDX(UTOP); i < NPDENTRIES; i++)
		e->env_pgdir[i] = kern_pgdir[i];
f01036a2:	8b 15 a8 fe 17 f0    	mov    0xf017fea8,%edx
f01036a8:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f01036ab:	8b 53 5c             	mov    0x5c(%ebx),%edx
f01036ae:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f01036b1:	83 c0 04             	add    $0x4,%eax
	e->env_pgdir = (pde_t *)page2kva(p);
	p->pp_ref++;

	for (i = 0; i < PDX(UTOP); i++)
		e->env_pgdir[i] = 0;
	for (i = PDX(UTOP); i < NPDENTRIES; i++)
f01036b4:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01036b9:	75 e7                	jne    f01036a2 <env_alloc+0x96>
		e->env_pgdir[i] = kern_pgdir[i];

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01036bb:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01036be:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01036c3:	77 20                	ja     f01036e5 <env_alloc+0xd9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01036c5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036c9:	c7 44 24 08 64 5f 10 	movl   $0xf0105f64,0x8(%esp)
f01036d0:	f0 
f01036d1:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
f01036d8:	00 
f01036d9:	c7 04 24 8a 69 10 f0 	movl   $0xf010698a,(%esp)
f01036e0:	e8 d1 c9 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01036e5:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01036eb:	83 ca 05             	or     $0x5,%edx
f01036ee:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01036f4:	8b 43 48             	mov    0x48(%ebx),%eax
f01036f7:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01036fc:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103701:	ba 00 10 00 00       	mov    $0x1000,%edx
f0103706:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103709:	89 da                	mov    %ebx,%edx
f010370b:	2b 15 e8 f1 17 f0    	sub    0xf017f1e8,%edx
f0103711:	c1 fa 05             	sar    $0x5,%edx
f0103714:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010371a:	09 d0                	or     %edx,%eax
f010371c:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f010371f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103722:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103725:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f010372c:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103733:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010373a:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103741:	00 
f0103742:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103749:	00 
f010374a:	89 1c 24             	mov    %ebx,(%esp)
f010374d:	e8 55 18 00 00       	call   f0104fa7 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103752:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103758:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f010375e:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103764:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f010376b:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0103771:	8b 43 44             	mov    0x44(%ebx),%eax
f0103774:	a3 ec f1 17 f0       	mov    %eax,0xf017f1ec
	*newenv_store = e;
f0103779:	8b 45 08             	mov    0x8(%ebp),%eax
f010377c:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010377e:	8b 53 48             	mov    0x48(%ebx),%edx
f0103781:	a1 e4 f1 17 f0       	mov    0xf017f1e4,%eax
f0103786:	85 c0                	test   %eax,%eax
f0103788:	74 05                	je     f010378f <env_alloc+0x183>
f010378a:	8b 40 48             	mov    0x48(%eax),%eax
f010378d:	eb 05                	jmp    f0103794 <env_alloc+0x188>
f010378f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103794:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103798:	89 44 24 04          	mov    %eax,0x4(%esp)
f010379c:	c7 04 24 af 69 10 f0 	movl   $0xf01069af,(%esp)
f01037a3:	e8 b8 04 00 00       	call   f0103c60 <cprintf>
	return 0;
f01037a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01037ad:	eb 0c                	jmp    f01037bb <env_alloc+0x1af>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01037af:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01037b4:	eb 05                	jmp    f01037bb <env_alloc+0x1af>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f01037b6:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01037bb:	83 c4 14             	add    $0x14,%esp
f01037be:	5b                   	pop    %ebx
f01037bf:	5d                   	pop    %ebp
f01037c0:	c3                   	ret    

f01037c1 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01037c1:	55                   	push   %ebp
f01037c2:	89 e5                	mov    %esp,%ebp
f01037c4:	57                   	push   %edi
f01037c5:	56                   	push   %esi
f01037c6:	53                   	push   %ebx
f01037c7:	83 ec 3c             	sub    $0x3c,%esp
f01037ca:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *newEnv;
	if (env_alloc(&newEnv, 0) < 0)
f01037cd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01037d4:	00 
f01037d5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01037d8:	89 04 24             	mov    %eax,(%esp)
f01037db:	e8 2c fe ff ff       	call   f010360c <env_alloc>
f01037e0:	85 c0                	test   %eax,%eax
f01037e2:	79 1c                	jns    f0103800 <env_create+0x3f>
		panic("fail to alloc env!");
f01037e4:	c7 44 24 08 c4 69 10 	movl   $0xf01069c4,0x8(%esp)
f01037eb:	f0 
f01037ec:	c7 44 24 04 8d 01 00 	movl   $0x18d,0x4(%esp)
f01037f3:	00 
f01037f4:	c7 04 24 8a 69 10 f0 	movl   $0xf010698a,(%esp)
f01037fb:	e8 b6 c8 ff ff       	call   f01000b6 <_panic>
	load_icode(newEnv, binary);
f0103800:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103803:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// LAB 3: Your code here.
	// Use lcr3() to switch to its address space.
	// switch address space for loading program segments

	struct Elf *ELFHeader = (struct Elf *)binary;
	if (ELFHeader->e_magic != ELF_MAGIC)
f0103806:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f010380c:	74 1c                	je     f010382a <env_create+0x69>
		panic("the binary is not elg!\n");
f010380e:	c7 44 24 08 d7 69 10 	movl   $0xf01069d7,0x8(%esp)
f0103815:	f0 
f0103816:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
f010381d:	00 
f010381e:	c7 04 24 8a 69 10 f0 	movl   $0xf010698a,(%esp)
f0103825:	e8 8c c8 ff ff       	call   f01000b6 <_panic>

	struct Proghdr *ph, *eph;
	ph = (struct Proghdr *)(binary + ELFHeader->e_phoff);
f010382a:	89 fb                	mov    %edi,%ebx
f010382c:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHeader->e_phnum;
f010382f:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103833:	c1 e6 05             	shl    $0x5,%esi
f0103836:	01 de                	add    %ebx,%esi

	lcr3(PADDR(e->env_pgdir));
f0103838:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010383b:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010383e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103843:	77 20                	ja     f0103865 <env_create+0xa4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103845:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103849:	c7 44 24 08 64 5f 10 	movl   $0xf0105f64,0x8(%esp)
f0103850:	f0 
f0103851:	c7 44 24 04 6b 01 00 	movl   $0x16b,0x4(%esp)
f0103858:	00 
f0103859:	c7 04 24 8a 69 10 f0 	movl   $0xf010698a,(%esp)
f0103860:	e8 51 c8 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103865:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010386a:	0f 22 d8             	mov    %eax,%cr3
f010386d:	eb 6c                	jmp    f01038db <env_create+0x11a>
	for (; ph < eph; ph ++){
		if (ph->p_type == ELF_PROG_LOAD){
f010386f:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103872:	75 64                	jne    f01038d8 <env_create+0x117>
			if (ph->p_filesz > ph->p_memsz)
f0103874:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103877:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f010387a:	76 1c                	jbe    f0103898 <env_create+0xd7>
				panic("file size overflow memory size!");
f010387c:	c7 44 24 08 34 69 10 	movl   $0xf0106934,0x8(%esp)
f0103883:	f0 
f0103884:	c7 44 24 04 6f 01 00 	movl   $0x16f,0x4(%esp)
f010388b:	00 
f010388c:	c7 04 24 8a 69 10 f0 	movl   $0xf010698a,(%esp)
f0103893:	e8 1e c8 ff ff       	call   f01000b6 <_panic>
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0103898:	8b 53 08             	mov    0x8(%ebx),%edx
f010389b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010389e:	e8 e4 fb ff ff       	call   f0103487 <region_alloc>
			memset((void *)ph->p_va, 0, ph->p_memsz);
f01038a3:	8b 43 14             	mov    0x14(%ebx),%eax
f01038a6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01038aa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01038b1:	00 
f01038b2:	8b 43 08             	mov    0x8(%ebx),%eax
f01038b5:	89 04 24             	mov    %eax,(%esp)
f01038b8:	e8 ea 16 00 00       	call   f0104fa7 <memset>
			memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f01038bd:	8b 43 10             	mov    0x10(%ebx),%eax
f01038c0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01038c4:	89 f8                	mov    %edi,%eax
f01038c6:	03 43 04             	add    0x4(%ebx),%eax
f01038c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038cd:	8b 43 08             	mov    0x8(%ebx),%eax
f01038d0:	89 04 24             	mov    %eax,(%esp)
f01038d3:	e8 84 17 00 00       	call   f010505c <memcpy>
	struct Proghdr *ph, *eph;
	ph = (struct Proghdr *)(binary + ELFHeader->e_phoff);
	eph = ph + ELFHeader->e_phnum;

	lcr3(PADDR(e->env_pgdir));
	for (; ph < eph; ph ++){
f01038d8:	83 c3 20             	add    $0x20,%ebx
f01038db:	39 de                	cmp    %ebx,%esi
f01038dd:	77 90                	ja     f010386f <env_create+0xae>
			memset((void *)ph->p_va, 0, ph->p_memsz);
			memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
		}
	}

	e->env_tf.tf_eip = ELFHeader->e_entry;
f01038df:	8b 47 18             	mov    0x18(%edi),%eax
f01038e2:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01038e5:	89 47 30             	mov    %eax,0x30(%edi)

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *)(USTACKTOP - PGSIZE), PGSIZE);
f01038e8:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01038ed:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01038f2:	89 f8                	mov    %edi,%eax
f01038f4:	e8 8e fb ff ff       	call   f0103487 <region_alloc>
	lcr3(PADDR(kern_pgdir));
f01038f9:	a1 a8 fe 17 f0       	mov    0xf017fea8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01038fe:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103903:	77 20                	ja     f0103925 <env_create+0x164>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103905:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103909:	c7 44 24 08 64 5f 10 	movl   $0xf0105f64,0x8(%esp)
f0103910:	f0 
f0103911:	c7 44 24 04 7d 01 00 	movl   $0x17d,0x4(%esp)
f0103918:	00 
f0103919:	c7 04 24 8a 69 10 f0 	movl   $0xf010698a,(%esp)
f0103920:	e8 91 c7 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103925:	05 00 00 00 10       	add    $0x10000000,%eax
f010392a:	0f 22 d8             	mov    %eax,%cr3
	// LAB 3: Your code here.
	struct Env *newEnv;
	if (env_alloc(&newEnv, 0) < 0)
		panic("fail to alloc env!");
	load_icode(newEnv, binary);
	newEnv->env_type = type;
f010392d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103930:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103933:	89 50 50             	mov    %edx,0x50(%eax)
	newEnv->env_parent_id = 0;
f0103936:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
}
f010393d:	83 c4 3c             	add    $0x3c,%esp
f0103940:	5b                   	pop    %ebx
f0103941:	5e                   	pop    %esi
f0103942:	5f                   	pop    %edi
f0103943:	5d                   	pop    %ebp
f0103944:	c3                   	ret    

f0103945 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103945:	55                   	push   %ebp
f0103946:	89 e5                	mov    %esp,%ebp
f0103948:	57                   	push   %edi
f0103949:	56                   	push   %esi
f010394a:	53                   	push   %ebx
f010394b:	83 ec 2c             	sub    $0x2c,%esp
f010394e:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103951:	a1 e4 f1 17 f0       	mov    0xf017f1e4,%eax
f0103956:	39 c7                	cmp    %eax,%edi
f0103958:	75 37                	jne    f0103991 <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f010395a:	8b 15 a8 fe 17 f0    	mov    0xf017fea8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103960:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103966:	77 20                	ja     f0103988 <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103968:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010396c:	c7 44 24 08 64 5f 10 	movl   $0xf0105f64,0x8(%esp)
f0103973:	f0 
f0103974:	c7 44 24 04 a1 01 00 	movl   $0x1a1,0x4(%esp)
f010397b:	00 
f010397c:	c7 04 24 8a 69 10 f0 	movl   $0xf010698a,(%esp)
f0103983:	e8 2e c7 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103988:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f010398e:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103991:	8b 57 48             	mov    0x48(%edi),%edx
f0103994:	85 c0                	test   %eax,%eax
f0103996:	74 05                	je     f010399d <env_free+0x58>
f0103998:	8b 40 48             	mov    0x48(%eax),%eax
f010399b:	eb 05                	jmp    f01039a2 <env_free+0x5d>
f010399d:	b8 00 00 00 00       	mov    $0x0,%eax
f01039a2:	89 54 24 08          	mov    %edx,0x8(%esp)
f01039a6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039aa:	c7 04 24 ef 69 10 f0 	movl   $0xf01069ef,(%esp)
f01039b1:	e8 aa 02 00 00       	call   f0103c60 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01039b6:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01039bd:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01039c0:	89 c8                	mov    %ecx,%eax
f01039c2:	c1 e0 02             	shl    $0x2,%eax
f01039c5:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01039c8:	8b 47 5c             	mov    0x5c(%edi),%eax
f01039cb:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f01039ce:	f7 c6 01 00 00 00    	test   $0x1,%esi
f01039d4:	0f 84 b7 00 00 00    	je     f0103a91 <env_free+0x14c>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01039da:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01039e0:	89 f0                	mov    %esi,%eax
f01039e2:	c1 e8 0c             	shr    $0xc,%eax
f01039e5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01039e8:	3b 05 a4 fe 17 f0    	cmp    0xf017fea4,%eax
f01039ee:	72 20                	jb     f0103a10 <env_free+0xcb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01039f0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01039f4:	c7 44 24 08 40 5e 10 	movl   $0xf0105e40,0x8(%esp)
f01039fb:	f0 
f01039fc:	c7 44 24 04 b0 01 00 	movl   $0x1b0,0x4(%esp)
f0103a03:	00 
f0103a04:	c7 04 24 8a 69 10 f0 	movl   $0xf010698a,(%esp)
f0103a0b:	e8 a6 c6 ff ff       	call   f01000b6 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103a10:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a13:	c1 e0 16             	shl    $0x16,%eax
f0103a16:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103a19:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103a1e:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103a25:	01 
f0103a26:	74 17                	je     f0103a3f <env_free+0xfa>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103a28:	89 d8                	mov    %ebx,%eax
f0103a2a:	c1 e0 0c             	shl    $0xc,%eax
f0103a2d:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103a30:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a34:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103a37:	89 04 24             	mov    %eax,(%esp)
f0103a3a:	e8 48 dd ff ff       	call   f0101787 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103a3f:	83 c3 01             	add    $0x1,%ebx
f0103a42:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103a48:	75 d4                	jne    f0103a1e <env_free+0xd9>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103a4a:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103a4d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103a50:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103a57:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103a5a:	3b 05 a4 fe 17 f0    	cmp    0xf017fea4,%eax
f0103a60:	72 1c                	jb     f0103a7e <env_free+0x139>
		panic("pa2page called with invalid pa");
f0103a62:	c7 44 24 08 b4 5f 10 	movl   $0xf0105fb4,0x8(%esp)
f0103a69:	f0 
f0103a6a:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0103a71:	00 
f0103a72:	c7 04 24 39 66 10 f0 	movl   $0xf0106639,(%esp)
f0103a79:	e8 38 c6 ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f0103a7e:	a1 ac fe 17 f0       	mov    0xf017feac,%eax
f0103a83:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103a86:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f0103a89:	89 04 24             	mov    %eax,(%esp)
f0103a8c:	e8 f4 da ff ff       	call   f0101585 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103a91:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103a95:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103a9c:	0f 85 1b ff ff ff    	jne    f01039bd <env_free+0x78>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103aa2:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103aa5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103aaa:	77 20                	ja     f0103acc <env_free+0x187>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103aac:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103ab0:	c7 44 24 08 64 5f 10 	movl   $0xf0105f64,0x8(%esp)
f0103ab7:	f0 
f0103ab8:	c7 44 24 04 be 01 00 	movl   $0x1be,0x4(%esp)
f0103abf:	00 
f0103ac0:	c7 04 24 8a 69 10 f0 	movl   $0xf010698a,(%esp)
f0103ac7:	e8 ea c5 ff ff       	call   f01000b6 <_panic>
	e->env_pgdir = 0;
f0103acc:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103ad3:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103ad8:	c1 e8 0c             	shr    $0xc,%eax
f0103adb:	3b 05 a4 fe 17 f0    	cmp    0xf017fea4,%eax
f0103ae1:	72 1c                	jb     f0103aff <env_free+0x1ba>
		panic("pa2page called with invalid pa");
f0103ae3:	c7 44 24 08 b4 5f 10 	movl   $0xf0105fb4,0x8(%esp)
f0103aea:	f0 
f0103aeb:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0103af2:	00 
f0103af3:	c7 04 24 39 66 10 f0 	movl   $0xf0106639,(%esp)
f0103afa:	e8 b7 c5 ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f0103aff:	8b 15 ac fe 17 f0    	mov    0xf017feac,%edx
f0103b05:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f0103b08:	89 04 24             	mov    %eax,(%esp)
f0103b0b:	e8 75 da ff ff       	call   f0101585 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103b10:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103b17:	a1 ec f1 17 f0       	mov    0xf017f1ec,%eax
f0103b1c:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103b1f:	89 3d ec f1 17 f0    	mov    %edi,0xf017f1ec
}
f0103b25:	83 c4 2c             	add    $0x2c,%esp
f0103b28:	5b                   	pop    %ebx
f0103b29:	5e                   	pop    %esi
f0103b2a:	5f                   	pop    %edi
f0103b2b:	5d                   	pop    %ebp
f0103b2c:	c3                   	ret    

f0103b2d <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0103b2d:	55                   	push   %ebp
f0103b2e:	89 e5                	mov    %esp,%ebp
f0103b30:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f0103b33:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b36:	89 04 24             	mov    %eax,(%esp)
f0103b39:	e8 07 fe ff ff       	call   f0103945 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0103b3e:	c7 04 24 54 69 10 f0 	movl   $0xf0106954,(%esp)
f0103b45:	e8 16 01 00 00       	call   f0103c60 <cprintf>
	while (1)
		monitor(NULL);
f0103b4a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103b51:	e8 2e d2 ff ff       	call   f0100d84 <monitor>
f0103b56:	eb f2                	jmp    f0103b4a <env_destroy+0x1d>

f0103b58 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103b58:	55                   	push   %ebp
f0103b59:	89 e5                	mov    %esp,%ebp
f0103b5b:	83 ec 18             	sub    $0x18,%esp
	asm volatile(
f0103b5e:	8b 65 08             	mov    0x8(%ebp),%esp
f0103b61:	61                   	popa   
f0103b62:	07                   	pop    %es
f0103b63:	1f                   	pop    %ds
f0103b64:	83 c4 08             	add    $0x8,%esp
f0103b67:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103b68:	c7 44 24 08 05 6a 10 	movl   $0xf0106a05,0x8(%esp)
f0103b6f:	f0 
f0103b70:	c7 44 24 04 e7 01 00 	movl   $0x1e7,0x4(%esp)
f0103b77:	00 
f0103b78:	c7 04 24 8a 69 10 f0 	movl   $0xf010698a,(%esp)
f0103b7f:	e8 32 c5 ff ff       	call   f01000b6 <_panic>

f0103b84 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103b84:	55                   	push   %ebp
f0103b85:	89 e5                	mov    %esp,%ebp
f0103b87:	83 ec 18             	sub    $0x18,%esp
f0103b8a:	8b 45 08             	mov    0x8(%ebp),%eax
	//	      what other states it can be in),
	//	   2. Set 'curenv' to the new environment,
	//	   3. Set its status to ENV_RUNNING,
	//	   4. Update its 'env_runs' counter,
	//	   5. Use lcr3() to switch to its address space.
	if (curenv != NULL && curenv->env_status == ENV_RUNNING)
f0103b8d:	8b 15 e4 f1 17 f0    	mov    0xf017f1e4,%edx
f0103b93:	85 d2                	test   %edx,%edx
f0103b95:	74 0d                	je     f0103ba4 <env_run+0x20>
f0103b97:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0103b9b:	75 07                	jne    f0103ba4 <env_run+0x20>
		curenv->env_status = ENV_RUNNABLE;
f0103b9d:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)

	curenv = e;
f0103ba4:	a3 e4 f1 17 f0       	mov    %eax,0xf017f1e4
	e->env_status = ENV_RUNNING;
f0103ba9:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++;
f0103bb0:	83 40 58 01          	addl   $0x1,0x58(%eax)

	lcr3(PADDR(e->env_pgdir));
f0103bb4:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103bb7:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103bbd:	77 20                	ja     f0103bdf <env_run+0x5b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103bbf:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103bc3:	c7 44 24 08 64 5f 10 	movl   $0xf0105f64,0x8(%esp)
f0103bca:	f0 
f0103bcb:	c7 44 24 04 08 02 00 	movl   $0x208,0x4(%esp)
f0103bd2:	00 
f0103bd3:	c7 04 24 8a 69 10 f0 	movl   $0xf010698a,(%esp)
f0103bda:	e8 d7 c4 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103bdf:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103be5:	0f 22 da             	mov    %edx,%cr3

	// Step 2: Use env_pop_tf() to restore the envi ronment's
	//	   registers and drop into user mode in the
	//	   environment.
	env_pop_tf(&(e->env_tf));
f0103be8:	89 04 24             	mov    %eax,(%esp)
f0103beb:	e8 68 ff ff ff       	call   f0103b58 <env_pop_tf>

f0103bf0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103bf0:	55                   	push   %ebp
f0103bf1:	89 e5                	mov    %esp,%ebp
f0103bf3:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103bf7:	ba 70 00 00 00       	mov    $0x70,%edx
f0103bfc:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103bfd:	b2 71                	mov    $0x71,%dl
f0103bff:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103c00:	0f b6 c0             	movzbl %al,%eax
}
f0103c03:	5d                   	pop    %ebp
f0103c04:	c3                   	ret    

f0103c05 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103c05:	55                   	push   %ebp
f0103c06:	89 e5                	mov    %esp,%ebp
f0103c08:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103c0c:	ba 70 00 00 00       	mov    $0x70,%edx
f0103c11:	ee                   	out    %al,(%dx)
f0103c12:	b2 71                	mov    $0x71,%dl
f0103c14:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103c17:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103c18:	5d                   	pop    %ebp
f0103c19:	c3                   	ret    

f0103c1a <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103c1a:	55                   	push   %ebp
f0103c1b:	89 e5                	mov    %esp,%ebp
f0103c1d:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0103c20:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c23:	89 04 24             	mov    %eax,(%esp)
f0103c26:	e8 f6 c9 ff ff       	call   f0100621 <cputchar>
	*cnt++;
}
f0103c2b:	c9                   	leave  
f0103c2c:	c3                   	ret    

f0103c2d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103c2d:	55                   	push   %ebp
f0103c2e:	89 e5                	mov    %esp,%ebp
f0103c30:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0103c33:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103c3a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103c3d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103c41:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c44:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c48:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103c4b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c4f:	c7 04 24 1a 3c 10 f0 	movl   $0xf0103c1a,(%esp)
f0103c56:	e8 93 0c 00 00       	call   f01048ee <vprintfmt>
	return cnt;
}
f0103c5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103c5e:	c9                   	leave  
f0103c5f:	c3                   	ret    

f0103c60 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103c60:	55                   	push   %ebp
f0103c61:	89 e5                	mov    %esp,%ebp
f0103c63:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103c66:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103c69:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c6d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c70:	89 04 24             	mov    %eax,(%esp)
f0103c73:	e8 b5 ff ff ff       	call   f0103c2d <vcprintf>
	va_end(ap);

	return cnt;
}
f0103c78:	c9                   	leave  
f0103c79:	c3                   	ret    

f0103c7a <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103c7a:	55                   	push   %ebp
f0103c7b:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103c7d:	c7 05 24 fa 17 f0 00 	movl   $0xf0000000,0xf017fa24
f0103c84:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103c87:	66 c7 05 28 fa 17 f0 	movw   $0x10,0xf017fa28
f0103c8e:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103c90:	66 c7 05 48 d3 11 f0 	movw   $0x67,0xf011d348
f0103c97:	67 00 
f0103c99:	b8 20 fa 17 f0       	mov    $0xf017fa20,%eax
f0103c9e:	66 a3 4a d3 11 f0    	mov    %ax,0xf011d34a
f0103ca4:	89 c2                	mov    %eax,%edx
f0103ca6:	c1 ea 10             	shr    $0x10,%edx
f0103ca9:	88 15 4c d3 11 f0    	mov    %dl,0xf011d34c
f0103caf:	c6 05 4e d3 11 f0 40 	movb   $0x40,0xf011d34e
f0103cb6:	c1 e8 18             	shr    $0x18,%eax
f0103cb9:	a2 4f d3 11 f0       	mov    %al,0xf011d34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103cbe:	c6 05 4d d3 11 f0 89 	movb   $0x89,0xf011d34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0103cc5:	b8 28 00 00 00       	mov    $0x28,%eax
f0103cca:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0103ccd:	b8 50 d3 11 f0       	mov    $0xf011d350,%eax
f0103cd2:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103cd5:	5d                   	pop    %ebp
f0103cd6:	c3                   	ret    

f0103cd7 <trap_init>:
}


void
trap_init(void)
{
f0103cd7:	55                   	push   %ebp
f0103cd8:	89 e5                	mov    %esp,%ebp
	void t_mchk();
	void t_simderr();
	void t_syscall();

	// trap
	SETGATE(idt[T_DIVIDE], 1, GD_KT, t_divide, 0);
f0103cda:	b8 92 43 10 f0       	mov    $0xf0104392,%eax
f0103cdf:	66 a3 00 f2 17 f0    	mov    %ax,0xf017f200
f0103ce5:	66 c7 05 02 f2 17 f0 	movw   $0x8,0xf017f202
f0103cec:	08 00 
f0103cee:	c6 05 04 f2 17 f0 00 	movb   $0x0,0xf017f204
f0103cf5:	c6 05 05 f2 17 f0 8f 	movb   $0x8f,0xf017f205
f0103cfc:	c1 e8 10             	shr    $0x10,%eax
f0103cff:	66 a3 06 f2 17 f0    	mov    %ax,0xf017f206
	SETGATE(idt[T_DEBUG], 1, GD_KT, t_debug, 0);
f0103d05:	b8 98 43 10 f0       	mov    $0xf0104398,%eax
f0103d0a:	66 a3 08 f2 17 f0    	mov    %ax,0xf017f208
f0103d10:	66 c7 05 0a f2 17 f0 	movw   $0x8,0xf017f20a
f0103d17:	08 00 
f0103d19:	c6 05 0c f2 17 f0 00 	movb   $0x0,0xf017f20c
f0103d20:	c6 05 0d f2 17 f0 8f 	movb   $0x8f,0xf017f20d
f0103d27:	c1 e8 10             	shr    $0x10,%eax
f0103d2a:	66 a3 0e f2 17 f0    	mov    %ax,0xf017f20e
	SETGATE(idt[T_NMI], 1, GD_KT, t_nmi, 0);
f0103d30:	b8 9e 43 10 f0       	mov    $0xf010439e,%eax
f0103d35:	66 a3 10 f2 17 f0    	mov    %ax,0xf017f210
f0103d3b:	66 c7 05 12 f2 17 f0 	movw   $0x8,0xf017f212
f0103d42:	08 00 
f0103d44:	c6 05 14 f2 17 f0 00 	movb   $0x0,0xf017f214
f0103d4b:	c6 05 15 f2 17 f0 8f 	movb   $0x8f,0xf017f215
f0103d52:	c1 e8 10             	shr    $0x10,%eax
f0103d55:	66 a3 16 f2 17 f0    	mov    %ax,0xf017f216
	SETGATE(idt[T_BRKPT], 1, GD_KT, t_brkpt, 0);
f0103d5b:	b8 a4 43 10 f0       	mov    $0xf01043a4,%eax
f0103d60:	66 a3 18 f2 17 f0    	mov    %ax,0xf017f218
f0103d66:	66 c7 05 1a f2 17 f0 	movw   $0x8,0xf017f21a
f0103d6d:	08 00 
f0103d6f:	c6 05 1c f2 17 f0 00 	movb   $0x0,0xf017f21c
f0103d76:	c6 05 1d f2 17 f0 8f 	movb   $0x8f,0xf017f21d
f0103d7d:	c1 e8 10             	shr    $0x10,%eax
f0103d80:	66 a3 1e f2 17 f0    	mov    %ax,0xf017f21e
	SETGATE(idt[T_OFLOW], 1, GD_KT, t_oflow, 0);
f0103d86:	b8 aa 43 10 f0       	mov    $0xf01043aa,%eax
f0103d8b:	66 a3 20 f2 17 f0    	mov    %ax,0xf017f220
f0103d91:	66 c7 05 22 f2 17 f0 	movw   $0x8,0xf017f222
f0103d98:	08 00 
f0103d9a:	c6 05 24 f2 17 f0 00 	movb   $0x0,0xf017f224
f0103da1:	c6 05 25 f2 17 f0 8f 	movb   $0x8f,0xf017f225
f0103da8:	c1 e8 10             	shr    $0x10,%eax
f0103dab:	66 a3 26 f2 17 f0    	mov    %ax,0xf017f226
	SETGATE(idt[T_BOUND], 1, GD_KT, t_bound, 0);
f0103db1:	b8 b0 43 10 f0       	mov    $0xf01043b0,%eax
f0103db6:	66 a3 28 f2 17 f0    	mov    %ax,0xf017f228
f0103dbc:	66 c7 05 2a f2 17 f0 	movw   $0x8,0xf017f22a
f0103dc3:	08 00 
f0103dc5:	c6 05 2c f2 17 f0 00 	movb   $0x0,0xf017f22c
f0103dcc:	c6 05 2d f2 17 f0 8f 	movb   $0x8f,0xf017f22d
f0103dd3:	c1 e8 10             	shr    $0x10,%eax
f0103dd6:	66 a3 2e f2 17 f0    	mov    %ax,0xf017f22e
	SETGATE(idt[T_ILLOP], 1, GD_KT, t_illop, 0);
f0103ddc:	b8 b6 43 10 f0       	mov    $0xf01043b6,%eax
f0103de1:	66 a3 30 f2 17 f0    	mov    %ax,0xf017f230
f0103de7:	66 c7 05 32 f2 17 f0 	movw   $0x8,0xf017f232
f0103dee:	08 00 
f0103df0:	c6 05 34 f2 17 f0 00 	movb   $0x0,0xf017f234
f0103df7:	c6 05 35 f2 17 f0 8f 	movb   $0x8f,0xf017f235
f0103dfe:	c1 e8 10             	shr    $0x10,%eax
f0103e01:	66 a3 36 f2 17 f0    	mov    %ax,0xf017f236
	SETGATE(idt[T_DEVICE], 1, GD_KT, t_device, 0);
f0103e07:	b8 bc 43 10 f0       	mov    $0xf01043bc,%eax
f0103e0c:	66 a3 38 f2 17 f0    	mov    %ax,0xf017f238
f0103e12:	66 c7 05 3a f2 17 f0 	movw   $0x8,0xf017f23a
f0103e19:	08 00 
f0103e1b:	c6 05 3c f2 17 f0 00 	movb   $0x0,0xf017f23c
f0103e22:	c6 05 3d f2 17 f0 8f 	movb   $0x8f,0xf017f23d
f0103e29:	c1 e8 10             	shr    $0x10,%eax
f0103e2c:	66 a3 3e f2 17 f0    	mov    %ax,0xf017f23e
	SETGATE(idt[T_DBLFLT], 1, GD_KT, t_dblflt, 0);
f0103e32:	b8 c2 43 10 f0       	mov    $0xf01043c2,%eax
f0103e37:	66 a3 40 f2 17 f0    	mov    %ax,0xf017f240
f0103e3d:	66 c7 05 42 f2 17 f0 	movw   $0x8,0xf017f242
f0103e44:	08 00 
f0103e46:	c6 05 44 f2 17 f0 00 	movb   $0x0,0xf017f244
f0103e4d:	c6 05 45 f2 17 f0 8f 	movb   $0x8f,0xf017f245
f0103e54:	c1 e8 10             	shr    $0x10,%eax
f0103e57:	66 a3 46 f2 17 f0    	mov    %ax,0xf017f246
	SETGATE(idt[T_TSS], 1, GD_KT, t_tss, 0);
f0103e5d:	b8 c6 43 10 f0       	mov    $0xf01043c6,%eax
f0103e62:	66 a3 50 f2 17 f0    	mov    %ax,0xf017f250
f0103e68:	66 c7 05 52 f2 17 f0 	movw   $0x8,0xf017f252
f0103e6f:	08 00 
f0103e71:	c6 05 54 f2 17 f0 00 	movb   $0x0,0xf017f254
f0103e78:	c6 05 55 f2 17 f0 8f 	movb   $0x8f,0xf017f255
f0103e7f:	c1 e8 10             	shr    $0x10,%eax
f0103e82:	66 a3 56 f2 17 f0    	mov    %ax,0xf017f256
	SETGATE(idt[T_SEGNP], 1, GD_KT, t_segnp, 0);
f0103e88:	b8 ca 43 10 f0       	mov    $0xf01043ca,%eax
f0103e8d:	66 a3 58 f2 17 f0    	mov    %ax,0xf017f258
f0103e93:	66 c7 05 5a f2 17 f0 	movw   $0x8,0xf017f25a
f0103e9a:	08 00 
f0103e9c:	c6 05 5c f2 17 f0 00 	movb   $0x0,0xf017f25c
f0103ea3:	c6 05 5d f2 17 f0 8f 	movb   $0x8f,0xf017f25d
f0103eaa:	c1 e8 10             	shr    $0x10,%eax
f0103ead:	66 a3 5e f2 17 f0    	mov    %ax,0xf017f25e
	SETGATE(idt[T_STACK], 1, GD_KT, t_stack, 0);
f0103eb3:	b8 ce 43 10 f0       	mov    $0xf01043ce,%eax
f0103eb8:	66 a3 60 f2 17 f0    	mov    %ax,0xf017f260
f0103ebe:	66 c7 05 62 f2 17 f0 	movw   $0x8,0xf017f262
f0103ec5:	08 00 
f0103ec7:	c6 05 64 f2 17 f0 00 	movb   $0x0,0xf017f264
f0103ece:	c6 05 65 f2 17 f0 8f 	movb   $0x8f,0xf017f265
f0103ed5:	c1 e8 10             	shr    $0x10,%eax
f0103ed8:	66 a3 66 f2 17 f0    	mov    %ax,0xf017f266
	SETGATE(idt[T_GPFLT], 1, GD_KT, t_gpflt, 0);
f0103ede:	b8 d2 43 10 f0       	mov    $0xf01043d2,%eax
f0103ee3:	66 a3 68 f2 17 f0    	mov    %ax,0xf017f268
f0103ee9:	66 c7 05 6a f2 17 f0 	movw   $0x8,0xf017f26a
f0103ef0:	08 00 
f0103ef2:	c6 05 6c f2 17 f0 00 	movb   $0x0,0xf017f26c
f0103ef9:	c6 05 6d f2 17 f0 8f 	movb   $0x8f,0xf017f26d
f0103f00:	c1 e8 10             	shr    $0x10,%eax
f0103f03:	66 a3 6e f2 17 f0    	mov    %ax,0xf017f26e
	SETGATE(idt[T_PGFLT], 1, GD_KT, t_pgflt, 0);
f0103f09:	b8 d6 43 10 f0       	mov    $0xf01043d6,%eax
f0103f0e:	66 a3 70 f2 17 f0    	mov    %ax,0xf017f270
f0103f14:	66 c7 05 72 f2 17 f0 	movw   $0x8,0xf017f272
f0103f1b:	08 00 
f0103f1d:	c6 05 74 f2 17 f0 00 	movb   $0x0,0xf017f274
f0103f24:	c6 05 75 f2 17 f0 8f 	movb   $0x8f,0xf017f275
f0103f2b:	c1 e8 10             	shr    $0x10,%eax
f0103f2e:	66 a3 76 f2 17 f0    	mov    %ax,0xf017f276
	SETGATE(idt[T_FPERR], 1, GD_KT, t_fperr, 0);
f0103f34:	b8 da 43 10 f0       	mov    $0xf01043da,%eax
f0103f39:	66 a3 80 f2 17 f0    	mov    %ax,0xf017f280
f0103f3f:	66 c7 05 82 f2 17 f0 	movw   $0x8,0xf017f282
f0103f46:	08 00 
f0103f48:	c6 05 84 f2 17 f0 00 	movb   $0x0,0xf017f284
f0103f4f:	c6 05 85 f2 17 f0 8f 	movb   $0x8f,0xf017f285
f0103f56:	c1 e8 10             	shr    $0x10,%eax
f0103f59:	66 a3 86 f2 17 f0    	mov    %ax,0xf017f286
	SETGATE(idt[T_ALIGN], 1, GD_KT, t_align, 0);
f0103f5f:	b8 e0 43 10 f0       	mov    $0xf01043e0,%eax
f0103f64:	66 a3 88 f2 17 f0    	mov    %ax,0xf017f288
f0103f6a:	66 c7 05 8a f2 17 f0 	movw   $0x8,0xf017f28a
f0103f71:	08 00 
f0103f73:	c6 05 8c f2 17 f0 00 	movb   $0x0,0xf017f28c
f0103f7a:	c6 05 8d f2 17 f0 8f 	movb   $0x8f,0xf017f28d
f0103f81:	c1 e8 10             	shr    $0x10,%eax
f0103f84:	66 a3 8e f2 17 f0    	mov    %ax,0xf017f28e
	SETGATE(idt[T_MCHK], 1, GD_KT, t_mchk, 0);
f0103f8a:	b8 e4 43 10 f0       	mov    $0xf01043e4,%eax
f0103f8f:	66 a3 90 f2 17 f0    	mov    %ax,0xf017f290
f0103f95:	66 c7 05 92 f2 17 f0 	movw   $0x8,0xf017f292
f0103f9c:	08 00 
f0103f9e:	c6 05 94 f2 17 f0 00 	movb   $0x0,0xf017f294
f0103fa5:	c6 05 95 f2 17 f0 8f 	movb   $0x8f,0xf017f295
f0103fac:	c1 e8 10             	shr    $0x10,%eax
f0103faf:	66 a3 96 f2 17 f0    	mov    %ax,0xf017f296
	SETGATE(idt[T_SIMDERR], 1, GD_KT, t_simderr, 0);
f0103fb5:	b8 ea 43 10 f0       	mov    $0xf01043ea,%eax
f0103fba:	66 a3 98 f2 17 f0    	mov    %ax,0xf017f298
f0103fc0:	66 c7 05 9a f2 17 f0 	movw   $0x8,0xf017f29a
f0103fc7:	08 00 
f0103fc9:	c6 05 9c f2 17 f0 00 	movb   $0x0,0xf017f29c
f0103fd0:	c6 05 9d f2 17 f0 8f 	movb   $0x8f,0xf017f29d
f0103fd7:	c1 e8 10             	shr    $0x10,%eax
f0103fda:	66 a3 9e f2 17 f0    	mov    %ax,0xf017f29e

	// interrupt
	SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 0);
f0103fe0:	b8 f0 43 10 f0       	mov    $0xf01043f0,%eax
f0103fe5:	66 a3 80 f3 17 f0    	mov    %ax,0xf017f380
f0103feb:	66 c7 05 82 f3 17 f0 	movw   $0x8,0xf017f382
f0103ff2:	08 00 
f0103ff4:	c6 05 84 f3 17 f0 00 	movb   $0x0,0xf017f384
f0103ffb:	c6 05 85 f3 17 f0 8e 	movb   $0x8e,0xf017f385
f0104002:	c1 e8 10             	shr    $0x10,%eax
f0104005:	66 a3 86 f3 17 f0    	mov    %ax,0xf017f386
	// Per-CPU setup 
	trap_init_percpu();
f010400b:	e8 6a fc ff ff       	call   f0103c7a <trap_init_percpu>
}
f0104010:	5d                   	pop    %ebp
f0104011:	c3                   	ret    

f0104012 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0104012:	55                   	push   %ebp
f0104013:	89 e5                	mov    %esp,%ebp
f0104015:	53                   	push   %ebx
f0104016:	83 ec 14             	sub    $0x14,%esp
f0104019:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f010401c:	8b 03                	mov    (%ebx),%eax
f010401e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104022:	c7 04 24 11 6a 10 f0 	movl   $0xf0106a11,(%esp)
f0104029:	e8 32 fc ff ff       	call   f0103c60 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f010402e:	8b 43 04             	mov    0x4(%ebx),%eax
f0104031:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104035:	c7 04 24 20 6a 10 f0 	movl   $0xf0106a20,(%esp)
f010403c:	e8 1f fc ff ff       	call   f0103c60 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0104041:	8b 43 08             	mov    0x8(%ebx),%eax
f0104044:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104048:	c7 04 24 2f 6a 10 f0 	movl   $0xf0106a2f,(%esp)
f010404f:	e8 0c fc ff ff       	call   f0103c60 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0104054:	8b 43 0c             	mov    0xc(%ebx),%eax
f0104057:	89 44 24 04          	mov    %eax,0x4(%esp)
f010405b:	c7 04 24 3e 6a 10 f0 	movl   $0xf0106a3e,(%esp)
f0104062:	e8 f9 fb ff ff       	call   f0103c60 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0104067:	8b 43 10             	mov    0x10(%ebx),%eax
f010406a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010406e:	c7 04 24 4d 6a 10 f0 	movl   $0xf0106a4d,(%esp)
f0104075:	e8 e6 fb ff ff       	call   f0103c60 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f010407a:	8b 43 14             	mov    0x14(%ebx),%eax
f010407d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104081:	c7 04 24 5c 6a 10 f0 	movl   $0xf0106a5c,(%esp)
f0104088:	e8 d3 fb ff ff       	call   f0103c60 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f010408d:	8b 43 18             	mov    0x18(%ebx),%eax
f0104090:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104094:	c7 04 24 6b 6a 10 f0 	movl   $0xf0106a6b,(%esp)
f010409b:	e8 c0 fb ff ff       	call   f0103c60 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01040a0:	8b 43 1c             	mov    0x1c(%ebx),%eax
f01040a3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040a7:	c7 04 24 7a 6a 10 f0 	movl   $0xf0106a7a,(%esp)
f01040ae:	e8 ad fb ff ff       	call   f0103c60 <cprintf>
}
f01040b3:	83 c4 14             	add    $0x14,%esp
f01040b6:	5b                   	pop    %ebx
f01040b7:	5d                   	pop    %ebp
f01040b8:	c3                   	ret    

f01040b9 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f01040b9:	55                   	push   %ebp
f01040ba:	89 e5                	mov    %esp,%ebp
f01040bc:	56                   	push   %esi
f01040bd:	53                   	push   %ebx
f01040be:	83 ec 10             	sub    $0x10,%esp
f01040c1:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f01040c4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01040c8:	c7 04 24 b0 6b 10 f0 	movl   $0xf0106bb0,(%esp)
f01040cf:	e8 8c fb ff ff       	call   f0103c60 <cprintf>
	print_regs(&tf->tf_regs);
f01040d4:	89 1c 24             	mov    %ebx,(%esp)
f01040d7:	e8 36 ff ff ff       	call   f0104012 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01040dc:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01040e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040e4:	c7 04 24 cb 6a 10 f0 	movl   $0xf0106acb,(%esp)
f01040eb:	e8 70 fb ff ff       	call   f0103c60 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01040f0:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01040f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040f8:	c7 04 24 de 6a 10 f0 	movl   $0xf0106ade,(%esp)
f01040ff:	e8 5c fb ff ff       	call   f0103c60 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0104104:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0104107:	83 f8 13             	cmp    $0x13,%eax
f010410a:	77 09                	ja     f0104115 <print_trapframe+0x5c>
		return excnames[trapno];
f010410c:	8b 14 85 80 6d 10 f0 	mov    -0xfef9280(,%eax,4),%edx
f0104113:	eb 10                	jmp    f0104125 <print_trapframe+0x6c>
	if (trapno == T_SYSCALL)
		return "System call";
f0104115:	83 f8 30             	cmp    $0x30,%eax
f0104118:	ba 89 6a 10 f0       	mov    $0xf0106a89,%edx
f010411d:	b9 95 6a 10 f0       	mov    $0xf0106a95,%ecx
f0104122:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0104125:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104129:	89 44 24 04          	mov    %eax,0x4(%esp)
f010412d:	c7 04 24 f1 6a 10 f0 	movl   $0xf0106af1,(%esp)
f0104134:	e8 27 fb ff ff       	call   f0103c60 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0104139:	3b 1d 00 fa 17 f0    	cmp    0xf017fa00,%ebx
f010413f:	75 19                	jne    f010415a <print_trapframe+0xa1>
f0104141:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0104145:	75 13                	jne    f010415a <print_trapframe+0xa1>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0104147:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f010414a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010414e:	c7 04 24 03 6b 10 f0 	movl   $0xf0106b03,(%esp)
f0104155:	e8 06 fb ff ff       	call   f0103c60 <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f010415a:	8b 43 2c             	mov    0x2c(%ebx),%eax
f010415d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104161:	c7 04 24 12 6b 10 f0 	movl   $0xf0106b12,(%esp)
f0104168:	e8 f3 fa ff ff       	call   f0103c60 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f010416d:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0104171:	75 51                	jne    f01041c4 <print_trapframe+0x10b>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0104173:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0104176:	89 c2                	mov    %eax,%edx
f0104178:	83 e2 01             	and    $0x1,%edx
f010417b:	ba a4 6a 10 f0       	mov    $0xf0106aa4,%edx
f0104180:	b9 af 6a 10 f0       	mov    $0xf0106aaf,%ecx
f0104185:	0f 45 ca             	cmovne %edx,%ecx
f0104188:	89 c2                	mov    %eax,%edx
f010418a:	83 e2 02             	and    $0x2,%edx
f010418d:	ba bb 6a 10 f0       	mov    $0xf0106abb,%edx
f0104192:	be c1 6a 10 f0       	mov    $0xf0106ac1,%esi
f0104197:	0f 44 d6             	cmove  %esi,%edx
f010419a:	83 e0 04             	and    $0x4,%eax
f010419d:	b8 c6 6a 10 f0       	mov    $0xf0106ac6,%eax
f01041a2:	be db 6b 10 f0       	mov    $0xf0106bdb,%esi
f01041a7:	0f 44 c6             	cmove  %esi,%eax
f01041aa:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01041ae:	89 54 24 08          	mov    %edx,0x8(%esp)
f01041b2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01041b6:	c7 04 24 20 6b 10 f0 	movl   $0xf0106b20,(%esp)
f01041bd:	e8 9e fa ff ff       	call   f0103c60 <cprintf>
f01041c2:	eb 0c                	jmp    f01041d0 <print_trapframe+0x117>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f01041c4:	c7 04 24 c3 57 10 f0 	movl   $0xf01057c3,(%esp)
f01041cb:	e8 90 fa ff ff       	call   f0103c60 <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01041d0:	8b 43 30             	mov    0x30(%ebx),%eax
f01041d3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01041d7:	c7 04 24 2f 6b 10 f0 	movl   $0xf0106b2f,(%esp)
f01041de:	e8 7d fa ff ff       	call   f0103c60 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01041e3:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f01041e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01041eb:	c7 04 24 3e 6b 10 f0 	movl   $0xf0106b3e,(%esp)
f01041f2:	e8 69 fa ff ff       	call   f0103c60 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01041f7:	8b 43 38             	mov    0x38(%ebx),%eax
f01041fa:	89 44 24 04          	mov    %eax,0x4(%esp)
f01041fe:	c7 04 24 51 6b 10 f0 	movl   $0xf0106b51,(%esp)
f0104205:	e8 56 fa ff ff       	call   f0103c60 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010420a:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010420e:	74 27                	je     f0104237 <print_trapframe+0x17e>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0104210:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0104213:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104217:	c7 04 24 60 6b 10 f0 	movl   $0xf0106b60,(%esp)
f010421e:	e8 3d fa ff ff       	call   f0103c60 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0104223:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0104227:	89 44 24 04          	mov    %eax,0x4(%esp)
f010422b:	c7 04 24 6f 6b 10 f0 	movl   $0xf0106b6f,(%esp)
f0104232:	e8 29 fa ff ff       	call   f0103c60 <cprintf>
	}
}
f0104237:	83 c4 10             	add    $0x10,%esp
f010423a:	5b                   	pop    %ebx
f010423b:	5e                   	pop    %esi
f010423c:	5d                   	pop    %ebp
f010423d:	c3                   	ret    

f010423e <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f010423e:	55                   	push   %ebp
f010423f:	89 e5                	mov    %esp,%ebp
f0104241:	57                   	push   %edi
f0104242:	56                   	push   %esi
f0104243:	83 ec 10             	sub    $0x10,%esp
f0104246:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0104249:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f010424a:	9c                   	pushf  
f010424b:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f010424c:	f6 c4 02             	test   $0x2,%ah
f010424f:	74 24                	je     f0104275 <trap+0x37>
f0104251:	c7 44 24 0c 82 6b 10 	movl   $0xf0106b82,0xc(%esp)
f0104258:	f0 
f0104259:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f0104260:	f0 
f0104261:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
f0104268:	00 
f0104269:	c7 04 24 9b 6b 10 f0 	movl   $0xf0106b9b,(%esp)
f0104270:	e8 41 be ff ff       	call   f01000b6 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0104275:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104279:	c7 04 24 a7 6b 10 f0 	movl   $0xf0106ba7,(%esp)
f0104280:	e8 db f9 ff ff       	call   f0103c60 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0104285:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104289:	83 e0 03             	and    $0x3,%eax
f010428c:	66 83 f8 03          	cmp    $0x3,%ax
f0104290:	75 3c                	jne    f01042ce <trap+0x90>
		// Trapped from user mode.
		assert(curenv);
f0104292:	a1 e4 f1 17 f0       	mov    0xf017f1e4,%eax
f0104297:	85 c0                	test   %eax,%eax
f0104299:	75 24                	jne    f01042bf <trap+0x81>
f010429b:	c7 44 24 0c c2 6b 10 	movl   $0xf0106bc2,0xc(%esp)
f01042a2:	f0 
f01042a3:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f01042aa:	f0 
f01042ab:	c7 44 24 04 d6 00 00 	movl   $0xd6,0x4(%esp)
f01042b2:	00 
f01042b3:	c7 04 24 9b 6b 10 f0 	movl   $0xf0106b9b,(%esp)
f01042ba:	e8 f7 bd ff ff       	call   f01000b6 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01042bf:	b9 11 00 00 00       	mov    $0x11,%ecx
f01042c4:	89 c7                	mov    %eax,%edi
f01042c6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01042c8:	8b 35 e4 f1 17 f0    	mov    0xf017f1e4,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01042ce:	89 35 00 fa 17 f0    	mov    %esi,0xf017fa00
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f01042d4:	89 34 24             	mov    %esi,(%esp)
f01042d7:	e8 dd fd ff ff       	call   f01040b9 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01042dc:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01042e1:	75 1c                	jne    f01042ff <trap+0xc1>
		panic("unhandled trap in kernel");
f01042e3:	c7 44 24 08 c9 6b 10 	movl   $0xf0106bc9,0x8(%esp)
f01042ea:	f0 
f01042eb:	c7 44 24 04 bf 00 00 	movl   $0xbf,0x4(%esp)
f01042f2:	00 
f01042f3:	c7 04 24 9b 6b 10 f0 	movl   $0xf0106b9b,(%esp)
f01042fa:	e8 b7 bd ff ff       	call   f01000b6 <_panic>
	else {
		env_destroy(curenv);
f01042ff:	a1 e4 f1 17 f0       	mov    0xf017f1e4,%eax
f0104304:	89 04 24             	mov    %eax,(%esp)
f0104307:	e8 21 f8 ff ff       	call   f0103b2d <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f010430c:	a1 e4 f1 17 f0       	mov    0xf017f1e4,%eax
f0104311:	85 c0                	test   %eax,%eax
f0104313:	74 06                	je     f010431b <trap+0xdd>
f0104315:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104319:	74 24                	je     f010433f <trap+0x101>
f010431b:	c7 44 24 0c 28 6d 10 	movl   $0xf0106d28,0xc(%esp)
f0104322:	f0 
f0104323:	c7 44 24 08 53 66 10 	movl   $0xf0106653,0x8(%esp)
f010432a:	f0 
f010432b:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
f0104332:	00 
f0104333:	c7 04 24 9b 6b 10 f0 	movl   $0xf0106b9b,(%esp)
f010433a:	e8 77 bd ff ff       	call   f01000b6 <_panic>
	env_run(curenv);
f010433f:	89 04 24             	mov    %eax,(%esp)
f0104342:	e8 3d f8 ff ff       	call   f0103b84 <env_run>

f0104347 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0104347:	55                   	push   %ebp
f0104348:	89 e5                	mov    %esp,%ebp
f010434a:	53                   	push   %ebx
f010434b:	83 ec 14             	sub    $0x14,%esp
f010434e:	8b 5d 08             	mov    0x8(%ebp),%ebx

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0104351:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104354:	8b 53 30             	mov    0x30(%ebx),%edx
f0104357:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010435b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010435f:	a1 e4 f1 17 f0       	mov    0xf017f1e4,%eax
f0104364:	8b 40 48             	mov    0x48(%eax),%eax
f0104367:	89 44 24 04          	mov    %eax,0x4(%esp)
f010436b:	c7 04 24 54 6d 10 f0 	movl   $0xf0106d54,(%esp)
f0104372:	e8 e9 f8 ff ff       	call   f0103c60 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0104377:	89 1c 24             	mov    %ebx,(%esp)
f010437a:	e8 3a fd ff ff       	call   f01040b9 <print_trapframe>
	env_destroy(curenv);
f010437f:	a1 e4 f1 17 f0       	mov    0xf017f1e4,%eax
f0104384:	89 04 24             	mov    %eax,(%esp)
f0104387:	e8 a1 f7 ff ff       	call   f0103b2d <env_destroy>
}
f010438c:	83 c4 14             	add    $0x14,%esp
f010438f:	5b                   	pop    %ebx
f0104390:	5d                   	pop    %ebp
f0104391:	c3                   	ret    

f0104392 <t_divide>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(t_divide, T_DIVIDE);
f0104392:	6a 00                	push   $0x0
f0104394:	6a 00                	push   $0x0
f0104396:	eb 5e                	jmp    f01043f6 <_alltraps>

f0104398 <t_debug>:
TRAPHANDLER_NOEC(t_debug, T_DEBUG);
f0104398:	6a 00                	push   $0x0
f010439a:	6a 01                	push   $0x1
f010439c:	eb 58                	jmp    f01043f6 <_alltraps>

f010439e <t_nmi>:
TRAPHANDLER_NOEC(t_nmi, T_NMI);
f010439e:	6a 00                	push   $0x0
f01043a0:	6a 02                	push   $0x2
f01043a2:	eb 52                	jmp    f01043f6 <_alltraps>

f01043a4 <t_brkpt>:
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT);
f01043a4:	6a 00                	push   $0x0
f01043a6:	6a 03                	push   $0x3
f01043a8:	eb 4c                	jmp    f01043f6 <_alltraps>

f01043aa <t_oflow>:
TRAPHANDLER_NOEC(t_oflow, T_OFLOW);
f01043aa:	6a 00                	push   $0x0
f01043ac:	6a 04                	push   $0x4
f01043ae:	eb 46                	jmp    f01043f6 <_alltraps>

f01043b0 <t_bound>:
TRAPHANDLER_NOEC(t_bound, T_BOUND);
f01043b0:	6a 00                	push   $0x0
f01043b2:	6a 05                	push   $0x5
f01043b4:	eb 40                	jmp    f01043f6 <_alltraps>

f01043b6 <t_illop>:
TRAPHANDLER_NOEC(t_illop, T_ILLOP);
f01043b6:	6a 00                	push   $0x0
f01043b8:	6a 06                	push   $0x6
f01043ba:	eb 3a                	jmp    f01043f6 <_alltraps>

f01043bc <t_device>:
TRAPHANDLER_NOEC(t_device, T_DEVICE);
f01043bc:	6a 00                	push   $0x0
f01043be:	6a 07                	push   $0x7
f01043c0:	eb 34                	jmp    f01043f6 <_alltraps>

f01043c2 <t_dblflt>:
TRAPHANDLER(t_dblflt, T_DBLFLT);
f01043c2:	6a 08                	push   $0x8
f01043c4:	eb 30                	jmp    f01043f6 <_alltraps>

f01043c6 <t_tss>:
TRAPHANDLER(t_tss, T_TSS);
f01043c6:	6a 0a                	push   $0xa
f01043c8:	eb 2c                	jmp    f01043f6 <_alltraps>

f01043ca <t_segnp>:
TRAPHANDLER(t_segnp, T_SEGNP);
f01043ca:	6a 0b                	push   $0xb
f01043cc:	eb 28                	jmp    f01043f6 <_alltraps>

f01043ce <t_stack>:
TRAPHANDLER(t_stack, T_STACK);
f01043ce:	6a 0c                	push   $0xc
f01043d0:	eb 24                	jmp    f01043f6 <_alltraps>

f01043d2 <t_gpflt>:
TRAPHANDLER(t_gpflt, T_GPFLT);
f01043d2:	6a 0d                	push   $0xd
f01043d4:	eb 20                	jmp    f01043f6 <_alltraps>

f01043d6 <t_pgflt>:
TRAPHANDLER(t_pgflt, T_PGFLT);
f01043d6:	6a 0e                	push   $0xe
f01043d8:	eb 1c                	jmp    f01043f6 <_alltraps>

f01043da <t_fperr>:
TRAPHANDLER_NOEC(t_fperr, T_FPERR);
f01043da:	6a 00                	push   $0x0
f01043dc:	6a 10                	push   $0x10
f01043de:	eb 16                	jmp    f01043f6 <_alltraps>

f01043e0 <t_align>:
TRAPHANDLER(t_align, T_ALIGN);
f01043e0:	6a 11                	push   $0x11
f01043e2:	eb 12                	jmp    f01043f6 <_alltraps>

f01043e4 <t_mchk>:
TRAPHANDLER_NOEC(t_mchk, T_MCHK);
f01043e4:	6a 00                	push   $0x0
f01043e6:	6a 12                	push   $0x12
f01043e8:	eb 0c                	jmp    f01043f6 <_alltraps>

f01043ea <t_simderr>:
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR);
f01043ea:	6a 00                	push   $0x0
f01043ec:	6a 13                	push   $0x13
f01043ee:	eb 06                	jmp    f01043f6 <_alltraps>

f01043f0 <t_syscall>:
TRAPHANDLER_NOEC(t_syscall, T_SYSCALL);
f01043f0:	6a 00                	push   $0x0
f01043f2:	6a 30                	push   $0x30
f01043f4:	eb 00                	jmp    f01043f6 <_alltraps>

f01043f6 <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds 
f01043f6:	1e                   	push   %ds
	pushl %es 
f01043f7:	06                   	push   %es
	pushal
f01043f8:	60                   	pusha  

	movw $GD_KD, %ax
f01043f9:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f01043fd:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f01043ff:	8e c0                	mov    %eax,%es
	pushl %esp
f0104401:	54                   	push   %esp
f0104402:	e8 37 fe ff ff       	call   f010423e <trap>

f0104407 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104407:	55                   	push   %ebp
f0104408:	89 e5                	mov    %esp,%ebp
f010440a:	83 ec 18             	sub    $0x18,%esp
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	panic("syscall not implemented");
f010440d:	c7 44 24 08 d0 6d 10 	movl   $0xf0106dd0,0x8(%esp)
f0104414:	f0 
f0104415:	c7 44 24 04 49 00 00 	movl   $0x49,0x4(%esp)
f010441c:	00 
f010441d:	c7 04 24 e8 6d 10 f0 	movl   $0xf0106de8,(%esp)
f0104424:	e8 8d bc ff ff       	call   f01000b6 <_panic>

f0104429 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104429:	55                   	push   %ebp
f010442a:	89 e5                	mov    %esp,%ebp
f010442c:	57                   	push   %edi
f010442d:	56                   	push   %esi
f010442e:	53                   	push   %ebx
f010442f:	83 ec 14             	sub    $0x14,%esp
f0104432:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104435:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104438:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010443b:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f010443e:	8b 1a                	mov    (%edx),%ebx
f0104440:	8b 01                	mov    (%ecx),%eax
f0104442:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104445:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010444c:	e9 88 00 00 00       	jmp    f01044d9 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0104451:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104454:	01 d8                	add    %ebx,%eax
f0104456:	89 c7                	mov    %eax,%edi
f0104458:	c1 ef 1f             	shr    $0x1f,%edi
f010445b:	01 c7                	add    %eax,%edi
f010445d:	d1 ff                	sar    %edi
f010445f:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0104462:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104465:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104468:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010446a:	eb 03                	jmp    f010446f <stab_binsearch+0x46>
			m--;
f010446c:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010446f:	39 c3                	cmp    %eax,%ebx
f0104471:	7f 1f                	jg     f0104492 <stab_binsearch+0x69>
f0104473:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104477:	83 ea 0c             	sub    $0xc,%edx
f010447a:	39 f1                	cmp    %esi,%ecx
f010447c:	75 ee                	jne    f010446c <stab_binsearch+0x43>
f010447e:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104481:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104484:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104487:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010448b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010448e:	76 18                	jbe    f01044a8 <stab_binsearch+0x7f>
f0104490:	eb 05                	jmp    f0104497 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104492:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0104495:	eb 42                	jmp    f01044d9 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0104497:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010449a:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010449c:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010449f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01044a6:	eb 31                	jmp    f01044d9 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01044a8:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01044ab:	73 17                	jae    f01044c4 <stab_binsearch+0x9b>
			*region_right = m - 1;
f01044ad:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01044b0:	83 e8 01             	sub    $0x1,%eax
f01044b3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01044b6:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01044b9:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01044bb:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01044c2:	eb 15                	jmp    f01044d9 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01044c4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01044c7:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01044ca:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f01044cc:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01044d0:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01044d2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01044d9:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01044dc:	0f 8e 6f ff ff ff    	jle    f0104451 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01044e2:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01044e6:	75 0f                	jne    f01044f7 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f01044e8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01044eb:	8b 00                	mov    (%eax),%eax
f01044ed:	83 e8 01             	sub    $0x1,%eax
f01044f0:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01044f3:	89 07                	mov    %eax,(%edi)
f01044f5:	eb 2c                	jmp    f0104523 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01044f7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01044fa:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01044fc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01044ff:	8b 0f                	mov    (%edi),%ecx
f0104501:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104504:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0104507:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010450a:	eb 03                	jmp    f010450f <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010450c:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010450f:	39 c8                	cmp    %ecx,%eax
f0104511:	7e 0b                	jle    f010451e <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0104513:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104517:	83 ea 0c             	sub    $0xc,%edx
f010451a:	39 f3                	cmp    %esi,%ebx
f010451c:	75 ee                	jne    f010450c <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f010451e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104521:	89 07                	mov    %eax,(%edi)
	}
}
f0104523:	83 c4 14             	add    $0x14,%esp
f0104526:	5b                   	pop    %ebx
f0104527:	5e                   	pop    %esi
f0104528:	5f                   	pop    %edi
f0104529:	5d                   	pop    %ebp
f010452a:	c3                   	ret    

f010452b <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010452b:	55                   	push   %ebp
f010452c:	89 e5                	mov    %esp,%ebp
f010452e:	57                   	push   %edi
f010452f:	56                   	push   %esi
f0104530:	53                   	push   %ebx
f0104531:	83 ec 4c             	sub    $0x4c,%esp
f0104534:	8b 75 08             	mov    0x8(%ebp),%esi
f0104537:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010453a:	c7 03 f7 6d 10 f0    	movl   $0xf0106df7,(%ebx)
	info->eip_line = 0;
f0104540:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0104547:	c7 43 08 f7 6d 10 f0 	movl   $0xf0106df7,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010454e:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0104555:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0104558:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010455f:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0104565:	77 21                	ja     f0104588 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0104567:	a1 00 00 20 00       	mov    0x200000,%eax
f010456c:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f010456f:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0104574:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f010457a:	89 7d c0             	mov    %edi,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f010457d:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f0104583:	89 7d bc             	mov    %edi,-0x44(%ebp)
f0104586:	eb 1a                	jmp    f01045a2 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104588:	c7 45 bc 2e 20 11 f0 	movl   $0xf011202e,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010458f:	c7 45 c0 95 f4 10 f0 	movl   $0xf010f495,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104596:	b8 94 f4 10 f0       	mov    $0xf010f494,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f010459b:	c7 45 c4 10 70 10 f0 	movl   $0xf0107010,-0x3c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01045a2:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01045a5:	39 7d c0             	cmp    %edi,-0x40(%ebp)
f01045a8:	0f 83 9d 01 00 00    	jae    f010474b <debuginfo_eip+0x220>
f01045ae:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f01045b2:	0f 85 9a 01 00 00    	jne    f0104752 <debuginfo_eip+0x227>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01045b8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01045bf:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01045c2:	29 f8                	sub    %edi,%eax
f01045c4:	c1 f8 02             	sar    $0x2,%eax
f01045c7:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01045cd:	83 e8 01             	sub    $0x1,%eax
f01045d0:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01045d3:	89 74 24 04          	mov    %esi,0x4(%esp)
f01045d7:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01045de:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01045e1:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01045e4:	89 f8                	mov    %edi,%eax
f01045e6:	e8 3e fe ff ff       	call   f0104429 <stab_binsearch>
	if (lfile == 0)
f01045eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01045ee:	85 c0                	test   %eax,%eax
f01045f0:	0f 84 63 01 00 00    	je     f0104759 <debuginfo_eip+0x22e>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01045f6:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01045f9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01045fc:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01045ff:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104603:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f010460a:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010460d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104610:	89 f8                	mov    %edi,%eax
f0104612:	e8 12 fe ff ff       	call   f0104429 <stab_binsearch>

	if (lfun <= rfun) {
f0104617:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010461a:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f010461d:	39 c8                	cmp    %ecx,%eax
f010461f:	7f 32                	jg     f0104653 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104621:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104624:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104627:	8d 3c 97             	lea    (%edi,%edx,4),%edi
f010462a:	8b 17                	mov    (%edi),%edx
f010462c:	89 55 b8             	mov    %edx,-0x48(%ebp)
f010462f:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104632:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104635:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f0104638:	73 09                	jae    f0104643 <debuginfo_eip+0x118>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010463a:	8b 55 b8             	mov    -0x48(%ebp),%edx
f010463d:	03 55 c0             	add    -0x40(%ebp),%edx
f0104640:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104643:	8b 57 08             	mov    0x8(%edi),%edx
f0104646:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0104649:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f010464b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010464e:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0104651:	eb 0f                	jmp    f0104662 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104653:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0104656:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104659:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010465c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010465f:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104662:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0104669:	00 
f010466a:	8b 43 08             	mov    0x8(%ebx),%eax
f010466d:	89 04 24             	mov    %eax,(%esp)
f0104670:	e8 16 09 00 00       	call   f0104f8b <strfind>
f0104675:	2b 43 08             	sub    0x8(%ebx),%eax
f0104678:	89 43 0c             	mov    %eax,0xc(%ebx)
	//
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f010467b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010467f:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0104686:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104689:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010468c:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010468f:	89 f8                	mov    %edi,%eax
f0104691:	e8 93 fd ff ff       	call   f0104429 <stab_binsearch>
	
	if(lline <= rline){
f0104696:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104699:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f010469c:	0f 8f be 00 00 00    	jg     f0104760 <debuginfo_eip+0x235>
		info->eip_line = stabs[lline].n_desc;
f01046a2:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01046a5:	0f b7 44 87 06       	movzwl 0x6(%edi,%eax,4),%eax
f01046aa:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01046ad:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01046b0:	89 c6                	mov    %eax,%esi
f01046b2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01046b5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01046b8:	8d 14 97             	lea    (%edi,%edx,4),%edx
f01046bb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01046be:	eb 06                	jmp    f01046c6 <debuginfo_eip+0x19b>
f01046c0:	83 e8 01             	sub    $0x1,%eax
f01046c3:	83 ea 0c             	sub    $0xc,%edx
f01046c6:	89 c7                	mov    %eax,%edi
f01046c8:	39 c6                	cmp    %eax,%esi
f01046ca:	7f 3c                	jg     f0104708 <debuginfo_eip+0x1dd>
	       && stabs[lline].n_type != N_SOL
f01046cc:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01046d0:	80 f9 84             	cmp    $0x84,%cl
f01046d3:	75 08                	jne    f01046dd <debuginfo_eip+0x1b2>
f01046d5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01046d8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01046db:	eb 11                	jmp    f01046ee <debuginfo_eip+0x1c3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01046dd:	80 f9 64             	cmp    $0x64,%cl
f01046e0:	75 de                	jne    f01046c0 <debuginfo_eip+0x195>
f01046e2:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f01046e6:	74 d8                	je     f01046c0 <debuginfo_eip+0x195>
f01046e8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01046eb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01046ee:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01046f1:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01046f4:	8b 04 86             	mov    (%esi,%eax,4),%eax
f01046f7:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01046fa:	2b 55 c0             	sub    -0x40(%ebp),%edx
f01046fd:	39 d0                	cmp    %edx,%eax
f01046ff:	73 0a                	jae    f010470b <debuginfo_eip+0x1e0>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104701:	03 45 c0             	add    -0x40(%ebp),%eax
f0104704:	89 03                	mov    %eax,(%ebx)
f0104706:	eb 03                	jmp    f010470b <debuginfo_eip+0x1e0>
f0104708:	8b 5d 0c             	mov    0xc(%ebp),%ebx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010470b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010470e:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104711:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104716:	39 f2                	cmp    %esi,%edx
f0104718:	7d 52                	jge    f010476c <debuginfo_eip+0x241>
		for (lline = lfun + 1;
f010471a:	83 c2 01             	add    $0x1,%edx
f010471d:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104720:	89 d0                	mov    %edx,%eax
f0104722:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104725:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104728:	8d 14 97             	lea    (%edi,%edx,4),%edx
f010472b:	eb 04                	jmp    f0104731 <debuginfo_eip+0x206>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010472d:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104731:	39 c6                	cmp    %eax,%esi
f0104733:	7e 32                	jle    f0104767 <debuginfo_eip+0x23c>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104735:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104739:	83 c0 01             	add    $0x1,%eax
f010473c:	83 c2 0c             	add    $0xc,%edx
f010473f:	80 f9 a0             	cmp    $0xa0,%cl
f0104742:	74 e9                	je     f010472d <debuginfo_eip+0x202>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104744:	b8 00 00 00 00       	mov    $0x0,%eax
f0104749:	eb 21                	jmp    f010476c <debuginfo_eip+0x241>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010474b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104750:	eb 1a                	jmp    f010476c <debuginfo_eip+0x241>
f0104752:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104757:	eb 13                	jmp    f010476c <debuginfo_eip+0x241>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104759:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010475e:	eb 0c                	jmp    f010476c <debuginfo_eip+0x241>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	
	if(lline <= rline){
		info->eip_line = stabs[lline].n_desc;
	}else{
		return -1;
f0104760:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104765:	eb 05                	jmp    f010476c <debuginfo_eip+0x241>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104767:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010476c:	83 c4 4c             	add    $0x4c,%esp
f010476f:	5b                   	pop    %ebx
f0104770:	5e                   	pop    %esi
f0104771:	5f                   	pop    %edi
f0104772:	5d                   	pop    %ebp
f0104773:	c3                   	ret    
f0104774:	66 90                	xchg   %ax,%ax
f0104776:	66 90                	xchg   %ax,%ax
f0104778:	66 90                	xchg   %ax,%ax
f010477a:	66 90                	xchg   %ax,%ax
f010477c:	66 90                	xchg   %ax,%ax
f010477e:	66 90                	xchg   %ax,%ax

f0104780 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104780:	55                   	push   %ebp
f0104781:	89 e5                	mov    %esp,%ebp
f0104783:	57                   	push   %edi
f0104784:	56                   	push   %esi
f0104785:	53                   	push   %ebx
f0104786:	83 ec 3c             	sub    $0x3c,%esp
f0104789:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010478c:	89 d7                	mov    %edx,%edi
f010478e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104791:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104794:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104797:	89 c3                	mov    %eax,%ebx
f0104799:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010479c:	8b 45 10             	mov    0x10(%ebp),%eax
f010479f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01047a2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01047a7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01047aa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01047ad:	39 d9                	cmp    %ebx,%ecx
f01047af:	72 05                	jb     f01047b6 <printnum+0x36>
f01047b1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01047b4:	77 69                	ja     f010481f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01047b6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01047b9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01047bd:	83 ee 01             	sub    $0x1,%esi
f01047c0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01047c4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01047c8:	8b 44 24 08          	mov    0x8(%esp),%eax
f01047cc:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01047d0:	89 c3                	mov    %eax,%ebx
f01047d2:	89 d6                	mov    %edx,%esi
f01047d4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01047d7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01047da:	89 54 24 08          	mov    %edx,0x8(%esp)
f01047de:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01047e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01047e5:	89 04 24             	mov    %eax,(%esp)
f01047e8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01047eb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01047ef:	e8 bc 09 00 00       	call   f01051b0 <__udivdi3>
f01047f4:	89 d9                	mov    %ebx,%ecx
f01047f6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01047fa:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01047fe:	89 04 24             	mov    %eax,(%esp)
f0104801:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104805:	89 fa                	mov    %edi,%edx
f0104807:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010480a:	e8 71 ff ff ff       	call   f0104780 <printnum>
f010480f:	eb 1b                	jmp    f010482c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104811:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104815:	8b 45 18             	mov    0x18(%ebp),%eax
f0104818:	89 04 24             	mov    %eax,(%esp)
f010481b:	ff d3                	call   *%ebx
f010481d:	eb 03                	jmp    f0104822 <printnum+0xa2>
f010481f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104822:	83 ee 01             	sub    $0x1,%esi
f0104825:	85 f6                	test   %esi,%esi
f0104827:	7f e8                	jg     f0104811 <printnum+0x91>
f0104829:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010482c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104830:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104834:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104837:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010483a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010483e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104842:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104845:	89 04 24             	mov    %eax,(%esp)
f0104848:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010484b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010484f:	e8 8c 0a 00 00       	call   f01052e0 <__umoddi3>
f0104854:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104858:	0f be 80 01 6e 10 f0 	movsbl -0xfef91ff(%eax),%eax
f010485f:	89 04 24             	mov    %eax,(%esp)
f0104862:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104865:	ff d0                	call   *%eax
}
f0104867:	83 c4 3c             	add    $0x3c,%esp
f010486a:	5b                   	pop    %ebx
f010486b:	5e                   	pop    %esi
f010486c:	5f                   	pop    %edi
f010486d:	5d                   	pop    %ebp
f010486e:	c3                   	ret    

f010486f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010486f:	55                   	push   %ebp
f0104870:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104872:	83 fa 01             	cmp    $0x1,%edx
f0104875:	7e 0e                	jle    f0104885 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104877:	8b 10                	mov    (%eax),%edx
f0104879:	8d 4a 08             	lea    0x8(%edx),%ecx
f010487c:	89 08                	mov    %ecx,(%eax)
f010487e:	8b 02                	mov    (%edx),%eax
f0104880:	8b 52 04             	mov    0x4(%edx),%edx
f0104883:	eb 22                	jmp    f01048a7 <getuint+0x38>
	else if (lflag)
f0104885:	85 d2                	test   %edx,%edx
f0104887:	74 10                	je     f0104899 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104889:	8b 10                	mov    (%eax),%edx
f010488b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010488e:	89 08                	mov    %ecx,(%eax)
f0104890:	8b 02                	mov    (%edx),%eax
f0104892:	ba 00 00 00 00       	mov    $0x0,%edx
f0104897:	eb 0e                	jmp    f01048a7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104899:	8b 10                	mov    (%eax),%edx
f010489b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010489e:	89 08                	mov    %ecx,(%eax)
f01048a0:	8b 02                	mov    (%edx),%eax
f01048a2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01048a7:	5d                   	pop    %ebp
f01048a8:	c3                   	ret    

f01048a9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01048a9:	55                   	push   %ebp
f01048aa:	89 e5                	mov    %esp,%ebp
f01048ac:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01048af:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01048b3:	8b 10                	mov    (%eax),%edx
f01048b5:	3b 50 04             	cmp    0x4(%eax),%edx
f01048b8:	73 0a                	jae    f01048c4 <sprintputch+0x1b>
		*b->buf++ = ch;
f01048ba:	8d 4a 01             	lea    0x1(%edx),%ecx
f01048bd:	89 08                	mov    %ecx,(%eax)
f01048bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01048c2:	88 02                	mov    %al,(%edx)
}
f01048c4:	5d                   	pop    %ebp
f01048c5:	c3                   	ret    

f01048c6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01048c6:	55                   	push   %ebp
f01048c7:	89 e5                	mov    %esp,%ebp
f01048c9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01048cc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01048cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01048d3:	8b 45 10             	mov    0x10(%ebp),%eax
f01048d6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01048da:	8b 45 0c             	mov    0xc(%ebp),%eax
f01048dd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01048e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01048e4:	89 04 24             	mov    %eax,(%esp)
f01048e7:	e8 02 00 00 00       	call   f01048ee <vprintfmt>
	va_end(ap);
}
f01048ec:	c9                   	leave  
f01048ed:	c3                   	ret    

f01048ee <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01048ee:	55                   	push   %ebp
f01048ef:	89 e5                	mov    %esp,%ebp
f01048f1:	57                   	push   %edi
f01048f2:	56                   	push   %esi
f01048f3:	53                   	push   %ebx
f01048f4:	83 ec 3c             	sub    $0x3c,%esp
f01048f7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01048fa:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01048fd:	eb 14                	jmp    f0104913 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01048ff:	85 c0                	test   %eax,%eax
f0104901:	0f 84 b3 03 00 00    	je     f0104cba <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0104907:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010490b:	89 04 24             	mov    %eax,(%esp)
f010490e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104911:	89 f3                	mov    %esi,%ebx
f0104913:	8d 73 01             	lea    0x1(%ebx),%esi
f0104916:	0f b6 03             	movzbl (%ebx),%eax
f0104919:	83 f8 25             	cmp    $0x25,%eax
f010491c:	75 e1                	jne    f01048ff <vprintfmt+0x11>
f010491e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0104922:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0104929:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0104930:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0104937:	ba 00 00 00 00       	mov    $0x0,%edx
f010493c:	eb 1d                	jmp    f010495b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010493e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104940:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0104944:	eb 15                	jmp    f010495b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104946:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104948:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010494c:	eb 0d                	jmp    f010495b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010494e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104951:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104954:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010495b:	8d 5e 01             	lea    0x1(%esi),%ebx
f010495e:	0f b6 0e             	movzbl (%esi),%ecx
f0104961:	0f b6 c1             	movzbl %cl,%eax
f0104964:	83 e9 23             	sub    $0x23,%ecx
f0104967:	80 f9 55             	cmp    $0x55,%cl
f010496a:	0f 87 2a 03 00 00    	ja     f0104c9a <vprintfmt+0x3ac>
f0104970:	0f b6 c9             	movzbl %cl,%ecx
f0104973:	ff 24 8d 8c 6e 10 f0 	jmp    *-0xfef9174(,%ecx,4)
f010497a:	89 de                	mov    %ebx,%esi
f010497c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104981:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0104984:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0104988:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010498b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010498e:	83 fb 09             	cmp    $0x9,%ebx
f0104991:	77 36                	ja     f01049c9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104993:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104996:	eb e9                	jmp    f0104981 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104998:	8b 45 14             	mov    0x14(%ebp),%eax
f010499b:	8d 48 04             	lea    0x4(%eax),%ecx
f010499e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01049a1:	8b 00                	mov    (%eax),%eax
f01049a3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01049a6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01049a8:	eb 22                	jmp    f01049cc <vprintfmt+0xde>
f01049aa:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01049ad:	85 c9                	test   %ecx,%ecx
f01049af:	b8 00 00 00 00       	mov    $0x0,%eax
f01049b4:	0f 49 c1             	cmovns %ecx,%eax
f01049b7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01049ba:	89 de                	mov    %ebx,%esi
f01049bc:	eb 9d                	jmp    f010495b <vprintfmt+0x6d>
f01049be:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01049c0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f01049c7:	eb 92                	jmp    f010495b <vprintfmt+0x6d>
f01049c9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f01049cc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01049d0:	79 89                	jns    f010495b <vprintfmt+0x6d>
f01049d2:	e9 77 ff ff ff       	jmp    f010494e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01049d7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01049da:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01049dc:	e9 7a ff ff ff       	jmp    f010495b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01049e1:	8b 45 14             	mov    0x14(%ebp),%eax
f01049e4:	8d 50 04             	lea    0x4(%eax),%edx
f01049e7:	89 55 14             	mov    %edx,0x14(%ebp)
f01049ea:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01049ee:	8b 00                	mov    (%eax),%eax
f01049f0:	89 04 24             	mov    %eax,(%esp)
f01049f3:	ff 55 08             	call   *0x8(%ebp)
			break;
f01049f6:	e9 18 ff ff ff       	jmp    f0104913 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01049fb:	8b 45 14             	mov    0x14(%ebp),%eax
f01049fe:	8d 50 04             	lea    0x4(%eax),%edx
f0104a01:	89 55 14             	mov    %edx,0x14(%ebp)
f0104a04:	8b 00                	mov    (%eax),%eax
f0104a06:	99                   	cltd   
f0104a07:	31 d0                	xor    %edx,%eax
f0104a09:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104a0b:	83 f8 06             	cmp    $0x6,%eax
f0104a0e:	7f 0b                	jg     f0104a1b <vprintfmt+0x12d>
f0104a10:	8b 14 85 e4 6f 10 f0 	mov    -0xfef901c(,%eax,4),%edx
f0104a17:	85 d2                	test   %edx,%edx
f0104a19:	75 20                	jne    f0104a3b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f0104a1b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104a1f:	c7 44 24 08 19 6e 10 	movl   $0xf0106e19,0x8(%esp)
f0104a26:	f0 
f0104a27:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104a2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a2e:	89 04 24             	mov    %eax,(%esp)
f0104a31:	e8 90 fe ff ff       	call   f01048c6 <printfmt>
f0104a36:	e9 d8 fe ff ff       	jmp    f0104913 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0104a3b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104a3f:	c7 44 24 08 65 66 10 	movl   $0xf0106665,0x8(%esp)
f0104a46:	f0 
f0104a47:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104a4b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a4e:	89 04 24             	mov    %eax,(%esp)
f0104a51:	e8 70 fe ff ff       	call   f01048c6 <printfmt>
f0104a56:	e9 b8 fe ff ff       	jmp    f0104913 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104a5b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104a5e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104a61:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104a64:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a67:	8d 50 04             	lea    0x4(%eax),%edx
f0104a6a:	89 55 14             	mov    %edx,0x14(%ebp)
f0104a6d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0104a6f:	85 f6                	test   %esi,%esi
f0104a71:	b8 12 6e 10 f0       	mov    $0xf0106e12,%eax
f0104a76:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0104a79:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0104a7d:	0f 84 97 00 00 00    	je     f0104b1a <vprintfmt+0x22c>
f0104a83:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0104a87:	0f 8e 9b 00 00 00    	jle    f0104b28 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104a8d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104a91:	89 34 24             	mov    %esi,(%esp)
f0104a94:	e8 9f 03 00 00       	call   f0104e38 <strnlen>
f0104a99:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0104a9c:	29 c2                	sub    %eax,%edx
f0104a9e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0104aa1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0104aa5:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104aa8:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0104aab:	8b 75 08             	mov    0x8(%ebp),%esi
f0104aae:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104ab1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104ab3:	eb 0f                	jmp    f0104ac4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0104ab5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104ab9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104abc:	89 04 24             	mov    %eax,(%esp)
f0104abf:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104ac1:	83 eb 01             	sub    $0x1,%ebx
f0104ac4:	85 db                	test   %ebx,%ebx
f0104ac6:	7f ed                	jg     f0104ab5 <vprintfmt+0x1c7>
f0104ac8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0104acb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0104ace:	85 d2                	test   %edx,%edx
f0104ad0:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ad5:	0f 49 c2             	cmovns %edx,%eax
f0104ad8:	29 c2                	sub    %eax,%edx
f0104ada:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0104add:	89 d7                	mov    %edx,%edi
f0104adf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104ae2:	eb 50                	jmp    f0104b34 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104ae4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104ae8:	74 1e                	je     f0104b08 <vprintfmt+0x21a>
f0104aea:	0f be d2             	movsbl %dl,%edx
f0104aed:	83 ea 20             	sub    $0x20,%edx
f0104af0:	83 fa 5e             	cmp    $0x5e,%edx
f0104af3:	76 13                	jbe    f0104b08 <vprintfmt+0x21a>
					putch('?', putdat);
f0104af5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104af8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104afc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0104b03:	ff 55 08             	call   *0x8(%ebp)
f0104b06:	eb 0d                	jmp    f0104b15 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0104b08:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104b0b:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104b0f:	89 04 24             	mov    %eax,(%esp)
f0104b12:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104b15:	83 ef 01             	sub    $0x1,%edi
f0104b18:	eb 1a                	jmp    f0104b34 <vprintfmt+0x246>
f0104b1a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0104b1d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0104b20:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104b23:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104b26:	eb 0c                	jmp    f0104b34 <vprintfmt+0x246>
f0104b28:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0104b2b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0104b2e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104b31:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104b34:	83 c6 01             	add    $0x1,%esi
f0104b37:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0104b3b:	0f be c2             	movsbl %dl,%eax
f0104b3e:	85 c0                	test   %eax,%eax
f0104b40:	74 27                	je     f0104b69 <vprintfmt+0x27b>
f0104b42:	85 db                	test   %ebx,%ebx
f0104b44:	78 9e                	js     f0104ae4 <vprintfmt+0x1f6>
f0104b46:	83 eb 01             	sub    $0x1,%ebx
f0104b49:	79 99                	jns    f0104ae4 <vprintfmt+0x1f6>
f0104b4b:	89 f8                	mov    %edi,%eax
f0104b4d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104b50:	8b 75 08             	mov    0x8(%ebp),%esi
f0104b53:	89 c3                	mov    %eax,%ebx
f0104b55:	eb 1a                	jmp    f0104b71 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104b57:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104b5b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0104b62:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104b64:	83 eb 01             	sub    $0x1,%ebx
f0104b67:	eb 08                	jmp    f0104b71 <vprintfmt+0x283>
f0104b69:	89 fb                	mov    %edi,%ebx
f0104b6b:	8b 75 08             	mov    0x8(%ebp),%esi
f0104b6e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104b71:	85 db                	test   %ebx,%ebx
f0104b73:	7f e2                	jg     f0104b57 <vprintfmt+0x269>
f0104b75:	89 75 08             	mov    %esi,0x8(%ebp)
f0104b78:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0104b7b:	e9 93 fd ff ff       	jmp    f0104913 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104b80:	83 fa 01             	cmp    $0x1,%edx
f0104b83:	7e 16                	jle    f0104b9b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0104b85:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b88:	8d 50 08             	lea    0x8(%eax),%edx
f0104b8b:	89 55 14             	mov    %edx,0x14(%ebp)
f0104b8e:	8b 50 04             	mov    0x4(%eax),%edx
f0104b91:	8b 00                	mov    (%eax),%eax
f0104b93:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104b96:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104b99:	eb 32                	jmp    f0104bcd <vprintfmt+0x2df>
	else if (lflag)
f0104b9b:	85 d2                	test   %edx,%edx
f0104b9d:	74 18                	je     f0104bb7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f0104b9f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ba2:	8d 50 04             	lea    0x4(%eax),%edx
f0104ba5:	89 55 14             	mov    %edx,0x14(%ebp)
f0104ba8:	8b 30                	mov    (%eax),%esi
f0104baa:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0104bad:	89 f0                	mov    %esi,%eax
f0104baf:	c1 f8 1f             	sar    $0x1f,%eax
f0104bb2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104bb5:	eb 16                	jmp    f0104bcd <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0104bb7:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bba:	8d 50 04             	lea    0x4(%eax),%edx
f0104bbd:	89 55 14             	mov    %edx,0x14(%ebp)
f0104bc0:	8b 30                	mov    (%eax),%esi
f0104bc2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0104bc5:	89 f0                	mov    %esi,%eax
f0104bc7:	c1 f8 1f             	sar    $0x1f,%eax
f0104bca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104bcd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104bd0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104bd3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104bd8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104bdc:	0f 89 80 00 00 00    	jns    f0104c62 <vprintfmt+0x374>
				putch('-', putdat);
f0104be2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104be6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0104bed:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0104bf0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104bf3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104bf6:	f7 d8                	neg    %eax
f0104bf8:	83 d2 00             	adc    $0x0,%edx
f0104bfb:	f7 da                	neg    %edx
			}
			base = 10;
f0104bfd:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104c02:	eb 5e                	jmp    f0104c62 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104c04:	8d 45 14             	lea    0x14(%ebp),%eax
f0104c07:	e8 63 fc ff ff       	call   f010486f <getuint>
			base = 10;
f0104c0c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104c11:	eb 4f                	jmp    f0104c62 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0104c13:	8d 45 14             	lea    0x14(%ebp),%eax
f0104c16:	e8 54 fc ff ff       	call   f010486f <getuint>
			base = 8;
f0104c1b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104c20:	eb 40                	jmp    f0104c62 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f0104c22:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104c26:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0104c2d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0104c30:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104c34:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0104c3b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104c3e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c41:	8d 50 04             	lea    0x4(%eax),%edx
f0104c44:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104c47:	8b 00                	mov    (%eax),%eax
f0104c49:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104c4e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104c53:	eb 0d                	jmp    f0104c62 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104c55:	8d 45 14             	lea    0x14(%ebp),%eax
f0104c58:	e8 12 fc ff ff       	call   f010486f <getuint>
			base = 16;
f0104c5d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104c62:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0104c66:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104c6a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0104c6d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104c71:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104c75:	89 04 24             	mov    %eax,(%esp)
f0104c78:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104c7c:	89 fa                	mov    %edi,%edx
f0104c7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c81:	e8 fa fa ff ff       	call   f0104780 <printnum>
			break;
f0104c86:	e9 88 fc ff ff       	jmp    f0104913 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104c8b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104c8f:	89 04 24             	mov    %eax,(%esp)
f0104c92:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104c95:	e9 79 fc ff ff       	jmp    f0104913 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104c9a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104c9e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0104ca5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104ca8:	89 f3                	mov    %esi,%ebx
f0104caa:	eb 03                	jmp    f0104caf <vprintfmt+0x3c1>
f0104cac:	83 eb 01             	sub    $0x1,%ebx
f0104caf:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0104cb3:	75 f7                	jne    f0104cac <vprintfmt+0x3be>
f0104cb5:	e9 59 fc ff ff       	jmp    f0104913 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0104cba:	83 c4 3c             	add    $0x3c,%esp
f0104cbd:	5b                   	pop    %ebx
f0104cbe:	5e                   	pop    %esi
f0104cbf:	5f                   	pop    %edi
f0104cc0:	5d                   	pop    %ebp
f0104cc1:	c3                   	ret    

f0104cc2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104cc2:	55                   	push   %ebp
f0104cc3:	89 e5                	mov    %esp,%ebp
f0104cc5:	83 ec 28             	sub    $0x28,%esp
f0104cc8:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ccb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104cce:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104cd1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104cd5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104cd8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104cdf:	85 c0                	test   %eax,%eax
f0104ce1:	74 30                	je     f0104d13 <vsnprintf+0x51>
f0104ce3:	85 d2                	test   %edx,%edx
f0104ce5:	7e 2c                	jle    f0104d13 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104ce7:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cea:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104cee:	8b 45 10             	mov    0x10(%ebp),%eax
f0104cf1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104cf5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104cf8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104cfc:	c7 04 24 a9 48 10 f0 	movl   $0xf01048a9,(%esp)
f0104d03:	e8 e6 fb ff ff       	call   f01048ee <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104d08:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104d0b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104d0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104d11:	eb 05                	jmp    f0104d18 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104d13:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104d18:	c9                   	leave  
f0104d19:	c3                   	ret    

f0104d1a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104d1a:	55                   	push   %ebp
f0104d1b:	89 e5                	mov    %esp,%ebp
f0104d1d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104d20:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104d23:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104d27:	8b 45 10             	mov    0x10(%ebp),%eax
f0104d2a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104d2e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d31:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104d35:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d38:	89 04 24             	mov    %eax,(%esp)
f0104d3b:	e8 82 ff ff ff       	call   f0104cc2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104d40:	c9                   	leave  
f0104d41:	c3                   	ret    
f0104d42:	66 90                	xchg   %ax,%ax
f0104d44:	66 90                	xchg   %ax,%ax
f0104d46:	66 90                	xchg   %ax,%ax
f0104d48:	66 90                	xchg   %ax,%ax
f0104d4a:	66 90                	xchg   %ax,%ax
f0104d4c:	66 90                	xchg   %ax,%ax
f0104d4e:	66 90                	xchg   %ax,%ax

f0104d50 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104d50:	55                   	push   %ebp
f0104d51:	89 e5                	mov    %esp,%ebp
f0104d53:	57                   	push   %edi
f0104d54:	56                   	push   %esi
f0104d55:	53                   	push   %ebx
f0104d56:	83 ec 1c             	sub    $0x1c,%esp
f0104d59:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104d5c:	85 c0                	test   %eax,%eax
f0104d5e:	74 10                	je     f0104d70 <readline+0x20>
		cprintf("%s", prompt);
f0104d60:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104d64:	c7 04 24 65 66 10 f0 	movl   $0xf0106665,(%esp)
f0104d6b:	e8 f0 ee ff ff       	call   f0103c60 <cprintf>

	i = 0;
	echoing = iscons(0);
f0104d70:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104d77:	e8 c6 b8 ff ff       	call   f0100642 <iscons>
f0104d7c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104d7e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104d83:	e8 a9 b8 ff ff       	call   f0100631 <getchar>
f0104d88:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104d8a:	85 c0                	test   %eax,%eax
f0104d8c:	79 17                	jns    f0104da5 <readline+0x55>
			cprintf("read error: %e\n", c);
f0104d8e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104d92:	c7 04 24 00 70 10 f0 	movl   $0xf0107000,(%esp)
f0104d99:	e8 c2 ee ff ff       	call   f0103c60 <cprintf>
			return NULL;
f0104d9e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104da3:	eb 6d                	jmp    f0104e12 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104da5:	83 f8 7f             	cmp    $0x7f,%eax
f0104da8:	74 05                	je     f0104daf <readline+0x5f>
f0104daa:	83 f8 08             	cmp    $0x8,%eax
f0104dad:	75 19                	jne    f0104dc8 <readline+0x78>
f0104daf:	85 f6                	test   %esi,%esi
f0104db1:	7e 15                	jle    f0104dc8 <readline+0x78>
			if (echoing)
f0104db3:	85 ff                	test   %edi,%edi
f0104db5:	74 0c                	je     f0104dc3 <readline+0x73>
				cputchar('\b');
f0104db7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0104dbe:	e8 5e b8 ff ff       	call   f0100621 <cputchar>
			i--;
f0104dc3:	83 ee 01             	sub    $0x1,%esi
f0104dc6:	eb bb                	jmp    f0104d83 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104dc8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104dce:	7f 1c                	jg     f0104dec <readline+0x9c>
f0104dd0:	83 fb 1f             	cmp    $0x1f,%ebx
f0104dd3:	7e 17                	jle    f0104dec <readline+0x9c>
			if (echoing)
f0104dd5:	85 ff                	test   %edi,%edi
f0104dd7:	74 08                	je     f0104de1 <readline+0x91>
				cputchar(c);
f0104dd9:	89 1c 24             	mov    %ebx,(%esp)
f0104ddc:	e8 40 b8 ff ff       	call   f0100621 <cputchar>
			buf[i++] = c;
f0104de1:	88 9e a0 fa 17 f0    	mov    %bl,-0xfe80560(%esi)
f0104de7:	8d 76 01             	lea    0x1(%esi),%esi
f0104dea:	eb 97                	jmp    f0104d83 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0104dec:	83 fb 0d             	cmp    $0xd,%ebx
f0104def:	74 05                	je     f0104df6 <readline+0xa6>
f0104df1:	83 fb 0a             	cmp    $0xa,%ebx
f0104df4:	75 8d                	jne    f0104d83 <readline+0x33>
			if (echoing)
f0104df6:	85 ff                	test   %edi,%edi
f0104df8:	74 0c                	je     f0104e06 <readline+0xb6>
				cputchar('\n');
f0104dfa:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104e01:	e8 1b b8 ff ff       	call   f0100621 <cputchar>
			buf[i] = 0;
f0104e06:	c6 86 a0 fa 17 f0 00 	movb   $0x0,-0xfe80560(%esi)
			return buf;
f0104e0d:	b8 a0 fa 17 f0       	mov    $0xf017faa0,%eax
		}
	}
}
f0104e12:	83 c4 1c             	add    $0x1c,%esp
f0104e15:	5b                   	pop    %ebx
f0104e16:	5e                   	pop    %esi
f0104e17:	5f                   	pop    %edi
f0104e18:	5d                   	pop    %ebp
f0104e19:	c3                   	ret    
f0104e1a:	66 90                	xchg   %ax,%ax
f0104e1c:	66 90                	xchg   %ax,%ax
f0104e1e:	66 90                	xchg   %ax,%ax

f0104e20 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104e20:	55                   	push   %ebp
f0104e21:	89 e5                	mov    %esp,%ebp
f0104e23:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104e26:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e2b:	eb 03                	jmp    f0104e30 <strlen+0x10>
		n++;
f0104e2d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104e30:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104e34:	75 f7                	jne    f0104e2d <strlen+0xd>
		n++;
	return n;
}
f0104e36:	5d                   	pop    %ebp
f0104e37:	c3                   	ret    

f0104e38 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104e38:	55                   	push   %ebp
f0104e39:	89 e5                	mov    %esp,%ebp
f0104e3b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104e3e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104e41:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e46:	eb 03                	jmp    f0104e4b <strnlen+0x13>
		n++;
f0104e48:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104e4b:	39 d0                	cmp    %edx,%eax
f0104e4d:	74 06                	je     f0104e55 <strnlen+0x1d>
f0104e4f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104e53:	75 f3                	jne    f0104e48 <strnlen+0x10>
		n++;
	return n;
}
f0104e55:	5d                   	pop    %ebp
f0104e56:	c3                   	ret    

f0104e57 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104e57:	55                   	push   %ebp
f0104e58:	89 e5                	mov    %esp,%ebp
f0104e5a:	53                   	push   %ebx
f0104e5b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e5e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104e61:	89 c2                	mov    %eax,%edx
f0104e63:	83 c2 01             	add    $0x1,%edx
f0104e66:	83 c1 01             	add    $0x1,%ecx
f0104e69:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104e6d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104e70:	84 db                	test   %bl,%bl
f0104e72:	75 ef                	jne    f0104e63 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104e74:	5b                   	pop    %ebx
f0104e75:	5d                   	pop    %ebp
f0104e76:	c3                   	ret    

f0104e77 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104e77:	55                   	push   %ebp
f0104e78:	89 e5                	mov    %esp,%ebp
f0104e7a:	53                   	push   %ebx
f0104e7b:	83 ec 08             	sub    $0x8,%esp
f0104e7e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104e81:	89 1c 24             	mov    %ebx,(%esp)
f0104e84:	e8 97 ff ff ff       	call   f0104e20 <strlen>
	strcpy(dst + len, src);
f0104e89:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104e8c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104e90:	01 d8                	add    %ebx,%eax
f0104e92:	89 04 24             	mov    %eax,(%esp)
f0104e95:	e8 bd ff ff ff       	call   f0104e57 <strcpy>
	return dst;
}
f0104e9a:	89 d8                	mov    %ebx,%eax
f0104e9c:	83 c4 08             	add    $0x8,%esp
f0104e9f:	5b                   	pop    %ebx
f0104ea0:	5d                   	pop    %ebp
f0104ea1:	c3                   	ret    

f0104ea2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104ea2:	55                   	push   %ebp
f0104ea3:	89 e5                	mov    %esp,%ebp
f0104ea5:	56                   	push   %esi
f0104ea6:	53                   	push   %ebx
f0104ea7:	8b 75 08             	mov    0x8(%ebp),%esi
f0104eaa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104ead:	89 f3                	mov    %esi,%ebx
f0104eaf:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104eb2:	89 f2                	mov    %esi,%edx
f0104eb4:	eb 0f                	jmp    f0104ec5 <strncpy+0x23>
		*dst++ = *src;
f0104eb6:	83 c2 01             	add    $0x1,%edx
f0104eb9:	0f b6 01             	movzbl (%ecx),%eax
f0104ebc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104ebf:	80 39 01             	cmpb   $0x1,(%ecx)
f0104ec2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104ec5:	39 da                	cmp    %ebx,%edx
f0104ec7:	75 ed                	jne    f0104eb6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104ec9:	89 f0                	mov    %esi,%eax
f0104ecb:	5b                   	pop    %ebx
f0104ecc:	5e                   	pop    %esi
f0104ecd:	5d                   	pop    %ebp
f0104ece:	c3                   	ret    

f0104ecf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104ecf:	55                   	push   %ebp
f0104ed0:	89 e5                	mov    %esp,%ebp
f0104ed2:	56                   	push   %esi
f0104ed3:	53                   	push   %ebx
f0104ed4:	8b 75 08             	mov    0x8(%ebp),%esi
f0104ed7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104eda:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104edd:	89 f0                	mov    %esi,%eax
f0104edf:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104ee3:	85 c9                	test   %ecx,%ecx
f0104ee5:	75 0b                	jne    f0104ef2 <strlcpy+0x23>
f0104ee7:	eb 1d                	jmp    f0104f06 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104ee9:	83 c0 01             	add    $0x1,%eax
f0104eec:	83 c2 01             	add    $0x1,%edx
f0104eef:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104ef2:	39 d8                	cmp    %ebx,%eax
f0104ef4:	74 0b                	je     f0104f01 <strlcpy+0x32>
f0104ef6:	0f b6 0a             	movzbl (%edx),%ecx
f0104ef9:	84 c9                	test   %cl,%cl
f0104efb:	75 ec                	jne    f0104ee9 <strlcpy+0x1a>
f0104efd:	89 c2                	mov    %eax,%edx
f0104eff:	eb 02                	jmp    f0104f03 <strlcpy+0x34>
f0104f01:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0104f03:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0104f06:	29 f0                	sub    %esi,%eax
}
f0104f08:	5b                   	pop    %ebx
f0104f09:	5e                   	pop    %esi
f0104f0a:	5d                   	pop    %ebp
f0104f0b:	c3                   	ret    

f0104f0c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104f0c:	55                   	push   %ebp
f0104f0d:	89 e5                	mov    %esp,%ebp
f0104f0f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104f12:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104f15:	eb 06                	jmp    f0104f1d <strcmp+0x11>
		p++, q++;
f0104f17:	83 c1 01             	add    $0x1,%ecx
f0104f1a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104f1d:	0f b6 01             	movzbl (%ecx),%eax
f0104f20:	84 c0                	test   %al,%al
f0104f22:	74 04                	je     f0104f28 <strcmp+0x1c>
f0104f24:	3a 02                	cmp    (%edx),%al
f0104f26:	74 ef                	je     f0104f17 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104f28:	0f b6 c0             	movzbl %al,%eax
f0104f2b:	0f b6 12             	movzbl (%edx),%edx
f0104f2e:	29 d0                	sub    %edx,%eax
}
f0104f30:	5d                   	pop    %ebp
f0104f31:	c3                   	ret    

f0104f32 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104f32:	55                   	push   %ebp
f0104f33:	89 e5                	mov    %esp,%ebp
f0104f35:	53                   	push   %ebx
f0104f36:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f39:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104f3c:	89 c3                	mov    %eax,%ebx
f0104f3e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104f41:	eb 06                	jmp    f0104f49 <strncmp+0x17>
		n--, p++, q++;
f0104f43:	83 c0 01             	add    $0x1,%eax
f0104f46:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104f49:	39 d8                	cmp    %ebx,%eax
f0104f4b:	74 15                	je     f0104f62 <strncmp+0x30>
f0104f4d:	0f b6 08             	movzbl (%eax),%ecx
f0104f50:	84 c9                	test   %cl,%cl
f0104f52:	74 04                	je     f0104f58 <strncmp+0x26>
f0104f54:	3a 0a                	cmp    (%edx),%cl
f0104f56:	74 eb                	je     f0104f43 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104f58:	0f b6 00             	movzbl (%eax),%eax
f0104f5b:	0f b6 12             	movzbl (%edx),%edx
f0104f5e:	29 d0                	sub    %edx,%eax
f0104f60:	eb 05                	jmp    f0104f67 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104f62:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104f67:	5b                   	pop    %ebx
f0104f68:	5d                   	pop    %ebp
f0104f69:	c3                   	ret    

f0104f6a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104f6a:	55                   	push   %ebp
f0104f6b:	89 e5                	mov    %esp,%ebp
f0104f6d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f70:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104f74:	eb 07                	jmp    f0104f7d <strchr+0x13>
		if (*s == c)
f0104f76:	38 ca                	cmp    %cl,%dl
f0104f78:	74 0f                	je     f0104f89 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104f7a:	83 c0 01             	add    $0x1,%eax
f0104f7d:	0f b6 10             	movzbl (%eax),%edx
f0104f80:	84 d2                	test   %dl,%dl
f0104f82:	75 f2                	jne    f0104f76 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104f84:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104f89:	5d                   	pop    %ebp
f0104f8a:	c3                   	ret    

f0104f8b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104f8b:	55                   	push   %ebp
f0104f8c:	89 e5                	mov    %esp,%ebp
f0104f8e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f91:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104f95:	eb 07                	jmp    f0104f9e <strfind+0x13>
		if (*s == c)
f0104f97:	38 ca                	cmp    %cl,%dl
f0104f99:	74 0a                	je     f0104fa5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104f9b:	83 c0 01             	add    $0x1,%eax
f0104f9e:	0f b6 10             	movzbl (%eax),%edx
f0104fa1:	84 d2                	test   %dl,%dl
f0104fa3:	75 f2                	jne    f0104f97 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0104fa5:	5d                   	pop    %ebp
f0104fa6:	c3                   	ret    

f0104fa7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104fa7:	55                   	push   %ebp
f0104fa8:	89 e5                	mov    %esp,%ebp
f0104faa:	57                   	push   %edi
f0104fab:	56                   	push   %esi
f0104fac:	53                   	push   %ebx
f0104fad:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104fb0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104fb3:	85 c9                	test   %ecx,%ecx
f0104fb5:	74 36                	je     f0104fed <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104fb7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104fbd:	75 28                	jne    f0104fe7 <memset+0x40>
f0104fbf:	f6 c1 03             	test   $0x3,%cl
f0104fc2:	75 23                	jne    f0104fe7 <memset+0x40>
		c &= 0xFF;
f0104fc4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104fc8:	89 d3                	mov    %edx,%ebx
f0104fca:	c1 e3 08             	shl    $0x8,%ebx
f0104fcd:	89 d6                	mov    %edx,%esi
f0104fcf:	c1 e6 18             	shl    $0x18,%esi
f0104fd2:	89 d0                	mov    %edx,%eax
f0104fd4:	c1 e0 10             	shl    $0x10,%eax
f0104fd7:	09 f0                	or     %esi,%eax
f0104fd9:	09 c2                	or     %eax,%edx
f0104fdb:	89 d0                	mov    %edx,%eax
f0104fdd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104fdf:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104fe2:	fc                   	cld    
f0104fe3:	f3 ab                	rep stos %eax,%es:(%edi)
f0104fe5:	eb 06                	jmp    f0104fed <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104fe7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104fea:	fc                   	cld    
f0104feb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104fed:	89 f8                	mov    %edi,%eax
f0104fef:	5b                   	pop    %ebx
f0104ff0:	5e                   	pop    %esi
f0104ff1:	5f                   	pop    %edi
f0104ff2:	5d                   	pop    %ebp
f0104ff3:	c3                   	ret    

f0104ff4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104ff4:	55                   	push   %ebp
f0104ff5:	89 e5                	mov    %esp,%ebp
f0104ff7:	57                   	push   %edi
f0104ff8:	56                   	push   %esi
f0104ff9:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ffc:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104fff:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105002:	39 c6                	cmp    %eax,%esi
f0105004:	73 35                	jae    f010503b <memmove+0x47>
f0105006:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105009:	39 d0                	cmp    %edx,%eax
f010500b:	73 2e                	jae    f010503b <memmove+0x47>
		s += n;
		d += n;
f010500d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0105010:	89 d6                	mov    %edx,%esi
f0105012:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105014:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010501a:	75 13                	jne    f010502f <memmove+0x3b>
f010501c:	f6 c1 03             	test   $0x3,%cl
f010501f:	75 0e                	jne    f010502f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105021:	83 ef 04             	sub    $0x4,%edi
f0105024:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105027:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010502a:	fd                   	std    
f010502b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010502d:	eb 09                	jmp    f0105038 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010502f:	83 ef 01             	sub    $0x1,%edi
f0105032:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0105035:	fd                   	std    
f0105036:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105038:	fc                   	cld    
f0105039:	eb 1d                	jmp    f0105058 <memmove+0x64>
f010503b:	89 f2                	mov    %esi,%edx
f010503d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010503f:	f6 c2 03             	test   $0x3,%dl
f0105042:	75 0f                	jne    f0105053 <memmove+0x5f>
f0105044:	f6 c1 03             	test   $0x3,%cl
f0105047:	75 0a                	jne    f0105053 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105049:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010504c:	89 c7                	mov    %eax,%edi
f010504e:	fc                   	cld    
f010504f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105051:	eb 05                	jmp    f0105058 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105053:	89 c7                	mov    %eax,%edi
f0105055:	fc                   	cld    
f0105056:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105058:	5e                   	pop    %esi
f0105059:	5f                   	pop    %edi
f010505a:	5d                   	pop    %ebp
f010505b:	c3                   	ret    

f010505c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010505c:	55                   	push   %ebp
f010505d:	89 e5                	mov    %esp,%ebp
f010505f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0105062:	8b 45 10             	mov    0x10(%ebp),%eax
f0105065:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105069:	8b 45 0c             	mov    0xc(%ebp),%eax
f010506c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105070:	8b 45 08             	mov    0x8(%ebp),%eax
f0105073:	89 04 24             	mov    %eax,(%esp)
f0105076:	e8 79 ff ff ff       	call   f0104ff4 <memmove>
}
f010507b:	c9                   	leave  
f010507c:	c3                   	ret    

f010507d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010507d:	55                   	push   %ebp
f010507e:	89 e5                	mov    %esp,%ebp
f0105080:	56                   	push   %esi
f0105081:	53                   	push   %ebx
f0105082:	8b 55 08             	mov    0x8(%ebp),%edx
f0105085:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105088:	89 d6                	mov    %edx,%esi
f010508a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010508d:	eb 1a                	jmp    f01050a9 <memcmp+0x2c>
		if (*s1 != *s2)
f010508f:	0f b6 02             	movzbl (%edx),%eax
f0105092:	0f b6 19             	movzbl (%ecx),%ebx
f0105095:	38 d8                	cmp    %bl,%al
f0105097:	74 0a                	je     f01050a3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105099:	0f b6 c0             	movzbl %al,%eax
f010509c:	0f b6 db             	movzbl %bl,%ebx
f010509f:	29 d8                	sub    %ebx,%eax
f01050a1:	eb 0f                	jmp    f01050b2 <memcmp+0x35>
		s1++, s2++;
f01050a3:	83 c2 01             	add    $0x1,%edx
f01050a6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01050a9:	39 f2                	cmp    %esi,%edx
f01050ab:	75 e2                	jne    f010508f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01050ad:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01050b2:	5b                   	pop    %ebx
f01050b3:	5e                   	pop    %esi
f01050b4:	5d                   	pop    %ebp
f01050b5:	c3                   	ret    

f01050b6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01050b6:	55                   	push   %ebp
f01050b7:	89 e5                	mov    %esp,%ebp
f01050b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01050bc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01050bf:	89 c2                	mov    %eax,%edx
f01050c1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01050c4:	eb 07                	jmp    f01050cd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01050c6:	38 08                	cmp    %cl,(%eax)
f01050c8:	74 07                	je     f01050d1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01050ca:	83 c0 01             	add    $0x1,%eax
f01050cd:	39 d0                	cmp    %edx,%eax
f01050cf:	72 f5                	jb     f01050c6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01050d1:	5d                   	pop    %ebp
f01050d2:	c3                   	ret    

f01050d3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01050d3:	55                   	push   %ebp
f01050d4:	89 e5                	mov    %esp,%ebp
f01050d6:	57                   	push   %edi
f01050d7:	56                   	push   %esi
f01050d8:	53                   	push   %ebx
f01050d9:	8b 55 08             	mov    0x8(%ebp),%edx
f01050dc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01050df:	eb 03                	jmp    f01050e4 <strtol+0x11>
		s++;
f01050e1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01050e4:	0f b6 0a             	movzbl (%edx),%ecx
f01050e7:	80 f9 09             	cmp    $0x9,%cl
f01050ea:	74 f5                	je     f01050e1 <strtol+0xe>
f01050ec:	80 f9 20             	cmp    $0x20,%cl
f01050ef:	74 f0                	je     f01050e1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01050f1:	80 f9 2b             	cmp    $0x2b,%cl
f01050f4:	75 0a                	jne    f0105100 <strtol+0x2d>
		s++;
f01050f6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01050f9:	bf 00 00 00 00       	mov    $0x0,%edi
f01050fe:	eb 11                	jmp    f0105111 <strtol+0x3e>
f0105100:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0105105:	80 f9 2d             	cmp    $0x2d,%cl
f0105108:	75 07                	jne    f0105111 <strtol+0x3e>
		s++, neg = 1;
f010510a:	8d 52 01             	lea    0x1(%edx),%edx
f010510d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105111:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0105116:	75 15                	jne    f010512d <strtol+0x5a>
f0105118:	80 3a 30             	cmpb   $0x30,(%edx)
f010511b:	75 10                	jne    f010512d <strtol+0x5a>
f010511d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0105121:	75 0a                	jne    f010512d <strtol+0x5a>
		s += 2, base = 16;
f0105123:	83 c2 02             	add    $0x2,%edx
f0105126:	b8 10 00 00 00       	mov    $0x10,%eax
f010512b:	eb 10                	jmp    f010513d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010512d:	85 c0                	test   %eax,%eax
f010512f:	75 0c                	jne    f010513d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105131:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105133:	80 3a 30             	cmpb   $0x30,(%edx)
f0105136:	75 05                	jne    f010513d <strtol+0x6a>
		s++, base = 8;
f0105138:	83 c2 01             	add    $0x1,%edx
f010513b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010513d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0105142:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0105145:	0f b6 0a             	movzbl (%edx),%ecx
f0105148:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010514b:	89 f0                	mov    %esi,%eax
f010514d:	3c 09                	cmp    $0x9,%al
f010514f:	77 08                	ja     f0105159 <strtol+0x86>
			dig = *s - '0';
f0105151:	0f be c9             	movsbl %cl,%ecx
f0105154:	83 e9 30             	sub    $0x30,%ecx
f0105157:	eb 20                	jmp    f0105179 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0105159:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010515c:	89 f0                	mov    %esi,%eax
f010515e:	3c 19                	cmp    $0x19,%al
f0105160:	77 08                	ja     f010516a <strtol+0x97>
			dig = *s - 'a' + 10;
f0105162:	0f be c9             	movsbl %cl,%ecx
f0105165:	83 e9 57             	sub    $0x57,%ecx
f0105168:	eb 0f                	jmp    f0105179 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010516a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010516d:	89 f0                	mov    %esi,%eax
f010516f:	3c 19                	cmp    $0x19,%al
f0105171:	77 16                	ja     f0105189 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0105173:	0f be c9             	movsbl %cl,%ecx
f0105176:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0105179:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010517c:	7d 0f                	jge    f010518d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010517e:	83 c2 01             	add    $0x1,%edx
f0105181:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0105185:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0105187:	eb bc                	jmp    f0105145 <strtol+0x72>
f0105189:	89 d8                	mov    %ebx,%eax
f010518b:	eb 02                	jmp    f010518f <strtol+0xbc>
f010518d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010518f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105193:	74 05                	je     f010519a <strtol+0xc7>
		*endptr = (char *) s;
f0105195:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105198:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010519a:	f7 d8                	neg    %eax
f010519c:	85 ff                	test   %edi,%edi
f010519e:	0f 44 c3             	cmove  %ebx,%eax
}
f01051a1:	5b                   	pop    %ebx
f01051a2:	5e                   	pop    %esi
f01051a3:	5f                   	pop    %edi
f01051a4:	5d                   	pop    %ebp
f01051a5:	c3                   	ret    
f01051a6:	66 90                	xchg   %ax,%ax
f01051a8:	66 90                	xchg   %ax,%ax
f01051aa:	66 90                	xchg   %ax,%ax
f01051ac:	66 90                	xchg   %ax,%ax
f01051ae:	66 90                	xchg   %ax,%ax

f01051b0 <__udivdi3>:
f01051b0:	55                   	push   %ebp
f01051b1:	57                   	push   %edi
f01051b2:	56                   	push   %esi
f01051b3:	83 ec 0c             	sub    $0xc,%esp
f01051b6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01051ba:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01051be:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01051c2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01051c6:	85 c0                	test   %eax,%eax
f01051c8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01051cc:	89 ea                	mov    %ebp,%edx
f01051ce:	89 0c 24             	mov    %ecx,(%esp)
f01051d1:	75 2d                	jne    f0105200 <__udivdi3+0x50>
f01051d3:	39 e9                	cmp    %ebp,%ecx
f01051d5:	77 61                	ja     f0105238 <__udivdi3+0x88>
f01051d7:	85 c9                	test   %ecx,%ecx
f01051d9:	89 ce                	mov    %ecx,%esi
f01051db:	75 0b                	jne    f01051e8 <__udivdi3+0x38>
f01051dd:	b8 01 00 00 00       	mov    $0x1,%eax
f01051e2:	31 d2                	xor    %edx,%edx
f01051e4:	f7 f1                	div    %ecx
f01051e6:	89 c6                	mov    %eax,%esi
f01051e8:	31 d2                	xor    %edx,%edx
f01051ea:	89 e8                	mov    %ebp,%eax
f01051ec:	f7 f6                	div    %esi
f01051ee:	89 c5                	mov    %eax,%ebp
f01051f0:	89 f8                	mov    %edi,%eax
f01051f2:	f7 f6                	div    %esi
f01051f4:	89 ea                	mov    %ebp,%edx
f01051f6:	83 c4 0c             	add    $0xc,%esp
f01051f9:	5e                   	pop    %esi
f01051fa:	5f                   	pop    %edi
f01051fb:	5d                   	pop    %ebp
f01051fc:	c3                   	ret    
f01051fd:	8d 76 00             	lea    0x0(%esi),%esi
f0105200:	39 e8                	cmp    %ebp,%eax
f0105202:	77 24                	ja     f0105228 <__udivdi3+0x78>
f0105204:	0f bd e8             	bsr    %eax,%ebp
f0105207:	83 f5 1f             	xor    $0x1f,%ebp
f010520a:	75 3c                	jne    f0105248 <__udivdi3+0x98>
f010520c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0105210:	39 34 24             	cmp    %esi,(%esp)
f0105213:	0f 86 9f 00 00 00    	jbe    f01052b8 <__udivdi3+0x108>
f0105219:	39 d0                	cmp    %edx,%eax
f010521b:	0f 82 97 00 00 00    	jb     f01052b8 <__udivdi3+0x108>
f0105221:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105228:	31 d2                	xor    %edx,%edx
f010522a:	31 c0                	xor    %eax,%eax
f010522c:	83 c4 0c             	add    $0xc,%esp
f010522f:	5e                   	pop    %esi
f0105230:	5f                   	pop    %edi
f0105231:	5d                   	pop    %ebp
f0105232:	c3                   	ret    
f0105233:	90                   	nop
f0105234:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105238:	89 f8                	mov    %edi,%eax
f010523a:	f7 f1                	div    %ecx
f010523c:	31 d2                	xor    %edx,%edx
f010523e:	83 c4 0c             	add    $0xc,%esp
f0105241:	5e                   	pop    %esi
f0105242:	5f                   	pop    %edi
f0105243:	5d                   	pop    %ebp
f0105244:	c3                   	ret    
f0105245:	8d 76 00             	lea    0x0(%esi),%esi
f0105248:	89 e9                	mov    %ebp,%ecx
f010524a:	8b 3c 24             	mov    (%esp),%edi
f010524d:	d3 e0                	shl    %cl,%eax
f010524f:	89 c6                	mov    %eax,%esi
f0105251:	b8 20 00 00 00       	mov    $0x20,%eax
f0105256:	29 e8                	sub    %ebp,%eax
f0105258:	89 c1                	mov    %eax,%ecx
f010525a:	d3 ef                	shr    %cl,%edi
f010525c:	89 e9                	mov    %ebp,%ecx
f010525e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0105262:	8b 3c 24             	mov    (%esp),%edi
f0105265:	09 74 24 08          	or     %esi,0x8(%esp)
f0105269:	89 d6                	mov    %edx,%esi
f010526b:	d3 e7                	shl    %cl,%edi
f010526d:	89 c1                	mov    %eax,%ecx
f010526f:	89 3c 24             	mov    %edi,(%esp)
f0105272:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105276:	d3 ee                	shr    %cl,%esi
f0105278:	89 e9                	mov    %ebp,%ecx
f010527a:	d3 e2                	shl    %cl,%edx
f010527c:	89 c1                	mov    %eax,%ecx
f010527e:	d3 ef                	shr    %cl,%edi
f0105280:	09 d7                	or     %edx,%edi
f0105282:	89 f2                	mov    %esi,%edx
f0105284:	89 f8                	mov    %edi,%eax
f0105286:	f7 74 24 08          	divl   0x8(%esp)
f010528a:	89 d6                	mov    %edx,%esi
f010528c:	89 c7                	mov    %eax,%edi
f010528e:	f7 24 24             	mull   (%esp)
f0105291:	39 d6                	cmp    %edx,%esi
f0105293:	89 14 24             	mov    %edx,(%esp)
f0105296:	72 30                	jb     f01052c8 <__udivdi3+0x118>
f0105298:	8b 54 24 04          	mov    0x4(%esp),%edx
f010529c:	89 e9                	mov    %ebp,%ecx
f010529e:	d3 e2                	shl    %cl,%edx
f01052a0:	39 c2                	cmp    %eax,%edx
f01052a2:	73 05                	jae    f01052a9 <__udivdi3+0xf9>
f01052a4:	3b 34 24             	cmp    (%esp),%esi
f01052a7:	74 1f                	je     f01052c8 <__udivdi3+0x118>
f01052a9:	89 f8                	mov    %edi,%eax
f01052ab:	31 d2                	xor    %edx,%edx
f01052ad:	e9 7a ff ff ff       	jmp    f010522c <__udivdi3+0x7c>
f01052b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01052b8:	31 d2                	xor    %edx,%edx
f01052ba:	b8 01 00 00 00       	mov    $0x1,%eax
f01052bf:	e9 68 ff ff ff       	jmp    f010522c <__udivdi3+0x7c>
f01052c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01052c8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01052cb:	31 d2                	xor    %edx,%edx
f01052cd:	83 c4 0c             	add    $0xc,%esp
f01052d0:	5e                   	pop    %esi
f01052d1:	5f                   	pop    %edi
f01052d2:	5d                   	pop    %ebp
f01052d3:	c3                   	ret    
f01052d4:	66 90                	xchg   %ax,%ax
f01052d6:	66 90                	xchg   %ax,%ax
f01052d8:	66 90                	xchg   %ax,%ax
f01052da:	66 90                	xchg   %ax,%ax
f01052dc:	66 90                	xchg   %ax,%ax
f01052de:	66 90                	xchg   %ax,%ax

f01052e0 <__umoddi3>:
f01052e0:	55                   	push   %ebp
f01052e1:	57                   	push   %edi
f01052e2:	56                   	push   %esi
f01052e3:	83 ec 14             	sub    $0x14,%esp
f01052e6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01052ea:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01052ee:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f01052f2:	89 c7                	mov    %eax,%edi
f01052f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01052f8:	8b 44 24 30          	mov    0x30(%esp),%eax
f01052fc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0105300:	89 34 24             	mov    %esi,(%esp)
f0105303:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105307:	85 c0                	test   %eax,%eax
f0105309:	89 c2                	mov    %eax,%edx
f010530b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010530f:	75 17                	jne    f0105328 <__umoddi3+0x48>
f0105311:	39 fe                	cmp    %edi,%esi
f0105313:	76 4b                	jbe    f0105360 <__umoddi3+0x80>
f0105315:	89 c8                	mov    %ecx,%eax
f0105317:	89 fa                	mov    %edi,%edx
f0105319:	f7 f6                	div    %esi
f010531b:	89 d0                	mov    %edx,%eax
f010531d:	31 d2                	xor    %edx,%edx
f010531f:	83 c4 14             	add    $0x14,%esp
f0105322:	5e                   	pop    %esi
f0105323:	5f                   	pop    %edi
f0105324:	5d                   	pop    %ebp
f0105325:	c3                   	ret    
f0105326:	66 90                	xchg   %ax,%ax
f0105328:	39 f8                	cmp    %edi,%eax
f010532a:	77 54                	ja     f0105380 <__umoddi3+0xa0>
f010532c:	0f bd e8             	bsr    %eax,%ebp
f010532f:	83 f5 1f             	xor    $0x1f,%ebp
f0105332:	75 5c                	jne    f0105390 <__umoddi3+0xb0>
f0105334:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0105338:	39 3c 24             	cmp    %edi,(%esp)
f010533b:	0f 87 e7 00 00 00    	ja     f0105428 <__umoddi3+0x148>
f0105341:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105345:	29 f1                	sub    %esi,%ecx
f0105347:	19 c7                	sbb    %eax,%edi
f0105349:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010534d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0105351:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105355:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105359:	83 c4 14             	add    $0x14,%esp
f010535c:	5e                   	pop    %esi
f010535d:	5f                   	pop    %edi
f010535e:	5d                   	pop    %ebp
f010535f:	c3                   	ret    
f0105360:	85 f6                	test   %esi,%esi
f0105362:	89 f5                	mov    %esi,%ebp
f0105364:	75 0b                	jne    f0105371 <__umoddi3+0x91>
f0105366:	b8 01 00 00 00       	mov    $0x1,%eax
f010536b:	31 d2                	xor    %edx,%edx
f010536d:	f7 f6                	div    %esi
f010536f:	89 c5                	mov    %eax,%ebp
f0105371:	8b 44 24 04          	mov    0x4(%esp),%eax
f0105375:	31 d2                	xor    %edx,%edx
f0105377:	f7 f5                	div    %ebp
f0105379:	89 c8                	mov    %ecx,%eax
f010537b:	f7 f5                	div    %ebp
f010537d:	eb 9c                	jmp    f010531b <__umoddi3+0x3b>
f010537f:	90                   	nop
f0105380:	89 c8                	mov    %ecx,%eax
f0105382:	89 fa                	mov    %edi,%edx
f0105384:	83 c4 14             	add    $0x14,%esp
f0105387:	5e                   	pop    %esi
f0105388:	5f                   	pop    %edi
f0105389:	5d                   	pop    %ebp
f010538a:	c3                   	ret    
f010538b:	90                   	nop
f010538c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105390:	8b 04 24             	mov    (%esp),%eax
f0105393:	be 20 00 00 00       	mov    $0x20,%esi
f0105398:	89 e9                	mov    %ebp,%ecx
f010539a:	29 ee                	sub    %ebp,%esi
f010539c:	d3 e2                	shl    %cl,%edx
f010539e:	89 f1                	mov    %esi,%ecx
f01053a0:	d3 e8                	shr    %cl,%eax
f01053a2:	89 e9                	mov    %ebp,%ecx
f01053a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01053a8:	8b 04 24             	mov    (%esp),%eax
f01053ab:	09 54 24 04          	or     %edx,0x4(%esp)
f01053af:	89 fa                	mov    %edi,%edx
f01053b1:	d3 e0                	shl    %cl,%eax
f01053b3:	89 f1                	mov    %esi,%ecx
f01053b5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01053b9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01053bd:	d3 ea                	shr    %cl,%edx
f01053bf:	89 e9                	mov    %ebp,%ecx
f01053c1:	d3 e7                	shl    %cl,%edi
f01053c3:	89 f1                	mov    %esi,%ecx
f01053c5:	d3 e8                	shr    %cl,%eax
f01053c7:	89 e9                	mov    %ebp,%ecx
f01053c9:	09 f8                	or     %edi,%eax
f01053cb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01053cf:	f7 74 24 04          	divl   0x4(%esp)
f01053d3:	d3 e7                	shl    %cl,%edi
f01053d5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01053d9:	89 d7                	mov    %edx,%edi
f01053db:	f7 64 24 08          	mull   0x8(%esp)
f01053df:	39 d7                	cmp    %edx,%edi
f01053e1:	89 c1                	mov    %eax,%ecx
f01053e3:	89 14 24             	mov    %edx,(%esp)
f01053e6:	72 2c                	jb     f0105414 <__umoddi3+0x134>
f01053e8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f01053ec:	72 22                	jb     f0105410 <__umoddi3+0x130>
f01053ee:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01053f2:	29 c8                	sub    %ecx,%eax
f01053f4:	19 d7                	sbb    %edx,%edi
f01053f6:	89 e9                	mov    %ebp,%ecx
f01053f8:	89 fa                	mov    %edi,%edx
f01053fa:	d3 e8                	shr    %cl,%eax
f01053fc:	89 f1                	mov    %esi,%ecx
f01053fe:	d3 e2                	shl    %cl,%edx
f0105400:	89 e9                	mov    %ebp,%ecx
f0105402:	d3 ef                	shr    %cl,%edi
f0105404:	09 d0                	or     %edx,%eax
f0105406:	89 fa                	mov    %edi,%edx
f0105408:	83 c4 14             	add    $0x14,%esp
f010540b:	5e                   	pop    %esi
f010540c:	5f                   	pop    %edi
f010540d:	5d                   	pop    %ebp
f010540e:	c3                   	ret    
f010540f:	90                   	nop
f0105410:	39 d7                	cmp    %edx,%edi
f0105412:	75 da                	jne    f01053ee <__umoddi3+0x10e>
f0105414:	8b 14 24             	mov    (%esp),%edx
f0105417:	89 c1                	mov    %eax,%ecx
f0105419:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010541d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0105421:	eb cb                	jmp    f01053ee <__umoddi3+0x10e>
f0105423:	90                   	nop
f0105424:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105428:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010542c:	0f 82 0f ff ff ff    	jb     f0105341 <__umoddi3+0x61>
f0105432:	e9 1a ff ff ff       	jmp    f0105351 <__umoddi3+0x71>
