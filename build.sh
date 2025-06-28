#!/bin/bash

rm -f icky

valac --pkg gtk4 --pkg gio-2.0 --pkg gio-unix-2.0 --pkg posix -o icky icky.vala
