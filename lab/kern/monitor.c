// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>
#include <inc/mmu.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>
#include <kern/trap.h>
#include <kern/pmap.h>

#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	const char *usage;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", "help (commands)",  mon_help },
	{ "kerninfo", "Display information about the kernel", "kerninfo", mon_kerninfo },
	{ "showbacktrace", "Display the backtrace of stack", "showbacktrace", mon_backtrace},
	{ "showmappings", "Display the physical page mappings", "showmappings start_addr (end_addr)", mon_showmappings },
	{ "setperm", "Set , clear of change the permission of any mapping address space", "setperm [+|-]perm", mon_setpermission}, 
	{ "dump", "Dump the contents of a range of memory", "dump [-p|-v] start_addr end_addr", mon_dump},
};

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	if(argc == 2){
		for (i = 0; i < ARRAY_SIZE(commands); i++)
			if (strcmp(argv[1], commands[i].name) == 0)
				break;
		if (i >= ARRAY_SIZE(commands))
			cprintf("No command : %s !\n", argv[1]);
		else
			cprintf("%s\nUsage : %s\n", commands[i].desc, commands[i].usage);
	}else{
		for (i = 0; i < ARRAY_SIZE(commands); i++)
			cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	}
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// 每次压栈的顺序依次是：保存ebx、保存ebp、返回地址eip、五个参数
	uint32_t eip;
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
		eip = *((uint32_t *)ebp + 1);
		debuginfo_eip(eip, &info);
		cprintf("  ebp %08x  eip %08x  args", ebp, eip);
		for(int i = 2; i < 7; i++){
			cprintf(" %08x", *((uint32_t*)ebp + i));
		}
		cprintf("\n         %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
		ebp = *((uint32_t *)ebp);
	}
	return 0;
}

int
mon_showmappings(int argc, char **argv, struct Trapframe *tf)
{
	// check arguments num
	if (argc != 3 && argc != 2){
		cprintf("Usage: showmappings start_addr (end_addr) \n");
		return 0;
	}
	// check address avalid : use strtol to check
	/* long int strtol(const char *nptr, char **endptr, int base)
	 * nptr : the string who is to change to a interger
	 * endptr : if the nptr is invalid, write the first invalid char in endptr
	 * base : the type of number
	*/
	char *errStr;
	uintptr_t start_addr = strtol(argv[1], &errStr, 16);
	if (*errStr){
		cprintf("error : invalid input : %s .\n", argv[1]);
		return 0;
	}
	start_addr = ROUNDDOWN(start_addr, PGSIZE);
	uintptr_t end_addr;
	if (argc == 2)
		end_addr = start_addr + PGSIZE;
	else{
		end_addr = strtol(argv[2], &errStr, 16);
		if (*errStr){
			cprintf("error : invalid input : %s .\n", argv[2]);
			return 0;
		}
		end_addr = ROUNDUP(end_addr, PGSIZE);
	}

	while(start_addr < end_addr){
		pte_t *cur_pte = pgdir_walk(kern_pgdir, (void *)start_addr, 0);
		if(!cur_pte || !(*cur_pte & PTE_P)){
			cprintf("virtual address 0x%08x not mapped.\n", start_addr);
		}else{
			cprintf("virtual address 0x%08x physical address 0x%08x permission: ", 
				start_addr, PTE_ADDR(*cur_pte));
			char perm_Global = (*cur_pte & PTE_G) ? 'G' : '-';
			char perm_PageSize = (*cur_pte & PTE_PS) ? 'S' : '-';
			char perm_Dirty = (*cur_pte & PTE_D) ? 'D' : '-';
			char perm_Accessed = (*cur_pte & PTE_A) ? 'A' : '-';
			char perm_CacheDisable = (*cur_pte & PTE_PCD) ? 'C' : '-';
			char perm_Wirtethrough = (*cur_pte & PTE_PWT) ? 'T' : '-';
			char perm_User = (*cur_pte & PTE_U) ? 'U' : '-';
			char perm_Writeable = (*cur_pte & PTE_W) ? 'W' : '-';
			char perm_Present = 'P';	// has been checked
			cprintf("%c%c%c%c%c%c%c%c%c\n", perm_Global, perm_PageSize, perm_Dirty, perm_Accessed, perm_CacheDisable, perm_Wirtethrough, perm_User, perm_Writeable,perm_Present);
		}
		start_addr += PGSIZE;
	}
	return 0;
}

int
mon_setpermission(int argc, char **argv, struct Trapframe *tf)
{
	if (argc != 3 || (*argv[2] != '+' && *argv[2] != '-')){
		cprintf("Usage : setperm [+|-]perm \n");
		return 0;
	}
	char *errStr;
	uint32_t start_addr = strtol(argv[1], &errStr, 16);
	start_addr = ROUNDDOWN(start_addr, PGSIZE);
	pte_t *ppte;
	struct PageInfo *pp = page_lookup(kern_pgdir, (void *)start_addr, &ppte);
	if (!pp || !*ppte){
		cprintf("virtual address 0x%08x not mapped.\n", start_addr);
		return 0;
	} 
	if (*argv[2] == '+'){
		*ppte |= str2permision(argv[2] + 1);
	}else if (*argv[2] == '-'){
		*ppte = *ppte & (~str2permision(argv[2] + 1));
	}
	return 0;
}

int
mon_dump(int argc, char **argv, struct Trapframe *tf)
{
	int is_phyaddr = 0;
	if (argc != 4 || *argv[1] != '-'){
		cprintf("Usage : dump [-p|-v] start_addr end_addr\n");
		return 0;
	}
	if (argv[1][1] == 'p' || argv[1][1] == 'P')
		is_phyaddr = 1;
	else if (argv[1][1] == 'v' || argv[1][1] == 'V')
		is_phyaddr = 0;
	else{
		cprintf("Usage : dump [-p|-v] start_addr end_addr\n");
		return 0;
	}

	// get start_addr and end_addr
	char *errStr;
	uintptr_t start_addr = strtol(argv[2], &errStr, 16);
	if (*errStr){
		cprintf("error : invalid input : %s .\n", argv[1]);
		return 0;
	}
	start_addr = ROUNDDOWN(start_addr, PGSIZE);
	uintptr_t end_addr = strtol(argv[3], &errStr, 16);
	if (*errStr){
		cprintf("error : invalid input : %s .\n", argv[2]);
		return 0;
	}
	end_addr = ROUNDUP(end_addr, PGSIZE);

	// if the addr is physical addr, change to vitual addr
	if (is_phyaddr){
		if ((PGNUM(start_addr) >= npages) || (PGNUM(end_addr) >= npages)){
			cprintf("error: the address overflow the max physical address\n");
			return 0;
		}
		start_addr = (uint32_t)KADDR(start_addr);
		end_addr = (uint32_t)KADDR(end_addr);
	}

	while(start_addr < end_addr){
		pte_t *ppte;
		if (page_lookup(kern_pgdir, (void *)start_addr, &ppte) == NULL || *ppte == 0){
			cprintf("virtual addr 0x%08x not mapping\n");
		}else{
			cprintf("virtual addr 0x%08x physical addr 0x%08x memory ", PTE_ADDR(*ppte) | PGOFF(start_addr));
			for (int i = 0; i < 16; i++)
				cprintf("%02x ", *(unsigned char *)start_addr);
			cprintf("\n");
		}
		start_addr += PGSIZE;
	}
	return 0;
}

/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void
monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");

	if (tf != NULL)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
