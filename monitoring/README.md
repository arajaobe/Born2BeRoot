*This project has been created as part of the 42 curriculum by arajaobe.*

# Born2beroot

## Description

Born2beroot is a system administration project whose goal is to introduce students to the basics of virtualization and Linux server administration in a rigorous, security-conscious environment. Using a virtualization tool, the project consists of setting up a virtual machine running a lightweight, UI-free Linux distribution, then configuring it according to strict subject requirements: manual disk partitioning with LVM, a hardened SSH configuration, a firewall, strong password and sudo policies, and a monitoring script that reports on the machine's status at regular intervals.

Beyond the technical checklist, the real objective of Born2beroot is to build an understanding of *why* each configuration choice matters: least-privilege principles, defense in depth, password aging policies, and the trade-offs between different Linux distributions and security tools. It is meant to give a first taste of what running and hardening a real server looks like, without ever touching a graphical interface.

For this project, the machine was set up using **Debian**, configured entirely from the command line.

## Instructions

### Prerequisites

- A hypervisor: [VirtualBox](https://www.virtualbox.org/) (used here) or UTM, depending on your host OS.
- A Debian netinstall ISO (`debian-12.x.x-amd64-netinst.iso` or similar), downloaded from the [official Debian site](https://www.debian.org/distrib/).
- At least 2 virtual disks of ~2.5GB+ each (as required by the subject for LVM), 1 CPU, and a reasonable amount of RAM (e.g. 1024MB).

### Setting up the VM

1. Create a new virtual machine in VirtualBox (Linux / Debian 64-bit), attach the Debian netinstall ISO, and allocate storage/CPU/RAM per the subject's constraints.
2. During installation, choose **manual partitioning** and set up LVM (Logical Volume Manager) with separate logical volumes for at least: `/`, `/home`, `/var`, `/var/log`, `/tmp`, `/srv`, and swap — following the principle of isolating partitions so that a runaway process (e.g. filling up logs) can't crash the whole system.
3. Do **not** install a desktop environment; select only "SSH server" and "standard system utilities" during package selection.
4. Set a strong root password and create a personal user (belonging to a group named after your login) with a strong password policy enforced afterward.

### Post-install configuration

1. **sudo**: install and configure `sudo` so that the personal user can execute administrative commands. Configure a custom `sudo` policy in `/etc/sudoers.d/` to:
 - restrict the number of authentication attempts,
 - log every sudo command (successful and failed) to `/var/log/sudo/`,
 - force a specific, secure TTY,
 - set a custom, more restrictive prompt on wrong password.
2. **SSH**: install and configure `openssh-server` to listen on a non-default port (e.g. 4242) and disable root login over SSH (`PermitRootLogin no`).
3. **Firewall**: install and configure UFW, allowing only the custom SSH port.
4. **Password policy**: configure `/etc/login.defs` and PAM (`libpam-pwquality`) to enforce password expiration (30 days), minimum age, warning period, and complexity rules (minimum length, mixed case, digits, no reuse, no more than 3 consecutive identical characters, must differ substantially from the login).
5. **Hostname**: set the machine's hostname to `login42` (e.g. `arajaobe42`), as required by the evaluation.
6. **Monitoring script**: write a bash script (`monitoring.sh`) that displays architecture, CPU physical/virtual core counts, RAM usage, disk usage, CPU load, last boot date, LVM status, active connections, active users, network IP/MAC address, and number of sudo commands executed. The script is scheduled via `crontab` to run every 10 minutes and broadcast its output to all connected terminals using `wall`.

### Running / verifying

- Connect over SSH: `ssh arajaobe@<VM_IP> -p 4242`
- Check partitioning: `lsblk` and `sudo lvdisplay`
- Check firewall status: `sudo ufw status`
- Check the sudo log: `cat /var/log/sudo/sudo.log`
- Check the monitoring script output: `sudo bash /root/monitoring.sh` or wait for the next `wall` broadcast.

## Project Description

### Why Debian over Rocky Linux

The subject allows either **Debian** or **Rocky Linux**. This project uses Debian.

| | Debian | Rocky Linux |
|---|---|---|
| Origin | Independent, community-driven distribution, one of the oldest Linux distros | Community rebuild of RHEL (Red Hat Enterprise Linux), created after CentOS shifted to a rolling-release model |
| Package manager | APT (`.deb` packages) | DNF/YUM (`.rpm` packages) |
| Release model | Stable branch with long, well-tested release cycles | Point releases tied to RHEL's release cadence, very predictable |
| Philosophy | Broad hardware/software support, strong free-software focus, huge package repository | Enterprise-oriented, binary-compatible with RHEL, favored in corporate/production environments |
| Documentation/community | Extremely large community, very well documented, tons of forum answers | Smaller but growing community, backed by enterprise usage of RHEL-like systems |
| Default security tooling | AppArmor | SELinux |

**Advantages of Debian**: extremely stable and well-tested packages, huge repository of software, lightweight, very well documented, and a good general-purpose choice for learning Linux fundamentals without being tied to a specific commercial ecosystem.

**Disadvantages of Debian**: packages can be older/more conservative than bleeding-edge distros, and AppArmor's simpler model is less granular than SELinux's for very complex enterprise policies.

**Advantages of Rocky Linux**: binary compatibility with RHEL makes it a natural choice for companies already running Red Hat infrastructure, strong enterprise-grade security tooling (SELinux) by default, and predictable long-term support cycles.

**Disadvantages of Rocky Linux**: smaller community than Debian, SELinux has a steeper learning curve, and it's a relatively young project (created in 2021) compared to Debian's decades of track record.

Debian was chosen for this project mainly for its lighter footprint, simpler AppArmor security model (a gentler introduction to Mandatory Access Control than SELinux), and the depth of community documentation available for a first system-administration project.

### Main design choices

- **Partitioning**: manual partitioning with LVM was used instead of guided/automatic partitioning so that each major directory (`/`, `/home`, `/var`, `/var/log`, `/tmp`, `/srv`, swap) sits on its own logical volume. This isolates failure domains — e.g. if `/var/log` fills up, it can't take down `/` — and makes it possible to resize volumes later without repartitioning the whole disk.
- **Security policies**: a strict password aging and complexity policy is enforced through `/etc/login.defs` and PAM, and `sudo` is locked down with attempt limits, full logging, and a custom prompt, so that every privileged action is both restricted and traceable.
- **User management**: a personal, non-root user is created and added to both a `sudo` group and a dedicated group named after the login, following the principle of least privilege — root login over SSH is disabled entirely, forcing all administration through the traceable personal account.
- **Services installed**: only the strict minimum required — SSH (on a non-default port), sudo, UFW, and the packages needed for the password/PAM policy and the monitoring script. No desktop environment or unnecessary services are installed, reducing the attack surface.

### AppArmor vs SELinux

| | AppArmor | SELinux |
|---|---|---|
| Used by default on | Debian, Ubuntu | Rocky Linux, RHEL, Fedora |
| Model | Path-based Mandatory Access Control (MAC): profiles are attached to file paths | Label-based MAC: every file, process, and resource gets a security context/label |
| Complexity | Easier to write and read profiles, gentler learning curve | More powerful and granular, but significantly more complex to configure |
| Granularity | Coarser (per-path rules) | Finer (per-label rules, can restrict based on process/user/role/type) |
| Typical use case | Good for confining specific applications with reasonably simple policies | Preferred in high-security/enterprise environments needing fine-grained control |

Both are Linux Security Modules that implement Mandatory Access Control on top of the traditional discretionary Unix permission model, restricting what a process can do even if it's running as root.

### UFW vs firewalld

| | UFW (Uncomplicated Firewall) | firewalld |
|---|---|---|
| Used by default on | Debian, Ubuntu | Rocky Linux, RHEL, Fedora |
| Backend | Frontend for `iptables`/`nftables` | Also manages `iptables`/`nftables`, but through "zones" |
| Philosophy | Simple, minimal syntax, aimed at quick and readable rule management | Zone-based model (e.g. public, home, trusted) allowing different rule sets per network context |
| Dynamic updates | Historically required reload for some changes, but generally simple to use | Supports fully dynamic rule updates without dropping existing connections |
| Learning curve | Very low — a handful of intuitive commands (`ufw allow`, `ufw enable`) | Steeper due to the zone concept, but more flexible for multi-network setups |

For this project, UFW was configured to deny all incoming traffic by default and explicitly allow only the custom SSH port, which is sufficient for a single-purpose server with one network context.

### VirtualBox vs UTM

| | VirtualBox | UTM |
|---|---|---|
| Developer | Oracle | Open-source project, built on QEMU |
| Platform support | Windows, macOS (Intel), Linux | Primarily macOS, including Apple Silicon (ARM) |
| Virtualization type | Type 2 hypervisor, hardware-assisted virtualization (VT-x/AMD-V) | Uses QEMU with Apple's Hypervisor.framework / hardware acceleration on Apple Silicon |
| Performance | Very mature, well-optimized on x86 hosts | Good performance on Apple Silicon thanks to native ARM virtualization; can also emulate x86 (slower) |
| Ecosystem | Large, long-standing user base, extensive documentation | Smaller but growing, especially popular since the shift to Apple Silicon |

VirtualBox was used for this project, running on an x86-based host, since it offers a mature, well-documented environment for hardware-assisted virtualization and is the tool most commonly used across the 42 community for this project.

## Resources

- [Debian Official Documentation](https://www.debian.org/doc/)
- [Debian Administrator's Handbook](https://debian-handbook.info/)
- [Debian Wiki – LVM](https://wiki.debian.org/LVM)
- [OpenSSH Server Configuration – man sshd_config](https://man.openbsd.org/sshd_config)
- [UFW Community Help Wiki](https://help.ubuntu.com/community/UFW)
- [AppArmor Wiki](https://gitlab.com/apparmor/apparmor/-/wikis/Documentation)
- [SELinux Project Wiki](https://selinuxproject.org/page/Main_Page)
- [Rocky Linux Documentation](https://docs.rockylinux.org/)
- [PAM (Pluggable Authentication Modules) Documentation](https://www.man7.org/linux/man-pages/man8/PAM.8.html)
- [VirtualBox User Manual](https://www.virtualbox.org/manual/UserManual.html)
- [UTM Documentation](https://docs.getutm.app/)

### AI usage disclosure

An AI assistant (Claude, by Anthropic) was used to help generate the initial structure and wording of this README.md file — specifically to draft the Description, Instructions, and Project Description sections, and to organize the Debian vs Rocky, AppArmor vs SELinux, UFW vs firewalld, and VirtualBox vs UTM comparisons into clear tables. AI was **not** used to configure the virtual machine itself, write the monitoring script, or perform the actual system administration tasks (partitioning, sudo/SSH/firewall configuration, PAM policy) — those were done manually by the student, with the AI-generated text reviewed and edited afterward to accurately reflect the choices actually made during setup.
