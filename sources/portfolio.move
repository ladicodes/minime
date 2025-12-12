module minime::portfolio {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::clock::Clock;
    use sui::table::{Self, Table};

    public struct PortfolioObject has key {
        id: UID,
        identity_id: ID,
        owner: address,
        permissions: Table<u64, ID>,
        memories: Table<u64, ID>,
        automations: Table<u64, ID>,
        permission_count: u64,
        memory_count: u64,
        automation_count: u64,
        created_at: u64,
        updated_at: u64,
    }

    public struct PortfolioCreated has copy, drop {
        portfolio_id: ID,
        identity_id: ID,
        owner: address,
        timestamp: u64,
    }

    public struct PermissionAdded has copy, drop {
        portfolio_id: ID,
        permission_id: ID,
        timestamp: u64,
    }

    public struct MemoryAdded has copy, drop {
        portfolio_id: ID,
        memory_id: ID,
        timestamp: u64,
    }

    public struct AutomationAdded has copy, drop {
        portfolio_id: ID,
        automation_id: ID,
        timestamp: u64,
    }

    public fun create_portfolio(
        identity_id: ID,
        clock: &Clock,
        ctx: &mut TxContext,
    ): PortfolioObject {
        let sender = tx_context::sender(ctx);
        let timestamp = sui::clock::timestamp_ms(clock);

        let portfolio = PortfolioObject {
            id: object::new(ctx),
            identity_id,
            owner: sender,
            permissions: table::new(ctx),
            memories: table::new(ctx),
            automations: table::new(ctx),
            permission_count: 0,
            memory_count: 0,
            automation_count: 0,
            created_at: timestamp,
            updated_at: timestamp,
        };

        event::emit(PortfolioCreated {
            portfolio_id: object::uid_to_inner(&portfolio.id),
            identity_id,
            owner: sender,
            timestamp,
        });

        portfolio
    }

    public fun add_permission(
        portfolio: &mut PortfolioObject,
        permission_id: ID,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        assert!(tx_context::sender(ctx) == portfolio.owner, 5001);

        table::add(&mut portfolio.permissions, portfolio.permission_count, permission_id);
        portfolio.permission_count = portfolio.permission_count + 1;
        portfolio.updated_at = sui::clock::timestamp_ms(clock);

        event::emit(PermissionAdded {
            portfolio_id: object::uid_to_inner(&portfolio.id),
            permission_id,
            timestamp: portfolio.updated_at,
        });
    }

    public fun add_memory(
        portfolio: &mut PortfolioObject,
        memory_id: ID,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        assert!(tx_context::sender(ctx) == portfolio.owner, 5001);

        table::add(&mut portfolio.memories, portfolio.memory_count, memory_id);
        portfolio.memory_count = portfolio.memory_count + 1;
        portfolio.updated_at = sui::clock::timestamp_ms(clock);

        event::emit(MemoryAdded {
            portfolio_id: object::uid_to_inner(&portfolio.id),
            memory_id,
            timestamp: portfolio.updated_at,
        });
    }

    public fun add_automation(
        portfolio: &mut PortfolioObject,
        automation_id: ID,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        assert!(tx_context::sender(ctx) == portfolio.owner, 5001);

        table::add(&mut portfolio.automations, portfolio.automation_count, automation_id);
        portfolio.automation_count = portfolio.automation_count + 1;
        portfolio.updated_at = sui::clock::timestamp_ms(clock);

        event::emit(AutomationAdded {
            portfolio_id: object::uid_to_inner(&portfolio.id),
            automation_id,
            timestamp: portfolio.updated_at,
        });
    }

    public fun owner(portfolio: &PortfolioObject): address {
        portfolio.owner
    }

    public fun identity_id(portfolio: &PortfolioObject): ID {
        portfolio.identity_id
    }

    public fun permission_count(portfolio: &PortfolioObject): u64 {
        portfolio.permission_count
    }

    public fun memory_count(portfolio: &PortfolioObject): u64 {
        portfolio.memory_count
    }

    public fun automation_count(portfolio: &PortfolioObject): u64 {
        portfolio.automation_count
    }

    public fun created_at(portfolio: &PortfolioObject): u64 {
        portfolio.created_at
    }

    public fun updated_at(portfolio: &PortfolioObject): u64 {
        portfolio.updated_at
    }

    public fun share(portfolio: PortfolioObject) {
        sui::transfer::share_object(portfolio);
    }

    #[test_only]
    public fun delete_for_testing(portfolio: PortfolioObject) {
        let PortfolioObject {
            id, identity_id: _, owner: _, permissions, memories, automations,
            permission_count: _, memory_count: _, automation_count: _, created_at: _, updated_at: _,
        } = portfolio;
        sui::table::drop(permissions);
        sui::table::drop(memories);
        sui::table::drop(automations);
        object::delete(id);
    }
}
