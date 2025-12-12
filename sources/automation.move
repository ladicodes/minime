module minime::automation {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::clock::Clock;
    use std::option::{Self, Option};

    const TYPE_REMINDER: u8 = 1;
    const TYPE_SCHEDULED_TASK: u8 = 2;
    const TYPE_RECURRING_TASK: u8 = 3;

    const STATUS_PENDING: u8 = 1;
    const STATUS_APPROVED: u8 = 2;
    const STATUS_EXECUTED: u8 = 3;
    const STATUS_CANCELLED: u8 = 4;

    public struct AutomationObject has key {
        id: UID,
        identity_id: ID,
        owner: address,
        automation_type: u8,
        title: vector<u8>,
        description: vector<u8>,
        trigger_at: u64,
        recurrence_pattern: Option<vector<u8>>,
        status: u8,
        execution_count: u64,
        last_executed_at: Option<u64>,
        created_at: u64,
        updated_at: u64,
    }

    public struct AutomationCreated has copy, drop {
        automation_id: ID,
        identity_id: ID,
        owner: address,
        automation_type: u8,
        trigger_at: u64,
        timestamp: u64,
    }

    public struct AutomationApproved has copy, drop {
        automation_id: ID,
        owner: address,
        timestamp: u64,
    }

    public struct AutomationExecuted has copy, drop {
        automation_id: ID,
        owner: address,
        execution_count: u64,
        timestamp: u64,
    }

    public struct AutomationCancelled has copy, drop {
        automation_id: ID,
        owner: address,
        timestamp: u64,
    }

    public fun create_automation(
        identity_id: ID,
        automation_type: u8,
        title: vector<u8>,
        description: vector<u8>,
        trigger_at: u64,
        recurrence_pattern: Option<vector<u8>>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): AutomationObject {
        let sender = tx_context::sender(ctx);
        let timestamp = sui::clock::timestamp_ms(clock);

        assert!(automation_type >= 1 && automation_type <= 3, 4001);
        assert!(trigger_at >= timestamp, 4002);

        let automation = AutomationObject {
            id: object::new(ctx),
            identity_id,
            owner: sender,
            automation_type,
            title,
            description,
            trigger_at,
            recurrence_pattern,
            status: STATUS_PENDING,
            execution_count: 0,
            last_executed_at: option::none(),
            created_at: timestamp,
            updated_at: timestamp,
        };

        event::emit(AutomationCreated {
            automation_id: object::uid_to_inner(&automation.id),
            identity_id,
            owner: sender,
            automation_type,
            trigger_at,
            timestamp,
        });

        automation
    }

    public fun approve_automation(
        automation: &mut AutomationObject,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        assert!(tx_context::sender(ctx) == automation.owner, 4010);
        assert!(automation.status == STATUS_PENDING, 4011);

        automation.status = STATUS_APPROVED;
        automation.updated_at = sui::clock::timestamp_ms(clock);

        event::emit(AutomationApproved {
            automation_id: object::uid_to_inner(&automation.id),
            owner: automation.owner,
            timestamp: automation.updated_at,
        });
    }

    public fun execute_automation(
        automation: &mut AutomationObject,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        assert!(tx_context::sender(ctx) == automation.owner, 4010);
        assert!(automation.status == STATUS_APPROVED, 4012);

        let timestamp = sui::clock::timestamp_ms(clock);
        assert!(timestamp >= automation.trigger_at, 4013);

        automation.status = STATUS_EXECUTED;
        automation.execution_count = automation.execution_count + 1;
        automation.last_executed_at = option::some(timestamp);
        automation.updated_at = timestamp;

        event::emit(AutomationExecuted {
            automation_id: object::uid_to_inner(&automation.id),
            owner: automation.owner,
            execution_count: automation.execution_count,
            timestamp,
        });
    }

    public fun cancel_automation(
        automation: &mut AutomationObject,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        assert!(tx_context::sender(ctx) == automation.owner, 4010);
        assert!(automation.status != STATUS_EXECUTED && automation.status != STATUS_CANCELLED, 4014);

        automation.status = STATUS_CANCELLED;
        automation.updated_at = sui::clock::timestamp_ms(clock);

        event::emit(AutomationCancelled {
            automation_id: object::uid_to_inner(&automation.id),
            owner: automation.owner,
            timestamp: automation.updated_at,
        });
    }

    public fun id(automation: &AutomationObject): ID {
        object::uid_to_inner(&automation.id)
    }

    public fun identity_id(automation: &AutomationObject): ID {
        automation.identity_id
    }

    public fun owner(automation: &AutomationObject): address {
        automation.owner
    }

    public fun automation_type(automation: &AutomationObject): u8 {
        automation.automation_type
    }

    public fun title(automation: &AutomationObject): &vector<u8> {
        &automation.title
    }

    public fun description(automation: &AutomationObject): &vector<u8> {
        &automation.description
    }

    public fun trigger_at(automation: &AutomationObject): u64 {
        automation.trigger_at
    }

    public fun status(automation: &AutomationObject): u8 {
        automation.status
    }

    public fun execution_count(automation: &AutomationObject): u64 {
        automation.execution_count
    }

    public fun last_executed_at(automation: &AutomationObject): &Option<u64> {
        &automation.last_executed_at
    }

    public fun created_at(automation: &AutomationObject): u64 {
        automation.created_at
    }

    public fun updated_at(automation: &AutomationObject): u64 {
        automation.updated_at
    }

    public fun is_active(automation: &AutomationObject): bool {
        automation.status == STATUS_APPROVED || automation.status == STATUS_PENDING
    }

    public fun share(automation: AutomationObject) {
        sui::transfer::share_object(automation);
    }

    #[test_only]
    public fun delete_for_testing(automation: AutomationObject) {
        let AutomationObject {
            id, identity_id: _, owner: _, automation_type: _, title: _, description: _,
            trigger_at: _, recurrence_pattern: _, status: _, execution_count: _,
            last_executed_at: _, created_at: _, updated_at: _,
        } = automation;
        object::delete(id);
    }
}
