// SPDX-License-Identifier: MIT

%lang starknet

// Starkware dependencies
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.signature import verify_ecdsa_signature

// Project dependencies
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.access.ownable.library import Ownable

//
// Storage
//

@storage_var
func _freeId() -> (id : Uint256) {
}

@storage_var
func _quests(tokenId : Uint256, id : felt) -> (quest_id : felt) {
}

@storage_var
func _immutable() -> (immutable : felt) {
}

@storage_var
func _public_key() -> (publicKey: felt) {
}

namespace Quest {
    //
    // Initializer
    //

    @external
    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        public_key: felt
    ) {
        _public_key.write(public_key);
        return ();
    }

    //
    // Getters
    //

    func getFreeId{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (id : Uint256) {
        return _freeId.read();
    }

    func getImmutable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (immutable : felt) {
        return _immutable.read();
    }

    func getPublicKey{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (publicKey: felt) {
        return _public_key.read();
    }

    func getProgress{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(tokenId : Uint256) -> (progress_len : felt, progress : felt*) {
        alloc_locals;
        let (arr) = alloc();
        let (len, progress) = getProgressLoop(tokenId, 0, arr, 0);
        return (len, arr);
    }

    func hasCompletedQuest{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(tokenId : Uint256, questId : felt) -> (completed : felt) {
        alloc_locals;
        let (arr) = alloc();
        let completed = hasCompletedQuestLoop(tokenId, 0, questId);
        return completed;
    }


    func getLevel{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(tokenId : Uint256) -> (level : felt) {
        alloc_locals;
        let (arr) = alloc();
        let level = getLevelLoop(tokenId, 0, 0);
        return level;
    }

    func tokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*) {
        alloc_locals;
        let (urlLength, defaultUrl) = getUrl();
        let (level) = getLevel(tokenId);
        let (tokenURI_len: felt, tokenURI: felt*) = append_felt_as_ascii(urlLength, defaultUrl, level);
        let array = tokenURI - tokenURI_len;
        return (tokenURI_len=tokenURI_len, tokenURI=array);
    }

    //
    // Externals
    //

    func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() {
        // Check if the contract is immutable
        let (immutable) = _immutable.read();
        assert immutable = 0;

        let (player) = get_caller_address();

        // Get NFT id
        let (oldId) = _freeId.read();
        let (newId, _) = uint256_add(oldId, Uint256(1, 0));

        // Mint NFT
        ERC721._mint(player, newId);
        _freeId.write(newId);
        _quests.write(newId, 0, 1);
        return ();
    }

    func completeQuest{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, ecdsa_ptr : SignatureBuiltin*}(
        questId : felt,
        tokenId: Uint256,
        sig : (felt, felt)
    ) {
        alloc_locals;

        // Check if the contract is immutable
        let (immutable) = _immutable.read();
        assert immutable = 0;
        // Check if the signature is valid
        let (messageHash) = hash2{hash_ptr=pedersen_ptr}(tokenId.low, tokenId.high);
        let (messageHash) = hash2{hash_ptr=pedersen_ptr}(questId, messageHash);
        let (public_key) = _public_key.read();
        verify_ecdsa_signature(messageHash, public_key, sig[0], sig[1]);

        // Check if the player owns the NFT
        let (player) = get_caller_address();
        let (owner) = ERC721.owner_of(tokenId);
        assert player = owner;

        // Check if the quest is already completed
        let (alreadyCompletedQuest) = hasCompletedQuest(tokenId, questId);
        assert alreadyCompletedQuest = 0;

        let (level) = getLevel(tokenId);
        _quests.write(tokenId, level, questId);
        return ();
    }

    func setImmutable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
        alloc_locals;
        Ownable.assert_only_owner();
        _immutable.write(1);
        return ();
    }

    func setPublicKey{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(public_key : felt) {
        alloc_locals;
        Ownable.assert_only_owner();
        _public_key.write(public_key);
        return ();
    }
}

//
// Internals
//

func append_felt_as_ascii {
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(arr_len : felt, arr : felt*, number : felt) -> (
        ptr_len : felt, ptr : felt*) {
    alloc_locals;
    let (q, r) = unsigned_div_rem(number, 10);
    if (q == 0 and r == 0) {
        return (arr_len, arr + arr_len);
    }

    let (ptr_len, ptr) = append_felt_as_ascii(arr_len, arr, q);
    assert [ptr] = r + 48;
    return (ptr_len + 1, ptr + 1);
}

func hasCompletedQuestLoop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(tokenId : Uint256, id : felt, targetQuestId : felt) -> (completed : felt) {
    let (questId) = _quests.read(tokenId, id);
    if (questId == targetQuestId) {
        return (completed=1);
    } else {
        if (questId == 0) {
            return (completed=0);
        } else {
            let completed = hasCompletedQuestLoop(tokenId, id + 1, targetQuestId);
            return completed;
        }
    }
}

func getLevelLoop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(tokenId: Uint256, level : felt, id : felt) -> (level : felt) {
    let (questId) = _quests.read(tokenId, id);
    if (questId == 0) {
        return (level=level);
    } else {
        let (level) = getLevelLoop(tokenId, level + 1, id + 1);
        return (level=level);
    }
}

func getUrl() -> (url_len : felt, url : felt*) {
    alloc_locals;
    let (url) = alloc();
    assert [url] = 104;
    assert [url + 1] = 116;
    assert [url + 2] = 116;
    assert [url + 3] = 112;
    assert [url + 4] = 115;
    assert [url + 5] = 58;
    assert [url + 6] = 47;
    assert [url + 7] = 47;
    assert [url + 8] = 113;
    assert [url + 9] = 117;
    assert [url + 10] = 101;
    assert [url + 11] = 115;
    assert [url + 12] = 116;
    assert [url + 13] = 45;
    assert [url + 14] = 97;
    assert [url + 15] = 112;
    assert [url + 16] = 105;
    assert [url + 17] = 46;
    assert [url + 18] = 115;
    assert [url + 19] = 116;
    assert [url + 20] = 97;
    assert [url + 21] = 114;
    assert [url + 22] = 107;
    assert [url + 23] = 110;
    assert [url + 24] = 101;
    assert [url + 25] = 116;
    assert [url + 26] = 46;
    assert [url + 27] = 105;
    assert [url + 28] = 100;
    assert [url + 29] = 47;
    assert [url + 30] = 113;
    assert [url + 31] = 117;
    assert [url + 32] = 101;
    assert [url + 33] = 115;
    assert [url + 34] = 116;
    assert [url + 35] = 45;
    assert [url + 36] = 108;
    assert [url + 37] = 118;
    assert [url + 38] = 108;
    assert [url + 39] = 47;
    return (40, url);
}

func getProgressLoop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(tokenId: Uint256, arr_len : felt, arr : felt*, id : felt) -> (progress_len : felt, progress : felt*) {
    let (questId) = _quests.read(tokenId, id);
    if (questId == 0) {
        return (arr_len, arr);
    } else {
        assert [arr + arr_len] = questId;
        let (progress_len, progress) = getProgressLoop(tokenId, arr_len + 1, arr, id + 1);
        return (progress_len, progress);
    }
}