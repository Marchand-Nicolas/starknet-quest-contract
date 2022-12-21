// SPDX-License-Identifier: MIT

%lang starknet

// Starkware dependencies
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem

// Project dependencies
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt, owner: felt
) {
    ERC721.initializer(name, symbol);
    Ownable.initializer(owner);
    return ();
}

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
func _admin() -> (address : felt) {
}

@storage_var
func _immutable() -> (immutable : felt) {
}

//
// Getters
//

@view
func getProgress{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(tokenId : Uint256) -> (progress_len : felt, progress : felt*) {
    alloc_locals;
    let (arr) = alloc();
    let (len, progress) = getQuestProgress(tokenId, 0, arr, 0);
    return (len, arr);
}

func getQuestProgress{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(tokenId: Uint256, arr_len : felt, arr : felt*, id : felt) -> (progress_len : felt, progress : felt*) {
    let (questId) = _quests.read(tokenId, id);
    if (questId == 0) {
        return (arr_len, arr);
    } else {
        assert [arr + arr_len] = questId;
        let (progress_len, progress) = getQuestProgress(tokenId, arr_len + 1, arr, id + 1);
        return (progress_len, progress);
    }
}

@view
func hasCompletedQuest{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(tokenId : Uint256, questId : felt) -> (completed : felt) {
    alloc_locals;
    let (arr) = alloc();
    let completed = hasCompletedQuestLoop(tokenId, 0, questId);
    return completed;
}

@view
func getLevel{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(tokenId : Uint256) -> (level : felt) {
    alloc_locals;
    let (arr) = alloc();
    let level = getLevelLoop(tokenId, 0, 0);
    return level;
}

@view
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

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return ERC165.supports_interface(interfaceId);
}

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    return ERC721.name();
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    return ERC721.symbol();
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    return ERC721.balance_of(owner);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    owner: felt
) {
    return ERC721.owner_of(tokenId);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (approved: felt) {
    return ERC721.get_approved(tokenId);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (isApproved: felt) {
    let (isApproved: felt) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved=isApproved);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    return Ownable.owner();
}

//
// Externals
//

@external
func approve{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    ERC721.approve(to, tokenId);
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    ERC721.set_approval_for_all(operator, approved);
    return ();
}

@external
func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256
) {
    ERC721.transfer_from(from_, to, tokenId);
    return ();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    ERC721.safe_transfer_from(from_, to, tokenId, data_len, data);
    return ();
}

@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    Ownable.assert_only_owner();
    ERC721._mint(to, tokenId);
    return ();
}

@external
func burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(tokenId: Uint256) {
    ERC721.assert_only_token_owner(tokenId);
    ERC721._burn(tokenId);
    return ();
}

@external
func setTokenURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    tokenId: Uint256, tokenURI: felt
) {
    Ownable.assert_only_owner();
    ERC721._set_token_uri(tokenId, tokenURI);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.renounce_ownership();
    return ();
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