module minime::memory {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::clock::Clock;
    use std::option::{Self, Option};

    const TYPE_TEXT: u8 = 1;
    const TYPE_VOICE: u8 = 2;
    const TYPE_MIXED: u8 = 3;

    const STATUS_ACTIVE: u8 = 1;
    const STATUS_ARCHIVED: u8 = 2;

    public struct MemoryObject has key {
        id: UID,
        identity_id: ID,
        owner: address,
        content_type: u8,
        title: vector<u8>,
        walrus_blob_id: vector<u8>,
        content_hash: vector<u8>,
        content_size: u64,
        ai_summary: Option<vector<u8>>,
        ai_suggestions: vector<vector<u8>>,
        tags: vector<vector<u8>>,
        status: u8,
        created_at: u64,
        updated_at: u64,
        expires_at: u64,
    }

    public struct MemoryCreated has copy, drop {
        memory_id: ID,
        identity_id: ID,
        owner: address,
        content_type: u8,
        walrus_blob_id: vector<u8>,
        timestamp: u64,
    }

    public struct MemoryUpdated has copy, drop {
        memory_id: ID,
        owner: address,
        timestamp: u64,
    }

    public struct MemoryArchived has copy, drop {
        memory_id: ID,
        owner: address,
        timestamp: u64,
    }

    public fun create_memory(
        identity_id: ID,
        content_type: u8,
        title: vector<u8>,
        walrus_blob_id: vector<u8>,
        content_hash: vector<u8>,
        content_size: u64,
        tags: vector<vector<u8>>,
        expires_at: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): MemoryObject {
        let sender = tx_context::sender(ctx);
        let timestamp = sui::clock::timestamp_ms(clock);

        assert!(content_type >= 1 && content_type <= 3, 3001);
        assert!(vector::length(&walrus_blob_id) > 0, 3002);
        assert!(vector::length(&content_hash) == 32, 3003);

        let memory = MemoryObject {
            id: object::new(ctx),
            identity_id,
            owner: sender,
            content_type,
            title,
            walrus_blob_id,
            content_hash,
            content_size,
            ai_summary: option::none(),
            ai_suggestions: vector::empty(),
            tags,
            status: STATUS_ACTIVE,
            created_at: timestamp,
            updated_at: timestamp,
            expires_at,
        };

        event::emit(MemoryCreated {
            memory_id: object::uid_to_inner(&memory.id),
            identity_id,
            owner: sender,
            content_type,
            walrus_blob_id: memory.walrus_blob_id,
            timestamp,
        });

        memory
    }

    public fun update_with_ai(
        memory: &mut MemoryObject,
        ai_summary: Option<vector<u8>>,
        ai_suggestions: vector<vector<u8>>,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        assert!(tx_context::sender(ctx) == memory.owner, 3010);
        assert!(memory.status == STATUS_ACTIVE, 3011);

        memory.ai_summary = ai_summary;
        memory.ai_suggestions = ai_suggestions;
        memory.updated_at = sui::clock::timestamp_ms(clock);

        event::emit(MemoryUpdated {
            memory_id: object::uid_to_inner(&memory.id),
            owner: memory.owner,
            timestamp: memory.updated_at,
        });
    }

    public fun add_tags(
        memory: &mut MemoryObject,
        new_tags: vector<vector<u8>>,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        assert!(tx_context::sender(ctx) == memory.owner, 3010);

        let new_tags_len = vector::length(&new_tags);
        let mut i = 0;
        while (i < new_tags_len) {
            vector::push_back(&mut memory.tags, *vector::borrow(&new_tags, i));
            i = i + 1;
        };

        memory.updated_at = sui::clock::timestamp_ms(clock);

        event::emit(MemoryUpdated {
            memory_id: object::uid_to_inner(&memory.id),
            owner: memory.owner,
            timestamp: memory.updated_at,
        });
    }

    public fun archive_memory(
        memory: &mut MemoryObject,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        assert!(tx_context::sender(ctx) == memory.owner, 3010);
        assert!(memory.status == STATUS_ACTIVE, 3011);

        memory.status = STATUS_ARCHIVED;
        memory.updated_at = sui::clock::timestamp_ms(clock);

        event::emit(MemoryArchived {
            memory_id: object::uid_to_inner(&memory.id),
            owner: memory.owner,
            timestamp: memory.updated_at,
        });
    }

    public fun id(memory: &MemoryObject): ID {
        object::uid_to_inner(&memory.id)
    }

    public fun identity_id(memory: &MemoryObject): ID {
        memory.identity_id
    }

    public fun owner(memory: &MemoryObject): address {
        memory.owner
    }

    public fun walrus_blob_id(memory: &MemoryObject): &vector<u8> {
        &memory.walrus_blob_id
    }

    public fun content_hash(memory: &MemoryObject): &vector<u8> {
        &memory.content_hash
    }

    public fun content_type(memory: &MemoryObject): u8 {
        memory.content_type
    }

    public fun ai_summary(memory: &MemoryObject): &Option<vector<u8>> {
        &memory.ai_summary
    }

    public fun ai_suggestions(memory: &MemoryObject): &vector<vector<u8>> {
        &memory.ai_suggestions
    }

    public fun tags(memory: &MemoryObject): &vector<vector<u8>> {
        &memory.tags
    }

    public fun title(memory: &MemoryObject): &vector<u8> {
        &memory.title
    }

    public fun status(memory: &MemoryObject): u8 {
        memory.status
    }

    public fun created_at(memory: &MemoryObject): u64 {
        memory.created_at
    }

    public fun updated_at(memory: &MemoryObject): u64 {
        memory.updated_at
    }

    public fun is_expired(memory: &MemoryObject, current_time: u64): bool {
        if (memory.expires_at == 0) {
            return false
        };
        current_time > memory.expires_at
    }

    public fun is_active(memory: &MemoryObject): bool {
        memory.status == STATUS_ACTIVE
    }

    public fun share(memory: MemoryObject) {
        sui::transfer::share_object(memory);
    }

    #[test_only]
    public fun delete_for_testing(memory: MemoryObject) {
        let MemoryObject {
            id, identity_id: _, owner: _, content_type: _, title: _, walrus_blob_id: _,
            content_hash: _, content_size: _, ai_summary: _, ai_suggestions: _, tags: _,
            status: _, created_at: _, updated_at: _, expires_at: _,
        } = memory;
        object::delete(id);
    }
}
