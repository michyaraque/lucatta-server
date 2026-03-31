// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#include "otpch.h"

#include "rsa.h"

#include <openssl/err.h>
#include <openssl/core_names.h>
#include <openssl/pem.h>
#include <openssl/rsa.h>

namespace {

struct Deleter
{
	void operator()(BIO* bio) const { BIO_free(bio); }
	void operator()(char* ptr) const { OPENSSL_free(ptr); }
	void operator()(BIGNUM* bn) const { BN_free(bn); }
	void operator()(EVP_PKEY* pkey) const { EVP_PKEY_free(pkey); }
	void operator()(EVP_PKEY_CTX* ctx) const { EVP_PKEY_CTX_free(ctx); }
};

template <class T>
using C_ptr = std::unique_ptr<T, Deleter>;

C_ptr<EVP_PKEY> pkey = nullptr;

std::string getBignumParamAsString(const EVP_PKEY* key, const char* keyName)
{
	BIGNUM* bn = nullptr;
	if (!EVP_PKEY_get_bn_param(key, keyName, &bn)) {
		throw std::runtime_error(
		    fmt::format("Error while reading RSA key parameter: {}", ERR_error_string(ERR_get_error(), nullptr)));
	}

	C_ptr<BIGNUM> bignum{bn};
	char* chars = BN_bn2dec(bignum.get());
	if (!chars) {
		throw std::runtime_error(
		    fmt::format("Error while serializing RSA key parameter: {}", ERR_error_string(ERR_get_error(), nullptr)));
	}

	C_ptr<char> str{chars};
	return str.get();
}

} // namespace

namespace tfs::rsa {

void decrypt(uint8_t* msg, size_t len)
{
	C_ptr<EVP_PKEY_CTX> pctx{EVP_PKEY_CTX_new_from_pkey(nullptr, pkey.get(), nullptr)};
	EVP_PKEY_decrypt_init(pctx.get());
	EVP_PKEY_CTX_set_rsa_padding(pctx.get(), RSA_NO_PADDING);

	EVP_PKEY_decrypt(pctx.get(), msg, &len, msg, len);
}

EVP_PKEY* loadPEM(std::string_view pem)
{
	C_ptr<BIO> bio{BIO_new(BIO_s_mem())};
	if (!BIO_write(bio.get(), pem.data(), pem.size())) {
		throw std::runtime_error(
		    fmt::format("Error while reading PEM data: {}", ERR_error_string(ERR_get_error(), nullptr)));
	}

	EVP_PKEY* pkey_ = nullptr;
	if (!PEM_read_bio_PrivateKey(bio.get(), &pkey_, nullptr, nullptr)) {
		throw std::runtime_error(
		    fmt::format("Error while reading private key: {}", ERR_error_string(ERR_get_error(), nullptr)));
	}

	pkey.reset(pkey_);
	return pkey_;
}

std::string getPublicModulus()
{
	if (!pkey) {
		throw std::runtime_error("RSA key is not loaded.");
	}

	return getBignumParamAsString(pkey.get(), OSSL_PKEY_PARAM_RSA_N);
}

uint32_t getPublicExponent()
{
	if (!pkey) {
		throw std::runtime_error("RSA key is not loaded.");
	}

	size_t exponent = 0;
	if (!EVP_PKEY_get_size_t_param(pkey.get(), OSSL_PKEY_PARAM_RSA_E, &exponent)) {
		throw std::runtime_error(
		    fmt::format("Error while reading RSA public exponent: {}", ERR_error_string(ERR_get_error(), nullptr)));
	}

	return static_cast<uint32_t>(exponent);
}

size_t getKeySize()
{
	if (!pkey) {
		throw std::runtime_error("RSA key is not loaded.");
	}

	return EVP_PKEY_get_size(pkey.get());
}

} // namespace tfs::rsa
