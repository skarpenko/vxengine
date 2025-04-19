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
 * VxEngine disassembler
 */

#include <cstdint>
#include <cstring>
#include <stdexcept>
#include <iostream>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <vector>
#include "vxe_instr.hxx"
#include "common.hxx"


////////////// Constants /////////////////
constexpr int WIDTH = 40;
constexpr int IWIDTH = 10;

/////////////////////////////////////////


void load_file(const std::string& filename, bool hex, std::vector<uint64_t>& binary)
{
	std::ios::openmode mode = std::ios::in;

	if(!hex)
		mode |= std::ios::binary;

	std::ifstream ifs(filename, mode);
	if(!ifs.is_open())
		throw std::runtime_error(std::string("error: failed to open '")
			+ filename + "'");

	if(!hex) {
		ifs.seekg(0, std::ios::end);
		std::streamsize size = ifs.tellg();
		if(!size)
			throw std::runtime_error(std::string("error: empty file"));
		ifs.seekg(0, std::ios::beg);

		if(size % sizeof(uint64_t)) size += sizeof(uint64_t);

		binary.resize(size/sizeof(uint64_t));
		ifs.read(reinterpret_cast<char*>(binary.data()), size);
	} else {
		binary.clear();
		std::string line;
		while(std::getline(ifs, line)) {
			if(line.empty() || line[0] == '@')
				continue;

			std::string hex = std::string("0x") + line;
			uint64_t v;
			size_t pos;

			try {
				v = stoull(hex, &pos, 0);
				if(pos != hex.size())
					throw std::runtime_error("");
			}
			catch(...) {
				throw std::runtime_error(std::string("invalid hex value '")
					+ hex + "'");
			}

			binary.push_back(v);
		}
	}
}


void parse_dst(unsigned dst, unsigned& vpu, unsigned& th)
{
	th = dst & 0x07;
	vpu = (dst >> 3) & 0x1f;
}


void finalize(uint64_t inst, const std::string& str, std::ostream& os)
{
	os << str;
	if(str.size() < WIDTH)
		os << std::string(WIDTH - str.size(), ' ');
	else
		os << ' ';
	os << "; 0x" << std::hex << std::setw(16) << std::setfill('0')
		<< inst << std::endl;
}


size_t ident(const std::string& inst)
{
	size_t r = 1;
	if(inst.size() < IWIDTH)
		r = IWIDTH - inst.size();
	return r;
}


void disasm_relu(uint64_t inst, std::ostream& os)
{
	std::stringstream ss;
	relu iw = generic(inst);
	std::string istr = RELU;
	unsigned vpu, th;

	parse_dst(iw.dst, vpu, th);

	ss << istr;
	if(th)
		ss << std::string(ident(istr), ' ') << "vpu" << vpu;

	finalize(inst, ss.str(), os);
}


void disasm_lrelu(uint64_t inst, std::ostream& os)
{
	std::stringstream ss;
	lrelu iw = generic(inst);
	std::string istr = LRELU;
	unsigned vpu, th;
	int ed = 0;

	parse_dst(iw.dst, vpu, th);

	if(iw.ed) ed = ~0x7f | iw.ed;

	ss << istr;
	if(th)
		ss << std::string(ident(istr), ' ') << "vpu" << vpu << ", " << ed;
	else
		ss << std::string(ident(istr), ' ') << ed;

	finalize(inst, ss.str(), os);
}


void disasm_af(uint64_t inst, std::ostream& os)
{
	generic_af iw = generic(inst);
	if(iw.af == relu::AF)
		disasm_relu(inst, os);
	else if(iw.af == lrelu::AF)
		disasm_lrelu(inst, os);
	else
		finalize(inst, "<unknown af code>", os);
}


void disasm_nop(uint64_t inst, std::ostream& os)
{
	finalize(inst, NOP, os);
}


void disasm_setacc(uint64_t inst, std::ostream& os)
{
	std::stringstream ss;
	setacc iw = generic(inst);
	std::string istr = SETACC;
	unsigned vpu, th;
	union cvt {
		float a;
		uint32_t b;
	};
	cvt c;
	c.b = iw.acc;

	parse_dst(iw.dst, vpu, th);

	ss << istr << std::string(ident(istr), ' ')
		<< "vpu" << vpu
		<< ", th" << th
		<< ", " << c.a;

	finalize(inst, ss.str(), os);
}


void disasm_setvl(uint64_t inst, std::ostream& os)
{
	std::stringstream ss;
	setvl iw = generic(inst);
	std::string istr = SETVL;
	unsigned vpu, th;

	parse_dst(iw.dst, vpu, th);

	ss << istr << std::string(ident(istr), ' ')
		<< "vpu" << vpu
		<< ", th" << th
		<< ", " << iw.len;

	finalize(inst, ss.str(), os);
}


void disasm_setrs(uint64_t inst, std::ostream& os)
{
	std::stringstream ss;
	setrs iw = generic(inst);
	std::string istr = SETRS;
	unsigned vpu, th;
	uint64_t addr;

	parse_dst(iw.dst, vpu, th);

	addr = iw.addr << 2;

	ss << istr << std::string(ident(istr), ' ')
		<< "vpu" << vpu
		<< ", th" << th
		<< ", 0x" << std::hex << addr;

	finalize(inst, ss.str(), os);
}


void disasm_setrt(uint64_t inst, std::ostream& os)
{
	std::stringstream ss;
	setrt iw = generic(inst);
	std::string istr = SETRT;
	unsigned vpu, th;
	uint64_t addr;

	parse_dst(iw.dst, vpu, th);

	addr = iw.addr << 2;

	ss << istr << std::string(ident(istr), ' ')
		<< "vpu" << vpu
		<< ", th" << th
		<< ", 0x" << std::hex << addr;

	finalize(inst, ss.str(), os);
}


void disasm_setrd(uint64_t inst, std::ostream& os)
{
	std::stringstream ss;
	setrd iw = generic(inst);
	std::string istr = SETRD;
	unsigned vpu, th;
	uint64_t addr;

	parse_dst(iw.dst, vpu, th);

	addr = iw.addr << 2;

	ss << istr << std::string(ident(istr), ' ')
		<< "vpu" << vpu
		<< ", th" << th
		<< ", 0x" << std::hex << addr;

	finalize(inst, ss.str(), os);
}


void disasm_seten(uint64_t inst, std::ostream& os)
{
	std::stringstream ss;
	seten iw = generic(inst);
	std::string istr = SETEN;
	unsigned vpu, th;

	parse_dst(iw.dst, vpu, th);

	ss << istr << std::string(ident(istr), ' ')
		<< "vpu" << vpu
		<< ", th" << th
		<< ", " << (iw.en ? SET : CLR);

	finalize(inst, ss.str(), os);
}


void disasm_prod(uint64_t inst, std::ostream& os)
{
	std::stringstream ss;
	prod iw = generic(inst);
	std::string istr = PROD;
	unsigned vpu, th;

	parse_dst(iw.dst, vpu, th);

	ss << istr;
	if(th)
		ss << std::string(ident(istr), ' ') << "vpu" << vpu;

	finalize(inst, ss.str(), os);
}


void disasm_store(uint64_t inst, std::ostream& os)
{
	std::stringstream ss;
	store iw = generic(inst);
	std::string istr = STORE;
	unsigned vpu, th;

	parse_dst(iw.dst, vpu, th);

	ss << istr;
	if(th)
		ss << std::string(ident(istr), ' ') << "vpu" << vpu;

	finalize(inst, ss.str(), os);
}


void disasm_sync(uint64_t inst, std::ostream& os)
{
	std::stringstream ss;
	sync iw = generic(inst);
	std::string istr = SYNC;

	ss << istr << std::string(ident(istr), ' ')
		<< (iw.stop ? STOP : NOSTOP) << ", "
		<< (iw.intr ? INT : NOINT);

	finalize(inst, ss.str(), os);
}


void disasm_unkn(uint64_t inst, std::ostream& os)
{
	finalize(inst, "<unknown code>", os);
}


void disassemble(const std::vector<uint64_t>& binary, std::ostream& os)
{
	for(uint64_t inst : binary) {
		generic g(inst);
		switch(g.op) {
			case generic_af::OP:
				disasm_af(g, os);
				break;
			case nop::OP:
				disasm_nop(g, os);
				break;
			case setacc::OP:
				disasm_setacc(g, os);
				break;
			case setvl::OP:
				disasm_setvl(g, os);
				break;
			case setrs::OP:
				disasm_setrs(g, os);
				break;
			case setrt::OP:
				disasm_setrt(g, os);
				break;
			case setrd::OP:
				disasm_setrd(g, os);
				break;
			case seten::OP:
				disasm_seten(g, os);
				break;
			case prod::OP:
				disasm_prod(g, os);
				break;
			case store::OP:
				disasm_store(g, os);
				break;
			case sync::OP:
				disasm_sync(g, os);
				break;
			default:
				disasm_unkn(g, os);
				break;
		}
	}
}


void print_help()
{
	std::cout << "VxE disassembler" << std::endl;
	std::cout << "vxedisasm -o outfile -x filename" << std::endl << std::endl
		<< "-h           display this information" << std::endl
		<< "-x           use hex input format" << std::endl
		<< "-o outfile   write output to an outfile instead of stdout" << std::endl
		<< std::endl;
}


int main(int argc, char **argv)
{
	bool hex_input = false;
	std::string file;
	std::string output;

	if(argc < 2) {
		std::cerr << "error: no input file specified" << std::endl
			<< "type `vxedisasm -h' for help" << std::endl;
		return -1;
	}

	// Parse command line
	for(int i = 1; i < argc; ++i) {
		if(argv[i][0] == '-') {
			if(std::strlen(argv[i]) > 2 || std::strlen(argv[i]) == 1) {
				std::cerr << "error: invalid option '"
					<< argv[i] << "'";
				return -1;
			}

			if(argv[i][1] == 'h') {
				print_help();
				return 0;
			} else if(argv[i][1] == 'o') {
				++i;

				if(i == argc) {
					std::cerr << "error: missing argument for '-o'"
						<< std::endl;
					return -1;
				}

				output = argv[i];
			} else if(argv[i][1] == 'x') {
				hex_input = true;
			} else {
				std::cerr << "error: invalid option '" << argv[i]
					<< "'" << std::endl;
					return -1;
			}
		} else {
			file = argv[i];
		}
	}


	std::vector<uint64_t> binary;

	// Load file
	try {
		load_file(file, hex_input, binary);
	}
	catch(const std::exception& e)
	{
		std::cerr << e.what() << std::endl;
		return -1;
	}

	// Disassembly
	if(!output.empty()) {
		std::ofstream ofs(output);
		if(!ofs.is_open()) {
			std::cerr << "error: failed to open '" << output << "'" << std::endl;
			return -1;
		}
		disassemble(binary, ofs);
	} else {
		disassemble(binary, std::cout);
	}

	return 0;
}
