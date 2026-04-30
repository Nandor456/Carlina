import {
  IsString,
  IsNotEmpty,
  IsOptional,
  Matches,
  Length,
  IsInt,
  Min,
  Max,
} from 'class-validator';

export class CreateVehicleDto {
  @IsString()
  @IsNotEmpty()
  @Matches(
    /^(?:[A-Z]{1,2}\s\d{2,3}\s[A-Z]{3}|[A-Z]{3}-\d{3}|[A-Z]{2}\s[A-Z]{2}-\d{3})$/,
    {
      message:
        'License plate must match Romanian (e.g., CJ 01 ABC, B 123 ABC) or Hungarian (e.g., ABC-123, AA BB-123) formats',
    },
  )
  licensePlate!: string;

  @IsString()
  @IsNotEmpty()
  make!: string;

  @IsString()
  @IsNotEmpty()
  model!: string;

  @IsInt()
  @Min(1900)
  @Max(new Date().getFullYear() + 1)
  @IsOptional()
  year?: number;

  @IsString()
  @Length(17, 17)
  @IsOptional()
  vin?: string;
}
