<?php

namespace Tests\Feature;

use Tests\TestCase;

class RunSheetAcceptanceContractTest extends TestCase
{
    public function test_run_sheet_acceptance_contract_contains_required_truth_and_isolation_guards(): void
    {
        $path = base_path('docs/PHX_P0_RUN_SHEET_ACCEPTANCE.md');

        $this->assertFileExists($path);
        $contract = file_get_contents($path);
        $this->assertNotFalse($contract);

        foreach (['DRAFT', 'READY', 'LIVE', 'COMPLETED', 'REVIEWED', 'CANCELLED'] as $state) {
            $this->assertStringContainsString($state, $contract);
        }

        foreach (['UNKNOWN', 'tenant', 'store', 'authenticated', 'audit', 'idempot'] as $guard) {
            $this->assertStringContainsStringIgnoringCase($guard, $contract);
        }

        $this->assertStringContainsString('Issue #99', $contract);
        $this->assertStringContainsStringIgnoringCase('PHOENIX', $contract);
    }
}
