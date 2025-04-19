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
 * VxEngine assembler
 */

#include <cstdint>
#include <cctype>
#include <cstring>
#include <stdexcept>
#include <iostream>
#include <fstream>
#include <iomanip>
#include <algorithm>
#include <vector>
#include "vxe_instr.hxx"
#include "common.hxx"


////////////// Globals //////////////////
std::string file;

/////////////////////////////////////////


std::string g_err_msg(int line, int col, const std::string& str)
{
	std::string err = file + ":" + std::to_string(line)
		+ ":" + std::to_string(col) + ": error: " + str;
	return err;
}


// Token
struct token {
	std::string tok;
	int line;
	int start_col, end_col;

	std::string lc() const
	{
		std::string cpy = tok;
		std::transform(cpy.begin(), cpy.end(), cpy.begin(),
			[](unsigned char c){ return std::tolower(c); });
		return cpy;
	}

	std::string err_msg(const std::string& str) const
	{
		return g_err_msg(line, start_col, str);
	}

	uint64_t to_uint64(const std::string& name = "unsigned") const
	{
		uint64_t r = 0;

		try {
			size_t pos;
			r = stoull(tok, &pos, 0);
			if(pos != tok.size())
				throw std::runtime_error("");
		}
		catch(...) {
			std::string msg = std::string("invalid ") + name + " '"
				+ tok + "'";
			throw std::runtime_error(err_msg(msg));
		}

		return r;
	}

	int to_int(bool neg = false, const std::string& name = "integer") const
	{
		int r = 0;

		try {
			size_t pos;
			r = stoi(tok, &pos, 0);
			if(pos != tok.size())
				throw std::runtime_error("");
		}
		catch(...) {
			std::string msg = std::string("invalid ") + name + " '"
				+ tok + "'";
			throw std::runtime_error(err_msg(msg));
		}

		if(neg && r > 0) {
			std::string msg = std::string("must be negative ") + name
				+ " '" + tok + "'";
			throw std::runtime_error(err_msg(msg));
		}

		return r;
	}


	unsigned long to_uint(const std::string& name = "unsigned") const
	{
		unsigned long r = 0;

		try {
			size_t pos;
			r = stoul(tok, &pos, 0);
			if(pos != tok.size())
				throw std::runtime_error("");
		}
		catch(...) {
			std::string msg = std::string("invalid ") + name + " '"
				+ tok + "'";
			throw std::runtime_error(err_msg(msg));
		}

		return r;
	}


	float to_float(const std::string& name = "float") const
	{
		float r = 0;

		try {
			size_t pos;
			r = stof(tok, &pos);
			if(pos != tok.size())
				throw std::runtime_error("");
		}
		catch(...) {
			std::string msg = std::string("invalid ") + name + " '"
				+ tok + "'";
			throw std::runtime_error(err_msg(msg));
		}

		return r;
	}
};


// Command
struct command {
	token opcode;
	std::vector<token> operands;
};


size_t parse_operand(int line_no, size_t col, const std::string& line, token& tok)
{
	size_t i = col;
	int start = -1;
	int end = -1;
	bool must_exist = false;	// Operand definition must exist
	size_t comma;

	tok.tok.clear();

	// Look for operand start
	for(; i < line.size(); ++i) {
		if(isalnum(line[i]) || line[i] == '-' || line[i] == '+' ) {
			start = i;
			break;
		} else if(!isspace(line[i])) {
			if(line[i] == ',') {
				must_exist = true;
				comma = i;
				continue;
			}
			if(line[i] == ';')
				return line.size();	// Line parsing done

			// Parsing error - unexpected character
			std::string msg = std::string("unexpected '") + line[i]
				+ "'";
			throw std::runtime_error(g_err_msg(line_no, i, msg));
			return 0;
		}
	}

	if(i == line.size()) {
		if(must_exist) {
			// Parsing error - missing operand
			std::string msg = std::string("expected operand after ','");
			throw std::runtime_error(g_err_msg(line_no, comma, msg));
			return 0;
		}
		return i;
	}

	// Look for operand end
	for(; i < line.size(); ++i) {
		if(isspace(line[i])) {
			if(end < 0) end = i - 1;
			break;
		} else if(!isalnum(line[i])) {
			if(line[i] == '.' || line[i] == '-' || line[i] == '+' )
				continue;
			if(line[i] == ';' || line[i] == ',') {
				if(end < 0) end = i - 1;
				break;
			}

			// Parsing error - unexpected character
			std::string msg = std::string("unexpected '") + line[i]
				+ "'";
			throw std::runtime_error(g_err_msg(line_no, i, msg));
			return 0;
		}
	}

	if(i == line.size())
		end = line.size() - 1;

	// Return parsed token
	tok.tok = line.substr(start, end - start + 1);
	tok.line = line_no;
	tok.start_col = start;
	tok.end_col = end;

	return i;
}


size_t parse_command(int line_no, const std::string& line, token& tok)
{
	size_t i = 0;
	int start = -1;
	int end = -1;

	tok.tok.clear();

	// Look for opcode start
	for(; i < line.size(); ++i) {
		if(isalnum(line[i]) || line[i] == '.') {
			start = i;
			break;
		} else if(!isspace(line[i])) {
			if(line[i] == ';')
				return line.size();	// Line parsing done

			// Parsing error - unexpected character
			std::string msg = std::string("unexpected '") + line[i]
				+ "'";
			throw std::runtime_error(g_err_msg(line_no, i, msg));
			return 0;
		}
	}

	if(i == line.size()) return i;	// Reached end of line?

	// Look for opcode end
	for(; i < line.size(); ++i) {
		if(isspace(line[i])) {
			end = i - 1;
			break;
		} else if(!isalnum(line[i])) {
			if(line[i] == '.')
				continue;
			if(line[i] == ';') {
				end = i - 1;
				break;
			}

			// Parsing error - unexpected character
			std::string msg = std::string("unexpected '") + line[i]
				+ "'";
			throw std::runtime_error(g_err_msg(line_no, i, msg));
			return 0;
		}
	}

	if(i == line.size())
		end = line.size() - 1;

	// Return parsed token
	tok.tok = line.substr(start, end - start + 1);
	tok.line = line_no;
	tok.start_col = start;
	tok.end_col = end;

	return i;
}


bool parse_line(int line_no, const std::string& line, command& cmd)
{
	if(line.empty())
		return false;

	cmd.operands.clear();

	token opcode;

	size_t pos = parse_command(line_no, line, opcode);
	if(opcode.tok.empty())
		return false;

	cmd.opcode = opcode;

	while(pos < line.size()) {
		token operand;
		pos = parse_operand(line_no, pos, line, operand);
		if(!operand.tok.empty())
			cmd.operands.push_back(operand);
	}

	return true;
}


unsigned to_vpu_no(const token& tok)
{
	unsigned vpu = 0;

	if(tok.lc() == VPU0) {
		vpu = 0;
	} else if(tok.lc() == VPU1) {
		vpu = 1;
	} else {
		std::string msg = std::string("invalid destination VPU '")
			+ tok.tok + "'. Must be 'vpu[0-1]'.";
		throw std::runtime_error(tok.err_msg(msg));
	}

	return vpu;
}


unsigned to_th_no(const token& tok)
{
	unsigned th = 0;

	if(tok.lc() == TH0) {
		th = 0;
	} else if(tok.lc() == TH1) {
		th = 1;
	} else if(tok.lc() == TH2) {
		th = 2;
	} else if(tok.lc() == TH3) {
		th = 3;
	} else if(tok.lc() == TH4) {
		th = 4;
	} else if(tok.lc() == TH5) {
		th = 5;
	} else if(tok.lc() == TH6) {
		th = 6;
	} else if(tok.lc() == TH7) {
		th = 7;
	} else {
		std::string msg = std::string("invalid destination thread '")
			+ tok.tok + "'. Must be 'th[0-7]'.";
		throw std::runtime_error(tok.err_msg(msg));
	}

	return th;
}


unsigned mkdst(unsigned vpu, unsigned th)
{
	vpu &= 0x1f;
	th &= 0x7;
	return (vpu << 3) | th;
}


bool get_clr_set(const token& tok)
{
	bool r;

	if(tok.lc() == SET) {
		r = true;
	} else if(tok.lc() == CLR) {
		r = false;
	} else {
		std::string msg = std::string("invalid operand '")
			+ tok.tok + "'. Must be 'clr' or 'set'.";
		throw std::runtime_error(tok.err_msg(msg));
	}

	return r;
}


bool get_int_noint(const token& tok)
{
	bool r;

	if(tok.lc() == INT) {
		r = true;
	} else if(tok.lc() == NOINT) {
		r = false;
	} else {
		std::string msg = std::string("invalid operand '")
			+ tok.tok + "'. Must be 'int' or 'noint'.";
		throw std::runtime_error(tok.err_msg(msg));
	}

	return r;
}


bool get_stop_nostop(const token& tok)
{
	bool r;

	if(tok.lc() == STOP) {
		r = true;
	} else if(tok.lc() == NOSTOP) {
		r = false;
	} else {
		std::string msg = std::string("invalid operand '")
			+ tok.tok + "'. Must be 'stop' or 'nostop'.";
		throw std::runtime_error(tok.err_msg(msg));
	}

	return r;
}


uint64_t code_gen_setacc(const command& cmd)
{
	unsigned vpu;
	unsigned th;
	float acc;

	if(cmd.operands.size() != 3)
		throw std::runtime_error(g_err_msg(cmd.opcode.line, cmd.opcode.start_col,
			SETACC + " instruction requires three operands."));

	vpu = to_vpu_no(cmd.operands[0]);
	th = to_th_no(cmd.operands[1]);
	acc = cmd.operands[2].to_float();

	return setacc(mkdst(vpu, th), acc);
}


uint64_t code_gen_setvl(const command& cmd)
{
	unsigned vpu;
	unsigned th;
	unsigned len;

	if(cmd.operands.size() != 3)
		throw std::runtime_error(g_err_msg(cmd.opcode.line, cmd.opcode.start_col,
			SETVL + " instruction requires three operands."));

	vpu = to_vpu_no(cmd.operands[0]);
	th = to_th_no(cmd.operands[1]);
	len = cmd.operands[2].to_uint();

	return setvl(mkdst(vpu, th), len);
}


uint64_t code_gen_setrs(const command& cmd)
{
	unsigned vpu;
	unsigned th;
	uint64_t addr;

	if(cmd.operands.size() != 3)
		throw std::runtime_error(g_err_msg(cmd.opcode.line, cmd.opcode.start_col,
			SETRS + " instruction requires three operands."));

	vpu = to_vpu_no(cmd.operands[0]);
	th = to_th_no(cmd.operands[1]);
	addr = cmd.operands[2].to_uint64();

	return setrs(mkdst(vpu, th), addr);
}


uint64_t code_gen_setrt(const command& cmd)
{
	unsigned vpu;
	unsigned th;
	uint64_t addr;

	if(cmd.operands.size() != 3)
		throw std::runtime_error(g_err_msg(cmd.opcode.line, cmd.opcode.start_col,
			SETRT + " instruction requires three operands."));

	vpu = to_vpu_no(cmd.operands[0]);
	th = to_th_no(cmd.operands[1]);
	addr = cmd.operands[2].to_uint64();

	return setrt(mkdst(vpu, th), addr);
}


uint64_t code_gen_setrd(const command& cmd)
{
	unsigned vpu;
	unsigned th;
	uint64_t addr;

	if(cmd.operands.size() != 3)
		throw std::runtime_error(g_err_msg(cmd.opcode.line, cmd.opcode.start_col,
			SETRD + " instruction requires three operands."));

	vpu = to_vpu_no(cmd.operands[0]);
	th = to_th_no(cmd.operands[1]);
	addr = cmd.operands[2].to_uint64();

	return setrd(mkdst(vpu, th), addr);
}


uint64_t code_gen_seten(const command& cmd)
{
	unsigned vpu;
	unsigned th;
	bool en;

	if(cmd.operands.size() != 3)
		throw std::runtime_error(g_err_msg(cmd.opcode.line, cmd.opcode.start_col,
			SETEN + " instruction requires three operands."));

	vpu = to_vpu_no(cmd.operands[0]);
	th = to_th_no(cmd.operands[1]);
	en = get_clr_set(cmd.operands[2]);

	return seten(mkdst(vpu, th), en);
}


uint64_t code_gen_prod(const command& cmd)
{
	if(cmd.operands.size() > 1)
		throw std::runtime_error(g_err_msg(cmd.opcode.line, cmd.opcode.start_col,
			PROD + " instruction can have only one optional operand 'vpu[0-1]'."));

	if(!cmd.operands.empty())
		return prod(to_vpu_no(cmd.operands[0]));
	else
		return prod();
}


uint64_t code_gen_store(const command& cmd)
{
	if(cmd.operands.size() > 1)
		throw std::runtime_error(g_err_msg(cmd.opcode.line, cmd.opcode.start_col,
			STORE + " instruction can have only one optional operand 'vpu[0-1]'."));

	if(!cmd.operands.empty())
		return store(to_vpu_no(cmd.operands[0]));
	else
		return store();
}


uint64_t code_gen_sync(const command& cmd)
{
	bool stop;
	bool intr;

	if(cmd.operands.size() != 2)
		throw std::runtime_error(g_err_msg(cmd.opcode.line, cmd.opcode.start_col,
			SYNC + " instruction requires two operands."));

	stop = get_stop_nostop(cmd.operands[0]);
	intr = get_int_noint(cmd.operands[1]);

	return sync(stop, intr);
}


uint64_t code_gen_nop(const command& cmd)
{
	return nop();
}


uint64_t code_gen_relu(const command& cmd)
{
	if(cmd.operands.size() > 1)
		throw std::runtime_error(g_err_msg(cmd.opcode.line, cmd.opcode.start_col,
			RELU + " instruction can have only one optional operand 'vpu[0-1]'."));

	if(!cmd.operands.empty())
		return relu(to_vpu_no(cmd.operands[0]));
	else
		return relu();
}


uint64_t code_gen_lrelu(const command& cmd)
{
	if(cmd.operands.empty() || cmd.operands.size() > 2)
		throw std::runtime_error(g_err_msg(cmd.opcode.line, cmd.opcode.start_col,
			LRELU +
			" instruction can have one optional operand 'vpu[0-1]' and one mandatory operand '-exp'."));

	if(cmd.operands.size() == 1) {
		int exp = cmd.operands[0].to_int(true);
		return lrelu(exp);
	} else {
		unsigned vpu = to_vpu_no(cmd.operands[0]);
		int exp = cmd.operands[1].to_int(true);
		return lrelu(exp, vpu);
	}
}


uint64_t code_gen_quad(const command& cmd)
{
	if(cmd.operands.size() != 1)
		throw std::runtime_error(g_err_msg(cmd.opcode.line, cmd.opcode.start_col,
			QUAD + " directive requires one integer operand."));

	return cmd.operands[0].to_uint64();
}


uint64_t code_gen(const command& cmd)
{
	uint64_t code = 0;

	if(cmd.opcode.lc() == SETACC)
		code = code_gen_setacc(cmd);
	else if(cmd.opcode.lc() == SETVL)
		code = code_gen_setvl(cmd);
	else if(cmd.opcode.lc() == SETRS)
		code = code_gen_setrs(cmd);
	else if(cmd.opcode.lc() == SETRT)
		code = code_gen_setrt(cmd);
	else if(cmd.opcode.lc() == SETRD)
		code = code_gen_setrd(cmd);
	else if(cmd.opcode.lc() == SETEN)
		code = code_gen_seten(cmd);
	else if(cmd.opcode.lc() == PROD)
		code = code_gen_prod(cmd);
	else if(cmd.opcode.lc() == STORE)
		code = code_gen_store(cmd);
	else if(cmd.opcode.lc() == SYNC)
		code = code_gen_sync(cmd);
	else if(cmd.opcode.lc() == NOP)
		code = code_gen_nop(cmd);
	else if(cmd.opcode.lc() == RELU)
		code = code_gen_relu(cmd);
	else if(cmd.opcode.lc() == LRELU)
		code = code_gen_lrelu(cmd);
	else if(cmd.opcode.lc() == QUAD)
		code = code_gen_quad(cmd);
	else
		throw std::runtime_error(g_err_msg(cmd.opcode.line, cmd.opcode.start_col,
			std::string("invalid command '") + cmd.opcode.tok + "'"));

	return code;
}


void compile(std::istream& is, std::vector<uint64_t>& binary)
{
	int line_no = 0;
	std::string line;
	while(std::getline(is, line)) {
		command cmd;
		++line_no;
		if(parse_line(line_no, line, cmd)) {
			uint64_t inst = code_gen(cmd);
			binary.push_back(inst);
		}
	}
}


void print_help()
{
	std::cout << "VxE assembler" << std::endl;
	std::cout << "vxeasm -o outfile -x filename" << std::endl << std::endl
		<< "-h           display this information" << std::endl
		<< "-x           use hex output format" << std::endl
		<< "-o outfile   write output to an outfile" << std::endl
		<< std::endl;
}


int main(int argc, char **argv)
{
	bool hex_output = false;
	std::string output = "vxe.out";

	if(argc < 2) {
		std::cerr << "error: no input file specified" << std::endl
			<< "type `vxeasm -h' for help" << std::endl;
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
				hex_output = true;
			} else {
				std::cerr << "error: invalid option '" << argv[i]
					<< "'" << std::endl;
					return -1;
			}
		} else {
			file = argv[i];
		}
	}

	if(file.empty()) {
		std::cerr << "error: no input file specified" << std::endl;
		return -1;
	}

	std::ifstream ifs(file);
	if(!ifs.is_open()) {
		std::cerr << "error: failed to open '" << file << "'" << std::endl;
		return -1;
	}

	std::ofstream ofs(output, hex_output ? std::ios::out : std::ios::out | std::ios::binary);
	if(!ofs.is_open()) {
		std::cerr << "error: failed to open '" << output << "'" << std::endl;
		return -1;
	}


	std::vector<uint64_t> binary;

	// Compile program
	try {
		compile(ifs, binary);
	}
	catch(const std::exception& e)
	{
		std::cerr << e.what() << std::endl;
		return -1;
	}

	// Save output
	if(hex_output) {
		ofs << "@000000000000000" << std::endl;
		for(uint64_t v : binary)
			ofs << std::hex << std::setw(16) << std::setfill('0') << v << std::endl;
	} else {
		ofs.write(reinterpret_cast<const char*>(binary.data()), binary.size() * sizeof(uint64_t));
	}

	return 0;
}
