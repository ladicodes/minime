module minime::permission {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::clock::Clock;
    use sui::vec_set::{Self, VecSet};

    const SCOPE_READ: u8 = 1;
    const SCOPE_WRITE: u8 = 2;
    const SCOPE_DELETE: u8 = 3;
    const SCOPE_FULL: u8 = 4;

    public struct PermissionObject has key {
        id: UID,
        identity_id: ID,
        owner: address,
        app_name: vector<u8>,
        app_id: vector<u8>,
        scopes: VecSet<vector<u8>>,
        access_token_hash: vector<u8>,
        expires_at: u64,
        created_at: u64,
        last_used_at: u64,
        is_active: bool,
    }

    public struct PermissionGranted has copy, drop {
        permission_id: ID,
        identity_id: ID,
        owner: address,
        app_id: vector<u8>,
        timestamp: u64,
    }

    public struct PermissionRevoked has copy, drop {
        permission_id: ID,
        owner: address,
        timestamp: u64,
    }

    public struct PermissionUpdated has copy, drop {
        permission_id: ID,
        owner: address,
        timestamp: u64,
    }

    public fun create_permission(
        identity_id: ID,
        app_name: vector<u8>,
        app_id: vector<u8>,
        scopes: vector<vector<u8>>,
        access_token_hash: vector<u8>,
        expires_at: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): PermissionObject {
        let sender = tx_context::sender(ctx);
        let timestamp = sui::clock::timestamp_ms(clock);

        let mut scopes_set = vec_set::empty();
        let scopes_len = vector::length(&scopes);
        let mut i = 0;
        while (i < scopes_len) {
            vec_set::insert(&mut scopes_set, *vector::borrow(&scopes, i));
            i = i + 1;
        };

        let permission = PermissionObject {
            id: object::new(ctx),
            identity_id,
            owner: sender,
            app_name,
            app_id: app_id,
            scopes: scopes_set,
            access_token_hash,
            expires_at,
            created_at: timestamp,
            last_used_at: timestamp,
            is_active: true,
        };

        event::emit(PermissionGranted {
            permission_id: object::uid_to_inner(&permission.id),
            identity_id,
            owner: sender,
            app_id: permission.app_id,
            timestamp,
        });

        permission
    }

    public fun revoke_permission(
        permission: &mut PermissionObject,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        assert!(tx_context::sender(ctx) == permission.owner, 2010);
        assert!(permission.is_active, 2011);

        permission.is_active = false;

        event::emit(PermissionRevoked {
            permission_id: object::uid_to_inner(&permission.id),
            owner: permission.owner,
            timestamp: sui::clock::timestamp_ms(clock),
        });
    }

    public fun add_scope(
        permission: &mut PermissionObject,
        scope: vector<u8>,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        assert!(tx_context::sender(ctx) == permission.owner, 2010);

        vec_set::insert(&mut permission.scopes, scope);
        permission.last_used_at = sui::clock::timestamp_ms(clock);

        event::emit(PermissionUpdated {
            permission_id: object::uid_to_inner(&permission.id),
            owner: permission.owner,
            timestamp: permission.last_used_at,
        });
    }

    public fun has_scope(permission: &PermissionObject, scope: &vector<u8>): bool {
        vec_set::contains(&permission.scopes, scope)
    }

    public fun id(permission: &PermissionObject): ID {
        object::uid_to_inner(&permission.id)
    }

    public fun identity_id(permission: &PermissionObject): ID {
        permission.identity_id
    }

    public fun owner(permission: &PermissionObject): address {
        permission.owner
    }

    public fun app_id(permission: &PermissionObject): &vector<u8> {
        &permission.app_id
    }

    public fun app_name(permission: &PermissionObject): &vector<u8> {
        &permission.app_name
    }

    public fun created_at(permission: &PermissionObject): u64 {
        permission.created_at
    }

    public fun last_used_at(permission: &PermissionObject): u64 {
        permission.last_used_at
    }

    public fun is_active(permission: &PermissionObject): bool {
        permission.is_active
    }

    public fun share(permission: PermissionObject) {
        sui::transfer::share_object(permission);
    }

    #[test_only]
    public fun delete_for_testing(permission: PermissionObject) {
        let PermissionObject {
            id, identity_id: _, owner: _, app_name: _, app_id: _, scopes: _,
            access_token_hash: _, expires_at: _, created_at: _, last_used_at: _, is_active: _,
        } = permission;
        object::delete(id);
    }
}
