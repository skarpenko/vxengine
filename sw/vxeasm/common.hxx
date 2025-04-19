/*
 * Copyright (c) 2020-2025 The VxEngine Project. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/*
 * VxEngine common constants
 */

#include <string>
#pragma once


////////////// Keywords //////////////////

// Commands
const std::string SETACC = "setacc";
const std::string SETVL = "setvl";
const std::string SETRS = "setrs";
const std::string SETRT = "setrt";
const std::string SETRD = "setrd";
const std::string SETEN = "seten";
const std::string PROD = "prod";
const std::string STORE = "store";
const std::string SYNC = "sync";
const std::string NOP = "nop";
const std::string RELU = "relu";
const std::string LRELU = "lrelu";
// Operands
const std::string CLR = "clr";
const std::string SET = "set";
const std::string INT = "int";
const std::string NOINT = "noint";
const std::string STOP = "stop";
const std::string NOSTOP = "nostop";
const std::string VPU0 = "vpu0";
const std::string VPU1 = "vpu1";
const std::string TH0 = "th0";
const std::string TH1 = "th1";
const std::string TH2 = "th2";
const std::string TH3 = "th3";
const std::string TH4 = "th4";
const std::string TH5 = "th5";
const std::string TH6 = "th6";
const std::string TH7 = "th7";
