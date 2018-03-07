// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>
#include <lib/pgfault.c>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if ((err & FEC_WR) == 0 || (uvpt[PGNUM(addr)] & PTE_COW) == 0)
		panic("pgfault: invalid user trap frame");

	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	envid_t env_id = sys_getenvid();
	if ((r = sys_page_alloc(env_id, (void *)PFTEMP, PTE_P | PTE_W | PTE_U)) < 0)
		panic("pgfault: fail to alloc page");
	addr = ROUNDDOWN(addr, PGSIZE);
	memmove(PFTEMP, addr, PGSIZE);
	if ((r = sys_page_unmap(env_id, addr)) < 0)
		panic("pgfault: fail to unmap");
	if ((r = sys_page_map(env_id, PFTEMP, env_id, addr, PTE_P | PTE_W | PTE_U)) < 0)
		panic("pgfault: fail to map");
	if ((r = sys_page_unmap(env_id, PFTEMP)) < 0)
		panic("pgfault: fail to unmpa");
	//panic("pgfault not implemented");
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	// panic("duppage not implemented");
	envid_t this_env_id = sys_getenvid();
	void *va = (void *)(pn * PGSIZE);
	int perm = uvpt[pn] & 0xfff;
	if ((perm & PTE_W) || (perm & PTE_COW)){
		// +PTE_COW, -PTE_W
		perm |= PTE_COW;
		perm &= ~PTE_W;
	}
	perm &= PTE_SYSCALL;
	if ((r = sys_page_map(this_env_id, va, envid, va, perm)) < 0)
		panic("duppage: %e", r);
	if ((r = sys_page_map(this_env_id, va, this_env_id, va, perm)) < 0)
		panic("duppage: %e", r);
	return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
	// LAB 4: Your code here.
	// panic("fork not implemented");
	set_pgfault_handler(pgfault);
	envid_t env_id = sys_exofork();
	if (env_id < 0)
		panic("fork: %e", env_id);
	else if (env_id == 0){
		// child
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}
	// parent
	for (uintptr_t addr = UTEXT; addr < USTACKTOP; addr += PGSIZE){
		if ((uvpd[PDX(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_P))
			duppage(env_id, PGNUM(addr));
	}
	// alloc page for exception stack
	int retVal = sys_page_alloc(env_id, (void *)(UXSTACKTOP - PGSIZE), PTE_U | PTE_W | PTE_P);
	if (retVal < 0)
		panic("fork: %e", retVal);

	extern void _pgfault_upcall();
	retVal = sys_env_set_pgfault_upcall(env_id, _pgfault_upcall);
	if (retVal < 0)
		panic("fork: %e", retVal);

	if ((retVal = sys_env_set_status(env_id, ENV_RUNNABLE)) < 0)
		panic("fork: %e", retVal);

	return env_id;
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
