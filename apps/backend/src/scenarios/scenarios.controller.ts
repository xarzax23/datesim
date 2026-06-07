import { Controller, Get, Param, NotFoundException } from '@nestjs/common';
import { SCENARIOS } from './scenarios.data';

function toPublicScenario(scenario: (typeof SCENARIOS)[number]) {
  return {
    id: scenario.id,
    name: scenario.name,
    description: scenario.description,
    difficulty: scenario.difficulty,
    characterName: scenario.characterName,
    characterBio: scenario.characterBio,
    openingMessage: scenario.openingMessage,
  };
}

@Controller('scenarios')
export class ScenariosController {
  @Get()
  findAll() {
    return SCENARIOS.map(toPublicScenario);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    const scenario = SCENARIOS.find((s) => s.id === id);
    if (!scenario) throw new NotFoundException(`Scenario ${id} not found`);
    return toPublicScenario(scenario);
  }
}
