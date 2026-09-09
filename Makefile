CXX ?= c++
PKG_CONFIG ?= pkg-config
QT_LIBEXEC := $(shell $(PKG_CONFIG) --variable=libexecdir Qt6Core)
QT_FLAGS := $(shell $(PKG_CONFIG) --cflags --libs Qt6Quick Qt6Qml Qt6Gui)

.PHONY: all check
all: native/liboshelf-native.so

build/drag.moc: native/drag.cpp
	@$(PKG_CONFIG) --atleast-version=6.8 Qt6Quick
	mkdir -p build
	$(QT_LIBEXEC)/moc $(shell $(PKG_CONFIG) --cflags Qt6Qml Qt6Quick) $< -o $@

native/liboshelf-native.so: native/drag.cpp build/drag.moc
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -std=c++17 -O2 -Wall -Wextra -Wpedantic -fPIC -shared -Ibuild $< -o build/liboshelf-native.so $(LDFLAGS) $(QT_FLAGS)
	mv build/liboshelf-native.so $@

check: all
	omarchy plugin validate .
	node --test tests/payload.test.cjs
	python3 tests/metadata_test.py
	python3 tests/install_test.py
