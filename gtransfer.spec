Name:		gtransfer
Version:	0.5.0
Release:	1%{?dist}
Summary:	Advanced data transfer tool for GridFTP
Group:		base
License:	GPLv3
URL:		https://github.com/fr4nk5ch31n3r/%{name}
Source0:	https://github.com/fr4nk5ch31n3r/%{name}/archive/v%{version}.tar.gz
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:	noarch
Requires:	coreutils,grep,sed,telnet,tgftp,uberftp,globus-gass-copy-progs

%description
gtransfer - An advanced data transfer tool for GridFTP. Gtransfer is a wrapper
for tgftp (which itself wraps globus-url-copy) and also uses functionality of
uberftp. Gtransfer provides several features that make it easy and comfortable
to use, that allow rerouting of data transfers for improved performance or
crossing network domains and that also allow for high-performance data
transfers.

%prep
%setup -q -n %{name}-%{version}

%install
rm -rf %{buildroot}
# Create needed directories
mkdir -p %{buildroot}%{_sysconfdir}/%{name}
mkdir -p %{buildroot}%{_sysconfdir}/%{name}/pids
mkdir -p %{buildroot}%{_sysconfdir}/%{name}/aliases
mkdir -p %{buildroot}%{_sysconfdir}/bash_completion.d
mkdir -p %{buildroot}%{_bindir}
# SLES does not have a "libexec" dir!
%if 0%{?rhel}
	mkdir -p %{buildroot}%{_libexecdir}/%{name}
%endif	
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
cp lib/gtransfer/multipathing.bashlib %{buildroot}%{_datadir}/%{name}/

################################################################################
# * Tools and symlinks
################################################################################
cp bin/gtransfer.bash %{buildroot}%{_bindir}/
cp bin/datapath.bash %{buildroot}%{_bindir}/
cp bin/defaultparam.bash %{buildroot}%{_bindir}/
cp bin/halias.bash %{buildroot}%{_bindir}/
cp bin/gtransfer-version.bash %{buildroot}%{_bindir}/
ln -s gtransfer.bash %{buildroot}%{_bindir}/gtransfer
ln -s gtransfer.bash %{buildroot}%{_bindir}/gt
ln -s datapath.bash %{buildroot}%{_bindir}/dpath
ln -s defaultparam.bash %{buildroot}%{_bindir}/dparam
ln -s halias.bash %{buildroot}%{_bindir}/halias
ln -s gtransfer-version.bash %{buildroot}%{_bindir}/gt-version

################################################################################
# * Additional (internal) tools
################################################################################
%if 0%{?rhel}
	cp libexec/getPidForUrl.r %{buildroot}%{_libexecdir}/%{name}/
	cp libexec/getUrlForPid.r %{buildroot}%{_libexecdir}/%{name}/
	cp libexec/packBinsNew.py %{buildroot}%{_libexecdir}/%{name}/
%endif
# SLES does not have a "libexec" dir!
%if 0%{?suse_version}
	cp libexec/getPidForUrl.r %{buildroot}%{_datadir}/%{name}/
	cp libexec/getUrlForPid.r %{buildroot}%{_datadir}/%{name}/
	cp libexec/packBinsNew.py %{buildroot}%{_datadir}/%{name}/
%endif

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
%config %{_sysconfdir}/%{name}/pids/irodsMicroService_mappingFile
%config %{_sysconfdir}/%{name}/aliases.conf
%config %{_sysconfdir}/bash_completion.d/gtransfer.sh

%doc README.md COPYING ChangeLog share/doc/dparam.1.md share/doc/dparam.5.md share/doc/dpath.1.md share/doc/dpath.5.md share/doc/gtransfer.1.md share/doc/halias.1.md share/doc/host-aliases.md share/doc/persistent-identifiers.md share/doc/images/multi-step-transfer.png share/doc/images/multipathing-transfer.png

%{_sysconfdir}/%{name}
%{_sysconfdir}/bash_completion.d
%{_sysconfdir}/bash_completion.d/gtransfer.sh

%{_bindir}/gtransfer.bash
%{_bindir}/gtransfer
%{_bindir}/gt
%{_bindir}/datapath.bash
%{_bindir}/dpath
%{_bindir}/defaultparam.bash
%{_bindir}/dparam
%{_bindir}/halias.bash
%{_bindir}/halias
%{_bindir}/gtransfer-version.bash
%{_bindir}/gt-version

%if 0%{?rhel}
	%{_libexecdir}/%{name}
	%{_libexecdir}/%{name}/getPidForUrl.r
	%{_libexecdir}/%{name}/getUrlForPid.r
	%{_libexecdir}/%{name}/packBinsNew.py
%endif

%{_datadir}/%{name}
%{_datadir}/%{name}/autoOptimization.bashlib
%{_datadir}/%{name}/exitCodes.bashlib
%{_datadir}/%{name}/helperFunctions.bashlib
%{_datadir}/%{name}/listTransfer.bashlib
%{_datadir}/%{name}/urlTransfer.bashlib
%{_datadir}/%{name}/alias.bashlib
%{_datadir}/%{name}/pids/irodsMicroService.bashlib
%{_datadir}/%{name}/multipathing.bashlib
%if 0%{?suse_version}
	%{_datadir}/%{name}
	%{_datadir}/%{name}/getPidForUrl.r
	%{_datadir}/%{name}/getUrlForPid.r
	%{_datadir}/%{name}/packBinsNew.py
%endif

%{_mandir}/man1/gtransfer.1.gz
%{_mandir}/man1/gt.1.gz
%{_mandir}/man1/dpath.1.gz
%{_mandir}/man5/dpath.5.gz
%{_mandir}/man1/dparam.1.gz
%{_mandir}/man5/dparam.5.gz
%{_mandir}/man1/halias.1.gz

%changelog
* Thu Apr 12 2016 Frank Scheiner <scheiner@hlrs.de> 0.5.1-1
- Updated source version number to new patch level.

* Thu Apr 12 2016 Frank Scheiner <scheiner@hlrs.de> 0.5.0-1
- Updated source package and version number to new release.

* Wed Jan 27 2016 Frank Scheiner <scheiner@hlrs.de> 0.4.1-1
- Updated source version number to new patch level.

* Thu Sep 17 2015 Frank Scheiner <scheiner@hlrs.de> 0.4.0-1
- Updated source package and version number to new release.

* Fri Apr 24 2015 Frank Scheiner <scheiner@hlrs.de> 0.3.0-2
- Changed if clauses to detect all RHEL compatible distributions (Scientific Linux was missing).

* Thu Apr 23 2015 Frank Scheiner <scheiner@hlrs.de> 0.3.0-1
- Updated source package and version number to new release.

* Thu Apr 23 2015 Frank Scheiner <scheiner@hlrs.de> 0.3.0RC2-1
- Introduced specific behaviour for SLES and RHEL compatible. Also added "%%config" tags for some config files.

* Fri Apr 17 2015 Frank Scheiner <scheiner@hlrs.de> 0.3.0RC1-1
- Updated source package and version number to upstream version.

* Fri Jan 16 2015 Frank Scheiner <scheiner@hlrs.de> 0.3.0BETA4-1
- Updated spec file to include new multipathing support and gt-version tool.

* Fri Jul 25 2014 Frank Scheiner <scheiner@hlrs.de> 0.3.0BETA3-1
- Updated source package and version number to upstream version.

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

