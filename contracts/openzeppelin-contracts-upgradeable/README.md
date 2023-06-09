# <img src="icon.svg" alt="OpenZeppelin" height="40px" align="left"> OpenZeppelin Contracts Upgradeable

[![NPM Package](https://img.shields.io/npm/v/@openzeppelin/contracts.svg)](https://www.npmjs.org/package/@openzeppelin/contracts)
[![Coverage Status](https://codecov.io/gh/OpenZeppelin/openzeppelin-contracts/graph/badge.svg)](https://codecov.io/gh/OpenZeppelin/openzeppelin-contracts)
[![GitPOAPs](https://public-api.gitpoap.io/v1/repo/OpenZeppelin/openzeppelin-contracts/badge)](https://www.gitpoap.io/gh/OpenZeppelin/openzeppelin-contracts)
[![Docs](https://img.shields.io/badge/docs-%F0%9F%93%84-yellow)](https://docs.openzeppelin.com/contracts)
[![Forum](https://img.shields.io/badge/forum-%F0%9F%92%AC-yellow)](https://docs.openzeppelin.com/contracts)

This repository hosts the Upgradeable variant of [OpenZeppelin Contracts], meant for use in upgradeable contracts. This variant is available as separate package called `@openzeppelin/contracts-upgradeable`.

[OpenZeppelin Contracts]: https://github.com/OpenZeppelin/openzeppelin-contracts

It follows all of the rules for [Writing Upgradeable Contracts]: constructors are replaced by initializer functions, state variables are initialized in initializer functions, and we additionally check for storage incompatibilities across minor versions.

[Writing Upgradeable Contracts]: https://docs.openzeppelin.com/upgrades-plugins/writing-upgradeable

> :warning: **Warning**
>
> There will be storage incompatibilities across major versions of this package, which makes it unsafe to upgrade a deployed contract from one major version to another, for example from 3.4.0 to 4.0.0.
> 
> Similarly, it is not safe to upgrade from `@openzeppelin/contracts-ethereum-package` (a similar previous package) to `@openzeppelin/contracts-upgradeable`.
>
> **It is strongly encouraged to use these contracts together with a tool that can automatically guarantee the safety of an upgradeable contract, such as the [OpenZeppelin Upgrades Plugins](https://github.com/OpenZeppelin/openzeppelin-upgrades).**

:building_construction: **Want to scale your decentralized application?** Check out [OpenZeppelin Defender](https://openzeppelin.com/defender) — a secure platform for automating and monitoring your operations.

## Overview

### Installation

```
$ npm install @openzeppelin/contracts-upgradeable
```

OpenZeppelin Contracts features a [stable API](https://docs.openzeppelin.com/contracts/releases-stability#api-stability), which means that your contracts won't break unexpectedly when upgrading to a newer minor version.

An alternative to npm is to use the GitHub repository (`openzeppelin/openzeppelin-contracts`) to retrieve the contracts. When doing this, make sure to specify the tag for a release such as `v4.5.0`, instead of using the `master` branch.

### Usage

The package replicates the structure of the main OpenZeppelin Contracts package, but every file and contract has the suffix `Upgradeable`.

```diff
-import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
+import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
 
-contract MyCollectible is ERC721 {
+contract MyCollectible is ERC721Upgradeable {
```

Constructors are replaced by internal initializer functions following the naming convention `__{ContractName}_init`. Since these are internal, you must always define your own public initializer function and call the parent initializer of the contract you extend.

```diff
-    constructor() ERC721("MyCollectible", "MCO") {
+    function initialize() initializer public {
+        __ERC721_init("MyCollectible", "MCO");
     }
```

> **Caution**
>
> Use with multiple inheritance requires special care. Initializer functions are not linearized by the compiler like constructors. Because of this, each `__{ContractName}_init` function embeds the linearized calls to all parent initializers. As a consequence, calling two of these `init` functions can potentially initialize the same contract twice.
>
> The function `__{ContractName}_init_unchained` found in every contract is the initializer function minus the calls to parent initializers, and can be used to avoid the double initialization problem, but doing this manually is not recommended. We hope to be able to implement safety checks for this in future versions of the Upgrades Plugins.

_If you're new to smart contract development, head to [Developing Smart Contracts](https://docs.openzeppelin.com/learn/developing-smart-contracts) to learn about creating a new project and compiling your contracts._

To keep your system secure, you should **always** use the installed code as-is, and neither copy-paste it from online sources nor modify it yourself. The library is designed so that only the contracts and functions you use are deployed, so you don't need to worry about it needlessly increasing gas costs.

## Learn More

The guides in the [documentation site](https://docs.openzeppelin.com/contracts) will teach about different concepts, and how to use the related contracts that OpenZeppelin Contracts provides:

* [Access Control](https://docs.openzeppelin.com/contracts/access-control): decide who can perform each of the actions on your system.
* [Tokens](https://docs.openzeppelin.com/contracts/tokens): create tradeable assets or collectives, and distribute them via [Crowdsales](https://docs.openzeppelin.com/contracts/crowdsales).
* [Utilities](https://docs.openzeppelin.com/contracts/utilities): generic useful tools including non-overflowing math, signature verification, and trustless paying systems.

The [full API](https://docs.openzeppelin.com/contracts/api/token/ERC20) is also thoroughly documented, and serves as a great reference when developing your smart contract application. You can also ask for help or follow Contracts's development in the [community forum](https://forum.openzeppelin.com).

Finally, you may want to take a look at the [guides on our blog](https://blog.openzeppelin.com/guides), which cover several common use cases and good practices. The following articles provide great background reading, though please note that some of the referenced tools have changed, as the tooling in the ecosystem continues to rapidly evolve.

* [The Hitchhiker’s Guide to Smart Contracts in Ethereum](https://blog.openzeppelin.com/the-hitchhikers-guide-to-smart-contracts-in-ethereum-848f08001f05) will help you get an overview of the various tools available for smart contract development, and help you set up your environment.
* [A Gentle Introduction to Ethereum Programming, Part 1](https://blog.openzeppelin.com/a-gentle-introduction-to-ethereum-programming-part-1-783cc7796094) provides very useful information on an introductory level, including many basic concepts from the Ethereum platform.
* For a more in-depth dive, you may read the guide [Designing the Architecture for Your Ethereum Application](https://blog.openzeppelin.com/designing-the-architecture-for-your-ethereum-application-9cec086f8317), which discusses how to better structure your application and its relationship to the real world.

## Security

This project is maintained by [OpenZeppelin](https://openzeppelin.com) with the goal of providing a secure and reliable library of smart contract components for the ecosystem. We address security through risk management in various areas such as engineering and open source best practices, scoping and API design, multi-layered review processes, and incident response preparedness.

The security policy is detailed in [`SECURITY.md`](./SECURITY.md), and specifies how you can report security vulnerabilities, which versions will receive security patches, and how to stay informed about them. We run a [bug bounty program on Immunefi](https://immunefi.com/bounty/openzeppelin) to reward the responsible disclosure of vulnerabilities.

The engineering guidelines we follow to promote project quality can be found in [`GUIDELINES.md`](./GUIDELINES.md).

Past audits can be found in [`audits/`](./audits).

Smart contracts are a nascent techology and carry a high level of technical risk and uncertainty. Although OpenZeppelin is well known for its security audits, using OpenZeppelin Contracts is not a substitute for a security audit.

OpenZeppelin Contracts is made available under the MIT License, which disclaims all warranties in relation to the project and which limits the liability of those that contribute and maintain the project, including OpenZeppelin. As set out further in the Terms, you acknowledge that you are solely responsible for any use of OpenZeppelin Contracts and you assume all risks associated with any such use.

## Contribute

OpenZeppelin Contracts exists thanks to its contributors. There are many ways you can participate and help build high quality software. Check out the [contribution guide](CONTRIBUTING.md)!

## License

OpenZeppelin Contracts is released under the [MIT License](LICENSE).

## Legal

Your use of this Project is governed by the terms found at www.openzeppelin.com/tos (the "Terms").
