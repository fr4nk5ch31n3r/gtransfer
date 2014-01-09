Name:		gtransfer
Version:	0.3.0BETA1
#Version:	0.2.3
Release:	1%{?dist}
Summary:	Advanced data transfer tool for GridFTP
Group:		base
License:	GPLv3
URL:		https://github.com/fscheiner/%{name}
Source0:	https://github.com/fscheiner/%{name}/archive/v%{version}.tar.gz
#URL:		https://github.com/fr4nk5ch31n3r/%{name}
#Source0:	https://github.com/fr4nk5ch31n3r/%{name}/archive/v%{version}.tar.gz
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:	noarch
Requires:	coreutils,grep,sed,telnet,tgftp,uberftp,globus-gass-copy-progs

%description
gtransfer - An advanced data transfer tool for GridFTP. gtransfer is a wrapper
for globus-url-copy and tgftp and provides several features that make it 
easy and comfortable to use, allow rerouting of data transfer for improved
performance or crossing network domains and provide improved performance.

%prep
%setup -q -n %{name}-%{version}

%install
rm -rf %{buildroot}
#  Create needed directories
mkdir -p %{buildroot}%{_sysconfdir}/%{name}
mkdir -p %{buildroot}%{_sysconfdir}/%{name}/pids
mkdir -p %{buildroot}%{_sysconfdir}/%{name}/aliases
mkdir -p %{buildroot}%{_sysconfdir}/bash_completion.d
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_libexecdir}/%{name}
mkdir -p %{buildroot}%{_datadir}/%{name}/pids
mkdir -p %{buildroot}%{_mandir}/man1
mkdir -p %{buildroot}%{_mandir}/man5

################################################################################
# Install all files
################################################################################
# * Configuration files
################################################################################
cp etc/gtransfer/gtransfer.conf %{buildroot}%{_sysconfdir}/%{name}/
cp etc/gtransfer/dpath.conf %{buildroot}%{_sysconfdir}/%{name}/
cp etc/gtransfer/dparam.conf %{buildroot}%{_sysconfdir}/%{name}/
cp etc/gtransfer/dpath.template %{buildroot}%{_sysconfdir}/%{name}/
cp etc/gtransfer/chunkConfig %{buildroot}%{_sysconfdir}/%{name}/
cp etc/gtransfer/pids/irodsMicroService_mappingFile %{buildroot}%{_sysconfdir}/%{name}/pids/
cp etc/gtransfer/aliases.conf %{buildroot}%{_sysconfdir}/%{name}/

cp etc/bash_completion.d/gtransfer.sh %{buildroot}%{_sysconfdir}/bash_completion.d/

################################################################################
# * Bash libraries
################################################################################
cp lib/gtransfer/autoOptimization.bashlib %{buildroot}%{_datadir}/%{name}/
cp lib/gtransfer/exitCodes.bashlib %{buildroot}%{_datadir}/%{name}/
cp lib/gtransfer/helperFunctions.bashlib %{buildroot}%{_datadir}/%{name}/
cp lib/gtransfer/listTransfer.bashlib %{buildroot}%{_datadir}/%{name}/
cp lib/gtransfer/urlTransfer.bashlib %{buildroot}%{_datadir}/%{name}/
cp lib/gtransfer/alias.bashlib %{buildroot}%{_datadir}/%{name}/
cp lib/gtransfer/pids/irodsMicroService.bashlib %{buildroot}%{_datadir}/%{name}/pids/

################################################################################
# * Tools and symlinks
################################################################################
cp bin/gtransfer.sh %{buildroot}%{_bindir}/
cp bin/datapath.sh %{buildroot}%{_bindir}/
cp bin/defaultparam.sh %{buildroot}%{_bindir}/
cp bin/halias.bash %{buildroot}%{_bindir}/
ln -s gtransfer.sh %{buildroot}%{_bindir}/gtransfer
ln -s gtransfer.sh %{buildroot}%{_bindir}/gt
ln -s datapath.sh %{buildroot}%{_bindir}/dpath
ln -s defaultparam.sh %{buildroot}%{_bindir}/dparam
ln -s halias.bash %{buildroot}%{_bindir}/halias

################################################################################
# * Additional (internal) tools
################################################################################
cp libexec/getPidForUrl.r %{buildroot}%{_libexecdir}/%{name}/
cp libexec/getUrlForPid.r %{buildroot}%{_libexecdir}/%{name}/

################################################################################
# * Manpages
################################################################################
cp share/man/man1/gtransfer.1 %{buildroot}%{_mandir}/man1/
cp share/man/man1/gt.1 %{buildroot}%{_mandir}/man1/
cp share/man/man1/dpath.1 %{buildroot}%{_mandir}/man1/
cp share/man/man5/dpath.5 %{buildroot}%{_mandir}/man5/
cp share/man/man1/dparam.1 %{buildroot}%{_mandir}/man1/
cp share/man/man5/dparam.5 %{buildroot}%{_mandir}/man5/
cp share/man/man1/halias.1 %{buildroot}%{_mandir}/man1/

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)

%config %{_sysconfdir}/%{name}/gtransfer.conf
%config %{_sysconfdir}/%{name}/dpath.conf
%config %{_sysconfdir}/%{name}/dparam.conf
%config %{_sysconfdir}/%{name}/dpath.template
%config %{_sysconfdir}/%{name}/chunkConfig

%doc README.md COPYING ChangeLog share/doc/dparam.1.md share/doc/dparam.5.md share/doc/dpath.1.md share/doc/dpath.5.md share/doc/gtransfer.1.md share/doc/halias.1.md share/doc/host_aliases.md share/doc/persistent_identifiers.md share/doc/images/multi-step_transfer.png

%{_sysconfdir}/%{name}
%{_sysconfdir}/bash_completion.d
%{_sysconfdir}/bash_completion.d/gtransfer.sh

%{_bindir}/gtransfer.sh
%{_bindir}/gtransfer
%{_bindir}/gt
%{_bindir}/datapath.sh
%{_bindir}/dpath
%{_bindir}/defaultparam.sh
%{_bindir}/dparam
%{_bindir}/halias.bash
%{_bindir}/halias

%{_libexecdir}/%{name}
%{_libexecdir}/%{name}/getPidForUrl.r
%{_libexecdir}/%{name}/getUrlForPid.r

%{_datadir}/%{name}
%{_datadir}/%{name}/autoOptimization.bashlib
%{_datadir}/%{name}/exitCodes.bashlib
%{_datadir}/%{name}/helperFunctions.bashlib
%{_datadir}/%{name}/listTransfer.bashlib
%{_datadir}/%{name}/urlTransfer.bashlib
%{_datadir}/%{name}/alias.bashlib
%{_datadir}/%{name}/pids/irodsMicroService.bashlib

%{_mandir}/man1/gtransfer.1.gz
%{_mandir}/man1/gt.1.gz
%{_mandir}/man1/dpath.1.gz
%{_mandir}/man5/dpath.5.gz
%{_mandir}/man1/dparam.1.gz
%{_mandir}/man5/dparam.5.gz
%{_mandir}/man1/halias.1.gz

%changelog
* Thu Nov 14 2013 Frank Scheiner <scheiner@hlrs.de> 0.3.0BETA1-1
- Added spec file to gtransfer repo. Bash libraries (architecture independent files) are now stored below "/usr/share/gtransfer".

* Thu Nov 14 2013 Frank Scheiner <scheiner@hlrs.de> 0.2.2-2
- Added missing aliases.conf and aliases dir to RPM.

* Thu Nov 14 2013 Frank Scheiner <scheiner@hlrs.de> 0.2.2-1
- Updated source package and version number to upstream version.

* Tue Oct 08 2013 Frank Scheiner <scheiner@hlrs.de> 0.2.0-1
- Updated source package and version number to upstream version. Included new files.

* Fri Apr 05 2013 Frank Scheiner <scheiner@hlrs.de> 0.1.2-2
- Added missing chunkconfig file to RPM.

* Fri Jan 25 2013 Frank Scheiner <scheiner@hlrs.de> 0.1.2-1
- Updated source package and version number to upstream version.

* Thu Jan 24 2013 Frank Scheiner <scheiner@hlrs.de> 0.1.1-1
- Updated source package and version number to upstream version.

* Fri Jan 18 2013 Frank Scheiner <scheiner@hlrs.de> 0.1.0-1
- Updated source package and version number to upstream version. Also included used bash libs. Updated name of bash completion file. Updated dir structure.

* Mon Nov 19 2012 Frank Scheiner <scheiner@hlrs.de> 0.0.10a-1
- Updated source package and version number to upstream version.

* Thu Nov 15 2012 Frank Scheiner <scheiner@hlrs.de> 0.0.10-1
- Updated source package and version number to upstream version.

* Mon Nov 05 2012 Frank Scheiner <scheiner@hlrs.de> 0.0.9c-1
- Updated source package and version number to upstream version. Also updated README name.

* Fri Oct 03 2012 Frank Scheiner <scheiner@hlrs.de> 0.0.9b-1
- Updated source package and version number.

* Fri Oct 03 2012 Frank Scheiner <scheiner@hlrs.de> 0.0.9a-1
- Updated source package and version number. Added bash_completion file.

* Fri Sep 21 2012 Frank Scheiner <scheiner@hlrs.de> 0.0.9-1
- Initial RPM package build for OBS

