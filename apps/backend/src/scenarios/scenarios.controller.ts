import { Controller, Get, Param, NotFoundException } from '@nestjs/common';
import { SCENARIOS } from './scenarios.data';

@Controller('scenarios')
export class ScenariosController {
  @Get()
  findAll() {
    return SCENARIOS.map(({ systemPrompt, ...rest }) => rest);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    const scenario = SCENARIOS.find((s) => s.id === id);
    if (!scenario) throw new NotFoundException(`Scenario ${id} not found`);
    const { systemPrompt, ...rest } = scenario;
    return rest;
  }
}
