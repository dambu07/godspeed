Name:           godspeed
Version:        0.7.0
Release:        1%{?dist}
Summary:        Ultimate Full-Stack Development Environment
License:        MIT
URL:            https://github.com/dambu07/godspeed
Source0:        %{name}-%{version}.tar.gz
Requires:       bash >= 4.0, git, curl, jq
BuildArch:      noarch

%description
Godspeed is an AI-powered development environment.

%prep
%autosetup

%build

%install
mkdir -p %{buildroot}%{_bindir}
install -m 755 godspeed.sh %{buildroot}%{_bindir}/godspeed

%files
%license LICENSE
%doc README.md
%{_bindir}/godspeed

%changelog
* Fri Aug 15 2025 Godspeed Team <maintainer@godspeed.sh> - 0.7.0-1
- Initial package
