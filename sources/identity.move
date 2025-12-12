module minime::identity {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::clock::Clock;
    use std::option::{Self, Option};

    const MAX_NAME_LEN: u64 = 256;

    public struct IdentityObject has key {
        id: UID,
        owner: address,
        provider: vector<u8>,
        provider_id: vector<u8>,
        email: Option<vector<u8>>,
        full_name: Option<vector<u8>>,
        is_verified: bool,
        created_at: u64,
        updated_at: u64,
    }

    public struct IdentityCreated has copy, drop {
        identity_id: ID,
        owner: address,
        provider: vector<u8>,
        timestamp: u64,
    }

    public struct IdentityUpdated has copy, drop {
        identity_id: ID,
        owner: address,
        timestamp: u64,
    }

    public fun create_identity(
        provider: vector<u8>,
        provider_id: vector<u8>,
        email: Option<vector<u8>>,
        full_name: Option<vector<u8>>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): IdentityObject {
        let sender = tx_context::sender(ctx);
        let timestamp = sui::clock::timestamp_ms(clock);

        assert!(vector::length(&provider) > 0, 1001);
        assert!(vector::length(&provider_id) > 0, 1002);

        let identity = IdentityObject {
            id: object::new(ctx),
            owner: sender,
            provider,
            provider_id,
            email,
            full_name,
            is_verified: false,
            created_at: timestamp,
            updated_at: timestamp,
        };

        event::emit(IdentityCreated {
            identity_id: object::uid_to_inner(&identity.id),
            owner: sender,
            provider: identity.provider,
            timestamp,
        });

        identity
    }

    public fun verify_identity(
        identity: &mut IdentityObject,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        assert!(tx_context::sender(ctx) == identity.owner, 1010);

        identity.is_verified = true;
        identity.updated_at = sui::clock::timestamp_ms(clock);

        event::emit(IdentityUpdated {
            identity_id: object::uid_to_inner(&identity.id),
            owner: identity.owner,
            timestamp: identity.updated_at,
        });
    }

    public fun update_email(
        identity: &mut IdentityObject,
        email: Option<vector<u8>>,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        assert!(tx_context::sender(ctx) == identity.owner, 1010);

        identity.email = email;
        identity.updated_at = sui::clock::timestamp_ms(clock);

        event::emit(IdentityUpdated {
            identity_id: object::uid_to_inner(&identity.id),
            owner: identity.owner,
            timestamp: identity.updated_at,
        });
    }

    public fun id(identity: &IdentityObject): ID {
        object::uid_to_inner(&identity.id)
    }

    public fun owner(identity: &IdentityObject): address {
        identity.owner
    }

    public fun provider(identity: &IdentityObject): &vector<u8> {
        &identity.provider
    }

    public fun provider_id(identity: &IdentityObject): &vector<u8> {
        &identity.provider_id
    }

    public fun email(identity: &IdentityObject): &Option<vector<u8>> {
        &identity.email
    }

    public fun full_name(identity: &IdentityObject): &Option<vector<u8>> {
        &identity.full_name
    }

    public fun is_verified(identity: &IdentityObject): bool {
        identity.is_verified
    }

    public fun created_at(identity: &IdentityObject): u64 {
        identity.created_at
    }

    public fun updated_at(identity: &IdentityObject): u64 {
        identity.updated_at
    }

    public fun share(identity: IdentityObject) {
        sui::transfer::share_object(identity);
    }

    #[test_only]
    public fun delete_for_testing(identity: IdentityObject) {
        let IdentityObject {
            id, owner: _, provider: _, provider_id: _, email: _, full_name: _,
            is_verified: _, created_at: _, updated_at: _,
        } = identity;
        object::delete(id);
    }
}
