module minime::minime {
    use sui::object::ID;
    use sui::tx_context::TxContext;
    use sui::clock::Clock;
    use std::option::Option;

    use minime::identity::{Self, IdentityObject};
    use minime::permission::{Self, PermissionObject};
    use minime::memory::{Self, MemoryObject};
    use minime::automation::{Self, AutomationObject};
    use minime::portfolio::{Self, PortfolioObject};

    public entry fun init_user(
        provider: vector<u8>,
        provider_id: vector<u8>,
        email: Option<vector<u8>>,
        full_name: Option<vector<u8>>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let identity = identity::create_identity(
            provider,
            provider_id,
            email,
            full_name,
            clock,
            ctx,
        );
        let identity_id = identity::id(&identity);

        let portfolio = portfolio::create_portfolio(identity_id, clock, ctx);

        identity::share(identity);
        portfolio::share(portfolio);
    }

    public entry fun grant_app_permission(
        identity_id: ID,
        app_name: vector<u8>,
        app_id: vector<u8>,
        scopes: vector<vector<u8>>,
        access_token_hash: vector<u8>,
        expires_at: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let permission = permission::create_permission(
            identity_id,
            app_name,
            app_id,
            scopes,
            access_token_hash,
            expires_at,
            clock,
            ctx,
        );

        permission::share(permission);
    }

    public entry fun revoke_app_permission(
        permission: &mut PermissionObject,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        permission::revoke_permission(permission, clock, ctx);
    }

    public entry fun create_text_memory(
        identity_id: ID,
        title: vector<u8>,
        walrus_blob_id: vector<u8>,
        content_hash: vector<u8>,
        content_size: u64,
        tags: vector<vector<u8>>,
        expires_at: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let memory = memory::create_memory(
            identity_id,
            1,
            title,
            walrus_blob_id,
            content_hash,
            content_size,
            tags,
            expires_at,
            clock,
            ctx,
        );

        memory::share(memory);
    }

    public entry fun create_voice_memory(
        identity_id: ID,
        title: vector<u8>,
        walrus_blob_id: vector<u8>,
        content_hash: vector<u8>,
        content_size: u64,
        tags: vector<vector<u8>>,
        expires_at: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let memory = memory::create_memory(
            identity_id,
            2,
            title,
            walrus_blob_id,
            content_hash,
            content_size,
            tags,
            expires_at,
            clock,
            ctx,
        );

        memory::share(memory);
    }

    public entry fun create_mixed_memory(
        identity_id: ID,
        title: vector<u8>,
        walrus_blob_id: vector<u8>,
        content_hash: vector<u8>,
        content_size: u64,
        tags: vector<vector<u8>>,
        expires_at: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let memory = memory::create_memory(
            identity_id,
            3,
            title,
            walrus_blob_id,
            content_hash,
            content_size,
            tags,
            expires_at,
            clock,
            ctx,
        );

        memory::share(memory);
    }

    public entry fun update_memory_with_ai(
        memory: &mut MemoryObject,
        ai_summary: Option<vector<u8>>,
        ai_suggestions: vector<vector<u8>>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        memory::update_with_ai(memory, ai_summary, ai_suggestions, clock, ctx);
    }

    public entry fun create_reminder(
        identity_id: ID,
        title: vector<u8>,
        description: vector<u8>,
        trigger_at: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let automation = automation::create_automation(
            identity_id,
            1,
            title,
            description,
            trigger_at,
            std::option::none(),
            clock,
            ctx,
        );

        automation::share(automation);
    }

    public entry fun create_scheduled_task(
        identity_id: ID,
        title: vector<u8>,
        description: vector<u8>,
        trigger_at: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let automation = automation::create_automation(
            identity_id,
            2,
            title,
            description,
            trigger_at,
            std::option::none(),
            clock,
            ctx,
        );

        automation::share(automation);
    }

    public entry fun create_recurring_task(
        identity_id: ID,
        title: vector<u8>,
        description: vector<u8>,
        trigger_at: u64,
        recurrence_pattern: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let automation = automation::create_automation(
            identity_id,
            3,
            title,
            description,
            trigger_at,
            std::option::some(recurrence_pattern),
            clock,
            ctx,
        );

        automation::share(automation);
    }

    public entry fun approve_automation(
        automation: &mut AutomationObject,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        automation::approve_automation(automation, clock, ctx);
    }

    public entry fun execute_automation(
        automation: &mut AutomationObject,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        automation::execute_automation(automation, clock, ctx);
    }

    public entry fun cancel_automation(
        automation: &mut AutomationObject,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        automation::cancel_automation(automation, clock, ctx);
    }

    public entry fun archive_memory(
        memory: &mut MemoryObject,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        memory::archive_memory(memory, clock, ctx);
    }
}
